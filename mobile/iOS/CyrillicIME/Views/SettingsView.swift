//
//  SettingsView.swift
//  Cyrillic IME
//
//  Main settings screen
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationView {
            List {
                // プロファイル選択セクション
                Section {
                    ForEach(viewModel.profiles) { profile in
                        ProfileRow(
                            profile: profile,
                            isSelected: profile.id == viewModel.currentProfileId
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectProfile(profile.id)
                        }
                    }
                } header: {
                    Text("入力プロファイル")
                } footer: {
                    Text("使用するキリル文字配列を選択してください")
                }

                // キーボード設定セクション
                Section {
                    NavigationLink {
                        KeyboardSetupGuideView()
                    } label: {
                        Label("キーボードの設定方法", systemImage: "keyboard")
                    }

                    if !viewModel.isKeyboardEnabled {
                        Text("キーボードが有効になっていません")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                } header: {
                    Text("設定")
                }

                // 情報セクション
                Section {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Rust Core")
                        Spacer()
                        Text(viewModel.rustCoreVersion)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("情報")
                }

                // テストセクション（DEBUG時のみ）
                #if DEBUG
                Section {
                    Button("エンジンを再初期化") {
                        viewModel.reinitializeEngine()
                    }

                    Button("ログを出力") {
                        viewModel.printDebugInfo()
                    }
                } header: {
                    Text("デバッグ")
                }
                #endif
            }
            .navigationTitle("Cyrillic IME")
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .onAppear {
            viewModel.loadProfiles()
        }
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let profile: Profile
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(.body)

                Text(profile.id)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Keyboard Setup Guide

struct KeyboardSetupGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("キーボードの有効化")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 12) {
                    StepView(
                        number: 1,
                        title: "設定アプリを開く",
                        description: "iOSの「設定」アプリを開いてください"
                    )

                    StepView(
                        number: 2,
                        title: "一般 > キーボード",
                        description: "「一般」→「キーボード」の順にタップ"
                    )

                    StepView(
                        number: 3,
                        title: "キーボード",
                        description: "「キーボード」をタップ"
                    )

                    StepView(
                        number: 4,
                        title: "新しいキーボードを追加",
                        description: "「新しいキーボードを追加...」をタップ"
                    )

                    StepView(
                        number: 5,
                        title: "Cyrillic IMEを選択",
                        description: "リストから「Cyrillic IME」を選択"
                    )

                    StepView(
                        number: 6,
                        title: "フルアクセスを許可（任意）",
                        description: "キーボード設定で「フルアクセスを許可」をオンにすると、より高度な機能が利用できます"
                    )
                }

                Divider()
                    .padding(.vertical, 8)

                Text("使い方")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 12) {
                    UsageStepView(
                        icon: "🌐",
                        title: "キーボードを切り替え",
                        description: "キーボードの地球儀ボタンを長押しして「Cyrillic IME」を選択"
                    )

                    UsageStepView(
                        icon: "⌨️",
                        title: "キリル文字で入力",
                        description: "キリル文字キーを押して日本語ひらがなに変換"
                    )

                    UsageStepView(
                        icon: "✨",
                        title: "プロファイル切り替え",
                        description: "このアプリで言語プロファイルを変更できます"
                    )
                }
            }
            .padding()
        }
        .navigationTitle("設定方法")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StepView: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct UsageStepView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
