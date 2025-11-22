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

                // Preview Section
                Section {
                    NavigationLink(destination: KeyboardLayoutPreview()) {
                        HStack {
                            Image(systemName: "keyboard.fill")
                                .foregroundColor(.purple)
                            Text("レイアウトプレビュー")
                        }
                    }
                } header: {
                    Text("キーボード")
                } footer: {
                    Text("選択したプロファイルのキーボード配列を確認できます")
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

                // Help Section
                Section {
                    NavigationLink(destination: TutorialView()) {
                        HStack {
                            Image(systemName: "graduationcap.fill")
                                .foregroundColor(.green)
                            Text("使い方チュートリアル")
                        }
                    }

                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                            Text("Pismoについて")
                        }
                    }
                } header: {
                    Text("ヘルプ")
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

// MARK: - User Dictionary View

struct UserDictionaryView: View {
    @StateObject private var dictionaryManager = UserDictionaryManager.shared
    @State private var showingAddSheet = false
    @State private var showingClearAlert = false

    var body: some View {
        List {
            if dictionaryManager.entries.isEmpty {
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
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .listRowBackground(Color.clear)
            } else {
                // Statistics Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        StatRow(label: "登録単語数", value: "\(dictionaryManager.entries.count)件")
                        StatRow(label: "総使用回数", value: "\(dictionaryManager.statistics.totalUsage)回")
                    }
                } header: {
                    Text("統計")
                }

                // Dictionary Entries
                Section {
                    ForEach(dictionaryManager.entries.sorted(by: { $0.frequency > $1.frequency })) { entry in
                        DictionaryEntryRow(entry: entry)
                    }
                    .onDelete(perform: deleteEntries)
                } header: {
                    Text("登録単語（頻度順）")
                }
            }
        }
        .navigationTitle("ユーザー辞書")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }

            if !dictionaryManager.entries.isEmpty {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingClearAlert = true }) {
                        Text("全削除")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddDictionaryEntryView()
        }
        .alert("全削除の確認", isPresented: $showingClearAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                dictionaryManager.clearAll()
            }
        } message: {
            Text("すべてのユーザー辞書エントリを削除してもよろしいですか？この操作は取り消せません。")
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        dictionaryManager.removeEntries(at: offsets)
    }
}

// MARK: - Supporting Views

struct DictionaryEntryRow: View {
    let entry: UserDictionaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.output)
                .font(.headline)

            HStack {
                Text("読み: \(entry.reading)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if entry.frequency > 0 {
                    Text("使用: \(entry.frequency)回")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
