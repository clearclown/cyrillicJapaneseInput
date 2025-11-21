//
//  SettingsView.swift
//  CyrillicIME
//
//  Settings screen for Pismo IME
//  Phase 5: Profile and Settings UI
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @AppStorage("enableLiveConversion") private var enableLiveConversion = true
    @AppStorage("enableHapticFeedback") private var enableHapticFeedback = true
    @AppStorage("showKeyboardPreview") private var showKeyboardPreview = true
    @State private var showingProfileSheet = false

    var body: some View {
        NavigationView {
            Form {
                // Profile Selection Section
                Section {
                    Button(action: {
                        showingProfileSheet = true
                    }) {
                        HStack {
                            Text("キーボードプロファイル")
                                .foregroundColor(.primary)
                            Spacer()
                            if let current = profileManager.currentProfile {
                                Text(current.nameJa)
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("プロファイル")
                } footer: {
                    Text("キリル文字配列を選択してください。各配列により同じ日本語音でも異なるキーを使います。")
                }

                // Input Settings Section
                Section {
                    Toggle("ライブ変換", isOn: $enableLiveConversion)
                    Toggle("ハプティックフィードバック", isOn: $enableHapticFeedback)
                    Toggle("キープレビュー表示", isOn: $showKeyboardPreview)
                } header: {
                    Text("入力設定")
                } footer: {
                    Text("ライブ変換：入力中に自動的に漢字変換を行います")
                }

                // User Dictionary Section
                Section {
                    NavigationLink(destination: UserDictionaryView()) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                            Text("ユーザー辞書")
                        }
                    }

                    Button(action: clearLearningData) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("学習データをクリア")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("辞書")
                } footer: {
                    Text("学習データには変換履歴と頻度情報が含まれます")
                }

                // About Section
                Section {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/clearclown/cyrillicJapaneseInput")!) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                            Text("GitHubで見る")
                        }
                    }
                } header: {
                    Text("アプリについて")
                }

                // Keyboard Setup Guide
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("キーボードの有効化")
                            .font(.headline)

                        Text("1. 設定 > 一般 > キーボード")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("2. キーボード > 新しいキーボードを追加")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("3. Pismo を選択")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button(action: openKeyboardSettings) {
                            HStack {
                                Image(systemName: "gear")
                                Text("設定を開く")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("セットアップ")
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showingProfileSheet) {
                ProfileSelectionView()
            }
        }
    }

    // MARK: - Actions

    private func clearLearningData() {
        // Clear learning data from PredictiveEngine
        UserDefaults.standard.removeObject(forKey: "PredictiveEngine.BigramMap")
        UserDefaults.standard.removeObject(forKey: "PredictiveEngine.UnigramMap")
        UserDefaults.standard.removeObject(forKey: "PredictiveEngine.RecentUsage")
        print("[SettingsView] Learning data cleared")
    }

    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - User Dictionary View (Placeholder)

struct UserDictionaryView: View {
    @State private var userWords: [UserDictionaryEntry] = []

    var body: some View {
        List {
            if userWords.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("ユーザー辞書は空です")
                        .font(.headline)

                    Text("よく使う単語を登録すると、変換候補の上位に表示されます")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(userWords) { entry in
                    VStack(alignment: .leading) {
                        Text(entry.word)
                            .font(.headline)
                        Text(entry.reading)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete(perform: deleteWords)
            }
        }
        .navigationTitle("ユーザー辞書")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: addWord) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            loadUserDictionary()
        }
    }

    private func loadUserDictionary() {
        // TODO: Load from UserDefaults or database
    }

    private func addWord() {
        // TODO: Show add word sheet
    }

    private func deleteWords(at offsets: IndexSet) {
        userWords.remove(atOffsets: offsets)
    }
}

struct UserDictionaryEntry: Identifiable {
    let id = UUID()
    let word: String
    let reading: String
    var frequency: Int = 0
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
