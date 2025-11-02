# Google Play Store デプロイ手順書

Cyrillic Japanese IME Android アプリを Google Play Store へデプロイするための手順書です。

## 📋 前提条件

- Android Studio Hedgehog (2023.1.1) 以降がインストール済み
- Google Play Console アカウント（初回登録料 $25）
- 有効な Google アカウント
- JDK 17 以降がインストール済み

## 🔧 Phase 1: Android Studio プロジェクトのセットアップ

### 1.1 Rust Core ライブラリのビルド

```bash
cd rust_core

# Android ターゲットの追加（初回のみ）
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add x86_64-linux-android
rustup target add i686-linux-android

# cargo-ndk のインストール（初回のみ）
cargo install cargo-ndk

# Android 用ライブラリのビルド（NDK 25 使用）
cargo ndk --target aarch64-linux-android --android-platform 21 -- build --release
cargo ndk --target armv7-linux-androideabi --android-platform 21 -- build --release
cargo ndk --target x86_64-linux-android --android-platform 21 -- build --release
cargo ndk --target i686-linux-android --android-platform 21 -- build --release

# ライブラリを Android プロジェクトにコピー
mkdir -p ../mobile/android/app/src/main/jniLibs/arm64-v8a
mkdir -p ../mobile/android/app/src/main/jniLibs/armeabi-v7a
mkdir -p ../mobile/android/app/src/main/jniLibs/x86_64
mkdir -p ../mobile/android/app/src/main/jniLibs/x86

cp target/aarch64-linux-android/release/libcyrillic_ime_core.so \
   ../mobile/android/app/src/main/jniLibs/arm64-v8a/

cp target/armv7-linux-androideabi/release/libcyrillic_ime_core.so \
   ../mobile/android/app/src/main/jniLibs/armeabi-v7a/

cp target/x86_64-linux-android/release/libcyrillic_ime_core.so \
   ../mobile/android/app/src/main/jniLibs/x86_64/

cp target/i686-linux-android/release/libcyrillic_ime_core.so \
   ../mobile/android/app/src/main/jniLibs/x86/
```

### 1.2 Android Studio でプロジェクトを開く

1. Android Studio を起動
2. **Open an Existing Project** を選択
3. `mobile/android` ディレクトリを選択
4. Gradle sync が自動的に実行されます（初回は数分かかります）

### 1.3 プロジェクト構造の確認

```
mobile/android/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/cyrillicime/
│   │   │   │   ├── IMEEngine.kt         # Rust Core との JNI ブリッジ
│   │   │   │   ├── CyrillicIMEService.kt # IME サービス本体
│   │   │   │   ├── ui/                   # Jetpack Compose UI
│   │   │   │   └── models/               # データモデル
│   │   │   ├── jniLibs/                  # ネイティブライブラリ
│   │   │   ├── res/                      # リソースファイル
│   │   │   └── AndroidManifest.xml       # マニフェスト
│   │   └── androidTest/                  # Instrumented テスト
│   │       └── test/                     # Unit テスト
│   └── build.gradle.kts                  # アプリレベルの Gradle 設定
├── build.gradle.kts                      # プロジェクトレベルの Gradle 設定
└── gradle.properties                     # Gradle プロパティ
```

### 1.4 build.gradle.kts の確認

`mobile/android/app/build.gradle.kts` を開き、以下を確認:

```kotlin
android {
    namespace = "com.cyrillicime"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.cyrillicime"  // 変更する場合はここを編集
        minSdk = 24
        targetSdk = 34
        versionCode = 1      // リリースごとにインクリメント
        versionName = "1.0.0" // ユーザーに表示されるバージョン
    }
}
```

## 🔑 Phase 2: 署名鍵の作成

### 2.1 リリース用キーストアの生成

