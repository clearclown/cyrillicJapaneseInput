# Phase 3: ライブ変換とインテリジェント入力

**ドキュメントバージョン**: 1.0
**最終更新**: 2025-11-22
**対象**: Phase 3担当エンジニア
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
ユーザーが明示的にSpaceキーを押さなくても、入力中に自動的に最適な変換候補を提示する「ライブ変換」機能を実装する。

### 達成目標
1. 🎯 **リアルタイム変換**: キー入力ごとに自動変換
2. 🎯 **文節分割**: 長文を適切な文節に分割
3. 🎯 **文節移動**: ←/→キーで文節間を移動
4. 🎯 **部分確定**: 確定したい文節のみを確定
5. 🎯 **予測変換**: 次に入力される単語を予測

### 成果物
- `LiveConversionManager.swift` (新規作成, ~400行)
- `ClauseSegmenter.swift` (新規作成, ~200行)
- `PredictiveEngine.swift` (新規作成, ~150行)
- `CyrillicInputManager.swift` (Phase 2から拡張, +200行)

---

## 前提条件

### Phase 2完了事項
以下のコンポーネントがPhase 2で実装済みであることが必須:
- ✅ `KanjiConversionEngine`: 漢字変換エンジン
- ✅ `Candidate`: 変換候補モデル
- ✅ `CyrillicInputManager.requestConversionCandidates()`: 候補取得メソッド
- ✅ azooKey辞書バンドル

### 技術スタック
- Swift 5.9+
- azooKey's KanaKanjiConverter
- Natural Language Framework (文節分割)

---

## 実装する機能

### 1. ライブ変換の動作

#### ユーザー体験（Phase 2との比較）

**Phase 2（手動変換）**:
```
1. ユーザー: К, А, Й, Ш, А を入力
   → 画面: "かいしゃ" (下線付き)

2. ユーザー: Space を押す  ← 明示的な変換トリガー
   → 画面: "会社" (太字下線)

3. ユーザー: Return を押す
   → 画面: "会社" (確定)
```

**Phase 3（ライブ変換）**:
```
1. ユーザー: К, А, Й を入力
   → 画面: "かい" (グレー下線)
   → 自動: まだ短いので変換しない

2. ユーザー: Ш を入力
   → 画面: "かいし" (グレー下線)
   → 自動: まだ単語として不完全

3. ユーザー: А を入力
   → 画面: "会社" (太字下線) ← 自動変換！
   → 候補: [会社, 開車, 快謝, ...]

4. ユーザー: Space を押すと次の候補
   → 画面: "開車" (太字下線)

5. ユーザー: Return または 次の文字入力
   → 画面: "会社" (確定)
```

### 2. 文節分割

#### 長文入力の例
```
入力: "きょうはいいてんきですね"

文節分割:
┌─────┬──┬────┬────┬────┬──┐
│きょう│は│いい  │てんき│です│ね│
│今日  │は│良い  │天気  │です│ね│
└─────┴──┴────┴────┴────┴──┘
   ▲      ▲     ▲      ▲      ▲   ▲
   文節1  助詞  文節2  文節3  助動詞 終助詞

ライブ変換結果:
"今日は良い天気ですね"
```

#### 文節の選択と変更
```
1. ユーザー: ← キーを押す
   → 画面: "今日は良い[天気]ですね"  ← 「天気」が選択状態

2. ユーザー: Space を押す
   → 画面: "今日は良い[電気]ですね"  ← 次の候補に変更

3. ユーザー: Return を押す
   → 画面: "今日は良い電気ですね"  ← 確定
```

### 3. 予測変換

#### コンテキストベース予測
```
確定済み: "今日は"
入力中: "い"

予測候補:
1. いい天気  (頻度: 高)
2. 行きます  (頻度: 中)
3. いつも    (頻度: 中)
```

---

## 技術仕様

### 1. LiveConversionManager

#### 役割
リアルタイム変換の制御と状態管理。

