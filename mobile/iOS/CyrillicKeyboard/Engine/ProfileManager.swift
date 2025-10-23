//
//  ProfileManager.swift
//  Cyrillic IME
//
//  Manages input profiles and schema loading
//

import Foundation

/// プロファイルとスキーマの管理を担当
class ProfileManager {
    // MARK: - Singleton
    static let shared = ProfileManager()

    // MARK: - Properties
    private(set) var availableProfiles: [Profile] = []
    private var loadedSchemas: Set<String> = []

    var currentProfile: Profile? {
        let currentId = UserDefaults.shared.currentProfileId
        return availableProfiles.first { $0.id == currentId }
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
        guard let kanaEngineJSON = loadBundledJSON(filename: "kana_engine") else {
            return "Failed to load kana_engine.json"
        }

        // 3. プロファイル配列をパース
        guard let profilesData = profilesJSON.data(using: .utf8) else {
            return "Invalid UTF-8 in profiles.json"
        }

        do {
            availableProfiles = try JSONDecoder().decode([Profile].self, from: profilesData)
        } catch {
            return "Failed to decode profiles.json: \(error.localizedDescription)"
        }

        // 4. Rust Coreエンジンを初期化
        if let error = RustCoreFFI.shared.initEngine(
            profilesJSON: profilesJSON,
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
        // Bundle検索：Keyboard Extension Bundle -> Main Bundle
        let bundles = [
            Bundle(identifier: "com.yourcompany.cyrillicime.keyboard"),
            Bundle.main
        ].compactMap { $0 }

        for bundle in bundles {
            if let url = bundle.url(forResource: filename, withExtension: "json", subdirectory: subdirectory),
               let data = try? Data(contentsOf: url),
               let jsonString = String(data: data, encoding: .utf8) {
                print("[ProfileManager] Loaded \(filename).json from bundle: \(bundle.bundleIdentifier ?? "unknown")")
                return jsonString
            }
        }

        print("[ProfileManager] Error: Could not find \(filename).json")
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