```bash
cd mobile/android/app

# キーストアを生成（パスワードは厳重に保管）
keytool -genkeypair -v \
  -storetype PKCS12 \
  -keystore cyrillicime-release-key.jks \
  -alias cyrillicime \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

**入力が必要な情報**:
- **Keystore password**: 強固なパスワードを設定（必ず記録）
- **Key password**: キーストアと同じか別のパスワード（必ず記録）
- **First and Last Name**: 開発者名または会社名
- **Organizational Unit**: 部署名（任意）
- **Organization**: 組織名（任意）
- **City or Locality**: 都市名
- **State or Province**: 都道府県
- **Country Code**: JP

⚠️ **重要**: このキーストアファイルとパスワードは厳重に保管してください。紛失すると、今後アプリの更新ができなくなります。

### 2.2 キーストア情報の設定

`mobile/android/keystore.properties` ファイルを作成:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=cyrillicime
storeFile=./app/cyrillicime-release-key.jks
```

⚠️ **重要**: このファイルは `.gitignore` に追加し、Git にコミットしないでください。

### 2.3 build.gradle.kts で署名設定を追加

`mobile/android/app/build.gradle.kts` に以下を追加:

```kotlin
// ファイルの先頭に追加
import java.util.Properties
import java.io.FileInputStream

android {
    // 既存の設定...

    // キーストアプロパティの読み込み
    val keystorePropertiesFile = rootProject.file("keystore.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

## 🎮 Phase 3: Google Play Console の設定

### 3.1 Google Play Console アカウントの作成

1. [Google Play Console](https://play.google.com/console) にアクセス
2. Google アカウントでログイン
3. 初回登録の場合:
   - **Create Developer Account** をクリック
   - 開発者情報を入力（個人 or 組織）
   - $25 の登録料を支払い
   - デベロッパー規約に同意

### 3.2 新しいアプリの作成

1. **All apps** → **Create app** をクリック
2. アプリ情報を入力:
   - **App name**: `Cyrillic Japanese IME`
   - **Default language**: 日本語
   - **App or game**: アプリ
   - **Free or paid**: 無料 または 有料
3. 規約とポリシーに同意
4. **Create app** をクリック

### 3.3 アプリのダッシュボード設定

作成後、以下のセクションを順番に設定していきます:

#### 3.3.1 App content (アプリのコンテンツ)

1. **App access** (アプリへのアクセス):
   - すべての機能にアクセス可能: **All or some functionality is restricted**
   - IME は特別な権限が必要なため、説明を追加

2. **Ads** (広告):
   - 広告を表示するか: **No** (または使用する場合は Yes)

3. **Content ratings** (コンテンツのレーティング):
   - **Start questionnaire** をクリック
   - メールアドレスを入力
   - カテゴリ: **Utility, Productivity, Communication, or Other**
   - 質問に回答（すべて No の場合、Everyone レーティング）
   - **Save** → **Apply rating**

4. **Target audience and content** (ターゲット層とコンテンツ):
   - 年齢層: **13歳以上** を選択
   - ストアリスト: 適切なものを選択

5. **Privacy policy** (プライバシーポリシー):
   - プライバシーポリシーの URL を入力（必須）
   - 例: `https://yourwebsite.com/privacy-policy`

6. **Data safety** (データの安全性):
   - データ収集について回答:
     - 個人データを収集しない場合: **No data collected**
     - データを収集する場合: 詳細を入力

#### 3.3.2 Store settings (ストアの設定)

1. **App category**: **Tools** または **Productivity**
2. **Store listing contact details**:
   - メールアドレス（サポート用）
   - 電話番号（任意）
   - ウェブサイト（任意）

## 📸 Phase 4: ストアリスティングの作成

### 4.1 アプリの詳細情報

1. **Main store listing** → **Store listing** を選択
2. 以下を入力:

#### App name
```
Cyrillic Japanese IME
```

#### Short description (80文字以内)
```
キリル文字キーボードで日本語入力。ロシア語・セルビア語・ウクライナ語対応。
```

