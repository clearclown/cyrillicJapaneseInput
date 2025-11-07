# Android デプロイ 初心者向けコマンドライン完全ガイド

**対象読者**: Android開発が初めての方、コマンドライン操作に不慣れな方
**前提知識**: 基本的なターミナル操作（cd, ls, mkdir など）

---

## 📋 目次

1. [開発環境について](#開発環境について)
2. [必要な環境の準備](#必要な環境の準備)
3. [Phase 1: Rust Coreのビルド](#phase-1-rust-coreのビルド)
4. [Phase 2: Android Studioプロジェクトのセットアップ](#phase-2-android-studioプロジェクトのセットアップ)
5. [Phase 3: 署名鍵の作成](#phase-3-署名鍵の作成)
6. [Phase 4: Google Play Consoleの設定](#phase-4-google-play-consoleの設定)
7. [Phase 5: リリースビルドの作成](#phase-5-リリースビルドの作成)
8. [Phase 6: 内部テストトラック](#phase-6-内部テストトラック)
9. [Phase 7: 本番環境への申請](#phase-7-本番環境への申請)
10. [トラブルシューティング](#トラブルシューティング)

---

## 開発環境について

### どのOSで開発できるか？

AndroidアプリはiOSと異なり、**Windows、macOS、Linuxのいずれでも開発可能**です。

| OS | Android開発 | 備考 |
|---------|------------|------|
| **Windows** | ✅ 可能 | Android Studioが完全対応 |
| **macOS** | ✅ 可能 | Android Studioが完全対応 |
| **Linux** | ✅ 可能 | Android Studioが完全対応 |

**このガイドでは、Linux（Ubuntu/Debian系）をベースに説明しますが、コマンドはWindows/macOSでも類似しています。**

---

## 必要な環境の準備

### ステップ1: OSとJDKのバージョン確認

```bash
# OSのバージョンを確認
lsb_release -a

# 期待される出力（例）:
# Description:    Ubuntu 22.04.3 LTS
# Release:        22.04

# Javaがインストールされているか確認
java -version

# 期待される出力:
# openjdk version "17.0.9" 2023-10-17
```

**必要バージョン**: JDK 17 以降

もしJavaがインストールされていない、またはバージョンが古い場合：

#### Ubuntu/Debianの場合

```bash
# JDK 17をインストール
sudo apt update
sudo apt install openjdk-17-jdk

# インストール確認
java -version
javac -version
```

#### macOSの場合

```bash
# Homebrewを使ってインストール
brew install openjdk@17

# パスを設定
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 確認
java -version
```

#### Windowsの場合

1. [Oracle JDK 17ダウンロードページ](https://www.oracle.com/java/technologies/downloads/#java17) にアクセス
2. Windows用インストーラをダウンロード
3. インストーラを実行
4. 環境変数`JAVA_HOME`を設定:
   ```
   JAVA_HOME=C:\Program Files\Java\jdk-17
   ```

---

### ステップ2: Android Studioのインストール

#### Linux（Ubuntu/Debian）の場合

```bash
# Snapを使ってインストール（推奨）
sudo snap install android-studio --classic

# インストール確認
android-studio --version

# Android Studioを起動
android-studio &
```

#### macOSの場合

```bash
# Homebrewでインストール
brew install --cask android-studio

# または、公式サイトからダウンロード
open https://developer.android.com/studio

# インストール後、Applicationsフォルダから起動
open -a "Android Studio"
```

#### Windowsの場合

1. [Android Studio公式サイト](https://developer.android.com/studio) にアクセス
2. Windows用インストーラをダウンロード
3. インストーラを実行
4. セットアップウィザードに従ってインストール

---

### ステップ3: Android Studioの初期セットアップ

Android Studioを初回起動すると、セットアップウィザードが表示されます：

1. **Welcome画面**:
   - `Next` をクリック

2. **Install Type**:
   - `Standard` を選択（推奨）
   - `Next` をクリック

3. **UI Theme**:
   - お好みのテーマを選択（Darcula / Light）
   - `Next` をクリック

4. **Verify Settings**:
   - インストール内容を確認（Android SDK、Android Virtual Device等）
   - `Finish` をクリック

**ダウンロード中...**（約5〜15分、SDKやエミュレーターイメージをダウンロード）

---

### ステップ4: Android SDK Command-line Toolsの確認

```bash
# Android SDKのパスを確認
echo $ANDROID_HOME

# 出力がない場合、環境変数を設定
# Linux/macOSの場合:
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# ~/.bashrc または ~/.zshrc に追加して永続化
echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.bashrc
source ~/.bashrc

# Windows（PowerShell）の場合:
# $env:ANDROID_HOME = "$env:USERPROFILE\AppData\Local\Android\Sdk"
# $env:Path += ";$env:ANDROID_HOME\cmdline-tools\latest\bin"
# $env:Path += ";$env:ANDROID_HOME\platform-tools"

# SDKがインストールされているか確認
sdkmanager --list | head -20

# adbコマンドの確認
adb --version

# 期待される出力:
# Android Debug Bridge version 1.0.41
```

---

### ステップ5: Rustのインストール

```bash
# Rustがインストールされているか確認
rustc --version

# インストールされていない場合
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# インストール中の選択肢で「1」を選択（デフォルトインストール）

# インストール後、シェルを再起動
source $HOME/.cargo/env

# バージョン確認
rustc --version
# 出力例: rustc 1.75.0 (82e1608df 2023-12-21)

cargo --version
# 出力例: cargo 1.75.0 (1d8b05cdd 2023-11-20)
```

---

### ステップ6: Android向けRustターゲットの追加

```bash
# Android向けのターゲットを追加
rustup target add aarch64-linux-android      # ARM64 (最新のスマホ)
rustup target add armv7-linux-androideabi    # ARM32 (古いスマホ)
rustup target add x86_64-linux-android       # x86_64 (エミュレーター)
rustup target add i686-linux-android         # x86 (古いエミュレーター)

# 追加されたか確認
rustup target list --installed | grep android

# 期待される出力:
# aarch64-linux-android
# armv7-linux-androideabi
# i686-linux-android
# x86_64-linux-android
```

---

### ステップ7: cargo-ndkのインストール

`cargo-ndk`は、Android NDK向けにRustライブラリをビルドするツールです。

```bash
# cargo-ndkをインストール
cargo install cargo-ndk

# インストール確認
cargo ndk --version

# 出力例: cargo-ndk 3.4.0
```

---

### ステップ8: Android NDKのインストール

```bash
# Android Studioを開く
android-studio &

# メニューから: Tools > SDK Manager
# または: Configure（Welcome画面）> SDK Manager

# SDK Managerで:
# 1. 「SDK Tools」タブを選択
# 2. ✅ NDK (Side by side) にチェック
# 3. バージョン25.x.x を選択（推奨）
# 4. 「Apply」→「OK」をクリック

# インストール確認（コマンドライン）
ls $ANDROID_HOME/ndk/

# 期待される出力:
# 25.2.9519653/
```

NDKのバージョンを環境変数に設定：

```bash
# NDKのバージョンを確認
ls $ANDROID_HOME/ndk/

# 環境変数を設定（25.2.9519653の部分は実際のバージョンに置き換え）
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.2.9519653
export PATH=$PATH:$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin

# ~/.bashrc に追加して永続化
echo 'export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.2.9519653' >> ~/.bashrc
source ~/.bashrc

# 確認
echo $ANDROID_NDK_HOME
```

---

### ステップ9: Google Play Consoleアカウントの準備

#### アカウント登録

1. [Google Play Console](https://play.google.com/console) にアクセス
2. Googleアカウントでログイン
3. 初回登録の場合：
   - **Create Developer Account** をクリック
   - 開発者情報を入力（個人 or 組織）
   - **$25の登録料**を支払い（一回のみ）
   - デベロッパー規約に同意

**注意**: 登録料は返金不可です。

---

## Phase 1: Rust Coreのビルド

### ステップ1: プロジェクトディレクトリに移動

```bash
# プロジェクトのルートディレクトリに移動
cd /path/to/cyrillicJapaneseInput

# 現在のディレクトリを確認
pwd
# 出力: /home/yourname/cyrillicJapaneseInput

# ディレクトリ構造を確認
ls -la

# 期待される出力:
# docs/
# profiles/
# rust_core/
# mobile/
# README.md
# CLAUDE.md
```

---

### ステップ2: Rust Coreディレクトリに移動

```bash
# rust_coreディレクトリに移動
cd rust_core

# ディレクトリ内容を確認
ls -la

# 期待される出力:
# Cargo.toml
# src/
# build.rs
```

---

### ステップ3: Android向けにビルド

```bash
# 全アーキテクチャ向けにビルド
cargo ndk --target aarch64-linux-android \
          --target armv7-linux-androideabi \
          --target x86_64-linux-android \
          --target i686-linux-android \
          --android-platform 24 \
          -- build --release

# ビルドには10〜20分かかる場合があります
# 進行状況が表示されます:
#    Compiling serde v1.0.193
#    Compiling ...
#    Finished release [optimized] target(s) in 15m 42s
```

**ビルドが成功したか確認**：

```bash
# ビルド成果物の確認
ls -lh target/aarch64-linux-android/release/ | grep ".so"
ls -lh target/armv7-linux-androideabi/release/ | grep ".so"
ls -lh target/x86_64-linux-android/release/ | grep ".so"
ls -lh target/i686-linux-android/release/ | grep ".so"

# 期待される出力（各ディレクトリに）:
# libcyrillic_ime_core.so  (約1〜3MB)
```

---

### ステップ4: ライブラリをAndroidプロジェクトにコピー

```bash
# まだrust_coreディレクトリにいることを確認
pwd
# 出力: /home/yourname/cyrillicJapaneseInput/rust_core

# Androidプロジェクト用のjniLibsディレクトリを作成
mkdir -p ../mobile/android/app/src/main/jniLibs/arm64-v8a
mkdir -p ../mobile/android/app/src/main/jniLibs/armeabi-v7a
mkdir -p ../mobile/android/app/src/main/jniLibs/x86_64
mkdir -p ../mobile/android/app/src/main/jniLibs/x86

# ビルドしたライブラリをコピー
cp target/aarch64-linux-android/release/libcyrillic_ime_core.so \
   ../mobile/android/app/src/main/jniLibs/arm64-v8a/

cp target/armv7-linux-androideabi/release/libcyrillic_ime_core.so \
   ../mobile/android/app/src/main/jniLibs/armeabi-v7a/

cp target/x86_64-linux-android/release/libcyrillic_ime_core.so \
   ../mobile/android/app/src/main/jniLibs/x86_64/

cp target/i686-linux-android/release/libcyrillic_ime_core.so \
   ../mobile/android/app/src/main/jniLibs/x86/

# コピーされたか確認
find ../mobile/android/app/src/main/jniLibs/ -name "*.so"

# 期待される出力:
# ../mobile/android/app/src/main/jniLibs/arm64-v8a/libcyrillic_ime_core.so
# ../mobile/android/app/src/main/jniLibs/armeabi-v7a/libcyrillic_ime_core.so
# ../mobile/android/app/src/main/jniLibs/x86_64/libcyrillic_ime_core.so
# ../mobile/android/app/src/main/jniLibs/x86/libcyrillic_ime_core.so
```

---

## Phase 2: Android Studioプロジェクトのセットアップ

### ステップ1: Android Studioでプロジェクトを開く

```bash
# プロジェクトのルートに戻る
cd /path/to/cyrillicJapaneseInput

# Androidプロジェクトディレクトリに移動
cd mobile/android

# Android Studioを起動してプロジェクトを開く
android-studio . &

# または、Android Studioを起動してから:
# File > Open > mobile/android ディレクトリを選択
```

**初回起動時**：Gradle Syncが自動的に実行されます（5〜10分かかります）。

---

### ステップ2: プロジェクト構造の確認（Android Studioで）

Android Studioの左側、**Project**ビューで以下を確認：

```
android/
├── app/                          # メインアプリモジュール
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/             # Kotlinソースコード
│   │   │   ├── res/              # リソース（レイアウト、文字列等）
│   │   │   ├── assets/           # プロファイルJSON
│   │   │   ├── jniLibs/          # ネイティブライブラリ（Rust .so）
│   │   │   └── AndroidManifest.xml
│   │   └── androidTest/          # テストコード
│   └── build.gradle.kts          # アプリビルド設定
├── build.gradle.kts              # プロジェクトビルド設定
├── settings.gradle.kts           # モジュール設定
└── gradle.properties             # Gradle設定
```

---

### ステップ3: JSONスキーマファイルのコピー

```bash
# ターミナルで（Android Studioとは別のウィンドウ）
cd /path/to/cyrillicJapaneseInput

# assetsディレクトリを作成
mkdir -p mobile/android/app/src/main/assets/profiles/schemas

# JSONファイルをコピー
cp profiles/profiles.json mobile/android/app/src/main/assets/profiles/
cp profiles/japaneseKanaEngine.json mobile/android/app/src/main/assets/profiles/
cp profiles/schemas/*.json mobile/android/app/src/main/assets/profiles/schemas/

# コピーされたか確認
ls -la mobile/android/app/src/main/assets/profiles/

# 期待される出力:
# profiles.json
# japaneseKanaEngine.json
# schemas/
```

**Android Studioで確認**：
- Project ビューで `app/src/main/assets/profiles/` フォルダが表示されることを確認

---

### ステップ4: build.gradle.ktsの確認

Android Studioで `app/build.gradle.kts` を開く：

**確認項目**：

```kotlin
android {
    namespace = "com.yourcompany.cyrillicime"  // 必要に応じて変更
    compileSdk = 34

    defaultConfig {
        applicationId = "com.yourcompany.cyrillicime"  // 重要: ユニークなID
        minSdk = 24
        targetSdk = 34
        versionCode = 1      // リリースごとにインクリメント
        versionName = "1.0.0" // ユーザーに表示されるバージョン
    }

    buildFeatures {
        compose = true  // Jetpack Composeを使用
    }
}
```

**`applicationId`を変更する場合**：
1. `com.yourcompany.cyrillicime` を任意のパッケージ名に変更
   - 例: `com.example.cyrillicime`
2. Sync Now をクリック

---

### ステップ5: Gradle Syncの実行

```bash
# Android Studioのメニューから: File > Sync Project with Gradle Files
# または、ツールバーの「Sync Now」をクリック
```

**コマンドラインからも可能**：

```bash
# プロジェクトディレクトリで
cd mobile/android

# Gradle Syncを実行
./gradlew --refresh-dependencies

# Windowsの場合:
# gradlew.bat --refresh-dependencies
```

---

### ステップ6: エミュレーターまたは実機でテストビルド

#### エミュレーターの作成（初回のみ）

```bash
# Android Studioのメニューから: Tools > Device Manager
# または、ツールバーの「Device Manager」アイコンをクリック

# Device Managerで:
# 1. 「Create Device」をクリック
# 2. デバイス選択: Pixel 7 Pro（推奨）
# 3. システムイメージ: Android 13.0 (API 33)（推奨）
# 4. AVD Name: Pixel_7_Pro_API_33
# 5. 「Finish」をクリック
```

**コマンドラインから**：

```bash
# 利用可能なシステムイメージを確認
sdkmanager --list | grep system-images

# システムイメージをインストール（API 33, x86_64）
sdkmanager "system-images;android-33;google_apis;x86_64"

# AVDを作成
avdmanager create avd -n Pixel_7_Pro_API_33 \
  -k "system-images;android-33;google_apis;x86_64" \
  -d "pixel_7_pro"

# エミュレーターを起動
emulator -avd Pixel_7_Pro_API_33 &
```

---

#### アプリをビルド＆インストール

**Android Studioから**：

1. ツールバーで実行ターゲットを選択（Pixel_7_Pro_API_33）
2. 緑の再生ボタン（Run）をクリック
3. ビルドが開始され、エミュレーターにアプリがインストールされます

**コマンドラインから**：

```bash
# プロジェクトディレクトリで
cd mobile/android

# Debugビルドを作成
./gradlew assembleDebug

# ビルド成果物の確認
ls -lh app/build/outputs/apk/debug/

# 期待される出力:
# app-debug.apk

# エミュレーターにインストール
adb install app/build/outputs/apk/debug/app-debug.apk

# インストール成功メッセージ:
# Success
```

---

## Phase 3: 署名鍵の作成

### ステップ1: キーストアの生成

**重要**: リリース用の署名鍵は**一度しか作成できません**。紛失すると、今後アプリの更新ができなくなります。必ず**安全な場所にバックアップ**してください。

```bash
# プロジェクトディレクトリに移動
cd mobile/android/app

# キーストアを生成
keytool -genkeypair -v \
  -storetype PKCS12 \
  -keystore cyrillicime-release-key.jks \
  -alias cyrillicime \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# 入力が求められます:
```

**入力項目**：

```
Enter keystore password: ********  # 強固なパスワード（必ず記録！）
Re-enter new password: ********

Enter key password for <cyrillicime>: ********  # キーのパスワード（必ず記録！）
Re-enter new password: ********

What is your first and last name?
  [Unknown]:  Taro Yamada  # 開発者名または会社名

What is the name of your organizational unit?
  [Unknown]:  Development  # 部署名（任意、Enterでスキップ可）

What is the name of your organization?
  [Unknown]:  YourCompany  # 組織名（任意）

What is the name of your City or Locality?
  [Unknown]:  Tokyo  # 都市名

What is the name of your State or Province?
  [Unknown]:  Tokyo  # 都道府県

What is the two-letter country code for this unit?
  [Unknown]:  JP  # 国コード

Is CN=Taro Yamada, OU=Development, O=YourCompany, L=Tokyo, ST=Tokyo, C=JP correct?
  [no]:  yes  # yesを入力
```

**生成成功メッセージ**：

```
Generating 2,048 bit RSA key pair and self-signed certificate (SHA256withRSA) with a validity of 10,000 days
        for: CN=Taro Yamada, OU=Development, O=YourCompany, L=Tokyo, ST=Tokyo, C=JP
[Storing cyrillicime-release-key.jks]
```

**確認**：

```bash
# キーストアが生成されたか確認
ls -lh cyrillicime-release-key.jks

# 期待される出力:
# -rw-rw-r-- 1 user user 2.5K Nov  6 10:30 cyrillicime-release-key.jks
```

---

### ステップ2: キーストア情報をプロパティファイルに保存

```bash
# まだ mobile/android/app ディレクトリにいることを確認
pwd

# keystore.properties ファイルを作成
cat > ../keystore.properties << 'EOF'
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=cyrillicime
storeFile=./app/cyrillicime-release-key.jks
EOF

# YOUR_KEYSTORE_PASSWORD と YOUR_KEY_PASSWORD を実際のパスワードに置き換え
nano ../keystore.properties

# 例:
# storePassword=MySecurePassword123!
# keyPassword=MyKeyPassword456!
# keyAlias=cyrillicime
# storeFile=./app/cyrillicime-release-key.jks

# 保存: Ctrl+O → Enter
# 終了: Ctrl+X
```

**確認**：

```bash
cat ../keystore.properties

# 期待される出力:
# storePassword=MySecurePassword123!
# keyPassword=MyKeyPassword456!
# keyAlias=cyrillicime
# storeFile=./app/cyrillicime-release-key.jks
```

---

### ステップ3: .gitignoreに追加（重要！）

**絶対にGitにコミットしないでください！**

```bash
# プロジェクトのルート .gitignore に追加
cd /path/to/cyrillicJapaneseInput

echo "keystore.properties" >> .gitignore
echo "*.jks" >> .gitignore

# 確認
cat .gitignore | grep -E "keystore|jks"

# 期待される出力:
# keystore.properties
# *.jks
```

---

### ステップ4: build.gradle.ktsに署名設定を追加

Android Studioで `mobile/android/app/build.gradle.kts` を開き、以下を追加：

```kotlin
import java.util.Properties
import java.io.FileInputStream

android {
    // 既存の設定...
    namespace = "com.yourcompany.cyrillicime"
    compileSdk = 34

    // キーストアプロパティの読み込み
    val keystorePropertiesFile = rootProject.file("keystore.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    // 署名設定
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

**保存して Sync Now をクリック**

---

## Phase 4: Google Play Consoleの設定

### ステップ1: Google Play Consoleにアクセス

```bash
# ブラウザでGoogle Play Consoleを開く
xdg-open https://play.google.com/console

# macOSの場合:
# open https://play.google.com/console

# Windowsの場合:
# start https://play.google.com/console
```

Googleアカウントでログインします。

---

### ステップ2: 新しいアプリを作成

**ブラウザでの操作**：

1. **All apps** → **Create app** をクリック
2. アプリ情報を入力:
   - **App name**: `Cyrillic Japanese IME`
   - **Default language**: 日本語
   - **App or game**: アプリ
   - **Free or paid**: 無料（または有料）
3. 規約とポリシーに同意:
   - ✅ **Developer Program Policies**
   - ✅ **US export laws**
4. **Create app** をクリック

---

### ステップ3: アプリダッシュボードの設定

作成後、「Set up your app」セクションが表示されます。以下を順番に設定：

#### 3.3.1 App access（アプリへのアクセス）

1. **App access** をクリック
2. 質問に回答:
   - **Is your app restricted to specific users?**
     - IMEは通常: `All or some functionality is restricted`
     - 理由を説明: "This is a custom keyboard (IME). Users need to enable it in system settings."
3. **Save** → **Apply changes**

---

#### 3.3.2 Ads（広告）

1. **Ads** をクリック
2. 質問に回答:
   - **Does your app contain ads?**
     - 広告を表示しない場合: `No`
3. **Save**

---

#### 3.3.3 Content ratings（コンテンツのレーティング）

1. **Content ratings** をクリック
2. **Start questionnaire** をクリック
3. メールアドレスを入力
4. カテゴリを選択: **Utility, Productivity, Communication, or Other**
5. 質問に回答（すべて No の場合、Everyone レーティング）
6. **Save** → **Calculate rating** → **Apply rating**

---

#### 3.3.4 Target audience（ターゲット層）

1. **Target audience and content** をクリック
2. 年齢層を選択: **13歳以上** を選択
3. **Save**

---

#### 3.3.5 Privacy policy（プライバシーポリシー）

1. **Privacy policy** をクリック
2. プライバシーポリシーの URL を入力（必須）
   - 例: `https://yourwebsite.com/privacy-policy`
   - または GitHub Pages: `https://yourusername.github.io/cyrillicime/privacy-policy`
3. **Save**

---

#### 3.3.6 Data safety（データの安全性）

1. **Data safety** をクリック
2. 質問に回答:
   - **Does your app collect or share user data?**
     - オフラインで動作し、データ収集しない場合: `No`
   - **Do you require users to provide personal information?**
     - `No`
3. **Save** → **Submit**

---

### ステップ4: ストアリスティングの作成

1. 左側のメニューで **Main store listing** を選択
2. 以下を入力:

#### App name

```
Cyrillic Japanese IME
```

#### Short description（80文字以内）

```
キリル文字キーボードで日本語入力。ロシア語・セルビア語・ウクライナ語対応。
```

#### Full description（4000文字以内）

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

#### App icon

**サイズ**: 512 x 512 px
**形式**: PNG（32-bit、透過なし）

アップロード方法：
1. **App icon** セクションで **Upload** をクリック
2. 用意したアイコン画像を選択

#### Feature graphic

**サイズ**: 1024 x 500 px
**形式**: PNG または JPEG

#### Screenshots（スクリーンショット）

**必須枚数**: 最低2枚、最大8枚

**Phone スクリーンショット**:
- **サイズ**: 1080 x 2340 px 以上

スクリーンショット作成方法：

```bash
# エミュレーターを起動
emulator -avd Pixel_7_Pro_API_33 &

# エミュレーター上でアプリを起動

# スクリーンショットを撮影（エミュレーターのツールバーから）
# または、コマンドから:
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ~/Desktop/screenshot1.png
```

**推奨するスクリーンショット内容**:
1. キーボード入力画面（ロシア語キーボード）
2. 変換候補表示画面
3. プロファイル選択画面
4. 設定画面

---

### ステップ5: カテゴリとタグの設定

1. **Store settings** を選択
2. **App category**: `Tools` または `Productivity`
3. **Tags**: `Keyboard`, `Language`, `IME`
4. **Save**

---

## Phase 5: リリースビルドの作成

### ステップ1: バージョン情報の更新

Android Studioで `mobile/android/app/build.gradle.kts` を編集：

```kotlin
defaultConfig {
    applicationId = "com.yourcompany.cyrillicime"
    minSdk = 24
    targetSdk = 34
    versionCode = 1      // ビルド番号（整数、毎回インクリメント）
    versionName = "1.0.0" // バージョン名（ユーザーに表示）
}
```

**Sync Now** をクリック

---

### ステップ2: ProGuardルールの確認

`mobile/android/app/proguard-rules.pro` を確認（必要に応じて作成）：

```proguard
# Rust JNI メソッドを保持
-keep class com.yourcompany.cyrillicime.** {
    native <methods>;
}

# Kotlin reflection 対策
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Jetpack Compose
-keep class androidx.compose.** { *; }
```

---

### ステップ3: Android App Bundle (AAB) のビルド

#### 方法1: Android Studioから（推奨）

1. メニューから: **Build** → **Generate Signed Bundle / APK**
2. **Android App Bundle** を選択 → **Next**
3. **Key store path** でキーストアファイルを選択:
   - `mobile/android/app/cyrillicime-release-key.jks`
4. パスワードを入力:
   - **Key store password**: （ステップ3で設定したパスワード）
   - **Key password**: （ステップ3で設定したキーのパスワード）
   - **Key alias**: `cyrillicime`
5. **Next** → **release** を選択 → **Finish**

**ビルド中...**（5〜10分）

ビルド成功メッセージ:
```
Gradle build finished in 8m 23s
```

AAB ファイルの場所:
```
mobile/android/app/release/app-release.aab
```

---

#### 方法2: コマンドラインから

```bash
# プロジェクトディレクトリに移動
cd mobile/android

# クリーンビルド
./gradlew clean

# Release AAB をビルド
./gradlew bundleRelease

# ビルド成功メッセージ:
# BUILD SUCCESSFUL in 8m 23s

# 生成された AAB の確認
ls -lh app/build/outputs/bundle/release/

# 期待される出力:
# app-release.aab  (約5〜15MB)
```

---

### ステップ4: AABファイルのサイズ確認

```bash
# AABファイルのサイズを確認
ls -lh app/build/outputs/bundle/release/app-release.aab

# 期待される出力:
# -rw-rw-r-- 1 user user 8.5M Nov  6 11:30 app-release.aab
```

**Google Playの推奨サイズ**: 150MB以下（通常のアプリは10〜20MB程度）

---

## Phase 6: 内部テストトラック

### ステップ1: 内部テストトラックの作成

```bash
# ブラウザでGoogle Play Consoleを開く
xdg-open https://play.google.com/console
```

**ブラウザでの操作**：

1. アプリを選択: `Cyrillic Japanese IME`
2. 左側のメニューで **Testing** → **Internal testing** を選択
3. **Create new release** をクリック
4. **Upload** をクリック
5. AAB ファイルを選択:
   - `mobile/android/app/build/outputs/bundle/release/app-release.aab`
6. アップロード中...（1〜5分）

---

### ステップ2: リリースノートの追加

**Release name**: `1.0.0 (1)`

**Release notes**（日本語）:

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

**Save** をクリック

---

### ステップ3: テスターの追加

1. **Testers** タブを選択
2. **Create email list** をクリック
3. リスト名を入力: `Internal Testers`
4. テスターのメールアドレスを追加（最大100名）:
   ```
   tester1@example.com
   tester2@example.com
   ```
5. **Save changes**

---

### ステップ4: 内部テストの開始

1. **Review release** をクリック
2. 内容を確認
3. **Start rollout to Internal testing** をクリック

**確認ダイアログが表示されます**: `Start rollout` をクリック

---

### ステップ5: テスターへの案内

テスターに招待メールが送信されます。テスターは以下の手順でアプリをインストール：

1. 招待メールの**リンクをクリック**
2. Google Playが開き、アプリのページが表示される
3. **インストール** をクリック

**確認項目**:
- ✅ キーボードが正しく有効化できるか
- ✅ ロシア語、セルビア語、ウクライナ語の入力が正常か
- ✅ 変換精度が十分か
- ✅ クラッシュが発生しないか
- ✅ UI が各デバイスで正しく表示されるか

---

## Phase 7: 本番環境への申請

### ステップ1: 最終チェックリスト

以下をすべて完了していることを確認：

- ✅ すべてのストアリスティング情報を入力済み
- ✅ グラフィックアセット（アイコン、スクリーンショット）をアップロード済み
- ✅ プライバシーポリシー URL を設定済み
- ✅ コンテンツレーティングを取得済み
- ✅ データの安全性セクションを完了
- ✅ 内部テストが完了
- ✅ すべての主要機能が動作確認済み
- ✅ クラッシュ率が 1% 未満
- ✅ Google Play ポリシーに準拠していることを確認

---

### ステップ2: 本番リリースの作成

1. Google Play Consoleで **Production** → **Countries / regions** を選択
2. 配信する国を選択:
   - **Add countries / regions** をクリック
   - 日本、ロシア、セルビア、ウクライナ等を選択
   - **Add** をクリック
3. **Production** → **Create new release** をクリック
4. AAB ファイルをアップロード（内部テストと同じファイル可）
5. リリースノートを入力
6. **Save** → **Review release** をクリック

---

### ステップ3: 段階的なロールアウト（推奨）

1. **Release to production** で **Percentage rollout** を選択
2. 初回は **20%** を選択（ユーザーの20%に配信）
3. **Start rollout to Production** をクリック

**確認ダイアログ**: `Start rollout` をクリック

---

### ステップ4: 審査状況の確認

審査ステータスは以下の順序で進行します：

1. **Pending publication**: 審査待ち
2. **In review**: 審査中（通常 数時間〜1日）
3. **Approved**: 承認済み
4. **Published**: 公開中

**メール通知**: 審査状況が変わるとGoogleからメールが届きます。

---

### ステップ5: ロールアウトの拡大

問題がない場合、以下の順序でロールアウトを拡大：

1. **20%** → 2日間監視
2. **50%** → 2日間監視
3. **100%** → 全ユーザーに配信

**拡大方法**:

```bash
# Google Play Consoleを開く
xdg-open https://play.google.com/console
```

1. **Production** を選択
2. **Manage rollout** をクリック
3. **Increase rollout** を選択
4. 新しい割合（50%または100%）を選択
5. **Update** をクリック

---

## トラブルシューティング

### 問題1: `JAVA_HOME is not set`

**原因**: Java環境変数が設定されていない

**解決策**:

```bash
# Javaのインストール場所を確認
which java

# 出力例: /usr/lib/jvm/java-17-openjdk-amd64/bin/java

# JAVA_HOMEを設定
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$PATH:$JAVA_HOME/bin

# ~/.bashrc に追加して永続化
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
source ~/.bashrc
```

---

### 問題2: `cargo ndk` でビルドエラー

**原因**: NDK環境変数が設定されていない

**解決策**:

```bash
# NDKのパスを確認
ls $ANDROID_HOME/ndk/

# 出力例: 25.2.9519653/

# NDK_HOMEを設定
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.2.9519653

# ~/.bashrc に追加
echo 'export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.2.9519653' >> ~/.bashrc
source ~/.bashrc

# 再ビルド
cargo ndk --target aarch64-linux-android --android-platform 24 -- build --release
```

---

### 問題3: Gradle Sync失敗

**原因**: 依存関係の問題またはキャッシュ破損

**解決策**:

```bash
# Gradleキャッシュをクリア
cd mobile/android
./gradlew clean
./gradlew --refresh-dependencies

# Android Studioのキャッシュをクリア
# メニューから: File > Invalidate Caches / Restart > Invalidate and Restart
```

---

### 問題4: 署名エラー "Keystore was tampered with, or password was incorrect"

**原因**: パスワードが間違っている

**解決策**:

```bash
# keystore.properties の内容を確認
cat mobile/android/keystore.properties

# パスワードが正しいか確認
# 正しいパスワードに修正
nano mobile/android/keystore.properties
```

---

### 問題5: Google Play で "Target API level must be at least 33"

**原因**: targetSdkが古い

**解決策**:

```kotlin
// build.gradle.kts で targetSdk を更新
defaultConfig {
    targetSdk = 34  // 最新のAPI レベルに更新
}
```

**Sync Now** → 再ビルド

---

### 問題6: AABファイルがアップロードできない

**原因**: ファイルサイズが大きすぎる、または署名が無効

**解決策**:

```bash
# AABファイルのサイズを確認
ls -lh app/build/outputs/bundle/release/app-release.aab

# 署名を確認
jarsigner -verify -verbose -certs app/build/outputs/bundle/release/app-release.aab

# 出力に "jar verified." が表示されればOK
```

---

## まとめ

### 全体のフロー（コマンドライン中心）

```bash
# 1. 環境準備
java -version                          # Java確認
android-studio --version               # Android Studio確認
rustc --version                        # Rust確認

# 2. Rust Coreビルド
cd rust_core
cargo ndk --target aarch64-linux-android --android-platform 24 -- build --release
cp target/aarch64-linux-android/release/libcyrillic_ime_core.so \
   ../mobile/android/app/src/main/jniLibs/arm64-v8a/

# 3. Android Studioでプロジェクトを開く
cd ../mobile/android
android-studio . &

# 4. 署名鍵の作成
cd app
keytool -genkeypair -v -storetype PKCS12 \
  -keystore cyrillicime-release-key.jks -alias cyrillicime

# 5. リリースビルド作成
cd ..
./gradlew bundleRelease

# 6. Google Play Consoleにアップロード（ブラウザ）
xdg-open https://play.google.com/console

# 7. 内部テスト
# → テスター追加
# → 動作確認

# 8. 本番申請
# → メタデータ入力
# → Start rollout to Production
```

---

## 参考リンク

- [Google Play Console](https://play.google.com/console)
- [Android Developers - Publish Your App](https://developer.android.com/studio/publish)
- [Google Play ポリシーセンター](https://play.google.com/about/developer-content-policy/)
- [Android App Bundle ガイド](https://developer.android.com/guide/app-bundle)
- [cargo-ndk Documentation](https://github.com/bbqsrc/cargo-ndk)

---

**最終更新**: 2025-11-06
**対象バージョン**: Android 7.0 (API 24) 以降
**Android Studio バージョン**: Hedgehog (2023.1.1) 以降
