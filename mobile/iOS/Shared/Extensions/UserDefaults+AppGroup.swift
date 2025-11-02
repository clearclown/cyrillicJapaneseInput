//
//  UserDefaults+AppGroup.swift
//  Cyrillic IME
//
//  App Group shared UserDefaults
//

import Foundation

extension UserDefaults {
    /// App Group識別子
    /// Main AppとKeyboard Extension間でデータを共有するために使用
    static let appGroupIdentifier = "group.com.yourcompany.cyrillicime"

    /// Shared UserDefaults instance
    static var shared: UserDefaults {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            fatalError("Unable to create UserDefaults with suite name: \(appGroupIdentifier)")
        }
        return defaults
    }

    // MARK: - Keys
    enum Keys {
        static let currentProfileId = "current_profile_id"
        static let hasCompletedOnboarding = "has_completed_onboarding"
    }

    // MARK: - Profile Management
    var currentProfileId: String {
        get {
            string(forKey: Keys.currentProfileId) ?? "rus_standard"
        }
        set {
            set(newValue, forKey: Keys.currentProfileId)
        }
    }

    var hasCompletedOnboarding: Bool {
        get {
            bool(forKey: Keys.hasCompletedOnboarding)
        }
        set {
            set(newValue, forKey: Keys.hasCompletedOnboarding)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    /// プロファイルが変更されたことを通知
    static let profileDidChange = Notification.Name("profileDidChange")
}