#### Full description (4000文字以内)
```
Cyrillic Japanese IME は、キリル文字キーボードを使用して日本語を入力できる革新的な入力メソッドです。

【主な機能】
✓ ロシア語キーボードで日本語入力
✓ セルビア語キーボードで日本語入力（特殊文字 Њ, Љ, Ћ 対応）
✓ ウクライナ語キーボードで日本語入力（Ї, Є 対応）
✓ リアルタイム変換エンジン
✓ カスタマイズ可能なプロファイル
✓ 完全オフラインで動作

【使い方】
1. アプリをインストール
2. 設定 → システム → 言語と入力 → 仮想キーボード
3. "Cyrillic Japanese IME" を有効化
4. 任意のテキスト入力欄でキーボードを切り替え

【対応言語】
・ロシア語 (Русский) → 日本語
・セルビア語 (Српски) → 日本語
・ウクライナ語 (Українська) → 日本語

【技術仕様】
・高速な Rust エンジンによる変換処理
・Jetpack Compose による現代的な UI
・Android 7.0 (API 24) 以上対応

【プライバシー】
・ネットワーク接続不要
・個人データの収集なし
・すべての処理はデバイス上で完結

開発者へのフィードバックや機能リクエストは、サポートメールまでお気軽にお寄せください。
```

### 4.2 グラフィックアセットの準備

#### アプリアイコン
- **サイズ**: 512 x 512 px
- **形式**: PNG（32-bit、透過なし）
- **要件**: 正方形、角丸なし

#### フィーチャーグラフィック
- **サイズ**: 1024 x 500 px
- **形式**: PNG または JPEG
- **用途**: Play Store のトップページに表示

#### スクリーンショット
必須枚数: **最低2枚、最大8枚**

**Phone スクリーンショット**:
- **サイズ**: 1080 x 2340 px 以上（アスペクト比 16:9 〜 2:1）
- **推奨サイズ**: 1080 x 2340 px (Pixel 7 など)

**7-inch Tablet スクリーンショット** (任意):
- **サイズ**: 1200 x 1920 px 以上

**10-inch Tablet スクリーンショット** (任意):
- **サイズ**: 1920 x 1200 px 以上

#### 推奨するスクリーンショット内容
1. キーボード入力画面（ロシア語キーボード）
2. 変換候補表示画面
3. プロファイル選択画面
4. 設定画面
5. キーボード切り替え画面

### 4.3 アセットのアップロード

1. Play Console の **Main store listing** に戻る
2. **Graphics** セクションで各アセットをアップロード
3. **Save** をクリック

## 🏗️ Phase 5: リリースビルドの作成

### 5.1 バージョン情報の更新

`mobile/android/app/build.gradle.kts` を編集:

```kotlin
defaultConfig {
    applicationId = "com.cyrillicime"
    minSdk = 24
    targetSdk = 34
    versionCode = 1      // ビルド番号（整数、毎回インクリメント）
    versionName = "1.0.0" // バージョン名（ユーザーに表示）
}
```

### 5.2 ProGuard ルールの確認

`mobile/android/app/proguard-rules.pro` を確認:

```proguard
# Rust JNI メソッドを保持
-keep class com.cyrillicime.IMEEngine {
    native <methods>;
}

# Kotlin reflection 対策
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Jetpack Compose
-keep class androidx.compose.** { *; }
```

### 5.3 Android App Bundle (AAB) のビルド

#### 方法1: Android Studio から

1. **Build** → **Generate Signed Bundle / APK** を選択
2. **Android App Bundle** を選択 → **Next**
3. **Key store path** でキーストアファイルを選択
4. パスワードとエイリアスを入力 → **Next**
5. **Build variant**: `release` を選択
6. **Finish** をクリック

AAB ファイルは `mobile/android/app/release/app-release.aab` に生成されます。

#### 方法2: コマンドラインから

```bash
cd mobile/android

# クリーンビルド
./gradlew clean

# Release AAB をビルド
./gradlew bundleRelease

# 生成された AAB の場所
ls -lh app/build/outputs/bundle/release/app-release.aab
```

### 5.4 AAB ファイルの検証

```bash
# bundletool のインストール（初回のみ）
# https://github.com/google/bundletool/releases から最新版をダウンロード

# AAB から APKs を生成してサイズを確認
java -jar bundletool.jar build-apks \
  --bundle=app/build/outputs/bundle/release/app-release.aab \
  --output=app-release.apks \
  --mode=universal

# デバイスにインストールして動作確認
java -jar bundletool.jar install-apks \
  --apks=app-release.apks
```

## 🚀 Phase 6: 内部テストトラック

### 6.1 内部テストトラックの作成

1. Play Console で **Testing** → **Internal testing** を選択
2. **Create new release** をクリック
3. **Upload** をクリックして AAB ファイルをアップロード
4. アップロードが完了するまで待機（数分）

