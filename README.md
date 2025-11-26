# Pismo - Cyrillic Japanese Keyboard

<p align="center">
  <img src="docs/appstore/pics/0_pismo_icon.png" alt="Pismo Icon" width="200"/>
</p>

<p align="center">
  <strong>キリル文字で日本語を入力するiOS/iPadOSキーボード</strong>
</p>

<p align="center">
  🇯🇵 <a href="#readme-日本語">日本語</a> |
  🇷🇺 <a href="docs/readmeLangs/README_RU.md">Русский</a> |
  🇺🇦 <a href="docs/readmeLangs/README_UK.md">Українська</a> |
  🇧🇾 <a href="docs/readmeLangs/README_BE.md">Беларуская</a> |
  🇧🇬 <a href="docs/readmeLangs/README_BG.md">Български</a> |
  🇷🇸 <a href="docs/readmeLangs/README_SR.md">Српски</a>
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

### 開発について

PismoはオープンソースプロジェクトですPismoは[azooKey](https://github.com/azooKey/azooKey)をベースに開発されています。

#### ビルド方法

```bash
# リポジトリをクローン（サブモジュール含む）
git clone https://github.com/clearclown/cyrillicJapaneseInput --recursive

# iOSプロジェクトを開く
open iOS/Pismo.xcodeproj
```

#### プロジェクト構造

```
cyrillicJapaneseInput/
├── iOS/                    # iOSアプリケーション
│   ├── Pismo.xcodeproj/
│   ├── MainApp/
│   ├── Keyboard/
│   └── AzooKeyCore/
├── Android/                # Androidアプリケーション（開発予定）
├── docs/                   # ドキュメント
└── README.md
```

### コントリビューション

Pull Requestを歓迎します。特に以下の貢献を求めています：

- 新しい言語のキーボードレイアウト
- 変換精度の改善
- ドキュメントの翻訳
- バグ報告・修正

詳しくは [CONTRIBUTING.md](docs/development/CONTRIBUTING.md) をご覧ください。

### ライセンス

MIT License

Copyright (c) 2024-2025 clearclown

このプロジェクトは [azooKey](https://github.com/azooKey/azooKey) をベースにしています。
azooKey Copyright (c) 2020-2025 Keita Miwa (ensan)

### 謝辞

- [azooKey](https://github.com/azooKey/azooKey) - ベースとなったキーボードアプリ
- キリル文字を発明し、文化遺産として現代に伝えてくれた先人たち

---

<p align="center">
  <strong>Pismo</strong> — キリル文字と日本語を繋ぐ架け橋
</p>
