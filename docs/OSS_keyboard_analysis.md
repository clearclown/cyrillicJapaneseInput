# OSSキーボード実装分析

このドキュメントは、主要なOSSキーボードプロジェクトを分析し、Pismoプロジェクトに活かせる知見をまとめたものです。

## 分析対象プロジェクト

1. **KeyboardKit** (iOS) - Swift/SwiftUI
2. **giellakbd-ios** (iOS) - 多言語対応
3. **AnySoftKeyboard** (Android) - XML定義ベース

---

## 1. KeyboardKit (iOS)

### 概要
- **リポジトリ**: https://github.com/KeyboardKit/KeyboardKit
- **特徴**: SwiftUI完全対応、包括的なキーボードフレームワーク
- **ライセンス**: Open Source + Pro版

### 主要なアーキテクチャ

#### KeyboardViewController
```swift
class KeyboardViewController: KeyboardInputViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setup(for: .keyboardKitDemo) { result in
            switch result {
            case .success:
                self?.setupDemoServices()
                self?.setupDemoState()
            case .failure(let error):
                print(error)
            }
        }
    }

    override func viewWillSetupKeyboardView() {
        setupKeyboardView { controller in
            DemoKeyboardView(
                services: controller.services,
                state: controller.state
            )
        }
    }
}
```

#### 動的レイアウト生成
```swift
var demoLayout: KeyboardLayout {
    var layout = KeyboardLayout.standard(for: keyboardContext)
    guard keyboardContext.keyboardType == .alphabetic else { return layout }
    var item = layout.createIdealItem(for: .rocket)
    item.size.width = .input
    layout.itemRows.insert(item, after: .space)
    return layout
}
```

#### KeyboardView (SwiftUI)
```swift
KeyboardView(
    layout: demoLayout,
    services: services,
    buttonContent: { $0.view },
    buttonView: { $0.view.opacity(isToolbarToggled ? 0 : 1) },
    collapsedView: { $0.view },
    emojiKeyboard: { $0.view },
    toolbar: { params in /* カスタムツールバー */ }
)
.keyboardCalloutActions { params in
    // カスタムコールアウト（長押し）
    if case .character(let char) = params.action, char == "K" {
        return .init(characters: String("keyboardkit".reversed()))
    }
    return params.standardActions()
}
.keyboardTheme(themeContext.currentTheme)
```

### Pismoへの適用

1. **レイアウトの動的生成**: `KeyboardLayout.standard(for: context)`パターン
2. **itemRows.insert()**: キーの動的挿入・削除
3. **SwiftUI対応**: 現在のUIKitベースから段階的移行の可能性
4. **テーマシステム**: `.keyboardTheme()`による一貫したスタイリング

---

## 2. giellakbd-ios (iOS)

### 概要
- **リポジトリ**: https://github.com/divvun/giellakbd-ios
- **特徴**: 少数民族・先住民言語対応、多言語サポート
- **ライセンス**: Apache 2.0 / MIT

### 主要なアーキテクチャ

#### KeyboardLocale構造体
```swift
public struct KeyboardLocale: Hashable {
    let identifier: String
    let languageName: String

    static func localeFromBundle(_ bundle: Bundle) -> KeyboardLocale? {
        guard let info = bundle.infoDictionary,
            let languageName = info["CFBundleDisplayName"] as? String,
            let ext = info["NSExtension"] as? [String: Any],
            let attributes = ext["NSExtensionAttributes"] as? [String: Any],
            let languageIdentifier = attributes["PrimaryLanguage"] as? String else {
                return nil
        }
        return KeyboardLocale(identifier: languageIdentifier, languageName: languageName)
    }
}
```

**Info.plistから言語情報を動的に読み取る設計**

#### SystemKeys - デバイス適応レイアウト
```swift
static func systemKeyRowsForCurrentDevice(
    spaceName: String,
    returnName: String,
    traits: UITraitCollection
) -> [KeyDefinition] {
    var keys = [KeyDefinition]()
    let device = DeviceContext.current
    let shouldUseIPadLayout = device.shouldUseIPadLayout(traitCollection: traits)

    // iPad/iPhoneで異なるレイアウト
    if shouldUseIPadLayout && device.isLargeIPad {
        keys.append(KeyDefinition(type: .keyboard, size: CGSize(width: 1.25, height: 1.0)))
        keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 1.25, height: 1.0)))
    } else {
        keys.append(KeyDefinition(type: .symbols, size: CGSize(width: 1.25, height: 1.0)))
        keys.append(KeyDefinition(type: .keyboard, size: CGSize(width: 1.25, height: 1.0)))
    }
    // ...
}
```