### 6.2 リリースノートの追加

**Release name**: `1.0.0 (1)`

**Release notes** (日本語):
```
初回リリース

【主な機能】
・ロシア語キーボードで日本語入力
・セルビア語キーボードで日本語入力
・ウクライナ語キーボードで日本語入力
・リアルタイム変換
・オフライン動作

【動作環境】
・Android 7.0 (API 24) 以上
```

### 6.3 テスターの追加

1. **Testers** タブを選択
2. **Create email list** をクリック
3. リスト名を入力（例: "Internal Testers"）
4. テスターのメールアドレスを追加（最大100名）
5. **Save** → **Save changes**

### 6.4 内部テストの実施

1. **Review release** → **Start rollout to Internal testing** をクリック
2. テスターに招待メールが送信されます
3. テスターは Play Store からアプリをインストール

**確認項目**:
- ✅ キーボードが正しく有効化できるか
- ✅ ロシア語、セルビア語、ウクライナ語の入力が正常か
- ✅ 変換精度が十分か
- ✅ クラッシュが発生しないか
- ✅ UI が各デバイスで正しく表示されるか
- ✅ 複数の Android バージョンで動作するか

## 📱 Phase 7: クローズドテストトラック（オプション）

### 7.1 クローズドテストの設定

1. **Testing** → **Closed testing** を選択
2. **Create new release** をクリック
3. 内部テストと同様に AAB をアップロード
4. より広範囲のテスター（最大数千人）を追加可能

### 7.2 フィードバックの収集

1. Play Console で **Feedback** を確認
2. クラッシュレポートを確認: **Quality** → **Android vitals**
3. 必要に応じてバグ修正版をリリース

## 🌟 Phase 8: 本番環境への申請

### 8.1 最終チェックリスト

- ✅ すべてのストアリスティング情報を入力済み
- ✅ グラフィックアセット（アイコン、スクリーンショット）をアップロード済み
- ✅ プライバシーポリシー URL を設定済み
- ✅ コンテンツレーティングを取得済み
- ✅ データの安全性セクションを完了
- ✅ 内部/クローズドテストが完了
- ✅ すべての主要機能が動作確認済み
- ✅ クラッシュ率が 1% 未満
- ✅ Google Play ポリシーに準拠していることを確認

### 8.2 本番リリースの作成

1. **Production** → **Create new release** を選択
2. **Upload** で AAB ファイルをアップロード（内部テストと同じファイル可）
3. リリースノートを入力
4. **Review release** をクリック

### 8.3 段階的なロールアウト（推奨）

1. **Release to production** で **Percentage rollout** を選択
2. 初回は **20%** を選択（ユーザーの20%に配信）
3. **Start rollout to Production** をクリック

段階的ロールアウトの利点:
- 重大なバグが見つかった場合、影響を最小限に抑えられる
- クラッシュ率やレビューを監視しながら段階的に拡大

### 8.4 ロールアウトの拡大

問題がない場合、以下の順序でロールアウトを拡大:
1. 20% → 2日間監視
2. 50% → 2日間監視
3. 100% → 全ユーザーに配信

問題が見つかった場合:
1. **Halt rollout** でロールアウトを停止
2. バグを修正して新しいバージョンをアップロード
3. 再度段階的ロールアウトを開始

### 8.5 審査ステータスの確認

Google Play の審査ステータス:
1. **Pending publication**: 審査待ち
2. **In review**: 審査中（通常 数時間〜1日）
3. **Approved**: 承認済み
4. **Published**: 公開中

**審査が Rejected された場合**:
1. Play Console で拒否理由を確認
2. ポリシー違反の詳細を確認
3. 問題を修正して新しいバージョンをアップロード
4. **Appeal** で異議申し立て（誤判定の場合）

## 📊 Phase 9: リリース後の管理

### 9.1 公開後の監視

#### Android vitals の確認
1. **Quality** → **Android vitals** を選択
2. 以下の指標を監視:
   - **Crash rate**: 1% 未満を維持
   - **ANR rate** (Application Not Responding): 0.5% 未満を維持
   - **Wake locks**: バッテリー消費の確認

