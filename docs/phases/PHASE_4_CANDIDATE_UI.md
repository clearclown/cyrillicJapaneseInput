# Phase 4: 候補UI強化とインタラクション

**ドキュメントバージョン**: 1.0
**最終更新**: 2025-11-22
**対象**: Phase 4担当エンジニア（UI/UX専門）
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
変換候補の表示UIを改善し、ユーザーが直感的に候補を選択・操作できるようにする。

### 達成目標
1. 🎯 **横スクロール候補バー**: 標準的な日本語IME風の候補表示
2. 🎯 **候補詳細表示**: 読み仮名、品詞情報の表示
3. 🎯 **タッチジェスチャー**: スワイプで候補切り替え
4. 🎯 **数字キー選択**: 1～9キーで候補を直接選択
5. 🎯 **アニメーション**: スムーズな候補切り替えアニメーション

### 成果物
- `CandidateBarView.swift` (新規作成, ~300行)
- `CandidateCellView.swift` (新規作成, ~100行)
- `GestureHandler.swift` (新規作成, ~150行)
- `CyrillicKeyboardView.swift` (Phase 1から拡張, +100行)

---

## 前提条件

### Phase 2完了事項
- ✅ `Candidate` モデル定義
- ✅ `onCandidatesUpdated` コールバック
- ✅ 基本的な候補表示機能

### Phase 3完了事項（オプション）
- ✅ ライブ変換機能
- ✅ 文節分割

---

## 実装する機能

### 1. 候補バーUI

#### デザイン仕様
```
┌────────────────────────────────────────────────┐
│  ┌────┬────┬────┬────┬────┬────┬────┬────┐   │
│  │ ① │ ② │ ③ │ ④│ ⑤ │ ⑥ │ ⑦ │ → │   │  ← 横スクロール可能
│  │会社│開車│快謝│かい│カイ│介 │海 │   │   │
│  └────┴────┴────┴────┴────┴────┴────┴────┘   │
│     ▲                                          │
│   選択中（太字、背景色）                       │
└────────────────────────────────────────────────┘
```

#### 候補セルのデザイン
```
┌──────────────┐
│  ①           │  ← 候補番号（1～9）
│  会社        │  ← メイン候補（大きく）
│  かいしゃ    │  ← 読み（小さく、グレー）
│  [名詞]      │  ← 品詞（さらに小さく）
└──────────────┘
```

### 2. インタラクション

#### 候補選択方法
1. **タップ**: 候補を直接タップ
2. **Spaceキー**: 次の候補に移動
3. **数字キー（1～9）**: 番号で直接選択
4. **左右スワイプ**: 候補をスワイプで切り替え
5. **Returnキー**: 選択中の候補を確定

#### ジェスチャー
- **右スワイプ**: 前の候補へ
- **左スワイプ**: 次の候補へ
- **上スワイプ**: 候補バーを展開（全候補表示）
- **下スワイプ**: 候補バーを閉じる

### 3. アニメーション

#### 候補切り替えアニメーション
```swift
// スムーズなスライドアニメーション
UIView.animate(withDuration: 0.2,
               delay: 0,
               options: [.curveEaseInOut],
               animations: {
    self.selectedCellView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
    self.selectedCellView.backgroundColor = .systemBlue
})
```

#### 候補表示アニメーション
```swift
// フェードイン + スケール
candidateBarView.alpha = 0
candidateBarView.transform = CGAffineTransform(scaleY: 0.8)

UIView.animate(withDuration: 0.25) {
    self.candidateBarView.alpha = 1.0
    self.candidateBarView.transform = .identity
}
```

---

## UI設計

### 1. CandidateBarView