#### スペースバー分割・バランス調整
```swift
func splitAndBalanceSpacebar() -> [[KeyDefinition]] {
    var copy = self
    for (i, row) in copy.enumerated() {
        for (keyIndex, key) in row.enumerated() {
            if case .spacebar = key.type {
                let splitSpace = KeyDefinition(
                    type: key.type,
                    size: CGSize(width: key.size.width / 2.0, height: key.size.height)
                )
                copy[i].remove(at: keyIndex)
                copy[i].insert(splitSpace, at: keyIndex)
                copy[i].insert(splitSpace, at: keyIndex)
                splitPoint = keyIndex + 1
            }
        }

        // 中央揃えのためのスペーサー挿入
        while splitPoint != (copy[i].count / 2) {
            if splitPoint > copy[i].count / 2 {
                copy[i].append(KeyDefinition(type: .spacer, size: CGSize(width: 0.0, height: 1.0)))
            } else {
                copy[i].insert(KeyDefinition(type: .spacer, size: CGSize(width: 0.0, height: 1.0)), at: 0)
            }
        }
    }
    return copy
}
```

### Pismoへの適用

1. **デバイス適応**: iPhone/iPad、Face ID有無でレイアウト変更
2. **KeyDefinition構造体**: `type` + `size` の組み合わせ
3. **スペーサーキー**: レイアウトバランス調整用の非表示キー
4. **Info.plist統合**: プロファイル情報をplistから読み取り

---

## 3. AnySoftKeyboard (Android)

### 概要
- **リポジトリ**: https://github.com/AnySoftKeyboard/AnySoftKeyboard
- **特徴**: 30言語以上対応、プライバシー重視、XML定義
- **ライセンス**: Apache 2.0

### 主要なアーキテクチャ

#### XMLベースのキーボード定義
```xml
<Keyboard xmlns:android="http://schemas.android.com/apk/res/android"
          android:keyWidth="10%p">

    <Row android:keyWidth="8.33%p">
        <!-- йцукенгшщзхъ -->
        <Key android:codes="1081"
             android:keyLabel="й"
             android:popupCharacters="1їӣӥ"
             android:keyEdgeFlags="left"/>
        <Key android:codes="1094"
             android:keyLabel="ц"
             android:popupCharacters="2ћџҵ"/>
        <!-- ... -->
    </Row>
</Keyboard>
```

#### 主要な属性

| 属性 | 説明 | 例 |
|-----|------|---|
| `android:codes` | Unicodeコードポイント | `1081` (й) |
| `android:keyLabel` | 表示テキスト | `"й"` |
| `android:popupCharacters` | 長押しバリエーション | `"1їӣӥ"` |
| `ask:hintLabel` | ヒント表示 | `"1"` (数字) |
| `android:keyWidth` | キー幅 | `"8.33%p"` |
| `android:keyEdgeFlags` | エッジフラグ | `"left"`, `"right"` |
| `android:isRepeatable` | 連続入力可能 | `true` (Backspace) |
| `android:isModifier` | モディファイアキー | `true` (Shift) |
| `android:isSticky` | スティッキー | `true` (Caps Lock的) |

#### ヒントラベル付きレイアウト
```xml
<Key android:codes="1081"
     android:keyLabel=""
     android:popupCharacters="1¹₁"
     ask:hintLabel="1"
     android:keyEdgeFlags="left"/>
```

**キリル文字をメイン表示、数字をヒントとして小さく表示**

#### 長押しバリエーション
```xml
<!-- е キーの長押し -->
<Key android:codes="1077"
     android:keyLabel="е"
     android:popupCharacters="5ёјҽҿӗәӛ"/>
```

**1つのキーで複数のバリエーション文字を入力可能**

#### 記号・演算子の長押し
```xml
<Key android:codes="1103"
     android:keyLabel=""
     android:popupCharacters="/÷"
     ask:hintLabel="/"/>
<Key android:codes="1090"
     android:keyLabel=""
     android:popupCharacters="<«"
     ask:hintLabel="<"/>
<Key android:codes="1100"
     android:keyLabel=""
     android:popupCharacters=">»µ"
     ask:hintLabel=">"/>
```

**ロシア語引用符«»も長押しで入力可能**

### Pismoへの適用