#### ユーザーレビューの監視
1. **Reviews** セクションで確認
2. 評価の低いレビューに返信
3. バグ報告や機能リクエストを記録

### 9.2 アップデートの提供

#### バージョンコードの更新
`build.gradle.kts`:
```kotlin
defaultConfig {
    versionCode = 2      // 前回より大きい整数
    versionName = "1.0.1" // セマンティックバージョニング
}
```

#### セマンティックバージョニングの推奨ルール
- **Major (1.x.x)**: 互換性のない大きな変更
- **Minor (x.1.x)**: 後方互換性のある機能追加
- **Patch (x.x.1)**: バグ修正

#### アップデートの手順
1. コードを修正
2. `versionCode` と `versionName` をインクリメント
3. 新しい AAB をビルド
4. **Production** → **Create new release**
5. AAB をアップロードしてリリース

### 9.3 ユーザー獲得の最適化

#### ストアリスティングの最適化 (ASO)
1. **Store listing experiments** で A/B テストを実施
   - アイコンのバリエーション
   - スクリーンショットの順序
   - 説明文のバリエーション

2. キーワードの最適化
   - Google Play の検索コンソールで検索クエリを確認
   - 効果的なキーワードを説明文に追加

#### プロモーション
1. **Acquire users** → **Store listing** で広告キャンペーンを設定（オプション）
2. SNS やウェブサイトでアプリを宣伝

## ⚠️ よくある問題と解決策

### 問題 1: "App signing by Google Play required"

**解決策**:
1. **Release** → **Setup** → **App integrity** を選択
2. **Use Google Play App Signing** を選択
3. Google に署名を委任（推奨）

### 問題 2: "Package name already exists"

**解決策**:
`build.gradle.kts` の `applicationId` を変更（例: `com.cyrillicime.app`）

### 問題 3: "Target API level must be at least 33"

**解決策**:
```kotlin
targetSdk = 34  // 最新の API レベルに更新
```

### 問題 4: "Missing accessibility features"

**解決策**:
IME として、アクセシビリティ機能を適切に実装:
```kotlin
// AndroidManifest.xml
<service android:name=".CyrillicIMEService"
    android:label="@string/ime_name"
    android:permission="android.permission.BIND_INPUT_METHOD">
    <intent-filter>
        <action android:name="android.view.InputMethod" />
    </intent-filter>
    <meta-data
        android:name="android.view.im"
        android:resource="@xml/method" />
</service>
```

### 問題 5: "Data safety section incomplete"

**解決策**:
Play Console で **App content** → **Data safety** を完了する

### 問題 6: AAB ビルドエラー

**解決策**:
```bash
# Gradle キャッシュをクリア
./gradlew clean

# ビルドツールを最新に更新
# build.gradle.kts で確認:
buildToolsVersion = "34.0.0"

# 再ビルド
./gradlew bundleRelease
```

## 🔒 セキュリティのベストプラクティス

### キーストアの管理
1. ✅ キーストアファイルをバックアップ（複数の安全な場所）
2. ✅ パスワードを安全に保管（パスワードマネージャー使用）
3. ✅ `.gitignore` に `*.jks` と `keystore.properties` を追加
4. ❌ キーストアを Git にコミットしない
5. ❌ キーストアをクラウドストレージに平文で保存しない

### Play App Signing の有効化
1. Google Play App Signing を使用（推奨）
2. Google がアップロード鍵と署名鍵を分離管理
3. アップロード鍵を紛失しても、Google に依頼してリセット可能

## 📚 参考リンク

- [Google Play Console](https://play.google.com/console)
- [Android Developers - Publish Your App](https://developer.android.com/studio/publish)
- [Google Play ポリシーセンター](https://play.google.com/about/developer-content-policy/)
- [Android App Bundle ガイド](https://developer.android.com/guide/app-bundle)
- [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
- [Android vitals](https://developer.android.com/topic/performance/vitals)

## ✅ デプロイ完了

上記の手順をすべて完了すると、Cyrillic Japanese IME が Google Play Store で公開されます！

---

**最終更新**: 2025-11-02
**対象バージョン**: Android 7.0 (API 24) 以降
**Android Studio バージョン**: Hedgehog (2023.1.1) 以降
