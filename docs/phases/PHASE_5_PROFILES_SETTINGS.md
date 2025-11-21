# Phase 5: プロファイル管理と設定機能

**ドキュメントバージョン**: 1.0
**最終更新**: 2025-11-22
**対象**: Phase 5担当エンジニア（メインアプリ開発）
**ステータス**: 🔜 未着手 (Not Started)

---

## 📋 目次

1. [フェーズ概要](#フェーズ概要)
2. [前提条件](#前提条件)
3. [実装する機能](#実装する機能)
4. [UI設計](#ui設計)
5. [実装手順](#実装手順)
6. [完了基準](#完了基準)

---

## フェーズ概要

### 目的
ユーザーがキリル文字プロファイル（ロシア語、セルビア語、ウクライナ語など）を選択・管理できる設定画面を実装する。

### 達成目標
1. 🎯 **プロファイル選択画面**: 利用可能なプロファイル一覧
2. 🎯 **プロファイル詳細**: 各プロファイルのキー配列プレビュー
3. 🎯 **設定同期**: メインアプリ ↔ キーボードExtensionでの設定共有
4. 🎯 **カスタマイズ**: キーボードの見た目とオプション設定
5. 🎯 **ユーザー辞書管理**: 学習データのエクスポート/インポート

### 成果物
- `SettingsViewController.swift` (新規作成, ~400行)
- `ProfileListView.swift` (新規作成, ~200行)
- `ProfileDetailView.swift` (新規作成, ~250行)
- `UserDictionaryView.swift` (新規作成, ~200行)
- `KeyboardThemeSettings.swift` (新規作成, ~150行)

---

## 前提条件

### Phase 1完了事項
- ✅ `ProfileManager`: プロファイル管理
- ✅ `Profile` モデル
- ✅ プロファイルJSON読み込み

### 必要な知識
- SwiftUI（メインアプリUI）
- App Groups（データ共有）
- UserDefaults共有

---

## 実装する機能

### 1. プロファイル選択

#### プロファイル一覧画面
```
┌─────────────────────────────────────┐
│ Pismo 設定                          │
├─────────────────────────────────────┤
│                                     │
│  キーボードプロファイル             │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ ✓ ロシア語標準                │ │ ← 現在選択中
│  │   (русский стандарт)          │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │   セルビア語                  │ │
│  │   (српски)                    │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │   ウクライナ語                │ │
│  │   (українська)                │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │   ブルガリア語                │ │
│  │   (български)                 │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

#### プロファイル詳細画面
```
┌─────────────────────────────────────┐
│ ← ロシア語標準                      │
├─────────────────────────────────────┤
│                                     │
│  キーボードレイアウトプレビュー     │
│                                     │
│  ┌───┬───┬───┬───┬───┬───┬───┐   │
│  │ Й │ Ц │ У │ К │ Е │ Н │ Г │   │
│  └───┴───┴───┴───┴───┴───┴───┘   │
│  ┌───┬───┬───┬───┬───┬───┬───┐   │
│  │ Ф │ Ы │ В │ А │ П │ Р │ О │   │
│  └───┴───┴───┴───┴───┴───┴───┘   │
│  ┌───┬───┬───┬───┬───┬───┬───┐   │
│  │ Я │ Ч │ С │ М │ И │ Т │ Ь │   │
│  └───┴───┴───┴───┴───┴───┴───┘   │
│                                     │
│  変換例:                            │
│  • КА → か (ka)                    │
│  • КЯ → きゃ (kya)                 │
│  • ЧИ → ち (chi)                   │
│                                     │
│  ┌───────────────────────────────┐ │
│  │   このプロファイルを使用       │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

### 2. キーボード設定

#### カスタマイズ項目
```
┌─────────────────────────────────────┐
│ キーボード設定                      │
├─────────────────────────────────────┤
│                                     │
│  入力モード                         │
│  ├─ デフォルト: IME（変換あり）    │
│  ├─ 直接平仮名（変換なし）          │
│  └─ ローマ字表示                    │
│                                     │
│  ライブ変換                         │
│  ├─ 有効  ◉ 無効  ○                │
│  └─ 変換遅延: 0.5秒                 │
│                                     │
│  候補表示                           │
│  ├─ 候補数: 10                      │
│  └─ 詳細表示: 有効                  │
│                                     │
│  テーマ                             │
│  ├─ ライト  ○                       │
│  ├─ ダーク  ◉                       │
│  └─ システム連動  ○                 │
│                                     │
│  サウンド                           │
│  └─ キークリック音: 有効            │
│                                     │
└─────────────────────────────────────┘
```

### 3. ユーザー辞書管理

#### 学習データ管理
```
┌─────────────────────────────────────┐
│ ユーザー辞書                        │
├─────────────────────────────────────┤
│                                     │
│  学習済み単語: 234件                │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ かいしゃ → 開車              │ │
│  │ 使用回数: 15回                │ │
│  │ 最終使用: 2025-11-22          │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ てすと → テスト              │ │
│  │ 使用回数: 8回                 │ │
│  │ 最終使用: 2025-11-21          │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  エクスポート                 │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  インポート                   │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  すべて削除                   │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

## UI設計

### 1. SettingsViewController (SwiftUI)

```swift
//
//  SettingsViewController.swift
//  CyrillicIME (Main App)
//
//  Main settings view
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @StateObject private var settingsStore = SettingsStore.shared

    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section(header: Text("キーボードプロファイル")) {
                    ForEach(profileManager.availableProfiles) { profile in
                        NavigationLink(destination: ProfileDetailView(profile: profile)) {
                            ProfileRowView(
                                profile: profile,
                                isSelected: profile.id == profileManager.currentProfile?.id
                            )
                        }
                    }
                }

                // Keyboard Settings Section
                Section(header: Text("キーボード設定")) {
                    NavigationLink(destination: KeyboardSettingsView()) {
                        Label("入力設定", systemImage: "keyboard")
                    }

                    NavigationLink(destination: ThemeSettingsView()) {
                        Label("テーマ", systemImage: "paintbrush")
                    }

                    NavigationLink(destination: SoundSettingsView()) {
                        Label("サウンド", systemImage: "speaker.wave.2")
                    }
                }

                // User Dictionary Section
                Section(header: Text("ユーザー辞書")) {
                    NavigationLink(destination: UserDictionaryView()) {
                        Label("学習済み単語", systemImage: "book")
                            .badge(settingsStore.userDictionaryCount)
                    }
                }

                // About Section
                Section(header: Text("アプリについて")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }

                    Link("使い方", destination: URL(string: "https://pismo.app/help")!)
                    Link("フィードバック", destination: URL(string: "https://pismo.app/feedback")!)
                }
            }
            .navigationTitle("Pismo 設定")
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

struct ProfileRowView: View {
    let profile: Profile
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.nameJa)
                    .font(.headline)

                Text(profile.nameEn)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}
```

### 2. ProfileDetailView

```swift
//
//  ProfileDetailView.swift
//  CyrillicIME
//
//  Profile detail and preview
//

import SwiftUI

struct ProfileDetailView: View {
    let profile: Profile
    @StateObject private var profileManager = ProfileManager.shared
    @State private var showingActivationAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(profile.nameJa)
                        .font(.title)
                        .bold()

                    Text(profile.nameEn)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                // Keyboard Layout Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("キーボードレイアウト")
                        .font(.headline)
                        .padding(.horizontal)

                    KeyboardPreviewView(layout: profile.keyboardLayout)
                }

                // Conversion Examples
                VStack(alignment: .leading, spacing: 8) {
                    Text("変換例")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        ConversionExampleRow(cyrillic: "КА", hiragana: "か", romaji: "ka")
                        ConversionExampleRow(cyrillic: "КЯ", hiragana: "きゃ", romaji: "kya")
                        ConversionExampleRow(cyrillic: "ЧИ", hiragana: "ち", romaji: "chi")
                        ConversionExampleRow(cyrillic: "ЖИ", hiragana: "じ", romaji: "ji")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Activate Button
                Button(action: activateProfile) {
                    Text(isCurrentProfile ? "使用中" : "このプロファイルを使用")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isCurrentProfile ? Color.green : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(isCurrentProfile)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("プロファイル変更完了", isPresented: $showingActivationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(profile.nameJa) に切り替えました")
        }
    }

    private var isCurrentProfile: Bool {
        profile.id == profileManager.currentProfile?.id
    }

    private func activateProfile() {
        profileManager.setCurrentProfile(profile)
        showingActivationAlert = true
    }
}

struct KeyboardPreviewView: View {
    let layout: [[String]]

    var body: some View {
        VStack(spacing: 4) {
            ForEach(layout, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(row, id: \.self) { key in
                        Text(key)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 40, height: 40)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
    }
}

struct ConversionExampleRow: View {
    let cyrillic: String
    let hiragana: String
    let romaji: String

    var body: some View {
        HStack(spacing: 16) {
            Text(cyrillic)
                .font(.system(size: 20, weight: .bold))
                .frame(width: 60)

            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)

            Text(hiragana)
                .font(.system(size: 24))
                .frame(width: 60)

            Text("(\(romaji))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

### 3. UserDictionaryView

```swift
//
//  UserDictionaryView.swift
//  CyrillicIME
//
//  User dictionary management
//

import SwiftUI

struct UserDictionaryView: View {
    @StateObject private var userDictionary = UserDictionary()
    @State private var entries: [(String, [String])] = []
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            Section(header: Text("学習済み単語 (\(entries.count)件)")) {
                ForEach(entries, id: \.0) { input, outputs in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(input)
                                .font(.body)
                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text(outputs.first ?? "")
                                .font(.headline)
                        }

                        if outputs.count > 1 {
                            Text("他 \(outputs.count - 1) 件")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteEntries)
            }

            Section {
                Button(action: { showingExportSheet = true }) {
                    Label("エクスポート", systemImage: "square.and.arrow.up")
                }

                Button(action: { showingImportSheet = true }) {
                    Label("インポート", systemImage: "square.and.arrow.down")
                }

                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    Label("すべて削除", systemImage: "trash")
                }
            }
        }
        .navigationTitle("ユーザー辞書")
        .onAppear(perform: loadEntries)
        .sheet(isPresented: $showingExportSheet) {
            ExportView(entries: entries)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportView(onImport: importEntries)
        }
        .alert("ユーザー辞書を削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                userDictionary.clear()
                loadEntries()
            }
        } message: {
            Text("すべての学習データが削除されます。この操作は取り消せません。")
        }
    }

    private func loadEntries() {
        // Load from UserDictionary
        // TODO: Implement
    }

    private func deleteEntries(at offsets: IndexSet) {
        // TODO: Implement
    }

    private func importEntries(data: Data) {
        // TODO: Implement
    }
}
```

---

## 実装手順

### Step 1: App Group設定（0.5日）
```swift
// 1. Xcodeで App Groups を有効化
// Target → Signing & Capabilities → + Capability → App Groups
// group.com.pismo.shared を追加

// 2. UserDefaults共有設定
extension UserDefaults {
    static let shared = UserDefaults(suiteName: "group.com.pismo.shared")!
}

// 3. ProfileManagerを更新
class ProfileManager {
    private let defaults = UserDefaults.shared  // 共有UserDefaults
}
```

### Step 2: SwiftUIビュー作成（3日）
1. SettingsView
2. ProfileDetailView
3. UserDictionaryView
4. KeyboardSettingsView
5. ThemeSettingsView

### Step 3: データ同期実装（2日）
1. プロファイル変更通知
2. 設定変更通知
3. ユーザー辞書同期

### Step 4: エクスポート/インポート（2日）
1. JSON形式でエクスポート
2. ファイル選択とインポート
3. データ検証

### Step 5: テストと調整（1日）

---

## 完了基準

### 機能完了基準

#### AC5.1: プロファイル切り替え
```gherkin
Given メインアプリの設定画面を開く
When 「セルビア語」プロファイルを選択
Then キーボードExtensionで「セルビア語」が使用される
And キーボードレイアウトが変更される
```

#### AC5.2: 設定同期
```gherkin
Given メインアプリで「ライブ変換:無効」に設定
When キーボードを開く
Then ライブ変換が無効になっている
```

#### AC5.3: ユーザー辞書管理
```gherkin
Given ユーザー辞書に50件の学習データがある
When 「エクスポート」を実行
Then JSONファイルがエクスポートされる
And 50件すべてのデータが含まれる
```

---

**ドキュメント終わり**
