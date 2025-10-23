//
//  SettingsViewModel.swift
//  Cyrillic IME
//
//  View model for settings screen
//

import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var profiles: [Profile] = []
    @Published var currentProfileId: String = ""
    @Published var isKeyboardEnabled: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    // MARK: - Computed Properties

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    var rustCoreVersion: String {
        return RustCoreFFI.shared.getVersion()
    }

    // MARK: - Initialization

    init() {
        currentProfileId = UserDefaults.shared.currentProfileId
        setupNotifications()
    }

    private func setupNotifications() {
        // プロファイル変更通知を購読
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProfileChanged),
            name: .profileDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    /// プロファイル一覧をロード
    func loadProfiles() {
        // ProfileManagerを初期化
        if let error = ProfileManager.shared.initialize() {
            showErrorAlert(error)
            return
        }

        profiles = ProfileManager.shared.availableProfiles
        currentProfileId = UserDefaults.shared.currentProfileId

        // 現在のプロファイルのスキーマをロード
        if let error = ProfileManager.shared.loadCurrentSchema() {
            showErrorAlert(error)
        }

        // キーボードが有効かチェック（実際のチェックロジックは後で実装）
        checkKeyboardEnabled()
    }

    /// プロファイルを選択
    func selectProfile(_ profileId: String) {
        guard profileId != currentProfileId else { return }

        if let error = ProfileManager.shared.switchProfile(to: profileId) {
            showErrorAlert(error)
            return
        }

        currentProfileId = profileId
    }

    /// エンジンを再初期化（デバッグ用）
    func reinitializeEngine() {
        // Note: Rust Coreは一度初期化すると再初期化できない仕様
        // この関数は将来の拡張用
        showErrorAlert("Engine reinitialization is not supported")
    }

    /// デバッグ情報を出力
    func printDebugInfo() {
        print("=== Debug Info ===")
        print("Current Profile ID: \(currentProfileId)")
        print("Available Profiles: \(profiles.count)")
        for profile in profiles {
            print("  - \(profile.id): \(profile.displayName)")
        }
        print("Rust Core Version: \(rustCoreVersion)")
        print("Keyboard Enabled: \(isKeyboardEnabled)")
        print("==================")
    }

    // MARK: - Private Methods

    @objc private func handleProfileChanged(_ notification: Notification) {
        if let profile = notification.object as? Profile {
            currentProfileId = profile.id
        }
    }

    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showError = true
        print("[SettingsViewModel] Error: \(message)")
    }

    private func checkKeyboardEnabled() {
        // iOS 16+ では UITextInputMode.activeInputModes を使用してチェック可能
        // 簡易実装：常にfalseを返す（実際の実装は後で追加）
        isKeyboardEnabled = false
    }
}
