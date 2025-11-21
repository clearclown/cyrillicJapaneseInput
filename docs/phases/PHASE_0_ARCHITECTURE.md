# Phase 0: 全体アーキテクチャとセットアップ

**ドキュメントバージョン**: 1.0
**最終更新**: 2025-11-22
**対象**: 全エンジニア（必読）

---

## 📋 目次

1. [プロジェクト概要](#プロジェクト概要)
2. [アーキテクチャ全体像](#アーキテクチャ全体像)
3. [技術スタック](#技術スタック)
4. [ディレクトリ構造](#ディレクトリ構造)
5. [開発環境セットアップ](#開発環境セットアップ)
6. [フェーズ間の依存関係](#フェーズ間の依存関係)
7. [コーディング規約](#コーディング規約)

---

## プロジェクト概要

### プロジェクト名
**Pismo (旧: Cyrillic Japanese IME)**

### 目的
キリル文字を使って日本語を入力できるIME（Input Method Editor）を開発する。

### 主要機能
1. **キリル文字 → 日本語平仮名変換**
2. **平仮名 → 漢字変換**
3. **リアルタイム変換**
4. **複数のキリル文字変種対応**（ロシア語、セルビア語、ウクライナ語、ブルガリア語など）

### 技術的特徴
- **Two-Stage Normalized Mapping**: `Cyrillic Character → Phonetic Key → Hiragana`
- **Hybrid-Native Architecture**: Rust Core (変換ロジック) + Swift/Kotlin UI
- **Offline-First**: すべての機能がネットワーク不要

---

## アーキテクチャ全体像

### システム構成図

```
┌─────────────────────────────────────────────────────────┐
│                  KeyboardViewController                 │
│            (UIInputViewController: iOS標準)             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│              CyrillicInputManager                       │
│         (入力処理のオーケストレーター)                  │
└──┬────┬────┬─────────────┬──────────────────┬──────────┘
   │    │    │             │                  │
   ↓    ↓    ↓             ↓                  ↓
┌─────┐ │ ┌──────────┐ ┌─────────────┐  ┌──────────────┐
│Rust │ │ │Displayed │ │Composing    │  │Kanji         │
│Core │ │ │Text      │ │Text         │  │Conversion    │
│(FFI)│ │ │Manager   │ │             │  │Engine        │
└─────┘ │ └──────────┘ └─────────────┘  └──────────────┘
        ↓
   ┌──────────┐
   │Live      │
   │Conversion│
   └──────────┘
```

### コンポーネント説明

#### 1. **KeyboardViewController**
- **役割**: UIライフサイクル管理、UI イベント処理
- **責務**: マネージャーへの委譲のみ、ビジネスロジックを持たない
- **Phase**: Phase 1で実装完了

#### 2. **CyrillicInputManager**
- **役割**: 入力処理のオーケストレーター
- **責務**:
  - キー入力の処理
  - 状態管理
  - コンポーネント間の調整
- **Phase**: Phase 1で基礎実装、Phase 2-5で拡張

#### 3. **DisplayedTextManager**
- **役割**: iOS IME プロトコルの抽象化
- **責務**:
  - `setMarkedText` / `unmarkText` の管理
  - テキストフィールドへの挿入
  - カーソル位置管理
- **Phase**: Phase 1で実装完了

#### 4. **CyrillicComposingText**
- **役割**: 入力状態の管理
- **責務**:
  - キリル文字入力履歴
  - 平仮名バッファ
  - Delete時の再構築
- **Phase**: Phase 1で実装完了

#### 5. **RustCoreFFI**
- **役割**: Rust Core エンジンとの FFI ブリッジ
- **責務**:
  - キリル文字 → 平仮名変換
  - スキーマ管理
- **Phase**: 既存（変更不要）

#### 6. **KanjiConversionEngine** (Phase 2)
- **役割**: 平仮名 → 漢字変換
- **責務**:
  - 候補生成
  - 学習機能
  - 予測変換
- **Phase**: Phase 2で実装

#### 7. **LiveConversionManager** (Phase 3)
- **役割**: リアルタイム変換
- **責務**:
  - 入力中の自動変換
  - 候補の自動選択
- **Phase**: Phase 3で実装

---

## 技術スタック

### iOS
- **言語**: Swift 5.9+
- **最小OS**: iOS 15.0
- **UI Framework**: UIKit
- **プロジェクト管理**: XcodeGen
- **依存管理**: Swift Package Manager

### Android (将来)
- **言語**: Kotlin 1.9+
- **最小API**: Android 8.0 (API 26)
- **UI Framework**: Jetpack Compose
- **ビルドシステム**: Gradle + Kotlin DSL

### 共通
- **Core Engine**: Rust 1.70+
- **FFI**: UniFFI (iOS), JNI (Android)
- **辞書**: JSON形式
- **変換エンジン**: azooKey KanaKanjiConverter (Phase 2)

---

## ディレクトリ構造

```
cyrillicJapaneseInput/
├── docs/                          # ドキュメント
│   ├── phases/                    # フェーズ別要件（このドキュメント）
│   ├── repos/                     # 参考実装
│   │   ├── azooKey/              # 日本語IME参考
│   │   └── JapaneseKeyboardKit/
│   ├── cyrillicJapaneseInput.xlsx # 変換仕様
│   └── 要件定義書.md
│
├── mobile/
│   └── iOS/
│       ├── Shared/               # 共有モデル・ユーティリティ
│       │   ├── Models/
│       │   │   ├── Profile.swift
│       │   │   ├── InputMode.swift
│       │   │   ├── CyrillicComposingText.swift  ← Phase 1
│       │   │   └── ConversionResult.swift
│       │   └── Extensions/
│       │       └── UserDefaults+Shared.swift
│       │
│       ├── CyrillicKeyboard/     # Keyboard Extension
│       │   ├── Engine/           # ビジネスロジック
│       │   │   ├── DisplayedTextManager.swift      ← Phase 1
│       │   │   ├── CyrillicInputManager.swift      ← Phase 1, 2, 3拡張
│       │   │   ├── KanjiConversionEngine.swift     ← Phase 2
│       │   │   ├── LiveConversionManager.swift     ← Phase 3
│       │   │   ├── ProfileManager.swift
│       │   │   └── RustCoreFFI.swift
│       │   │
│       │   ├── Views/            # UI コンポーネント
│       │   │   └── CyrillicKeyboardView.swift
│       │   │
│       │   ├── KeyboardViewController.swift  ← Phase 1リファクタリング
│       │   └── Info.plist
│       │
│       ├── CyrillicIME/          # Main App
│       │   └── ...
│       │
│       ├── project.yml           # XcodeGen設定
│       └── Pismo.xcodeproj/     # 生成されたプロジェクト
│
├── profiles/                     # 変換スキーマ・辞書
│   ├── profiles.json
│   ├── japaneseKanaEngine.json
│   └── schemas/
│       ├── schema_rus_v1.json
│       └── ...
│
└── rust_core/                    # Rust変換エンジン
    ├── src/
    └── Cargo.toml
```

---

## 開発環境セットアップ

### 必須ツール

#### macOS
```bash
# Xcode
xcode-select --install

# XcodeGen
brew install xcodegen

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add aarch64-apple-ios aarch64-apple-ios-sim

# Python (xlsxファイル読み込み用)
brew install python
pip3 install openpyxl
```

#### プロジェクトクローン
```bash
git clone [repository-url]
cd cyrillicJapaneseInput/mobile/iOS
xcodegen generate
```

### シミュレータでの実行

```bash
# ビルド
xcodebuild -project Pismo.xcodeproj \
  -scheme Pismo \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build

# インストール
xcrun simctl install booted ~/path/to/Pismo.app

# 起動
xcrun simctl launch booted com.pismo.Pismo
```

### キーボード有効化

1. 設定 → 一般 → キーボード → キーボード
2. 「新しいキーボードを追加」
3. Pismo を選択

---

## フェーズ間の依存関係

### Phase 依存グラフ

```
Phase 0 (このドキュメント)
    ↓
Phase 1 ─┐
    ↓    │
Phase 2 ←┘ (Phase 1完了が前提)
    ↓
Phase 3 (Phase 2完了が前提)
    ↓
Phase 4 (Phase 3完了が前提)
    ↓
Phase 5 (Phase 4完了が前提)
```

### 並列開発可能なフェーズ

- **Phase 2 と Phase 4**: 並列可能（異なるファイル）
- **Phase 3 と Phase 4**: 並列可能（異なるファイル）
- **Phase 5**: すべて完了後に統合

---

## コーディング規約

### Swift

#### 命名規則
```swift
// クラス: PascalCase
class DisplayedTextManager { }

// メソッド・変数: camelCase
func updateComposingText() { }
var composingText: String

// 定数: camelCase
let maxCandidateCount = 10

// Private: private 修飾子 + camelCase
private var privateState: Int
```

#### ファイル構造
```swift
//
//  FileName.swift
//  Target
//
//  Purpose description
//

import UIKit

// MARK: - Main Class

class ClassName {
    // MARK: - Properties

    // MARK: - Initialization

    // MARK: - Public Methods

    // MARK: - Private Methods
}

// MARK: - Extensions

extension ClassName { }
```

#### ドキュメンテーション
```swift
/// Brief description
///
/// Detailed description (optional)
///
/// - Parameters:
///   - param1: Description
///   - param2: Description
/// - Returns: Description
/// - Throws: Error description (if applicable)
func methodName(param1: Type, param2: Type) -> ReturnType {
    // Implementation
}
```

### ログ規約

```swift
// フォーマット: [ComponentName] Level: Message
print("[DisplayedTextManager] Set marked text: '\(text)'")
print("[CyrillicInputManager] Error: No current profile")
print("[KeyboardViewController] viewDidLoad completed")
```

---

## API契約

### DisplayedTextManager

```swift
public protocol DisplayedTextManagerProtocol {
    func setTextDocumentProxy(_ proxy: UITextDocumentProxy)
    func updateComposingText(_ composingText: String, liveConversionText: String?)
    func stopComposition()
    func insertText(_ text: String)
    func deleteBackward(count: Int)
}
```

### CyrillicInputManager

```swift
public protocol CyrillicInputManagerProtocol {
    // Callbacks
    var onCandidatesUpdated: (([String]) -> Void)? { get set }
    var onComposingTextChanged: ((String) -> Void)? { get set }

    // Input handling
    func setInputMode(_ mode: InputMode)
    func processKey(_ key: String)
    func processDelete()
    func processSpace()
    func processReturn()
    func selectCandidate(at index: Int)
    func commitIfNeeded()
}
```

---

## テスト戦略

### ユニットテスト
- 各コンポーネントは独立してテスト可能
- Mockを使用して依存を注入

### 統合テスト
- 実際のRust Coreと接続してテスト
- シミュレータでの動作確認

### UIテスト
- XCUITestを使用
- 基本的な入力フローをカバー

---

## 参考資料

### 必読ドキュメント
1. `docs/cyrillicJapaneseInput.xlsx` - 変換仕様
2. `docs/要件定義書.md` - 要件定義
3. `docs/アプリ設計書.md` - 設計書

### 参考実装
1. **azooKey** (`docs/repos/azooKey/`)
   - 最も参考になる本格的な日本語IME
   - アーキテクチャパターンを模倣

2. **JapaneseKeyboardKit** (`docs/repos/JapaneseKeyboardKit/`)
   - Mozcとの統合例

### 外部リソース
- [Apple UIInputViewController Documentation](https://developer.apple.com/documentation/uikit/uiinputviewcontroller)
- [azooKey GitHub](https://github.com/azooKey/azooKey)
- [Mozc GitHub](https://github.com/google/mozc)

---

## 次のステップ

1. **Phase 1完了を確認** → `PHASE_1_FOUNDATION.md`を参照
2. **Phase 2に着手** → `PHASE_2_KANJI_CONVERSION.md`を参照
3. **定期的にアーキテクチャドキュメントを更新**

---

**ドキュメント終わり**
