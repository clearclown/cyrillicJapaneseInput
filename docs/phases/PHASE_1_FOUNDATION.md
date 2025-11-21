# Phase 1: 基礎アーキテクチャとIME統合

**ドキュメントバージョン**: 1.0
**最終更新**: 2025-11-22
**対象**: Phase 1担当エンジニア
**ステータス**: ✅ 完了 (Completed)

---

## 📋 目次

1. [フェーズ概要](#フェーズ概要)
2. [前提条件](#前提条件)
3. [実装された機能](#実装された機能)
4. [コンポーネント詳細](#コンポーネント詳細)
5. [技術要件](#技術要件)
6. [完了基準](#完了基準)
7. [テスト要件](#テスト要件)
8. [次のステップ](#次のステップ)

---

## フェーズ概要

### 目的
iOS標準IMEプロトコルに準拠した基礎アーキテクチャを構築し、キリル文字入力から平仮名表示までの基本フローを実装する。

### 達成目標
1. ✅ **DisplayedTextManager**: iOS IMEプロトコルの抽象化
2. ✅ **CyrillicComposingText**: 入力状態の管理
3. ✅ **CyrillicInputManager**: 入力処理のオーケストレーション
4. ✅ **KeyboardViewController**: UIライフサイクルとイベント処理の分離

### 成果物
- `DisplayedTextManager.swift` (190行)
- `CyrillicComposingText.swift` (171行)
- `CyrillicInputManager.swift` (345行)
- `KeyboardViewController.swift` (リファクタリング: 400+行 → 235行)

---

## 前提条件

### 既存コンポーネント
以下のコンポーネントはPhase 0で既に実装済み:
- ✅ `RustCoreFFI`: Rust変換エンジンとのFFIブリッジ
- ✅ `ProfileManager`: プロファイル管理
- ✅ `CyrillicKeyboardView`: キーボードUIビュー
- ✅ Rust Core: キリル文字 → 平仮名変換エンジン

### 技術スタック
- Swift 5.9+
- iOS 15.0+
- UIKit
- XcodeGen

---

## 実装された機能

### 1. iOS標準IMEプロトコル統合

#### 問題点（Phase 1前）
```swift
// ❌ 非標準: キーボード内バッファに表示
textDocumentProxy.insertText(composingText)  // 確定されてしまう
// ユーザー体験: 変換前の文字が確定されてしまい、削除できない
```

#### 解決策（Phase 1後）
```swift
// ✅ 標準: setMarkedText で下線付き表示
textDocumentProxy.setMarkedText("かいしゃ", selectedRange: NSRange(location: 4, length: 0))
// ユーザー体験: 下線付きで表示され、変換可能
```

**実装ファイル**: `DisplayedTextManager.swift`

### 2. 入力履歴とDelete対応

#### 問題点（Phase 1前）
```swift
// ❌ 履歴なし: Deleteで再構築できない
composingText = result.output  // 上書きのみ
```

#### 解決策（Phase 1後）
```swift
// ✅ 履歴保持: Deleteで再構築可能
cyrillicKeys.append(key)
hiraganaTarget += result.output

// Delete時
cyrillicKeys.removeLast()
// 履歴から全キーを再生して再構築
```

**実装ファイル**: `CyrillicComposingText.swift`

### 3. マネージャーベースアーキテクチャ

#### Before（Phase 1前）
```
KeyboardViewController (400+ lines)
├── UIライフサイクル
├── 入力処理ロジック      ← 混在
├── 変換ロジック          ← 混在
├── テキスト表示ロジック   ← 混在
└── UI更新
```

#### After（Phase 1後）
```
KeyboardViewController (235 lines)
├── UIライフサイクル
├── マネージャー初期化
└── イベント委譲のみ
    ↓
CyrillicInputManager (345 lines)
├── 入力処理オーケストレーション
├── モード別ハンドリング
└── Rust Core呼び出し
    ↓
DisplayedTextManager (190 lines)
└── iOS IMEプロトコル抽象化
```

---

## コンポーネント詳細

### 1. DisplayedTextManager

#### 役割
iOS標準IMEプロトコル（`setMarkedText` / `unmarkText`）の抽象化レイヤー。

#### 責務
- ✅ 未確定文字（composing text）の表示
- ✅ 確定文字の挿入
- ✅ カーソル位置管理
- ✅ ライブ変換テキストの表示

#### API契約
```swift
protocol DisplayedTextManagerProtocol {
    /// UITextDocumentProxyを設定
    func setTextDocumentProxy(_ proxy: UITextDocumentProxy)

    /// 未確定テキストを更新
    /// - Parameters:
    ///   - composingText: ベースとなる未確定テキスト（平仮名）
    ///   - liveConversionText: 表示するライブ変換結果（漢字）
    func updateComposingText(_ composingText: String, liveConversionText: String?)

    /// 変換を停止し、未確定テキストをクリア
    func stopComposition()

    /// 確定テキストを挿入
    func insertText(_ text: String)

    /// 後方削除
    func deleteBackward(count: Int)
}
```

#### 実装例
```swift:DisplayedTextManager.swift
final class DisplayedTextManager {
    private weak var proxy: UITextDocumentProxy?
    private(set) var composingText: String = ""
    private(set) var displayedLiveConversionText: String?
    private let isMarkedTextEnabled: Bool

    init(isMarkedTextEnabled: Bool = true) {
        self.isMarkedTextEnabled = isMarkedTextEnabled
    }

    func updateComposingText(_ composingText: String, liveConversionText: String? = nil) {
        guard let proxy = proxy else { return }

        self.composingText = composingText
        self.displayedLiveConversionText = liveConversionText

        if composingText.isEmpty && liveConversionText == nil {
            proxy.unmarkText()
            return
        }

        let displayText = liveConversionText ?? composingText

        if isMarkedTextEnabled {
            let range = NSRange(location: displayText.count, length: 0)
            proxy.setMarkedText(displayText, selectedRange: range)
        }
    }

    func insertText(_ text: String) {
        guard let proxy = proxy else { return }

        proxy.unmarkText()
        proxy.insertText(text)

        composingText = ""
        displayedLiveConversionText = nil
    }
}
```

#### テストケース
```swift
func testSetMarkedText() {
    // Given
    let manager = DisplayedTextManager(isMarkedTextEnabled: true)
    let mockProxy = MockUITextDocumentProxy()
    manager.setTextDocumentProxy(mockProxy)

    // When
    manager.updateComposingText("かいしゃ")

    // Then
    XCTAssertTrue(mockProxy.setMarkedTextCalled)
    XCTAssertEqual(mockProxy.markedText, "かいしゃ")
}

func testInsertCommitsAndClearsState() {
    // Given
    let manager = DisplayedTextManager()
    manager.updateComposingText("かいしゃ")

    // When
    manager.insertText("会社")

    // Then
    XCTAssertEqual(manager.composingText, "")
    XCTAssertNil(manager.displayedLiveConversionText)
}
```

---

### 2. CyrillicComposingText

#### 役割
キリル文字入力の状態管理。入力履歴を保持し、Delete時の再構築を可能にする。

#### 責務
- ✅ キリル文字入力履歴の保持
- ✅ 平仮名バッファの管理
- ✅ Delete時の履歴管理
- ✅ カーソル位置追跡

#### データ構造
```swift
struct CyrillicComposingText {
    // キー入力履歴（Delete時の再構築用）
    private(set) var cyrillicKeys: [String] = []

    // 未完了のキリル文字バッファ（例: "К"）
    private(set) var cyrillicBuffer: String = ""

    // 変換済み平仮名（例: "かいしゃ"）
    private(set) var hiraganaTarget: String = ""

    // カーソル位置
    private(set) var cursorPosition: Int = 0
}
```

#### 主要メソッド
```swift
/// キーを追加（変換結果と共に）
mutating func append(key: String, result: ConversionResult) {
    cyrillicKeys.append(key)
    cyrillicBuffer = result.buffer

    if !result.output.isEmpty {
        hiraganaTarget += result.output  // ✅ APPEND（上書きではない）
        cursorPosition = hiraganaTarget.count
    }
}

/// 後方削除
@discardableResult
mutating func deleteBackward() -> Bool {
    guard !cyrillicKeys.isEmpty else { return false }
    cyrillicKeys.removeLast()
    return true
}

/// 全クリア
mutating func clear() {
    cyrillicKeys.removeAll()
    cyrillicBuffer = ""
    hiraganaTarget = ""
    cursorPosition = 0
}
```

#### 使用例
```swift
var composing = CyrillicComposingText()

// 入力: К → А → Й
composing.append(key: "К", result: ConversionResult(buffer: "К", output: "", action: "buffer"))
composing.append(key: "А", result: ConversionResult(buffer: "", output: "か", action: "commit"))
composing.append(key: "Й", result: ConversionResult(buffer: "", output: "い", action: "commit"))

print(composing.hiraganaTarget)  // "かい"
print(composing.cyrillicKeys)    // ["К", "А", "Й"]

// Delete
composing.deleteBackward()
print(composing.cyrillicKeys)    // ["К", "А"]
// CyrillicInputManager が履歴から再構築 → "か"
```

#### テストケース
```swift
func testAppendAccumulatesHiragana() {
    // Given
    var composing = CyrillicComposingText()

    // When
    composing.append(key: "К", result: ConversionResult(buffer: "К", output: "", action: "buffer"))
    composing.append(key: "А", result: ConversionResult(buffer: "", output: "か", action: "commit"))
    composing.append(key: "Й", result: ConversionResult(buffer: "", output: "い", action: "commit"))

    // Then
    XCTAssertEqual(composing.hiraganaTarget, "かい")
    XCTAssertEqual(composing.cyrillicKeys, ["К", "А", "Й"])
}

func testDeleteBackwardRemovesLastKey() {
    // Given
    var composing = CyrillicComposingText()
    composing.append(key: "К", result: ConversionResult(buffer: "", output: "か", action: "commit"))
    composing.append(key: "Й", result: ConversionResult(buffer: "", output: "い", action: "commit"))

    // When
    let success = composing.deleteBackward()

    // Then
    XCTAssertTrue(success)
    XCTAssertEqual(composing.cyrillicKeys, ["К"])
}
```

---

### 3. CyrillicInputManager

#### 役割
入力処理のオーケストレーター。すべてのコンポーネントを調整する。

#### 責務
- ✅ キー入力の処理
- ✅ モード別ハンドリング（Direct Cyrillic / Hiragana / IME）
- ✅ Rust Core呼び出し
- ✅ DisplayedTextManager への委譲
- ✅ Delete時の再構築
- ✅ コールバックによる通知

#### アーキテクチャ
```
CyrillicInputManager
├── displayedTextManager: DisplayedTextManager
├── rustCore: RustCoreFFI
├── profileManager: ProfileManager
└── composingText: CyrillicComposingText

コールバック:
├── onCandidatesUpdated: ([String]) -> Void
└── onComposingTextChanged: (String) -> Void
```

#### 主要メソッド
```swift
/// キー入力処理
func processKey(_ key: String) {
    guard let profile = profileManager.currentProfile else { return }

    // Rust Core呼び出し
    guard let result = rustCore.processKey(
        cyrillicKey: key,
        currentBuffer: composingText.cyrillicBuffer,
        profileId: profile.id
    ) else { return }

    // 状態更新
    composingText.append(key: key, result: result)

    // モード別処理
    switch currentInputMode {
    case .directCyrillic:
        handleDirectCyrillicMode(result: result)
    case .japaneseHiragana:
        handleHiraganaMode(result: result)
    case .japaneseIME:
        handleIMEMode(result: result)
    }
}

/// Delete処理
func processDelete() {
    if isConverting && !candidates.isEmpty {
        exitConversionMode()
    } else if composingText.deleteBackward() {
        rebuildComposingText()  // ✅ 履歴から再構築
    } else {
        displayedTextManager.deleteBackward()
    }
}

/// 履歴から再構築
private func rebuildComposingText() {
    guard let profile = profileManager.currentProfile else { return }

    var newHiragana = ""
    var newBuffer = ""

    // 全キーを再生
    for key in composingText.cyrillicKeys {
        guard let result = rustCore.processKey(
            cyrillicKey: key,
            currentBuffer: newBuffer,
            profileId: profile.id
        ) else { continue }

        if !result.output.isEmpty {
            newHiragana += result.output
        }
        newBuffer = result.buffer
    }

    composingText.setHiragana(newHiragana, buffer: newBuffer)
    displayedTextManager.updateComposingText(newHiragana)
    onComposingTextChanged?(newHiragana)
}
```

#### モード別ハンドリング
```swift
/// IMEモード: 平仮名を未確定テキストとして表示
private func handleIMEMode(result: ConversionResult) {
    displayedTextManager.updateComposingText(composingText.hiraganaTarget)
    onComposingTextChanged?(composingText.hiraganaTarget)

    // TODO Phase 2: 漢字候補を取得
    // conversionEngine.requestCandidates(composingText.hiraganaTarget)
}

/// 平仮名モード: 平仮名を即座に確定
private func handleHiraganaMode(result: ConversionResult) {
    if result.action == "commit" && !result.output.isEmpty {
        displayedTextManager.insertText(result.output)
        composingText.setHiragana("", buffer: result.buffer)
    } else {
        displayedTextManager.updateComposingText(composingText.hiraganaTarget)
    }
}
```

#### テストケース
```swift
func testProcessKeyAccumulatesHiragana() {
    // Given
    let mockDisplayed = MockDisplayedTextManager()
    let manager = CyrillicInputManager(displayedTextManager: mockDisplayed)
    manager.setInputMode(.japaneseIME)

    // When
    manager.processKey("К")
    manager.processKey("А")
    manager.processKey("Й")

    // Then
    XCTAssertEqual(manager.currentComposingText, "かい")
    XCTAssertEqual(mockDisplayed.lastComposingText, "かい")
}

func testDeleteRebuildFromHistory() {
    // Given
    let manager = CyrillicInputManager(displayedTextManager: DisplayedTextManager())
    manager.processKey("К")
    manager.processKey("А")
    manager.processKey("Й")

    // When
    manager.processDelete()

    // Then
    XCTAssertEqual(manager.currentComposingText, "か")  // "かい" → "か"
}
```

---

### 4. KeyboardViewController (リファクタリング)

#### Before（Phase 1前）
```swift
class KeyboardViewController: UIInputViewController {
    // 400+ lines

    // 問題点:
    // 1. UIライフサイクル
    // 2. 入力処理ロジック         ← 混在
    // 3. 変換ロジック             ← 混在
    // 4. テキスト表示ロジック      ← 混在
    // 5. バッファ管理             ← 混在
    // 6. Rust Core呼び出し        ← 混在

    func handleKey(_ key: String) {
        // 100+ lines of logic...
        let result = RustCoreFFI.shared.processKey(...)
        if result.action == "commit" {
            composingText += result.output  // バッファ管理
            textDocumentProxy.setMarkedText(composingText, ...)  // 表示
        }
        // ...
    }
}
```

#### After（Phase 1後）
```swift
class KeyboardViewController: UIInputViewController {
    // 235 lines

    // MARK: - Managers
    private var displayedTextManager: DisplayedTextManager!
    private var inputManager: CyrillicInputManager!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeEngine()
        setupManagers()
        setupKeyboardView()
    }

    // MARK: - Manager Setup
    private func setupManagers() {
        displayedTextManager = DisplayedTextManager(isMarkedTextEnabled: true)
        displayedTextManager.setTextDocumentProxy(textDocumentProxy)

        inputManager = CyrillicInputManager(
            displayedTextManager: displayedTextManager,
            rustCore: RustCoreFFI.shared,
            profileManager: ProfileManager.shared
        )

        // コールバック設定
        inputManager.onCandidatesUpdated = { [weak self] candidates in
            self?.keyboardView?.showCandidates(candidates)
        }

        inputManager.onComposingTextChanged = { [weak self] text in
            self?.keyboardView?.updateBufferDisplay(text)
        }
    }
}

// MARK: - CyrillicKeyboardViewDelegate
extension KeyboardViewController: CyrillicKeyboardViewDelegate {
    func keyboardView(_ view: CyrillicKeyboardView, didPressCyrillicKey key: String) {
        inputManager.setInputMode(view.currentInputMode)
        inputManager.processKey(key)  // ✅ 全ロジックを委譲
    }

    func keyboardViewDidPressDelete(_ view: CyrillicKeyboardView) {
        inputManager.processDelete()  // ✅ Delete処理を委譲
    }

    func keyboardViewDidPressSpace(_ view: CyrillicKeyboardView) {
        inputManager.processSpace()  // ✅ Space処理を委譲
    }
}
```

#### 改善点
1. **LOC削減**: 400+ lines → 235 lines (41% 削減)
2. **責務分離**: UIライフサイクルのみに専念
3. **テスタビリティ向上**: マネージャーを差し替え可能
4. **可読性向上**: ビジネスロジックがマネージャーに集約

---

## 技術要件

### 必須要件

#### R1.1: iOS標準IMEプロトコル準拠
- [x] `setMarkedText(_:selectedRange:)` を使用した未確定テキスト表示
- [x] `unmarkText()` を使用した確定処理
- [x] `UITextDocumentProxy` の適切な使用

#### R1.2: 入力履歴管理
- [x] すべてのキー入力を配列で保持
- [x] Delete時に履歴から1つ削除
- [x] 履歴を再生して状態を再構築

#### R1.3: マネージャーパターン
- [x] `DisplayedTextManager`: テキスト表示専門
- [x] `CyrillicInputManager`: 入力処理オーケストレーション
- [x] `KeyboardViewController`: UI イベント処理のみ

#### R1.4: コールバックベース通知
- [x] `onCandidatesUpdated`: 候補リスト更新通知
- [x] `onComposingTextChanged`: 未確定テキスト変更通知

### 非機能要件

#### NR1.1: パフォーマンス
- [x] キー入力 → 表示更新: 16ms以内（60fps）
- [x] Delete → 再構築: 50ms以内

#### NR1.2: メモリ使用量
- [x] 入力履歴: 最大1000文字分
- [x] マネージャー常駐メモリ: 合計 < 1MB

#### NR1.3: コード品質
- [x] SwiftLint警告ゼロ
- [x] すべてのpublicメソッドにドキュメンテーション
- [x] MARK: コメントによるセクション分割

---

## 完了基準

### 機能完了基準

#### AC1: 基本入力フロー
```gherkin
Given ユーザーがキリル文字キーボードを開く
When "К", "А", "Й" を順に入力
Then テキストフィールドに "かい" が下線付きで表示される
And 未確定状態である（確定されていない）
```

#### AC2: Delete動作
```gherkin
Given "かいしゃ" が未確定テキストとして表示されている
When Deleteキーを1回押す
Then "かいし" が表示される
And 未確定状態を維持する
```

#### AC3: 確定動作
```gherkin
Given "かいしゃ" が未確定テキストとして表示されている
When Returnキーを押す
Then "かいしゃ" が確定される
And 下線が消える
And 未確定テキストがクリアされる
```

#### AC4: モード別動作
```gherkin
Scenario: 平仮名モード
  Given 平仮名モードが選択されている
  When "К", "А" を入力
  Then "か" が即座に確定される
  And 未確定テキストは残らない

Scenario: IMEモード
  Given IMEモードが選択されている
  When "К", "А" を入力
  Then "か" が未確定テキストとして表示される
  And Spaceで変換可能な状態
```

### コード完了基準

#### CC1: ファイル構成
- [x] `DisplayedTextManager.swift` が `CyrillicKeyboard/Engine/` に存在
- [x] `CyrillicComposingText.swift` が `Shared/Models/` に存在
- [x] `CyrillicInputManager.swift` が `CyrillicKeyboard/Engine/` に存在
- [x] `KeyboardViewController.swift` がリファクタリング済み

#### CC2: API契約遵守
- [x] すべてのパブリックメソッドがプロトコルで定義されている
- [x] プロトコルが Phase 0 の API契約と一致

#### CC3: ログ出力
- [x] すべての主要処理でログ出力
- [x] フォーマット: `[ComponentName] Message`

---

## テスト要件

### ユニットテスト

#### UT1: DisplayedTextManager
```swift
class DisplayedTextManagerTests: XCTestCase {
    func testSetMarkedText() { }
    func testInsertTextCommitsAndClearsState() { }
    func testStopCompositionClearsMarkedText() { }
    func testDeleteBackward() { }
    func testCursorPositionUpdate() { }
}
```

#### UT2: CyrillicComposingText
```swift
class CyrillicComposingTextTests: XCTestCase {
    func testAppendAccumulatesHiragana() { }
    func testDeleteBackwardRemovesLastKey() { }
    func testClearResetsAllState() { }
    func testEmptyCheck() { }
}
```

#### UT3: CyrillicInputManager
```swift
class CyrillicInputManagerTests: XCTestCase {
    func testProcessKeyAccumulatesHiragana() { }
    func testDeleteRebuildFromHistory() { }
    func testModeSwitch() { }
    func testCallbackNotification() { }
}
```

### 統合テスト

#### IT1: キー入力フロー
```swift
func testEndToEndInputFlow() {
    // Given
    let viewController = KeyboardViewController()
    viewController.loadView()
    viewController.viewDidLoad()

    // When
    simulateKeyPress("К")
    simulateKeyPress("А")
    simulateKeyPress("Й")

    // Then
    XCTAssertEqual(textDocumentProxy.markedText, "かい")
}
```

#### IT2: Delete再構築
```swift
func testDeleteRebuildsCorrectly() {
    // Given: "かいしゃ" 入力済み
    simulateKeyPress("К")
    simulateKeyPress("А")
    simulateKeyPress("Й")
    simulateKeyPress("Ш")
    simulateKeyPress("А")

    // When
    simulateKeyPress(UIKeyInputBackspace)

    // Then
    XCTAssertEqual(textDocumentProxy.markedText, "かいし")
}
```

### シミュレータテスト

#### ST1: 実機動作確認
```bash
# ビルド
xcodebuild -project Pismo.xcodeproj \
  -scheme Pismo \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build

# インストール
xcrun simctl install booted path/to/Pismo.app

# 起動
xcrun simctl launch booted com.pismo.Pismo
```

#### ST2: 動作確認項目
1. キーボード表示確認
2. "かいしゃ" 入力
3. Delete動作確認
4. Return確定確認
5. メモアプリでの動作確認

---

## 次のステップ

### Phase 2への準備
Phase 1が完了したら、次は **Phase 2: 漢字変換** に進みます。

#### Phase 2で実装する機能
1. **KanjiConversionEngine**: azooKey の KanaKanjiConverter 統合
2. **辞書バンドル**: ~50MB の日本語辞書
3. **候補表示**: 変換候補の取得と表示
4. **学習機能**: ユーザー辞書

#### Phase 2への依存関係
Phase 2は Phase 1の以下のコンポーネントに依存します:
- ✅ `CyrillicInputManager.startConversion()` メソッド（TODO箇所を実装）
- ✅ `CyrillicInputManager.onCandidatesUpdated` コールバック
- ✅ `DisplayedTextManager.updateComposingText(_:liveConversionText:)` メソッド

#### 次のドキュメント
**Phase 2**: `PHASE_2_KANJI_CONVERSION.md`

---

## 参考資料

### 実装済みファイル
- `mobile/iOS/CyrillicKeyboard/Engine/DisplayedTextManager.swift`
- `mobile/iOS/Shared/Models/CyrillicComposingText.swift`
- `mobile/iOS/CyrillicKeyboard/Engine/CyrillicInputManager.swift`
- `mobile/iOS/CyrillicKeyboard/KeyboardViewController.swift`

### 参考実装
- `docs/repos/azooKey/Keyboard/KeyboardViewController.swift`
- `docs/repos/azooKey/KeyboardViews/InputManager.swift`
- `docs/repos/azooKey/KeyboardViews/DisplayedTextManager.swift`

### Apple公式ドキュメント
- [UIInputViewController](https://developer.apple.com/documentation/uikit/uiinputviewcontroller)
- [UITextDocumentProxy](https://developer.apple.com/documentation/uikit/uitextdocumentproxy)
- [Custom Keyboard Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html)

---

**ドキュメント終わり**
