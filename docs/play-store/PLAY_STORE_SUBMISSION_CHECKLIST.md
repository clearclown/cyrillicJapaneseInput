# Google Play Store 公開チェックリスト

## ✅ 完了済みの準備

### 1. ビルド関連
- [x] リリース用署名キー（keystore）作成完了
  - ファイル: `mobile/android/pismo-release-key.jks`
  - **重要**: このファイルは絶対に失わないでください！バックアップを推奨
- [x] AAB ファイルビルド完了
  - ファイル: `mobile/android/app/build/outputs/bundle/release/app-release.aab`
  - サイズ: 1.9MB
  - バージョン: 1.0.0 (versionCode: 1)

### 2. ストアリスティング素材
- [x] アプリアイコン (512x512 PNG)
  - ファイル: `docs/play-store/app-icon-512.png`
- [x] スクリーンショット (2枚)
  - ファイル: `docs/play-store/screenshot-1.png`
  - ファイル: `docs/play-store/screenshot-2.png`
  - **注**: 実際のアプリのスクリーンショットに置き換えることを推奨
- [x] アプリ説明文
  - ファイル: `docs/play-store/store-listing.md`

### 3. 法的要件
- [x] プライバシーポリシー
  - URL: `https://clearclown.github.io/cyrillicJapaneseInput/`
  - ファイル: `docs/play-store/privacy-policy.html`

---

## 📋 Google Play Console での手順

### ステップ1: デベロッパーアカウントの準備

1. https://play.google.com/console にアクセス
2. Google アカウントでログイン
3. **初回のみ**: デベロッパー登録費用 $25 を支払う

### ステップ2: 新しいアプリを作成

1. 「アプリを作成」ボタンをクリック
2. 以下を入力：
   - **アプリ名**: `Pismo - キリル文字で日本語入力`
   - **デフォルト言語**: 日本語
   - **アプリまたはゲーム**: アプリ
   - **無料または有料**: 無料
3. 宣言事項にチェック → 「アプリを作成」

### ステップ3: アプリのコンテンツを設定

左側メニューから「アプリのコンテンツ」を選択し、以下を順番に設定：

#### a) プライバシーポリシー
```
https://clearclown.github.io/cyrillicJapaneseInput/
```

#### b) アプリのアクセス権限
- 「すべての機能を無制限に利用できます」を選択
- 特別なアクセス要件なし

#### c) 広告
- 「いいえ、このアプリには広告が含まれていません」

#### d) ターゲット層と内容
- **ターゲット年齢層**: すべての年齢
- **ストア掲載情報の詳細**: 適切なカテゴリを選択

#### e) COVID-19 接触確認アプリまたはステータスアプリ
- 「いいえ」

#### f) データの安全性
- 「このアプリはユーザーデータを収集または共有しません」を選択

### ステップ4: ストアの設定

左側メニューから「ストアの設定」→「メインのストア掲載情報」：

#### アプリの詳細
以下の内容を `docs/play-store/store-listing.md` からコピー＆ペースト：

**簡単な説明** (80文字):
```
キリル文字配列で日本語ひらがなを入力できる革新的なIME。ロシア語、セルビア語、ウクライナ語キーボードに対応。
```

**詳しい説明** (4000文字):
```
[store-listing.md の「詳しい説明」セクションをコピー]
```

#### グラフィック
1. **アプリアイコン** (512x512):
   - `docs/play-store/app-icon-512.png` をアップロード

2. **スクリーンショット** (携帯電話):
   - `docs/play-store/screenshot-1.png` をアップロード
   - `docs/play-store/screenshot-2.png` をアップロード
   - **推奨**: 実際のアプリのスクリーンショットに置き換える

#### 分類
- **アプリカテゴリ**: ツール
- **タグ**: 生産性、言語、日本語

#### 連絡先の詳細
- **メールアドレス**: [あなたのサポートメールアドレス]
- **ウェブサイト** (オプション): GitHub リポジトリ URL など

### ステップ5: リリースの作成

1. 左側メニューから「リリース」→「製品版」を選択
2. 「新しいリリースを作成」をクリック
3. **App Bundle をアップロード**:
   - `mobile/android/app/build/outputs/bundle/release/app-release.aab` をドラッグ＆ドロップ
4. **リリース名**:
   ```
   1.0.0 - 初回リリース
   ```
5. **リリースノート**:
   ```
   【日本語】
   Pismo の初回リリースです！

   主な機能：
   • キリル文字配列で日本語ひらがなを入力
   • ロシア語、セルビア語、ウクライナ語配列に対応
   • 完全オフライン動作
   • プライバシー重視（データ収集なし）

   【English】
   First release of Pismo!

   Key features:
   • Type Japanese hiragana using Cyrillic keyboard layouts
   • Supports Russian, Serbian, Ukrainian layouts
   • Completely offline operation
   • Privacy-focused (no data collection)
   ```

### ステップ6: 審査に提出

1. すべての必須項目が緑色のチェックマークになっていることを確認
2. 「審査に送信」ボタンをクリック
3. 審査には通常 **数日〜1週間** かかります

---

## 📊 審査後の対応

### 承認された場合
- おめでとうございます！アプリが Play Store に公開されます
- 通常、承認から数時間以内に検索可能になります

### 却下された場合
- 却下理由をよく読む
- 必要な修正を行う
- 再提出

---

## 🔄 アップデート手順

新しいバージョンをリリースする場合：

1. `mobile/android/app/build.gradle.kts` のバージョンを更新：
   ```kotlin
   versionCode = 2  // インクリメント
   versionName = "1.1.0"  // 新しいバージョン
   ```

2. 新しい AAB をビルド：
   ```bash
   cd mobile/android
   ./gradlew bundleRelease
   ```

3. Play Console で新しいリリースを作成し、AAB をアップロード

---

## 🎯 重要な注意事項

### セキュリティ
- **keystore ファイルは絶対に失わない！**
  - 複数の安全な場所にバックアップ
  - パスワードも安全に保管
  - 失うと、アプリを二度と更新できなくなります

### プライバシー
- プライバシーポリシーの URL を変更しないこと
- 変更する場合は Play Console でも更新すること

### バージョン管理
- `versionCode` は必ず単調増加
- `versionName` はユーザーに表示される

---

## 📞 サポートリソース

- Google Play Console ヘルプ: https://support.google.com/googleplay/android-developer
- Android デベロッパーガイド: https://developer.android.com/distribute/best-practices/launch

---

## ✨ 完成！

すべての準備が整いました。Google Play Console にログインして、上記の手順に従ってアプリを公開しましょう！

健闘を祈ります！ 🚀