#### 責務
- ✅ キー入力ごとの変換トリガー判定
- ✅ 変換候補の自動選択
- ✅ 文節分割の管理
- ✅ ライブ変換のオン/オフ制御

#### アーキテクチャ
```
LiveConversionManager
├── conversionEngine: KanjiConversionEngine
├── clauseSegmenter: ClauseSegmenter
├── predictiveEngine: PredictiveEngine
└── conversionState: ConversionState

状態遷移:
Idle → Composing → LiveConverting → Confirmed → Idle
```

#### 変換トリガー条件
```swift
/// ライブ変換をトリガーするかどうかを判定
func shouldTriggerLiveConversion(hiragana: String) -> Bool {
    // 条件1: 最低3文字以上
    guard hiragana.count >= 3 else { return false }

    // 条件2: 単語として完結している可能性
    // （助詞、動詞語尾、句読点など）
    if endsWithParticle(hiragana) { return true }
    if endsWithVerbEnding(hiragana) { return true }

    // 条件3: 辞書に存在する単語
    if isDictionaryWord(hiragana) { return true }

    // 条件4: 前回変換から一定時間経過（500ms）
    if timeSinceLastInput > 0.5 { return true }

    return false
}
```

### 2. ClauseSegmenter

#### 役割
長文を適切な文節に分割。

#### 分割アルゴリズム
```swift
/// 文節分割
func segment(_ hiragana: String) -> [Clause] {
    // Natural Language Frameworkを使用
    let tagger = NLTagger(tagSchemes: [.lexicalClass])
    tagger.string = hiragana

    var clauses: [Clause] = []
    var currentClause = ""

    tagger.enumerateTags(in: hiragana.startIndex..<hiragana.endIndex,
                         unit: .word,
                         scheme: .lexicalClass) { tag, range in

        let word = String(hiragana[range])

        // 助詞で区切る
        if tag == .particle {
            if !currentClause.isEmpty {
                clauses.append(Clause(text: currentClause, type: .word))
                currentClause = ""
            }
            clauses.append(Clause(text: word, type: .particle))
        } else {
            currentClause += word
        }

        return true
    }

    if !currentClause.isEmpty {
        clauses.append(Clause(text: currentClause, type: .word))
    }

    return clauses
}
```

#### Clause モデル
```swift
struct Clause: Identifiable, Equatable {
    let id: UUID
    let text: String          // "今日"
    let type: ClauseType      // .word, .particle, .auxiliary
    var candidates: [String]  // ["今日", "きょう", "京"]
    var selectedIndex: Int    // 0
}

enum ClauseType {
    case word       // 実質語（名詞、動詞、形容詞など）
    case particle   // 助詞（は、が、を、に、など）
    case auxiliary  // 助動詞（です、ます、だ、など）
    case punctuation // 句読点
}
```

### 3. PredictiveEngine

#### 役割
次に入力される単語を予測。

#### 予測アルゴリズム
```swift
/// コンテキストベース予測
func predict(context: String, prefix: String) -> [String] {
    // 1. Bigramモデル: "今日は" → ["いい", "行く", ...]
    let bigramCandidates = bigramModel.predict(after: context)

    // 2. プレフィックスマッチ: "い" で始まる単語
    let prefixMatches = bigramCandidates.filter { $0.hasPrefix(prefix) }

    // 3. スコアリング: 頻度 × 最近の使用率
    let scored = prefixMatches.map { word in
        (word, score(word, context: context))
    }

    // 4. ソートして返す
    return scored.sorted { $0.1 > $1.1 }.map { $0.0 }
}

private func score(_ word: String, context: String) -> Double {
    let frequency = frequencyMap[word] ?? 0.0
    let recency = recentUseScore(word)
    let contextual = bigramScore(context, word)

    return frequency * 0.4 + recency * 0.3 + contextual * 0.3
}
```

---

## API設計

### LiveConversionManager

