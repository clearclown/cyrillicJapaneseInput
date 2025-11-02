//
//  CyrillicIMEApp.swift
//  Cyrillic IME
//
//  App entry point
//

import SwiftUI

@main
struct CyrillicIMEApp: App {
    init() {
        // アプリ起動時の初期化処理
        setupApp()
    }

    var body: some Scene {
        WindowGroup {
            SettingsView()
        }
    }

    private func setupApp() {
        // オンボーディング完了チェック
        if !UserDefaults.shared.hasCompletedOnboarding {
            // 初回起動時の処理
            print("[App] First launch detected")
            // デフォルトプロファイルを設定
            UserDefaults.shared.currentProfileId = "rus_standard"
            UserDefaults.shared.hasCompletedOnboarding = true
        }

        print("[App] Initialized")
        print("[App] Current Profile: \(UserDefaults.shared.currentProfileId)")
    }
}
