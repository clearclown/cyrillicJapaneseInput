# Pismo - Cyrillic Japanese Keyboard

<p align="center">
  <img src="docs/appstore/pics/0_pismo_icon.png" alt="Pismo Icon" width="200"/>
</p>

<p align="center">
  <strong>キリル文字で日本語を入力するiOS/iPadOSキーボード</strong>
</p>

<p align="center">
  :jp: <a href="#readme-日本語">日本語</a> |
  :ru: <a href="docs/readmeLangs/README_RU.md">Русский</a> |
  :ukraine: <a href="docs/readmeLangs/README_UK.md">Українська</a> |
  :belarus~: <a href="docs/readmeLangs/README_BE.md">Беларуская</a> |
  :bulgaria: <a href="docs/readmeLangs/README_BG.md">Български</a> |
  :serbia: <a href="docs/readmeLangs/README_SR.md">Српски</a>
</p>

<p align="center">
  <em>Coming Soon:</em> English | 简体中文 | 繁體中文 | العربية | فارسی
</p>

---

## README 日本語

### Pismoとは

**Pismo（ピスモ）** は、キリル文字を使って日本語（ひらがな・カタカナ）を入力できるiOS/iPadOS向けキーボードアプリです。

「Pismo」はスラヴ諸語で「文字」「書くこと」を意味する言葉であり、キリル文字と日本語という二つの文字体系を繋ぐこのアプリにふさわしい名前です。

<p align="center">
  <img src="docs/appstore/pics/resized/1_Main_Keyboard_View.png" alt="Keyboard View" width="250"/>
  <img src="docs/appstore/pics/resized/3_Live_Conversion_Demo.png" alt="Live Conversion" width="250"/>
</p>

### キリル文字について

キリル文字は、9世紀にブルガリア帝国で発展した文字体系です。ギリシャ文字を基に、スラヴ諸語の音韻を表すために創られました。

現在、キリル文字は以下のような多くの言語で使用されています：

| 言語 | 地域 | 特徴 |
|------|------|------|
| ロシア語 | ロシア | 33文字 |
| ウクライナ語 | ウクライナ | 33文字（ІіЇїЄєҐґを含む） |
| ベラルーシ語 | ベラルーシ | 32文字（ЎўІіを含む） |
| ブルガリア語 | ブルガリア | 30文字（キリル文字発祥の地） |
| セルビア語 | セルビア | 30文字（ラテン文字も併用） |
| その他 | モンゴル、カザフスタン等 | 各言語独自の拡張文字 |

**注意：** このアプリは特定の政治的思想や立場を持つものではありません。キリル文字という文字体系そのものへの純粋な興味と、言語学習の支援を目的としています。

### こんな方におすすめ

- **キリル文字に興味がある日本人の方**
  - スラヴ諸語の学習者
  - 東方正教会の聖典・典礼文の学習者
  - ロシア文学・ウクライナ文学の愛好家
  - 言語学・文字研究に興味のある方

- **日本語を学ぶキリル文字使用者**
  - キリル文字キーボードに慣れた方が日本語を入力したい場合

### 主な機能

- **5言語対応キーボード**
  - ロシア語 (Русский)
  - ウクライナ語 (Українська)
  - ベラルーシ語 (Беларуская)
  - ブルガリア語 (Български)
  - セルビア語 (Српски)

- **リアルタイム変換**
  - キリル文字入力 → 日本語（ひらがな/カタカナ）へ即座に変換
  - 例：`привет` → `ぷりゔぇっと`

- **高精度変換エンジン**
  - azooKeyの変換エンジンを採用
  - ニューラルかな漢字変換システム「Zenzai」搭載

- **プライバシー重視**
  - 入力データをサーバーに送信しません
  - オフラインで完全に動作

<p align="center">
  <img src="docs/appstore/pics/resized/2_ MultiLanguage_Support.png" alt="Multi-language Support" width="250"/>
  <img src="docs/appstore/pics/resized/4_Features_Overview.png" alt="Features" width="250"/>