1. **長押しバリエーション**: UILongPressGestureRecognizerで実装
2. **ヒントラベル**: 各キーに小さく数字/記号を表示
3. **動的キー幅**: パーセンテージベースの幅指定
4. **JSON拡張**: 現在のスキーマに`popupCharacters`と`hintLabel`を追加

---

## Pismoプロジェクトへの実装提案

### 優先度: 高

#### 1. 長押しバリエーション機能
```swift
// CyrillicKeyboardView.swift
private func createKeyButton(title: String, action: Selector) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)

    // 長押しジェスチャー追加
    let longPress = UILongPressGestureRecognizer(
        target: self,
        action: #selector(handleLongPress(_:))
    )
    longPress.minimumPressDuration = 0.5
    button.addGestureRecognizer(longPress)

    return button
}

@objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
    guard gesture.state == .began,
          let button = gesture.view as? UIButton,
          let keyLabel = button.titleLabel?.text else { return }

    // ポップアップメニュー表示
    showVariantMenu(for: keyLabel, at: button)
}
```

#### 2. ヒントラベル表示
```swift
private func createKeyButton(title: String, hint: String?, action: Selector) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 22)

    // ヒントラベル追加
    if let hint = hint {
        let hintLabel = UILabel()
        hintLabel.text = hint
        hintLabel.font = .systemFont(ofSize: 10)
        hintLabel.textColor = .gray
        button.addSubview(hintLabel)

        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hintLabel.topAnchor.constraint(equalTo: button.topAnchor, constant: 2),
            hintLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -4)
        ])
    }

    return button
}
```

#### 3. JSONスキーマ拡張
```json
// schema_rus_v1.json
{
  "А": {
    "kana_key": "a",
    "popupCharacters": ["Ӑ", "Ӓ", "Ӕ"],
    "hintLabel": "@"
  },
  "Е": {
    "kana_key": "e",
    "popupCharacters": ["Ё", "Є", "Ҽ", "Ҿ", "Ӗ", "Ә", "Ӛ"],
    "hintLabel": "5"
  }
}
```

### 優先度: 中

#### 4. デバイス適応レイアウト
```swift
private func buildKeyboardLayout() {
    let device = UIDevice.current
    let isIPad = device.userInterfaceIdiom == .pad

    let keysPerRow = isIPad ?
        [14, 13, 11] : // iPad: より多くのキー
        distributeKeys(keys.count) // iPhone: 動的分配
}
```

#### 5. キーサイズ動的調整
```swift
private func calculateKeyWidth(
    totalKeys: Int,
    rowWidth: CGFloat,
    minKeyWidth: CGFloat = 30.0
) -> CGFloat {
    let spacing: CGFloat = 5.0
    let totalSpacing = spacing * CGFloat(totalKeys - 1)
    let availableWidth = rowWidth - totalSpacing
    return max(minKeyWidth, availableWidth / CGFloat(totalKeys))
}
```

### 優先度: 低

#### 6. SwiftUI移行
- 段階的にUIKitからSwiftUIへ移行
- KeyboardKitのような宣言的UI構築

#### 7. テーマシステム
- ライト/ダークモード対応
- カスタムカラースキーム

---

## 参考資料

### KeyboardKit
- **リポジトリ**: https://github.com/KeyboardKit/KeyboardKit
- **ドキュメント**: https://keyboardkit.github.io/KeyboardKit/documentation/keyboardkit/

### giellakbd-ios
- **リポジトリ**: https://github.com/divvun/giellakbd-ios
- **README**: https://github.com/divvun/giellakbd-ios/blob/main/README.md

### AnySoftKeyboard
- **リポジトリ**: https://github.com/AnySoftKeyboard/AnySoftKeyboard
- **Wiki**: https://github.com/AnySoftKeyboard/AnySoftKeyboard/wiki

### Apple公式
- **Custom Keyboard Guide**: https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html
- **UIInputViewController**: https://developer.apple.com/documentation/uikit/uiinputviewcontroller

---

## まとめ

3つの主要OSSキーボードプロジェクトから得られた知見：

1. **動的レイアウト生成**: デバイスとコンテキストに応じた適応的UI
2. **長押しバリエーション**: 1キーで複数文字入力（省スペース）
3. **ヒントラベル**: キーに追加情報を小さく表示
4. **XMLベース定義**: 宣言的なキーボードレイアウト記述
5. **デバイス適応**: iPhone/iPad、ノッチ有無での最適化
6. **スペーサーキー**: レイアウトバランス調整用

これらをPismoプロジェクトに段階的に導入することで、よりプロフェッショナルなキーボード体験を実現できます。