```swift
//
//  LiveConversionManager.swift
//  CyrillicKeyboard
//
//  Manages real-time conversion as user types
//

import Foundation
import NaturalLanguage

/// Manages live (automatic) conversion
final class LiveConversionManager {
    // MARK: - Properties

    /// Conversion engine
    private let conversionEngine: KanjiConversionEngine

    /// Clause segmenter
    private let clauseSegmenter: ClauseSegmenter

    /// Predictive engine
    private let predictiveEngine: PredictiveEngine

    /// Whether live conversion is enabled
    var isEnabled: Bool = true

    /// Minimum hiragana length to trigger conversion
    var minimumLength: Int = 3

    /// Delay before auto-conversion (seconds)
    var conversionDelay: TimeInterval = 0.5

    /// Last input timestamp
    private var lastInputTime: Date = Date()

    /// Current conversion state
    private var state: ConversionState = .idle

    // MARK: - Callbacks

    /// Called when live conversion result is ready
    var onLiveConversionUpdated: ((String) -> Void)?

    /// Called when clauses are updated
    var onClausesUpdated: (([Clause]) -> Void)?

    // MARK: - Initialization

    init(conversionEngine: KanjiConversionEngine,
         clauseSegmenter: ClauseSegmenter = ClauseSegmenter(),
         predictiveEngine: PredictiveEngine = PredictiveEngine()) {
        self.conversionEngine = conversionEngine
        self.clauseSegmenter = clauseSegmenter
        self.predictiveEngine = predictiveEngine
    }

    // MARK: - Conversion Control

    /// Processes input for live conversion
    /// - Parameter hiragana: Current hiragana input
    func processInput(_ hiragana: String) {
        guard isEnabled else { return }

        lastInputTime = Date()

        // Check if we should trigger conversion
        if shouldTriggerLiveConversion(hiragana) {
            performLiveConversion(hiragana)
        }
    }

    /// Forces immediate conversion
    func forceConversion(_ hiragana: String) {
        performLiveConversion(hiragana)
    }

    /// Clears conversion state
    func reset() {
        state = .idle
        onLiveConversionUpdated?("")
        onClausesUpdated?([])
    }

    // MARK: - Private Methods

    /// Determines if live conversion should trigger
    private func shouldTriggerLiveConversion(_ hiragana: String) -> Bool {
        // Minimum length
        guard hiragana.count >= minimumLength else { return false }

        // Check time delay
        let elapsed = Date().timeIntervalSince(lastInputTime)
        if elapsed < conversionDelay { return false }

        // Check if ends with particle or verb ending
        if endsWithParticle(hiragana) { return true }
        if endsWithVerbEnding(hiragana) { return true }

        // Check if it's a dictionary word
        if isDictionaryWord(hiragana) { return true }

        return false
    }

    /// Performs live conversion
    private func performLiveConversion(_ hiragana: String) {
        state = .converting

        Task {
            do {
                // Get conversion candidates
                let candidates = try await conversionEngine.requestCandidates(
                    for: hiragana,
                    maxCount: 1
                )

                guard let best = candidates.first else {
                    await MainActor.run {
                        self.onLiveConversionUpdated?(hiragana)
                    }
                    return
                }

                await MainActor.run {
                    self.state = .converted
                    self.onLiveConversionUpdated?(best.text)
                }
            } catch {
                print("[LiveConversionManager] Conversion failed: \(error)")
                await MainActor.run {
                    self.onLiveConversionUpdated?(hiragana)
                }
            }
        }
    }

    /// Checks if hiragana ends with a particle
    private func endsWithParticle(_ hiragana: String) -> Bool {
        let particles = ["は", "が", "を", "に", "で", "と", "から", "まで", "へ", "の"]
        return particles.contains { hiragana.hasSuffix($0) }
    }

    /// Checks if hiragana ends with verb ending
    private func endsWithVerbEnding(_ hiragana: String) -> Bool {
        let endings = ["ます", "ました", "ません", "ませんでした", "です", "でした"]
        return endings.contains { hiragana.hasSuffix($0) }
    }

    /// Checks if word exists in dictionary
    private func isDictionaryWord(_ hiragana: String) -> Bool {
        // TODO: Implement dictionary lookup
        return false
    }

    // MARK: - Clause Management

    /// Segments hiragana into clauses
    func segmentIntoClauses(_ hiragana: String) -> [Clause] {
        let clauses = clauseSegmenter.segment(hiragana)

        // Get candidates for each clause
        var clausesWithCandidates: [Clause] = []

        for clause in clauses {
            var mutableClause = clause

            if clause.type == .word {
                Task {
                    if let candidates = try? await conversionEngine.requestCandidates(
                        for: clause.text,
                        maxCount: 5
                    ) {
                        mutableClause.candidates = candidates.map { $0.text }
                    }
                }
            }

            clausesWithCandidates.append(mutableClause)
        }

        onClausesUpdated?(clausesWithCandidates)
        return clausesWithCandidates
    }
}

// MARK: - Supporting Types

enum ConversionState {
    case idle           // No active conversion
    case composing      // User is typing
    case converting     // Conversion in progress
    case converted      // Conversion complete
    case selecting      // User is selecting clause
}
```