</p>

### インストール

App Storeで「Pismo」を検索するか、以下のリンクからダウンロードしてください。

<!-- App Store公開後にリンクを追加 -->
*App Store リンク: 公開準備中*

---

## 技術アーキテクチャ

### システム概要

Pismoは複数のオープンソースプロジェクトの技術を組み合わせて構築されています。

```
┌─────────────────────────────────────────────────────────────────┐
│                        Pismo Keyboard                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────────────────────┐    │
│  │ Cyrillic Input  │───▶│   CyrillicKanaConverter        │    │
│  │ (キリル文字入力)  │    │   (キリル文字→かな変換エンジン)    │    │
│  └─────────────────┘    └───────────────┬─────────────────┘    │
│                                         │                      │
│                                         ▼                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              azooKey Conversion Engine                   │   │
│  │  ┌───────────────────┐  ┌───────────────────────────┐   │   │
│  │  │ Zenzai (Neural)   │  │ Dictionary (Mozc-based)   │   │   │
│  │  │ ニューラル変換      │  │ 辞書データ                 │   │   │
│  │  └───────────────────┘  └───────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                         │                      │
│                                         ▼                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Japanese Output                       │   │
│  │                   (日本語出力: 漢字変換)                    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 入力処理フロー

1. **キリル文字入力**: ユーザーがキリル文字キーボードで文字を入力
2. **CyrillicKanaConverter**: キリル文字をひらがなに変換
   - ポリグラフ対応（例: `ся` → `しゃ`、`цу` → `つ`）
   - 言語別マッピング（ロシア語、ウクライナ語、ブルガリア語など）
   - 外来語表記対応（例: `ヴ`、`ティ`、`ファ`など）
3. **azooKey変換エンジン**: ひらがなを漢字かな混じり文に変換
   - Zenzai: ニューラルネットワークベースの予測変換
   - 辞書検索: Google Mozc由来の辞書データを使用
4. **出力**: 変換結果を入力フィールドに挿入

### 主要コンポーネント

#### iOS (Keyboard Extension)

| コンポーネント | 説明 | 基盤技術 |
|--------------|------|---------|
| `CyrillicKanaConverter` | キリル文字→ひらがな変換 | 独自実装 |
| `InputManager` | 入力状態管理・候補表示 | azooKey |
| `KanaKanjiConverter` | ひらがな→漢字変換 | azooKey + Zenzai |
| `Dictionary` | 単語辞書・学習辞書 | Google Mozc派生 |

#### キリル文字→かな変換の仕組み

`CyrillicKanaConverter`は以下のマッピングテーブルを使用します：

```swift
// 基本的な母音
"а" → "あ", "и" → "い", "у" → "う", "э" → "え", "о" → "お"

// 子音 + 母音の組み合わせ
"ка" → "か", "ки" → "き", "ку" → "く", "кэ" → "け", "ко" → "こ"
"са" → "さ", "си" → "し", "су" → "す", "сэ" → "せ", "со" → "そ"

// 拗音（小さい「や・ゆ・よ」）
"кя" → "きゃ", "ся" → "しゃ", "ня" → "にゃ"

// 促音（っ）
"っ" は子音の重複で表現: "иттэ" → "いって"