```swift
//
//  CandidateBarView.swift
//  CyrillicKeyboard
//
//  Horizontal scrollable candidate bar
//

import UIKit

/// Horizontal candidate bar
final class CandidateBarView: UIView {
    // MARK: - Properties

    /// Collection view for candidates
    private let collectionView: UICollectionView

    /// Candidates to display
    private var candidates: [Candidate] = []

    /// Currently selected index
    private var selectedIndex: Int = 0

    /// Selection callback
    var onCandidateSelected: ((Int) -> Void)?

    // MARK: - Initialization

    override init(frame: CGRect) {
        // Setup collection view layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false

        super.init(frame: frame)

        setupViews()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .systemGray6

        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            CandidateCellView.self,
            forCellWithReuseIdentifier: CandidateCellView.reuseIdentifier
        )
    }

    private func setupGestures() {
        // Swipe gestures
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipe.direction = .left
        addGestureRecognizer(leftSwipe)

        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipe.direction = .right
        addGestureRecognizer(rightSwipe)
    }

    // MARK: - Public Methods

    /// Updates candidates
    func updateCandidates(_ candidates: [Candidate], selectedIndex: Int = 0) {
        self.candidates = candidates
        self.selectedIndex = selectedIndex

        collectionView.reloadData()

        // Scroll to selected
        if !candidates.isEmpty {
            let indexPath = IndexPath(item: selectedIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }

        // Animate appearance
        animateAppearance()
    }

    /// Selects candidate at index
    func selectCandidate(at index: Int) {
        guard index < candidates.count else { return }

        let previousIndex = selectedIndex
        selectedIndex = index

        // Update cells
        let previousIndexPath = IndexPath(item: previousIndex, section: 0)
        let newIndexPath = IndexPath(item: index, section: 0)

        collectionView.reloadItems(at: [previousIndexPath, newIndexPath])
        collectionView.scrollToItem(at: newIndexPath, at: .centeredHorizontally, animated: true)
    }

    /// Moves to next candidate
    func selectNextCandidate() {
        let next = (selectedIndex + 1) % candidates.count
        selectCandidate(at: next)
    }

    /// Moves to previous candidate
    func selectPreviousCandidate() {
        let prev = (selectedIndex - 1 + candidates.count) % candidates.count
        selectCandidate(at: prev)
    }

    // MARK: - Gesture Handlers

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            selectNextCandidate()
        case .right:
            selectPreviousCandidate()
        default:
            break
        }
    }

    // MARK: - Animations

    private func animateAppearance() {
        alpha = 0
        transform = CGAffineTransform(scaleY: 0.8)

        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
            self.alpha = 1.0
            self.transform = .identity
        }
    }
}

// MARK: - UICollectionViewDataSource

extension CandidateBarView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return candidates.count
    }

    func collectionView(_ collectionView: UICollectionView,
                       cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CandidateCellView.reuseIdentifier,
            for: indexPath
        ) as! CandidateCellView

        let candidate = candidates[indexPath.item]
        let isSelected = indexPath.item == selectedIndex
        let number = indexPath.item < 9 ? indexPath.item + 1 : nil

        cell.configure(
            candidate: candidate,
            number: number,
            isSelected: isSelected
        )

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension CandidateBarView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectCandidate(at: indexPath.item)
        onCandidateSelected?(indexPath.item)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CandidateBarView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                       layout collectionViewLayout: UICollectionViewLayout,
                       sizeForItemAt indexPath: IndexPath) -> CGSize {
        let candidate = candidates[indexPath.item]
        let width = estimatedWidth(for: candidate)
        return CGSize(width: width, height: collectionView.bounds.height - 8)
    }

    private func estimatedWidth(for candidate: Candidate) -> CGFloat {
        // Calculate based on text length
        let textWidth = (candidate.text as NSString).size(
            withAttributes: [.font: UIFont.systemFont(ofSize: 18, weight: .medium)]
        ).width

        return max(60, textWidth + 32)
    }
}
```

### 2. CandidateCellView

