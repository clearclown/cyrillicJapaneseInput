//
//  AppLanguageSettingView.swift
//  MainApp
//
//  Created for Pismo Cyrillic keyboard
//

import SwiftUI

/// アプリの表示言語を選択するビュー
struct AppLanguageSettingView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    var body: some View {
        Form {
            Section {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Button {
                        appLanguage = language.rawValue
                        updateAppLanguage(language)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(language.displayName)
                                    .foregroundStyle(.primary)
                                Text(language.localizedName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if appLanguage == language.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            } footer: {
                Text("言語を変更すると、アプリを再起動する必要があります。")
            }

            Section {
                Button("設定アプリで言語を変更") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } footer: {
                Text("iOSの設定アプリからも言語を変更できます。")
            }
        }
        .navigationTitle("アプリの表示言語")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func updateAppLanguage(_ language: AppLanguage) {
        // システム言語に戻す場合は設定を削除
        if language == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([language.languageCode], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }
}

/// サポートされているアプリ言語
enum AppLanguage: String, CaseIterable {
    case system = "system"
    case japanese = "ja"
    case english = "en"
    case russian = "ru"
    case ukrainian = "uk"
    case korean = "ko"
    case chinese = "zh-Hans"

    /// 言語の表示名（その言語で）
    var displayName: String {
        switch self {
        case .system: return "システム設定に従う"
        case .japanese: return "日本語"
        case .english: return "English"
        case .russian: return "Русский"
        case .ukrainian: return "Українська"
        case .korean: return "한국어"
        case .chinese: return "简体中文"
        }
    }

    /// 言語の説明（日本語で）
    var localizedName: String {
        switch self {
        case .system: return "Use System Language"
        case .japanese: return "Japanese"
        case .english: return "英語"
        case .russian: return "ロシア語"
        case .ukrainian: return "ウクライナ語"
        case .korean: return "韓国語"
        case .chinese: return "中国語（簡体字）"
        }
    }

    /// 言語コード
    var languageCode: String {
        switch self {
        case .system: return ""
        case .japanese: return "ja"
        case .english: return "en"
        case .russian: return "ru"
        case .ukrainian: return "uk"
        case .korean: return "ko"
        case .chinese: return "zh-Hans"
        }
    }
}

#Preview {
    NavigationStack {
        AppLanguageSettingView()
    }
}
