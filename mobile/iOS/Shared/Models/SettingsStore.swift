//
//  SettingsStore.swift
//  Cyrillic IME
//
//  Centralized settings management for keyboard preferences
//

import Foundation
import Combine

/// キーボード設定のテーマ
enum KeyboardTheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var displayName: String {
        switch self {
        case .light: return "ライト"
        case .dark: return "ダーク"
        case .system: return "システム連動"
        }
    }
}

/// キーボード設定の集中管理クラス
class SettingsStore: ObservableObject {
    // MARK: - Singleton
    static let shared = SettingsStore()

    // MARK: - Published Properties

    /// ライブ変換が有効かどうか
    @Published var liveConversionEnabled: Bool {
        didSet {
            UserDefaults.shared.set(liveConversionEnabled, forKey: Keys.liveConversionEnabled)
            postSettingsChangedNotification()
        }
    }

    /// ライブ変換の遅延時間（秒）
    @Published var liveConversionDelay: Double {
        didSet {
            UserDefaults.shared.set(liveConversionDelay, forKey: Keys.liveConversionDelay)
            postSettingsChangedNotification()
        }
    }

    /// 候補表示数
    @Published var candidateCount: Int {
        didSet {
            UserDefaults.shared.set(candidateCount, forKey: Keys.candidateCount)
            postSettingsChangedNotification()
        }
    }

    /// 候補の詳細表示が有効かどうか
    @Published var showDetailedCandidates: Bool {
        didSet {
            UserDefaults.shared.set(showDetailedCandidates, forKey: Keys.showDetailedCandidates)
            postSettingsChangedNotification()
        }
    }

    /// キーボードテーマ
    @Published var keyboardTheme: KeyboardTheme {
        didSet {
            UserDefaults.shared.set(keyboardTheme.rawValue, forKey: Keys.keyboardTheme)
            postSettingsChangedNotification()
        }
    }

    /// キークリック音が有効かどうか
    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.shared.set(soundEnabled, forKey: Keys.soundEnabled)
            postSettingsChangedNotification()
        }
    }

    /// デフォルト入力モード
    @Published var defaultInputMode: InputMode {
        didSet {
            UserDefaults.shared.currentInputMode = defaultInputMode
            postSettingsChangedNotification()
        }
    }

    /// ユーザー辞書のエントリ数（読み取り専用）
    @Published private(set) var userDictionaryCount: Int = 0

    // MARK: - Keys
    private enum Keys {
        static let liveConversionEnabled = "live_conversion_enabled"
        static let liveConversionDelay = "live_conversion_delay"
        static let candidateCount = "candidate_count"
        static let showDetailedCandidates = "show_detailed_candidates"
        static let keyboardTheme = "keyboard_theme"
        static let soundEnabled = "sound_enabled"
    }

    // MARK: - Initialization

    private init() {
        let defaults = UserDefaults.shared

        // デフォルト値を設定
        self.liveConversionEnabled = defaults.bool(forKey: Keys.liveConversionEnabled)
        self.liveConversionDelay = defaults.double(forKey: Keys.liveConversionDelay) == 0 ? 0.5 : defaults.double(forKey: Keys.liveConversionDelay)
        self.candidateCount = defaults.integer(forKey: Keys.candidateCount) == 0 ? 10 : defaults.integer(forKey: Keys.candidateCount)
        self.showDetailedCandidates = defaults.bool(forKey: Keys.showDetailedCandidates)

        let themeRawValue = defaults.string(forKey: Keys.keyboardTheme) ?? KeyboardTheme.system.rawValue
        self.keyboardTheme = KeyboardTheme(rawValue: themeRawValue) ?? .system

        self.soundEnabled = defaults.bool(forKey: Keys.soundEnabled)
        self.defaultInputMode = defaults.currentInputMode

        // ユーザー辞書の件数を読み込み
        loadUserDictionaryCount()
    }

    // MARK: - Public Methods

    /// すべての設定をデフォルトに戻す
    func resetToDefaults() {
        liveConversionEnabled = false
        liveConversionDelay = 0.5
        candidateCount = 10
        showDetailedCandidates = false
        keyboardTheme = .system
        soundEnabled = false
        defaultInputMode = .japaneseHiragana
    }

    /// ユーザー辞書の件数を更新
    func updateUserDictionaryCount(_ count: Int) {
        userDictionaryCount = count
    }

    // MARK: - Private Methods

    private func loadUserDictionaryCount() {
        // TODO: 実際のユーザー辞書から件数を取得
        // 現時点ではダミー値
        userDictionaryCount = 0
    }

    private func postSettingsChangedNotification() {
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// 設定が変更されたことを通知
    static let settingsDidChange = Notification.Name("settingsDidChange")
}