```swift
//
//  CandidateCellView.swift
//  CyrillicKeyboard
//
//  Individual candidate cell
//

import UIKit

/// Candidate cell in candidate bar
final class CandidateCellView: UICollectionViewCell {
    static let reuseIdentifier = "CandidateCellView"

    // MARK: - UI Components

    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let mainLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let readingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let typeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.textColor = .systemGray2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray4.cgColor

        contentView.addSubview(numberLabel)
        contentView.addSubview(mainLabel)
        contentView.addSubview(readingLabel)
        contentView.addSubview(typeLabel)

        NSLayoutConstraint.activate([
            numberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            numberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),

            mainLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 2),
            mainLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            readingLabel.topAnchor.constraint(equalTo: mainLabel.bottomAnchor, constant: 2),
            readingLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            typeLabel.topAnchor.constraint(equalTo: readingLabel.bottomAnchor, constant: 2),
            typeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            typeLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -4)
        ])
    }

    // MARK: - Configuration

    func configure(candidate: Candidate, number: Int?, isSelected: Bool) {
        // Number
        if let number = number {
            numberLabel.text = "⓪①②③④⑤⑥⑦⑧⑨"
                .dropFirst(number)
                .prefix(1)
                .description
            numberLabel.isHidden = false
        } else {
            numberLabel.isHidden = true
        }

        // Main text
        mainLabel.text = candidate.text

        // Reading (if different from main text)
        if candidate.type == .kanji, let metadata = candidate.metadata {
            readingLabel.text = metadata.partOfSpeech
            readingLabel.isHidden = false
        } else {
            readingLabel.isHidden = true
        }

        // Type
        typeLabel.text = typeDescription(for: candidate.type)
        typeLabel.isHidden = candidate.type == .kanji

        // Selection state
        if isSelected {
            contentView.backgroundColor = .systemBlue
            contentView.layer.borderColor = UIColor.systemBlue.cgColor
            mainLabel.textColor = .white
            readingLabel.textColor = .white
            typeLabel.textColor = .white
            numberLabel.textColor = .white

            // Scale animation
            UIView.animate(withDuration: 0.2) {
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }
        } else {
            contentView.backgroundColor = .systemBackground
            contentView.layer.borderColor = UIColor.systemGray4.cgColor
            mainLabel.textColor = .label
            readingLabel.textColor = .systemGray
            typeLabel.textColor = .systemGray2
            numberLabel.textColor = .systemGray

            transform = .identity
        }
    }

    private func typeDescription(for type: CandidateType) -> String {
        switch type {
        case .kanji: return ""
        case .hiragana: return "ひらがな"
        case .katakana: return "カタカナ"
        case .userDictionary: return "ユーザー"
        }
    }
}
```

---

## 実装手順

### Step 1: CandidateBarView作成（2日）
1. UICollectionView セットアップ
2. レイアウトロジック
3. 候補更新メソッド
4. ジェスチャー処理

### Step 2: CandidateCellView作成（1日）
1. セルレイアウト
2. 候補表示ロジック
3. 選択状態の視覚化

### Step 3: CyrillicKeyboardView統合（2日）
1. CandidateBarView 追加
2. 数字キー処理
3. コールバック接続

### Step 4: アニメーション実装（1日）
1. 候補切り替えアニメーション
2. 表示/非表示アニメーション

### Step 5: テストとUX調整（2日）
1. タップ領域の調整
2. スクロール動作の最適化
3. パフォーマンステスト

---

## 完了基準

### 機能完了基準

#### AC4.1: 候補バー表示
```gherkin
Given "かいしゃ" を入力
When Spaceキーを押す
Then 候補バーが表示される
And 最初の候補が選択状態
And 候補番号（①②③...）が表示される
```

#### AC4.2: タップ選択
```gherkin
Given 候補バーが表示されている
When 候補を直接タップ
Then その候補が確定される
```

#### AC4.3: 数字キー選択
```gherkin
Given 候補バーに5つの候補が表示されている
When "3"キーを押す
Then 3番目の候補が確定される
```

#### AC4.4: スワイプ操作
```gherkin
Given 候補バーが表示されている
When 左にスワイプ
Then 次の候補が選択される
```

---

**ドキュメント終わり**
