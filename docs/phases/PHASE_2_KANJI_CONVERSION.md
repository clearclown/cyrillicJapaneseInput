# Phase 2: 漢字変換エンジン統合

**ドキュメントバージョン**: 1.0
**最終更新**: 2025-11-22
**対象**: Phase 2担当エンジニア
**ステータス**: 🔜 未着手 (Not Started)

---

## 📋 目次

1. [フェーズ概要](#フェーズ概要)
2. [前提条件](#前提条件)
3. [実装する機能](#実装する機能)
4. [技術仕様](#技術仕様)
5. [実装手順](#実装手順)
6. [API設計](#api設計)
7. [テスト要件](#テスト要件)
8. [完了基準](#完了基準)
9. [次のステップ](#次のステップ)

---

## フェーズ概要

### 目的
平仮名を漢字に変換するエンジンを統合し、実用的な日本語入力を実現する。

### 達成目標
1. 🎯 **azooKey KanaKanjiConverter 統合**: 本格的な変換エンジン
2. 🎯 **辞書バンドル**: ~50MB の日本語辞書
3. 🎯 **候補表示**: 複数の変換候補を表示
4. 🎯 **候補選択**: Space/数字キーで候補を選択
5. 🎯 **学習機能**: ユーザー辞書と変換学習

### 成果物
- `KanjiConversionEngine.swift` (新規作成, ~300行)
- `CyrillicInputManager.swift` (Phase 1から拡張, +150行)
- `package.swift` または `Podfile` (azooKey依存追加)
- `louds-trie辞書ファイル` (~50MB, バンドル)

---

## 前提条件

### Phase 1完了事項
以下のコンポーネントがPhase 1で実装済みであることが必須:
- ✅ `CyrillicInputManager`: 入力オーケストレーター
- ✅ `DisplayedTextManager`: iOS IMEプロトコル抽象化
- ✅ `CyrillicComposingText`: 入力状態管理
- ✅ `onCandidatesUpdated: ([String]) -> Void` コールバック

### Phase 1のTODO箇所
Phase 1では以下の箇所がスタブ実装されており、Phase 2で実装します:

```swift:CyrillicInputManager.swift (Phase 1)
// TODO Phase 2: Request kanji candidates
// conversionEngine.requestCandidates(composingText.hiraganaTarget) { candidates in
//     self.candidates = candidates
//     self.onCandidatesUpdated?(candidates)
// }
```

### 技術スタック
- Swift 5.9+
- azooKey's KanaKanjiConverter
- Swift Package Manager または CocoaPods

---

## 実装する機能

### 1. 基本的な変換フロー

#### ユーザー体験
```
1. ユーザー: К, А, Й, Ш, А を入力
   → 画面: "かいしゃ" (下線付き)

2. ユーザー: Space を押す
   → 画面: 候補が表示される
   [1] 会社
   [2] 開車
   [3] 快謝
   [4] かいしゃ (平仮名)

3. ユーザー: もう一度 Space を押す
   → 画面: 次の候補に切り替わる
   "開車" (下線付き、太字)

4. ユーザー: Return を押す
   → 画面: "開車" が確定される（下線消える）
```

### 2. 変換候補の優先順位

#### 候補ソース
1. **ユーザー辞書** (最優先): 過去に確定した単語
2. **システム辞書**: azooKey の辞書 (~50MB)
3. **平仮名そのまま**: 変換しない選択肢
4. **カタカナ**: 平仮名→カタカナ変換

#### 候補数
- デフォルト: 10候補
- 最大: 50候補（スクロール可能）

### 3. 文節変換

#### Phase 2スコープ外（Phase 3で実装）
Phase 2では「全体変換」のみサポート:
- ✅ "かいしゃ" → "会社" (全体を一括変換)
- ❌ "かい|しゃ" → "会|社" (文節分割は Phase 3)

### 4. 学習機能

#### 基本学習
```swift
// ユーザーが「かいしゃ」→「会社」を選択
conversionEngine.learn(input: "かいしゃ", selected: "会社")

// 次回、「かいしゃ」入力時
// 「会社」が最上位候補になる
```

#### 学習データ保存
- 場所: `UserDefaults` (App Group経由)
- フォーマット: JSON
- 最大エントリ: 10,000件

---

## 技術仕様

### azooKey KanaKanjiConverter 統合

#### 1. 依存関係追加

##### Option A: Swift Package Manager
```swift:Package.swift
// Package.swift
let package = Package(
    name: "Pismo",
    dependencies: [
        .package(url: "https://github.com/ensan-hcl/azooKey", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "CyrillicKeyboard",
            dependencies: [
                .product(name: "KanaKanjiConverter", package: "azooKey")
            ]
        )
    ]
)
```

##### Option B: CocoaPods
```ruby:Podfile
# Podfile
platform :ios, '15.0'

target 'CyrillicKeyboard' do
  use_frameworks!
  pod 'azooKey-KanaKanjiConverter', '~> 1.0'
end
```

#### 2. 辞書ファイルのバンドル

azooKeyの辞書は ~50MB のバイナリファイル:

```
CyrillicKeyboard.appex/
└── Resources/
    └── louds-trie/
        ├── louds.bin        (~40MB)
        ├── chid.bin         (~5MB)
        └── mid.bin          (~5MB)
```

**XcodeGenでの設定**:
```yaml:project.yml
targets:
  CyrillicKeyboard:
    sources:
      - path: CyrillicKeyboard
    resources:
      - path: ../louds-trie
        type: folder
```

#### 3. 初期化

```swift
// KanjiConversionEngine.swift
import KanaKanjiConverter

class KanjiConversionEngine {
    private let converter: KanaKanjiConverter

    init() throws {
        guard let bundlePath = Bundle.main.path(forResource: "louds-trie", ofType: nil),
              let dictionaryURL = URL(string: "file://\(bundlePath)") else {
            throw ConversionError.dictionaryNotFound
        }

        self.converter = try KanaKanjiConverter(dictionaryURL: dictionaryURL)
    }

    func requestCandidates(for hiragana: String, count: Int = 10) async throws -> [Candidate] {
        return try await converter.requestCandidates(
            composingText: ComposingText(hiragana),
            options: .init(maxCount: count)
        )
    }
}
```

---

## API設計

### KanjiConversionEngine

#### クラス定義
```swift
/// 平仮名→漢字変換エンジン
final class KanjiConversionEngine {
    // MARK: - Properties

    /// azooKey's converter
    private let converter: KanaKanjiConverter

    /// User dictionary for learning
    private let userDictionary: UserDictionary

    /// Conversion options
    private let options: ConversionOptions

    // MARK: - Initialization

    /// Initializes the conversion engine
    /// - Throws: ConversionError if dictionary not found
    init() throws

    // MARK: - Conversion

    /// Requests conversion candidates for hiragana input
    /// - Parameters:
    ///   - hiragana: Input hiragana string
    ///   - maxCount: Maximum number of candidates
    /// - Returns: Array of conversion candidates
    /// - Throws: ConversionError on failure
    func requestCandidates(for hiragana: String, maxCount: Int) async throws -> [Candidate]

    /// Learns from user selection
    /// - Parameters:
    ///   - input: Input hiragana
    ///   - selected: User's selected candidate
    func learn(input: String, selected: Candidate)

    /// Clears user learning data
    func clearLearningData()
}
```

#### Candidate モデル
```swift
/// 変換候補
struct Candidate: Identifiable, Equatable {
    /// 候補ID
    let id: UUID

    /// 表示文字列（例: "会社"）
    let text: String

    /// 候補の種類
    let type: CandidateType

    /// 優先度スコア（高いほど優先）
    let score: Double

    /// 詳細情報（品詞など）
    let metadata: CandidateMetadata?
}

enum CandidateType {
    case kanji       // 漢字変換
    case hiragana    // 平仮名そのまま
    case katakana    // カタカナ
    case userDictionary  // ユーザー辞書
}

struct CandidateMetadata {
    let partOfSpeech: String?  // 品詞
    let frequency: Int?        // 頻度
}
```

#### ConversionOptions
```swift
struct ConversionOptions {
    /// 最大候補数
    var maxCandidateCount: Int = 10

    /// カタカナ候補を含めるか
    var includeKatakana: Bool = true

    /// 平仮名候補を含めるか
    var includeHiragana: Bool = true

    /// ユーザー辞書を優先するか
    var prioritizeUserDictionary: Bool = true
}
```

### CyrillicInputManager 拡張

Phase 1のCyrillicInputManagerに以下を追加:

```swift
// CyrillicInputManager.swift (Phase 2拡張)

final class CyrillicInputManager {
    // MARK: - Properties (追加)

    /// Kanji conversion engine (Phase 2)
    private let conversionEngine: KanjiConversionEngine?

    /// Current candidates
    private var candidates: [Candidate] = []

    /// Selected candidate index
    private var selectedCandidateIndex: Int = 0

    // MARK: - Initialization (更新)

    init(displayedTextManager: DisplayedTextManager,
         rustCore: RustCoreFFI = .shared,
         profileManager: ProfileManager = .shared,
         conversionEngine: KanjiConversionEngine? = nil) {  // Phase 2: 追加
        self.displayedTextManager = displayedTextManager
        self.rustCore = rustCore
        self.profileManager = profileManager
        self.conversionEngine = conversionEngine  // Phase 2: 追加
    }

    // MARK: - Conversion (Phase 2新規実装)

    /// Requests kanji conversion candidates
    private func requestConversionCandidates() {
        guard let engine = conversionEngine else {
            // Phase 1フォールバック: カタカナのみ
            showFallbackCandidates()
            return
        }

        Task {
            do {
                let candidateList = try await engine.requestCandidates(
                    for: composingText.hiraganaTarget,
                    maxCount: 10
                )

                await MainActor.run {
                    self.candidates = candidateList
                    self.onCandidatesUpdated?(candidateList.map { $0.text })
                }
            } catch {
                print("[CyrillicInputManager] Conversion error: \(error)")
                showFallbackCandidates()
            }
        }
    }

    /// Shows fallback candidates (hiragana + katakana only)
    private func showFallbackCandidates() {
        var candidateList = [Candidate]()

        // Hiragana
        candidateList.append(Candidate(
            id: UUID(),
            text: composingText.hiraganaTarget,
            type: .hiragana,
            score: 1.0,
            metadata: nil
        ))

        // Katakana
        if let katakana = convertToKatakana(composingText.hiraganaTarget) {
            candidateList.append(Candidate(
                id: UUID(),
                text: katakana,
                type: .katakana,
                score: 0.5,
                metadata: nil
            ))
        }

        candidates = candidateList
        onCandidatesUpdated?(candidateList.map { $0.text })
    }

    /// Commits selected candidate and learns
    private func commitCandidate(at index: Int) {
        guard index < candidates.count else { return }

        let selected = candidates[index]

        // Learn from selection
        if let engine = conversionEngine {
            engine.learn(input: composingText.hiraganaTarget, selected: selected)
        }

        // Commit text
        commitText(selected.text)
    }
}
```

---

## 実装手順

### Step 1: 依存関係追加（1日）

#### 1.1 azooKey パッケージ追加
```bash
# Swift Package Manager を使用する場合
cd mobile/iOS
open Pismo.xcodeproj

# Xcode:
# File → Add Packages...
# URL: https://github.com/ensan-hcl/azooKey
# Version: 1.0.0 - Next Major
```

#### 1.2 辞書ファイルダウンロード
```bash
# azooKey の辞書をダウンロード
cd mobile/iOS
curl -L -o louds-trie.zip "https://github.com/ensan-hcl/azooKey/releases/download/v1.0.0/louds-trie.zip"
unzip louds-trie.zip -d CyrillicKeyboard/Resources/

# 確認
ls -lh CyrillicKeyboard/Resources/louds-trie/
# -rw-r--r--  1 user  staff   40M louds.bin
# -rw-r--r--  1 user  staff   5M  chid.bin
# -rw-r--r--  1 user  staff   5M  mid.bin
```

#### 1.3 XcodeGenにリソース追加
```yaml:project.yml
targets:
  CyrillicKeyboard:
    type: app-extension
    sources:
      - path: CyrillicKeyboard
    resources:
      - path: CyrillicKeyboard/Resources/louds-trie
        type: folder
        buildPhase: resources
```

```bash
# プロジェクト再生成
xcodegen generate
```

### Step 2: KanjiConversionEngine作成（2日）

#### 2.1 ファイル作成
```swift:CyrillicKeyboard/Engine/KanjiConversionEngine.swift
//
//  KanjiConversionEngine.swift
//  CyrillicKeyboard
//
//  Provides hiragana → kanji conversion using azooKey
//

import Foundation
import KanaKanjiConverter

/// Errors that can occur during conversion
enum ConversionError: Error {
    case dictionaryNotFound
    case invalidInput
    case conversionFailed(String)
}

/// Manages hiragana → kanji conversion
final class KanjiConversionEngine {
    // MARK: - Properties

    /// azooKey's KanaKanjiConverter
    private let converter: KanaKanjiConverter

    /// User dictionary
    private let userDictionary: UserDictionary

    /// Conversion options
    private var options: ConversionOptions

    // MARK: - Initialization

    init(options: ConversionOptions = .default) throws {
        // Locate dictionary bundle
        guard let bundlePath = Bundle.main.path(forResource: "louds-trie", ofType: nil) else {
            throw ConversionError.dictionaryNotFound
        }

        let dictionaryURL = URL(fileURLWithPath: bundlePath)

        // Initialize converter
        self.converter = try KanaKanjiConverter(dictionaryURL: dictionaryURL)
        self.userDictionary = UserDictionary()
        self.options = options

        print("[KanjiConversionEngine] Initialized with dictionary at: \(bundlePath)")
    }

    // MARK: - Conversion

    /// Requests conversion candidates
    func requestCandidates(for hiragana: String, maxCount: Int = 10) async throws -> [Candidate] {
        guard !hiragana.isEmpty else {
            throw ConversionError.invalidInput
        }

        print("[KanjiConversionEngine] Requesting candidates for: '\(hiragana)'")

        // Check user dictionary first
        var candidates: [Candidate] = []

        if options.prioritizeUserDictionary {
            let userCandidates = userDictionary.lookup(hiragana)
            candidates.append(contentsOf: userCandidates)
        }

        // Get system candidates
        let composingText = ComposingText(hiragana)
        let systemCandidates = try await converter.requestCandidates(
            composingText: composingText,
            options: RequestOptions(N_best: maxCount)
        )

        candidates.append(contentsOf: systemCandidates.map { azooCandidate in
            Candidate(
                id: UUID(),
                text: azooCandidate.text,
                type: .kanji,
                score: azooCandidate.value,
                metadata: CandidateMetadata(
                    partOfSpeech: azooCandidate.data.first?.ruby,
                    frequency: nil
                )
            )
        })

        // Add hiragana option
        if options.includeHiragana {
            candidates.append(Candidate(
                id: UUID(),
                text: hiragana,
                type: .hiragana,
                score: 0.1,
                metadata: nil
            ))
        }

        // Add katakana option
        if options.includeKatakana, let katakana = convertToKatakana(hiragana) {
            candidates.append(Candidate(
                id: UUID(),
                text: katakana,
                type: .katakana,
                score: 0.05,
                metadata: nil
            ))
        }

        // Sort by score
        candidates.sort { $0.score > $1.score }

        // Limit count
        let limited = Array(candidates.prefix(maxCount))

        print("[KanjiConversionEngine] Returned \(limited.count) candidates")
        return limited
    }

    /// Learns from user selection
    func learn(input: String, selected: Candidate) {
        userDictionary.add(input: input, output: selected.text)
        print("[KanjiConversionEngine] Learned: '\(input)' → '\(selected.text)'")
    }

    /// Clears learning data
    func clearLearningData() {
        userDictionary.clear()
        print("[KanjiConversionEngine] Cleared learning data")
    }

    // MARK: - Utility

    private func convertToKatakana(_ hiragana: String) -> String? {
        let mutableString = NSMutableString(string: hiragana)
        if CFStringTransform(mutableString, nil, kCFStringTransformHiraganaKatakana, false) {
            return mutableString as String
        }
        return nil
    }
}

// MARK: - Supporting Types

struct ConversionOptions {
    var maxCandidateCount: Int
    var includeKatakana: Bool
    var includeHiragana: Bool
    var prioritizeUserDictionary: Bool

    static let `default` = ConversionOptions(
        maxCandidateCount: 10,
        includeKatakana: true,
        includeHiragana: true,
        prioritizeUserDictionary: true
    )
}

struct Candidate: Identifiable, Equatable {
    let id: UUID
    let text: String
    let type: CandidateType
    let score: Double
    let metadata: CandidateMetadata?
}

enum CandidateType {
    case kanji
    case hiragana
    case katakana
    case userDictionary
}

struct CandidateMetadata {
    let partOfSpeech: String?
    let frequency: Int?
}
```

#### 2.2 UserDictionary実装
```swift:CyrillicKeyboard/Engine/UserDictionary.swift
//
//  UserDictionary.swift
//  CyrillicKeyboard
//
//  Manages user learning data
//

import Foundation

/// User dictionary for learning
final class UserDictionary {
    // MARK: - Properties

    private var entries: [String: [String]] = [:]
    private let userDefaults: UserDefaults
    private let key = "com.pismo.userDictionary"

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    // MARK: - Dictionary Management

    func add(input: String, output: String) {
        var outputs = entries[input] ?? []

        // Move to front if exists, otherwise append
        if let index = outputs.firstIndex(of: output) {
            outputs.remove(at: index)
        }
        outputs.insert(output, at: 0)

        // Limit to 10 entries per input
        if outputs.count > 10 {
            outputs = Array(outputs.prefix(10))
        }

        entries[input] = outputs
        save()
    }

    func lookup(_ input: String) -> [Candidate] {
        guard let outputs = entries[input] else { return [] }

        return outputs.enumerated().map { (index, output) in
            Candidate(
                id: UUID(),
                text: output,
                type: .userDictionary,
                score: Double(10 - index),  // Higher score for recent
                metadata: nil
            )
        }
    }

    func clear() {
        entries.removeAll()
        save()
    }

    // MARK: - Persistence

    private func load() {
        if let data = userDefaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) {
            entries = decoded
            print("[UserDictionary] Loaded \(entries.count) entries")
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: key)
            print("[UserDictionary] Saved \(entries.count) entries")
        }
    }
}
```

### Step 3: CyrillicInputManager統合（2日）

Phase 1の `CyrillicInputManager.swift` に変換エンジンを統合:

```swift:CyrillicKeyboard/Engine/CyrillicInputManager.swift
// 既存ファイルに追加

final class CyrillicInputManager {
    // MARK: - Properties (Phase 2追加)

    private let conversionEngine: KanjiConversionEngine?
    private var candidates: [Candidate] = []
    private var selectedCandidateIndex: Int = 0

    // MARK: - Initialization (Phase 2更新)

    init(displayedTextManager: DisplayedTextManager,
         rustCore: RustCoreFFI = .shared,
         profileManager: ProfileManager = .shared,
         conversionEngine: KanjiConversionEngine? = nil) {
        self.displayedTextManager = displayedTextManager
        self.rustCore = rustCore
        self.profileManager = profileManager
        self.conversionEngine = conversionEngine
    }

    // MARK: - Conversion (Phase 2実装)

    /// Phase 1の handleIMEMode を更新
    private func handleIMEMode(result: ConversionResult) {
        displayedTextManager.updateComposingText(composingText.hiraganaTarget)
        onComposingTextChanged?(composingText.hiraganaTarget)

        // Phase 2: リアルタイム候補取得
        if !composingText.hiraganaTarget.isEmpty {
            requestConversionCandidates()
        }
    }

    /// Phase 1の startConversion を更新
    private func startConversion() {
        isConverting = true
        requestConversionCandidates()
    }

    /// Phase 2新規実装
    private func requestConversionCandidates() {
        guard let engine = conversionEngine else {
            showFallbackCandidates()
            return
        }

        Task {
            do {
                let candidateList = try await engine.requestCandidates(
                    for: composingText.hiraganaTarget,
                    maxCount: 10
                )

                await MainActor.run {
                    self.candidates = candidateList
                    self.selectedCandidateIndex = 0
                    self.onCandidatesUpdated?(candidateList.map { $0.text })

                    // Show first candidate as live conversion
                    if !candidateList.isEmpty {
                        self.displayedTextManager.updateComposingText(
                            self.composingText.hiraganaTarget,
                            liveConversionText: candidateList[0].text
                        )
                    }
                }
            } catch {
                print("[CyrillicInputManager] Conversion error: \(error)")
                await MainActor.run {
                    self.showFallbackCandidates()
                }
            }
        }
    }

    /// Phase 1の commitCandidate を更新
    private func commitCandidate(at index: Int) {
        guard index < candidates.count else { return }

        let selected = candidates[index]

        // Phase 2: Learn from selection
        conversionEngine?.learn(input: composingText.hiraganaTarget, selected: selected)

        commitText(selected.text)
    }
}
```

### Step 4: KeyboardViewController更新（1日）

```swift:CyrillicKeyboard/KeyboardViewController.swift
class KeyboardViewController: UIInputViewController {
    // MARK: - Managers

    private var conversionEngine: KanjiConversionEngine?

    // MARK: - Manager Setup (Phase 2更新)

    private func setupManagers() {
        // Initialize conversion engine
        do {
            conversionEngine = try KanjiConversionEngine()
        } catch {
            print("[KeyboardViewController] Failed to initialize conversion engine: \(error)")
            conversionEngine = nil
        }

        // Create DisplayedTextManager
        displayedTextManager = DisplayedTextManager(isMarkedTextEnabled: true)
        displayedTextManager.setTextDocumentProxy(textDocumentProxy)

        // Create CyrillicInputManager (Phase 2: pass conversionEngine)
        inputManager = CyrillicInputManager(
            displayedTextManager: displayedTextManager,
            rustCore: RustCoreFFI.shared,
            profileManager: ProfileManager.shared,
            conversionEngine: conversionEngine  // Phase 2追加
        )

        // Setup callbacks
        inputManager.onCandidatesUpdated = { [weak self] candidates in
            self?.keyboardView?.showCandidates(candidates)
        }
    }
}
```

### Step 5: ビルドとテスト（1日）

```bash
# ビルド
cd mobile/iOS
xcodebuild -project Pismo.xcodeproj \
  -scheme Pismo \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build

# シミュレータにインストール
xcrun simctl install booted path/to/Pismo.app

# 起動
xcrun simctl launch booted com.pismo.Pismo
```

---

## テスト要件

### ユニットテスト

#### UT2.1: KanjiConversionEngine
```swift
class KanjiConversionEngineTests: XCTestCase {
    var engine: KanjiConversionEngine!

    override func setUp() {
        engine = try! KanjiConversionEngine()
    }

    func testRequestCandidatesForKaisha() async throws {
        // When
        let candidates = try await engine.requestCandidates(for: "かいしゃ", maxCount: 10)

        // Then
        XCTAssertFalse(candidates.isEmpty)
        XCTAssertTrue(candidates.contains { $0.text == "会社" })
    }

    func testLearning() async throws {
        // Given
        let candidate = Candidate(id: UUID(), text: "開車", type: .kanji, score: 1.0, metadata: nil)

        // When
        engine.learn(input: "かいしゃ", selected: candidate)
        let candidates = try await engine.requestCandidates(for: "かいしゃ")

        // Then
        XCTAssertEqual(candidates.first?.text, "開車")  // Learned candidate should be first
    }
}
```

#### UT2.2: UserDictionary
```swift
class UserDictionaryTests: XCTestCase {
    func testAddAndLookup() {
        // Given
        let dict = UserDictionary()

        // When
        dict.add(input: "かいしゃ", output: "会社")
        let results = dict.lookup("かいしゃ")

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.text, "会社")
    }

    func testPersistence() {
        // Given
        let defaults = UserDefaults(suiteName: "test")!
        let dict1 = UserDictionary(userDefaults: defaults)
        dict1.add(input: "てすと", output: "テスト")

        // When
        let dict2 = UserDictionary(userDefaults: defaults)
        let results = dict2.lookup("てすと")

        // Then
        XCTAssertEqual(results.first?.text, "テスト")
    }
}
```

### 統合テスト

#### IT2.1: エンドツーエンド変換
```swift
func testEndToEndConversion() async {
    // Given
    let viewController = KeyboardViewController()
    viewController.loadView()
    viewController.viewDidLoad()

    // When: Type "かいしゃ"
    simulateKeyPress("К")
    simulateKeyPress("А")
    simulateKeyPress("Й")
    simulateKeyPress("Ш")
    simulateKeyPress("А")

    // Then: Hiragana displayed
    XCTAssertEqual(textDocumentProxy.markedText, "かいしゃ")

    // When: Press Space
    simulateKeyPress(" ")

    // Wait for async conversion
    try await Task.sleep(nanoseconds: 100_000_000)  // 100ms

    // Then: First candidate displayed
    XCTAssertTrue(textDocumentProxy.markedText == "会社" ||
                  textDocumentProxy.markedText == "開車")

    // When: Press Return
    simulateKeyPress("\n")

    // Then: Committed
    XCTAssertNil(textDocumentProxy.markedText)
    XCTAssertTrue(textDocumentProxy.documentContextBeforeInput?.contains("会社") == true ||
                  textDocumentProxy.documentContextBeforeInput?.contains("開車") == true)
}
```

---

## 完了基準

### 機能完了基準

#### AC2.1: 基本変換
```gherkin
Given ユーザーが "かいしゃ" を入力
When Spaceキーを押す
Then 候補に "会社" が含まれる
And 候補に "開車" が含まれる
And 候補に "かいしゃ" が含まれる（平仮名）
```

#### AC2.2: 候補サイクリング
```gherkin
Given 変換候補が表示されている
When Spaceキーを複数回押す
Then 候補が順に切り替わる
And 最後の候補の後は最初に戻る
```

#### AC2.3: 学習
```gherkin
Given ユーザーが "かいしゃ" → "開車" を選択
When 次回 "かいしゃ" を入力
Then "開車" が最上位候補になる
```

#### AC2.4: 辞書サイズ
```gherkin
Given azooKey辞書がバンドルされている
Then 辞書ファイルサイズが 45MB～55MB
And 変換候補数が 10,000単語以上
```

### パフォーマンス基準

#### P2.1: 変換速度
- 候補取得: 100ms以内
- UI更新: 16ms以内（60fps）

#### P2.2: メモリ使用量
- 辞書ロード時: < 100MB
- 通常動作時: < 50MB

---

## 次のステップ

### Phase 3: ライブ変換
Phase 2完了後、Phase 3では以下を実装:
- **LiveConversionManager**: 入力中の自動変換
- **文節分割**: "かい|しゃ" → "会|社"
- **予測変換**: 次の単語を予測

詳細は `PHASE_3_LIVE_CONVERSION.md` を参照。

---

**ドキュメント終わり**