// 撥音（ん）
"н" + 母音以外 → "ん": "ниндзя" → "にんじゃ"
```

#### 言語別の特殊マッピング

各スラヴ言語には固有の文字があり、それぞれ対応しています：

| 言語 | 特殊文字 | 変換例 |
|------|---------|--------|
| ウクライナ語 | ї, і, є, ґ | `ї` → `йі` (yi) |
| ベラルーシ語 | ў, і | `ў` → `う` |
| ブルガリア語 | ъ, ь | `ъ` → 硬音記号 |
| セルビア語 | ђ, љ, њ, ћ, џ | `ђ` → `ぢ`, `љ` → `りゅ` |

---

## 使用技術・謝辞

Pismoは以下のオープンソースプロジェクトの技術を使用しています。これらのプロジェクトの開発者に深く感謝いたします。

### azooKey

<a href="https://github.com/azooKey/azooKey">
  <img src="https://github.com/azooKey/azooKey/raw/develop/MainApp/Assets.xcassets/AppIcon.appiconset/icon.png" alt="azooKey" width="64"/>
</a>

**[azooKey](https://github.com/azooKey/azooKey)** - iOS向け日本語キーボードアプリ

Pismoのベースとなったキーボードフレームワークです。以下の機能を提供しています：

- **Keyboard Extension フレームワーク**: iOS向けカスタムキーボードの基盤
- **Zenzai変換エンジン**: ニューラルネットワークベースのかな漢字変換
- **ライブ変換**: リアルタイムでの漢字変換表示
- **カスタマイズ可能なUI**: テーマ・レイアウトのカスタマイズ機能

```
azooKey Copyright (c) 2020-2025 Keita Miwa (ensan)
Licensed under MIT License
https://github.com/azooKey/azooKey
```

### Google Mozc

<a href="https://github.com/google/mozc">
  <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Google_Mozc_Logo.svg" alt="Mozc" width="64"/>
</a>

**[Google Mozc](https://github.com/google/mozc)** - オープンソース日本語入力システム

azooKeyの辞書データはMozcの辞書データをベースにしています：

- **単語辞書**: 一般語・固有名詞・慣用句
- **品詞情報**: 形態素解析用の品詞タグ
- **連接コスト**: 単語間の接続確率データ

```
Mozc Copyright 2010-2024, Google Inc.
Licensed under BSD 3-Clause License
https://github.com/google/mozc
```

### その他の技術

| 技術 | 用途 | ライセンス |
|------|------|-----------|
| Swift/SwiftUI | iOSアプリ開発 | Apache 2.0 |
| Swift Package Manager | 依存関係管理 | Apache 2.0 |

---

## 開発について

### ビルド方法

```bash
# リポジトリをクローン（サブモジュール含む）
git clone https://github.com/clearclown/cyrillicJapaneseInput --recursive

# iOSプロジェクトを開く
open iOS/Pismo.xcodeproj
```

### プロジェクト構造

```
cyrillicJapaneseInput/
├── iOS/                          # iOSアプリケーション
│   ├── Pismo.xcodeproj/          # Xcodeプロジェクト
│   ├── MainApp/                  # メインアプリ (設定画面等)
│   ├── Keyboard/                 # Keyboard Extension
│   │   └── Display/
│   │       └── InputManager.swift   # 入力管理
│   └── AzooKeyCore/              # azooKeyコアライブラリ
│       └── Sources/
│           └── AzooKeyUtils/
│               └── CyrillicKanaConverter.swift  # キリル→かな変換
├── Android/                      # Androidアプリ (開発予定)
├── docs/                         # ドキュメント
│   ├── mappings/                 # キリル文字マッピングCSV
│   ├── readmeLangs/              # 多言語README
│   └── appstore/                 # App Store素材
└── README.md
```

### コントリビューション

Pull Requestを歓迎します。特に以下の貢献を求めています：

- 新しい言語のキーボードレイアウト
- 変換精度の改善
- ドキュメントの翻訳
- バグ報告・修正

詳しくは [CONTRIBUTING.md](docs/development/CONTRIBUTING.md) をご覧ください。

---

## ライセンス

MIT License

Copyright (c) 2024-2025 clearclown / Pismo Project

このプロジェクトは以下のオープンソースプロジェクトをベースにしています：

- **azooKey** - Copyright (c) 2020-2025 Keita Miwa (ensan) - MIT License
- **Google Mozc** - Copyright 2010-2024, Google Inc. - BSD 3-Clause License

詳細は [LICENSE](LICENSE) ファイルをご覧ください。

---

<p align="center">
  <strong>Pismo</strong> — キリル文字と日本語を繋ぐ架け橋
</p>

<p align="center">
  Built with azooKey | Powered by Mozc Dictionary
</p>