### ClauseSegmenter

```swift
//
//  ClauseSegmenter.swift
//  CyrillicKeyboard
//
//  Segments hiragana text into clauses
//

import Foundation
import NaturalLanguage

/// Segments hiragana into clauses
final class ClauseSegmenter {
    // MARK: - Properties

    private let tagger: NLTagger

    // MARK: - Initialization

    init() {
        self.tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
    }

    // MARK: - Segmentation

    /// Segments hiragana into clauses
    func segment(_ hiragana: String) -> [Clause] {
        guard !hiragana.isEmpty else { return [] }

        tagger.string = hiragana

        var clauses: [Clause] = []
        var currentClause = ""
        var currentType: ClauseType = .word

        tagger.enumerateTags(
            in: hiragana.startIndex..<hiragana.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, range in
            let word = String(hiragana[range])

            let type = self.clauseTypeFromTag(tag)

            // Particle creates boundary
            if type == .particle {
                if !currentClause.isEmpty {
                    clauses.append(Clause(
                        id: UUID(),
                        text: currentClause,
                        type: currentType,
                        candidates: [],
                        selectedIndex: 0
                    ))
                    currentClause = ""
                }

                clauses.append(Clause(
                    id: UUID(),
                    text: word,
                    type: .particle,
                    candidates: [word],
                    selectedIndex: 0
                ))
            } else {
                currentClause += word
                currentType = type
            }

            return true
        }

        // Add remaining clause
        if !currentClause.isEmpty {
            clauses.append(Clause(
                id: UUID(),
                text: currentClause,
                type: currentType,
                candidates: [],
                selectedIndex: 0
            ))
        }

        return clauses
    }

    // MARK: - Helper Methods

    private func clauseTypeFromTag(_ tag: NLTag?) -> ClauseType {
        guard let tag = tag else { return .word }

        switch tag {
        case .particle:
            return .particle
        case .classifier, .determiner:
            return .auxiliary
        default:
            return .word
        }
    }
}

// MARK: - Clause Model

struct Clause: Identifiable, Equatable {
    let id: UUID
    let text: String
    let type: ClauseType
    var candidates: [String]
    var selectedIndex: Int

    var selectedCandidate: String {
        guard !candidates.isEmpty else { return text }
        return candidates[selectedIndex]
    }
}

enum ClauseType {
    case word
    case particle
    case auxiliary
    case punctuation
}
```

### PredictiveEngine

