//
//  ProfileManager.swift
//  Cyrillic IME
//
//  Manages input profiles and schema loading
//

import Foundation
import Combine

/// プロファイルとスキーマの管理を担当
class ProfileManager: ObservableObject {
    // MARK: - Singleton
    static let shared = ProfileManager()

    // MARK: - Properties
    @Published private(set) var availableProfiles: [Profile] = []
    private var loadedSchemas: Set<String> = []
    private var schemaCache: [String: Schema] = [:]

    var currentProfile: Profile? {
        let currentId = UserDefaults.shared.currentProfileId
        return availableProfiles.first { $0.id == currentId }
    }

    /// 現在のプロファイルのスキーマを取得
    var currentSchema: Schema? {
        guard let profile = currentProfile else { return nil }
        return schemaCache[profile.inputSchemaId]
    }

    private init() {}

    // MARK: - Initialization

    /// プロファイルとエンジンを初期化
    /// - Returns: 成功時はnil、エラー時はエラーメッセージ
    func initialize() -> String? {
        // 1. プロファイルJSONをロード
        guard let profilesJSON = loadBundledJSON(filename: "profiles") else {
            return "Failed to load profiles.json"
        }

        // 2. かなエンジンJSONをロード
        guard let kanaEngineJSON = loadBundledJSON(filename: "japaneseKanaEngine") else {
            return "Failed to load japaneseKanaEngine.json"
        }

        // 3. プロファイル配列をパース（新しい行ベース構造）
        guard let profilesData = profilesJSON.data(using: .utf8) else {
            return "Invalid UTF-8 in profiles.json"
        }

        do {
            availableProfiles = try JSONDecoder().decode([Profile].self, from: profilesData)
        } catch {
            return "Failed to decode profiles.json: \(error.localizedDescription)"
        }

        // 4. Rust Core用に古いフォーマット（フラット配列）に変換
        let rustProfiles = availableProfiles.map { profile -> [String: Any] in
            return [
                "id": profile.id,
                "name_ja": profile.nameJa,
                "name_en": profile.nameEn,
                "keyboardLayout": profile.keyboardLayout.allKeys,  // 配列に変換
                "inputSchemaId": profile.inputSchemaId
            ]
        }

        guard let rustProfilesData = try? JSONSerialization.data(withJSONObject: rustProfiles),
              let rustProfilesJSON = String(data: rustProfilesData, encoding: .utf8) else {
            return "Failed to serialize profiles for Rust engine"
        }

        // 5. Rust Coreエンジンを初期化
        if let error = RustCoreFFI.shared.initEngine(
            profilesJSON: rustProfilesJSON,
            kanaEngineJSON: kanaEngineJSON
        ) {
            return "Failed to initialize Rust engine: \(error)"
        }

        print("[ProfileManager] Initialized with \(availableProfiles.count) profiles")
        return nil
    }

    // MARK: - Schema Loading

    /// 指定したプロファイルのスキーマをロード
    /// - Parameter profile: ロードするプロファイル
    /// - Returns: 成功時はnil、エラー時はエラーメッセージ
    func loadSchemaForProfile(_ profile: Profile) -> String? {
        let schemaId = profile.inputSchemaId

        // 既にロード済みならスキップ
        if loadedSchemas.contains(schemaId) {
            print("[ProfileManager] Schema \(schemaId) already loaded")
            return nil
        }

        // スキーマJSONファイルをロード
        guard let schemaJSON = loadBundledJSON(filename: schemaId, subdirectory: "schemas") else {
            return "Failed to load schema file: \(schemaId).json"
        }

        // Swift側でスキーマをパースしてキャッシュ
        guard let schemaData = schemaJSON.data(using: .utf8) else {
            return "Invalid UTF-8 in \(schemaId).json"
        }

        do {
            let schema = try JSONDecoder().decode(Schema.self, from: schemaData)
            schemaCache[schemaId] = schema
            print("[ProfileManager] Parsed schema \(schemaId) with \(schema.count) entries")
        } catch {
            return "Failed to decode schema \(schemaId): \(error.localizedDescription)"
        }

        // Rust Coreにスキーマをロード
        if let error = RustCoreFFI.shared.loadSchema(schemaJSON: schemaJSON, schemaId: schemaId) {
            return "Failed to load schema \(schemaId): \(error)"
        }

        loadedSchemas.insert(schemaId)
        print("[ProfileManager] Loaded schema: \(schemaId)")
        return nil
    }

    /// 現在のプロファイルのスキーマをロード
    /// - Returns: 成功時はnil、エラー時はエラーメッセージ
    func loadCurrentSchema() -> String? {
        guard let profile = currentProfile else {
            return "No current profile set"
        }
        return loadSchemaForProfile(profile)
    }

    // MARK: - Profile Switching

    /// プロファイルを切り替え
    /// - Parameter profileId: 切り替え先のプロファイルID
    /// - Returns: 成功時はnil、エラー時はエラーメッセージ
    func switchProfile(to profileId: String) -> String? {
        guard let profile = availableProfiles.first(where: { $0.id == profileId }) else {
            return "Profile not found: \(profileId)"
        }

        // スキーマをロード（未ロードの場合）
        if let error = loadSchemaForProfile(profile) {
            return error
        }

        // UserDefaultsに保存
        UserDefaults.shared.currentProfileId = profileId

        // 通知を送信
        NotificationCenter.default.post(name: .profileDidChange, object: profile)

        print("[ProfileManager] Switched to profile: \(profileId)")
        return nil
    }

    // MARK: - Helper Methods

    /// Bundleから指定したJSONファイルを読み込む
    /// - Parameters:
    ///   - filename: ファイル名（拡張子なし）
    ///   - subdirectory: サブディレクトリ（オプション）
    /// - Returns: JSON文字列、読み込み失敗時はnil
    private func loadBundledJSON(filename: String, subdirectory: String? = nil) -> String? {
        // Bundle.main はKeyboard Extension内ではExtensionのBundleを指す
        let bundle = Bundle.main

        if let url = bundle.url(forResource: filename, withExtension: "json", subdirectory: subdirectory) {
            print("[ProfileManager] Found \(filename).json at: \(url.path)")

            if let data = try? Data(contentsOf: url),
               let jsonString = String(data: data, encoding: .utf8) {
                print("[ProfileManager] Successfully loaded \(filename).json from bundle: \(bundle.bundleIdentifier ?? "unknown")")
                return jsonString
            } else {
                print("[ProfileManager] Error: Could not read data from \(url.path)")
            }
        } else {
            print("[ProfileManager] Error: Could not find \(filename).json in bundle")
            print("[ProfileManager] Bundle path: \(bundle.bundlePath)")
            if let resourcePath = bundle.resourcePath {
                print("[ProfileManager] Resource path: \(resourcePath)")
            }
        }

        return nil
    }

    // MARK: - Validation

    /// プロファイルが有効かチェック
    /// - Parameter profileId: チェックするプロファイルID
    /// - Returns: 有効な場合true
    func isValidProfile(_ profileId: String) -> Bool {
        return availableProfiles.contains { $0.id == profileId }
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension ProfileManager {
    /// テスト用の初期化（プロファイル直接設定）
    func initializeForTesting(profiles: [Profile]) {
        availableProfiles = profiles
    }
}
#endif