```swift
//
//  PredictiveEngine.swift
//  CyrillicKeyboard
//
//  Predicts next words based on context
//

import Foundation

/// Predicts next words
final class PredictiveEngine {
    // MARK: - Properties

    /// Bigram frequency map
    private var bigramMap: [String: [String: Double]] = [:]

    /// Unigram frequency map
    private var unigramMap: [String: Double] = [:]

    /// Recent usage tracking
    private var recentUsage: [String: Date] = [:]

    // MARK: - Initialization

    init() {
        loadBigramModel()
    }

    // MARK: - Prediction

    /// Predicts next words based on context and prefix
    /// - Parameters:
    ///   - context: Previous word or phrase
    ///   - prefix: Current input prefix
    ///   - maxCount: Maximum predictions
    /// - Returns: Array of predicted words
    func predict(after context: String, prefix: String, maxCount: Int = 5) -> [String] {
        // Get bigram candidates
        var candidates: [(String, Double)] = []

        if let bigrams = bigramMap[context] {
            for (word, score) in bigrams {
                if word.hasPrefix(prefix) || prefix.isEmpty {
                    let finalScore = calculateScore(
                        word: word,
                        bigramScore: score,
                        context: context
                    )
                    candidates.append((word, finalScore))
                }
            }
        }

        // Sort by score
        candidates.sort { $0.1 > $1.1 }

        return Array(candidates.prefix(maxCount)).map { $0.0 }
    }

    /// Records user selection for learning
    func recordSelection(context: String, selected: String) {
        // Update bigram
        if bigramMap[context] == nil {
            bigramMap[context] = [:]
        }
        bigramMap[context]?[selected, default: 0] += 1.0

        // Update unigram
        unigramMap[selected, default: 0] += 1.0

        // Record recent usage
        recentUsage[selected] = Date()

        // Persist
        saveBigramModel()
    }

    // MARK: - Private Methods

    private func calculateScore(word: String, bigramScore: Double, context: String) -> Double {
        let bigramWeight = 0.5
        let unigramWeight = 0.3
        let recencyWeight = 0.2

        let unigramScore = unigramMap[word] ?? 0.0
        let recencyScore = recencyScoreForWord(word)

        return (bigramScore * bigramWeight) +
               (unigramScore * unigramWeight) +
               (recencyScore * recencyWeight)
    }

    private func recencyScoreForWord(_ word: String) -> Double {
        guard let lastUsed = recentUsage[word] else { return 0.0 }

        let elapsed = Date().timeIntervalSince(lastUsed)
        let hours = elapsed / 3600.0

        // Decay: 1.0 at 0 hours, 0.0 at 168 hours (1 week)
        return max(0.0, 1.0 - (hours / 168.0))
    }

    private func loadBigramModel() {
        // Load from UserDefaults or file
        // TODO: Implement persistence
    }

    private func saveBigramModel() {
        // Save to UserDefaults or file
        // TODO: Implement persistence
    }
}
```

---

## 実装手順

### Step 1: LiveConversionManager作成（2日）
1. 基本クラス構造
2. 変換トリガー判定ロジック
3. KanjiConversionEngine統合
4. コールバック実装

### Step 2: ClauseSegmenter作成（2日）
1. Natural Language Framework統合
2. 文節分割ロジック
3. Clauseモデル定義
4. 候補取得統合

### Step 3: PredictiveEngine作成（2日）
1. Bigramモデル構築
2. 予測アルゴリズム
3. スコアリングロジック
4. 永続化

### Step 4: CyrillicInputManager統合（2日）
1. LiveConversionManager統合
2. 文節選択ロジック
3. ←/→キー処理
4. 部分確定ロジック

### Step 5: テストと調整（2日）
1. ユニットテスト
2. 統合テスト
3. パフォーマンステスト
4. UX調整

---

## 完了基準

### 機能完了基準

#### AC3.1: ライブ変換
```gherkin
Given ライブ変換が有効
When "かいしゃ" を入力
Then 自動的に "会社" に変換される
And Spaceキーを押さなくても変換される
```

#### AC3.2: 文節分割
```gherkin
Given "きょうはいいてんきですね" を入力
Then 文節に分割される: ["今日", "は", "良い", "天気", "です", "ね"]
And 各文節に候補が表示される
```

#### AC3.3: 予測変換
```gherkin
Given "今日は" が確定済み
When "い" を入力
Then 予測候補が表示される: ["いい天気", "行きます", "いつも"]
```

---

## 次のステップ

Phase 4では候補UI、Phase 5ではプロファイル管理を実装します。

詳細は `PHASE_4_CANDIDATE_UI.md` を参照。

---

**ドキュメント終わり**
