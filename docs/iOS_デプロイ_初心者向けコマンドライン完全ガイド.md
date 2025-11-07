# iOS デプロイ 初心者向けコマンドライン完全ガイド

**対象読者**: iOS開発が初めての方、コマンドライン操作に不慣れな方
**前提知識**: 基本的なターミナル操作（cd, ls, mkdir など）

---

## 📋 目次

1. [macOSがいつ必要か？](#macosがいつ必要か)
2. [必要な環境の準備](#必要な環境の準備)
3. [Phase 1: Rust Coreのビルド](#phase-1-rust-coreのビルド)
4. [Phase 2: Xcodeプロジェクトのセットアップ](#phase-2-xcodeプロジェクトのセットアップ)
5. [Phase 3: Apple Developerアカウント設定](#phase-3-apple-developerアカウント設定)
6. [Phase 4: ビルドとアーカイブ](#phase-4-ビルドとアーカイブ)
7. [Phase 5: TestFlightテスト](#phase-5-testflightテスト)
8. [Phase 6: App Store申請](#phase-6-app-store申請)
9. [トラブルシューティング](#トラブルシューティング)

---

## macOSがいつ必要か？

### ✅ macOSが**絶対に必要**な作業

以下の作業は**macOS搭載のMac**でしか実行できません：

1. **Xcodeの使用**
   - Xcode自体がmacOS専用アプリケーション
   - iOS向けのビルド、署名、アーカイブがXcode必須

2. **iOSシミュレーターでのテスト**
   - iOSシミュレーターはmacOSでのみ動作

3. **App Store Connectへのアップロード**
   - `xcodebuild`コマンド（macOS専用）を使用
   - または Xcode Organizerから手動アップロード

4. **iOSデバイスへの実機インストール**
   - Xcodeの署名機能が必要

### ⚠️ macOSが**不要**な作業（他のOSでも可能）

1. **Rust Coreのコーディング**
   - Linux/Windowsでも開発可能
   - ただし、iOS向けビルドにはmacOSが必要

2. **ドキュメント作成、設計**
   - どのOSでも可能

3. **JSONスキーマファイルの編集**
   - どのOSでも可能

### 🔄 推奨ワークフロー

```
[Linux/Windows PC]          [macOS Mac]
    ↓                           ↓
Rust Coreコーディング → Git Push → Git Pull
JSONスキーマ編集              ↓
                        Xcodeでビルド
                              ↓
                        App Store申請
```

**結論**: iOS開発の最終段階（ビルド〜デプロイ）には**macOSが必須**です。

---

## 必要な環境の準備

### ステップ1: macOSバージョンの確認

```bash
# macOSのバージョンを確認
sw_vers

# 期待される出力例:
# ProductName:        macOS
# ProductVersion:     13.5
# BuildVersion:       22G74
```

**必要バージョン**: macOS 13.0 (Ventura) 以降を推奨

もしバージョンが古い場合：
```bash
# システム設定を開く
open /System/Applications/System\ Settings.app

# 「一般」→「ソフトウェアアップデート」でアップデート
```

---

### ステップ2: Xcodeのインストール

#### 方法1: App Storeから（推奨）

```bash
# App Storeを開く
open -a "App Store"

# App Storeで「Xcode」を検索してインストール（約15GB）
```

#### 方法2: コマンドラインから

```bash
# Command Line Toolsがインストールされているか確認
xcode-select -p

# インストールされていない場合、以下を実行
xcode-select --install

# ダイアログが表示されたら「インストール」をクリック
```

インストール完了後、Xcodeのパスを設定：

```bash
# Xcodeのパスを設定
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# パスが正しく設定されたか確認
xcode-select -p
# 出力: /Applications/Xcode.app/Contents/Developer
```

Xcodeのバージョン確認：

```bash
xcodebuild -version

# 期待される出力:
# Xcode 15.1
# Build version 15C65
```

---

### ステップ3: Rustのインストール

```bash
# Rustがインストールされているか確認
rustc --version

# インストールされていない場合
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# インストール中に表示される選択肢では「1」を選択（デフォルトインストール）

# インストール後、現在のシェルを再起動
source $HOME/.cargo/env

# バージョン確認
rustc --version
# 出力例: rustc 1.75.0 (82e1608df 2023-12-21)
```

---

### ステップ4: iOS向けRustターゲットの追加

```bash
# iOS向けのターゲットを追加
rustup target add aarch64-apple-ios          # 実機（iPhone/iPad）
rustup target add aarch64-apple-ios-sim      # シミュレーター（M1/M2 Mac）
rustup target add x86_64-apple-ios           # シミュレーター（Intel Mac）

# 追加されたか確認
rustup target list --installed | grep ios

# 期待される出力:
# aarch64-apple-ios
# aarch64-apple-ios-sim
# x86_64-apple-ios
```

---

### ステップ5: cargo-lipoのインストール

`cargo-lipo`は、複数のiOSターゲット向けにUniversal Binaryを生成するツールです。

```bash
# cargo-lipoをインストール
cargo install cargo-lipo

# インストール確認
cargo lipo --version

# 出力例: cargo-lipo 1.6.0
```

---

### ステップ6: Apple Developerアカウントの準備

#### 無料アカウント vs 有料アカウント

| 項目 | 無料アカウント | 有料アカウント（$99/年） |
|------|---------------|------------------------|
| 実機テスト | ○（自分のデバイスのみ） | ○ |
| App Store申請 | × | ○ |
| TestFlight | × | ○ |
| プロビジョニングプロファイル有効期限 | 7日 | 1年 |

**App Storeにリリースする場合は有料アカウントが必須です。**

#### アカウント登録手順

1. [Apple Developer](https://developer.apple.com/) にアクセス
2. 「Account」をクリック
3. Apple IDでサインイン
4. 有料登録する場合：「Enroll」→ $99を支払い

登録完了後、以下のコマンドでXcodeにアカウントを追加：

```bash
# Xcodeを起動
open -a Xcode

# Xcode > Settings > Accounts でApple IDを追加
```

---

## Phase 1: Rust Coreのビルド

### ステップ1: プロジェクトディレクトリに移動

```bash
# プロジェクトのルートディレクトリに移動
cd /path/to/cyrillicJapaneseInput

# 現在のディレクトリを確認
pwd
# 出力: /Users/yourname/cyrillicJapaneseInput

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

### ステップ3: iOS向けにビルド

```bash
# Rustプロジェクトの依存関係を確認
cat Cargo.toml

# iOS向けにUniversal Binaryをビルド
cargo lipo --release --targets aarch64-apple-ios,aarch64-apple-ios-sim,x86_64-apple-ios

# ビルドには5〜10分かかる場合があります
# 進行状況が表示されます:
#    Compiling serde v1.0.193
#    Compiling ...
#    Finished release [optimized] target(s) in 8m 23s
```

**ビルドが成功したか確認**：

```bash
# ビルド成果物の確認
ls -lh target/universal/release/

# 期待される出力:
# libcyrillic_ime_core.a  (約2〜5MB)
```

---

### ステップ4: ライブラリをiOSプロジェクトにコピー

```bash
# まだrust_coreディレクトリにいることを確認
pwd
# 出力: /Users/yourname/cyrillicJapaneseInput/rust_core

# iOSプロジェクト用のlibsディレクトリを作成
mkdir -p ../mobile/iOS/CyrillicIME/libs

# ビルドしたライブラリをコピー
cp target/universal/release/libcyrillic_ime_core.a ../mobile/iOS/CyrillicIME/libs/

# コピーされたか確認
ls -lh ../mobile/iOS/CyrillicIME/libs/

# 期待される出力:
# libcyrillic_ime_core.a
```

---

### ステップ5: ヘッダーファイルのコピー（FFI用）

```bash
# Rust CoreのFFIヘッダーファイルが存在するか確認
ls include/

# 期待される出力:
# cyrillic_ime_core.h

# ヘッダーファイルをコピー
cp include/cyrillic_ime_core.h ../mobile/iOS/CyrillicIME/libs/

# コピーされたか確認
ls -la ../mobile/iOS/CyrillicIME/libs/

# 期待される出力:
# libcyrillic_ime_core.a
# cyrillic_ime_core.h
```

---

## Phase 2: Xcodeプロジェクトのセットアップ

### ステップ1: Xcodeプロジェクトを開く

```bash
# プロジェクトのルートに戻る
cd /path/to/cyrillicJapaneseInput

# iOSプロジェクトディレクトリに移動
cd mobile/iOS

# Xcodeプロジェクトを開く
open CyrillicIME.xcodeproj
```

**注意**: もしプロジェクトがまだ存在しない場合、以下の手順で新規作成します。

---

### ステップ2: 新規Xcodeプロジェクトの作成（プロジェクトが存在しない場合のみ）

```bash
# Xcodeを起動
open -a Xcode

# Xcodeのメニューから: File > New > Project
# または、以下のキーボードショートカット:
# Shift + Command + N
```

**Xcodeのウィザードで以下を選択**：

1. **テンプレート選択**:
   - `iOS` → `App` を選択
   - `Next` をクリック

2. **プロジェクト設定**:
   - **Product Name**: `CyrillicIME`
   - **Team**: Apple Developerアカウントを選択
   - **Organization Identifier**: `com.yourcompany`（自分のドメインに変更）
   - **Bundle Identifier**: `com.yourcompany.CyrillicIME`（自動生成される）
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `None`
   - `Next` をクリック

3. **保存場所**:
   - `/path/to/cyrillicJapaneseInput/mobile/iOS/` を選択
   - `Create` をクリック

---

### ステップ3: Rust Coreライブラリをプロジェクトに追加（GUI）

Xcodeが開いている状態で：

1. **プロジェクトナビゲータ**（左側のサイドバー）で `CyrillicIME` をクリック
2. 右クリック → `Add Files to "CyrillicIME"...` を選択
3. `mobile/iOS/CyrillicIME/libs/` フォルダに移動
4. `libcyrillic_ime_core.a` と `cyrillic_ime_core.h` を選択
5. **オプション設定**:
   - ✅ **Copy items if needed**
   - ✅ **Create groups**
   - ✅ **Add to targets: CyrillicIME**
6. `Add` をクリック

---

### ステップ4: Build Settingsの設定（GUI）

Xcodeで：

1. **プロジェクトナビゲータ**で `CyrillicIME`（最上部の青いアイコン）をクリック
2. **TARGETS**で `CyrillicIME` を選択
3. **Build Settings** タブをクリック
4. 検索ボックスに以下を入力して設定：

#### Library Search Paths

検索: `Library Search Paths`

ダブルクリックして以下を追加：
```
$(PROJECT_DIR)/CyrillicIME/libs
```

#### Other Linker Flags

検索: `Other Linker Flags`

ダブルクリックして以下を追加：
```
-lcyrillic_ime_core
```

#### Header Search Paths

検索: `Header Search Paths`

ダブルクリックして以下を追加：
```
$(PROJECT_DIR)/CyrillicIME/libs
```

---

### ステップ5: Keyboard Extensionの追加

```bash
# Xcodeでメニューから: File > New > Target
# または: Control + Command + N
```

**ウィザードで以下を選択**：

1. **テンプレート選択**:
   - `iOS` → `Keyboard Extension` を選択
   - `Next` をクリック

2. **設定**:
   - **Product Name**: `CyrillicKeyboard`
   - **Language**: `Swift`
   - `Finish` をクリック

3. **スキームのアクティブ化**:
   - ダイアログが表示されたら `Activate` をクリック

---

### ステップ6: JSONスキーマファイルのバンドル

```bash
# Finderでprofilesフォルダを開く
open profiles/

# Xcodeのプロジェクトナビゲータに戻る
# CyrillicKeyboardターゲットを右クリック → "Add Files to "CyrillicKeyboard"..."

# profiles/ フォルダ全体を選択:
# - profiles.json
# - japaneseKanaEngine.json
# - schemas/ ディレクトリ

# オプション設定:
# ✅ Copy items if needed
# ✅ Create folder references（重要！）
# ✅ Add to targets: CyrillicKeyboard

# Addをクリック
```

**確認**：プロジェクトナビゲータで `CyrillicKeyboard` → `profiles/` フォルダが青色（folder reference）で表示されていること。

---

## Phase 3: Apple Developerアカウント設定

### ステップ1: Apple Developer Portalにアクセス

```bash
# ブラウザでApple Developer Portalを開く
open https://developer.apple.com/account/
```

Apple IDでサインインします。

---

### ステップ2: App IDの作成（コマンドラインからは不可、ブラウザで実施）

**ブラウザでの操作**：

1. **Certificates, Identifiers & Profiles** をクリック
2. 左側のメニューで **Identifiers** を選択
3. 右上の **+** ボタンをクリック
4. **App IDs** を選択 → `Continue`

**メインアプリ用App ID**:

- **Description**: `Cyrillic Japanese IME`
- **Bundle ID**: `Explicit` を選択
  - `com.yourcompany.CyrillicIME`（Xcodeで設定したものと同じ）
- **Capabilities**:
  - ✅ **App Groups**（キーボード拡張機能で必要）
- `Continue` → `Register`

**Keyboard Extension用App ID**（同じ手順で作成）:

- **Description**: `Cyrillic Keyboard Extension`
- **Bundle ID**: `com.yourcompany.CyrillicIME.CyrillicKeyboard`
- **Capabilities**:
  - ✅ **App Groups**
- `Continue` → `Register`

---

### ステップ3: App Groupの作成

1. **Identifiers**メニューで右上の **+** ボタンをクリック
2. **App Groups** を選択 → `Continue`
3. 設定:
   - **Description**: `Cyrillic IME App Group`
   - **Identifier**: `group.com.yourcompany.CyrillicIME`
4. `Register` をクリック

---

### ステップ4: App IDにApp Groupを紐付け

1. **Identifiers**で `com.yourcompany.CyrillicIME` を選択
2. **App Groups** にチェックを入れる
3. `Configure` をクリック
4. 作成した `group.com.yourcompany.CyrillicIME` を選択
5. `Continue` → `Save`

**Keyboard Extension側も同様に設定**：
`com.yourcompany.CyrillicIME.CyrillicKeyboard` に対しても同じApp Groupを設定

---

## Phase 4: ビルドとアーカイブ

### ステップ1: 署名設定の確認（GUI）

Xcodeで：

1. プロジェクトナビゲータで `CyrillicIME`（プロジェクトアイコン）をクリック
2. **TARGETS** → `CyrillicIME` を選択
3. **Signing & Capabilities** タブをクリック
4. 設定:
   - ✅ **Automatically manage signing**（推奨）
   - **Team**: Apple Developerアカウントを選択
   - **Bundle Identifier**: `com.yourcompany.CyrillicIME` が表示されていることを確認

**同じ手順でKeyboard Extensionも設定**：
- **TARGETS** → `CyrillicKeyboard` を選択
- 同様に署名設定

---

### ステップ2: シミュレーターでビルドテスト

```bash
# 利用可能なシミュレーターのリストを表示
xcrun simctl list devices

# 期待される出力（例）:
# -- iOS 17.0 --
#     iPhone 15 (12345678-1234-1234-1234-123456789ABC)
#     iPhone 15 Pro (23456789-2345-2345-2345-234567890BCD)
```

**Xcodeでビルド**：

```bash
# Xcodeのツールバーで:
# 1. スキームを「CyrillicIME」に設定
# 2. デバイスを「iPhone 15 Pro」（任意のシミュレーター）に設定
# 3. Command + B でビルド
```

またはコマンドラインから：

```bash
# プロジェクトディレクトリに移動
cd /path/to/cyrillicJapaneseInput/mobile/iOS

# シミュレーター向けにビルド
xcodebuild -scheme CyrillicIME \
           -sdk iphonesimulator \
           -configuration Debug \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
           build

# ビルド成功メッセージ:
# ** BUILD SUCCEEDED **
```

---

### ステップ3: 実機向けにアーカイブ（App Store申請用）

```bash
# Xcodeのツールバーで:
# 1. スキームを「CyrillicIME」に設定
# 2. デバイスを「Any iOS Device」に設定
# 3. メニューから: Product > Archive
#    または: Command + Shift + B
```

**コマンドラインから**：

```bash
# アーカイブディレクトリを作成
mkdir -p build

# アーカイブを作成
xcodebuild -scheme CyrillicIME \
           -sdk iphoneos \
           -configuration Release \
           -archivePath build/CyrillicIME.xcarchive \
           archive

# 処理には5〜10分かかります
# 成功メッセージ:
# ** ARCHIVE SUCCEEDED **
```

**アーカイブの確認**：

```bash
# アーカイブが作成されたか確認
ls -lh build/

# 期待される出力:
# CyrillicIME.xcarchive/
```

---

### ステップ4: アーカイブの検証

```bash
# Xcodeで: Window > Organizer
# または: Command + Shift + Option + O
```

**Organizerウィンドウで**：

1. 左側の **Archives** を選択
2. 最新の `CyrillicIME` アーカイブを選択
3. **Validate App** ボタンをクリック
4. **App Store Connect** を選択 → `Next`
5. 配布証明書を選択（自動選択される） → `Next`
6. すべてのチェック項目を確認 → `Validate`

**検証中...**（1〜3分かかります）

検証成功メッセージ:
```
✅ Validation Successful
```

---

## Phase 5: TestFlightテスト

### ステップ1: App Store Connectでアプリを作成

```bash
# ブラウザでApp Store Connectを開く
open https://appstoreconnect.apple.com/
```

**ブラウザでの操作**：

1. **My Apps** → **+** → **New App** をクリック
2. 設定:
   - **Platforms**: ✅ iOS
   - **Name**: `Cyrillic Japanese IME`
   - **Primary Language**: 日本語
   - **Bundle ID**: `com.yourcompany.CyrillicIME` を選択
   - **SKU**: `CYRILLICIME001`（任意のユニークな値）
   - **User Access**: Full Access
3. `Create` をクリック

---

### ステップ2: TestFlightへのアップロード

**方法1: Xcodeから（推奨）**

```bash
# Xcodeで: Window > Organizer
# または: Command + Shift + Option + O
```

Organizerウィンドウで：

1. 検証済みのアーカイブを選択
2. **Distribute App** ボタンをクリック
3. **App Store Connect** を選択 → `Next`
4. **Upload** を選択 → `Next`
5. 配布証明書を確認 → `Next`
6. **Upload** をクリック

**アップロード中...**（5〜15分）

成功メッセージ:
```
✅ Upload Successful
```

**方法2: コマンドラインから**

```bash
# ExportOptions.plistを作成
cat > ExportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
EOF

# YOUR_TEAM_IDを実際のTeam IDに置き換え
# Team IDは https://developer.apple.com/account/ の「Membership」で確認

# アーカイブをエクスポート
xcodebuild -exportArchive \
           -archivePath build/CyrillicIME.xcarchive \
           -exportPath build/export \
           -exportOptionsPlist ExportOptions.plist

# App Store Connectにアップロード
xcrun altool --upload-app \
             --type ios \
             --file build/export/CyrillicIME.ipa \
             --username "your_apple_id@example.com" \
             --password "your-app-specific-password"

# App-Specific Passwordの作成方法:
# https://appleid.apple.com/ → セキュリティ → App用パスワード
```

---

### ステップ3: TestFlightでの内部テスト

```bash
# App Store Connectを開く
open https://appstoreconnect.apple.com/
```

**ブラウザでの操作**：

1. **My Apps** → `Cyrillic Japanese IME` を選択
2. **TestFlight** タブをクリック
3. **iOS** セクションで最新のビルドが表示されるまで待つ（10〜30分）
4. ビルドが「Processing」→「Ready to Submit」になったら:
   - **Export Compliance**を設定（暗号化の使用について）
   - 標準的なHTTPS通信のみの場合: `No` を選択
5. **Internal Testing** → `Default Group` をクリック
6. **Testers** → **+** でテスターを追加
   - テスターはApple Developerアカウントメンバーである必要があります
7. 招待メールがテスターに送信されます

**テスターの操作**：

```bash
# iPhoneでTestFlightアプリをApp Storeからインストール
# TestFlightアプリを開く
# 招待を承諾してアプリをインストール
```

---

## Phase 6: App Store申請

### ステップ1: アプリ情報の入力

```bash
# App Store Connectを開く
open https://appstoreconnect.apple.com/
```

**ブラウザでの操作**：

1. **My Apps** → `Cyrillic Japanese IME` を選択
2. **App Store** タブをクリック
3. 左側で `1.0 Prepare for Submission` を選択

**入力項目**：

#### スクリーンショット

スクリーンショットは以下のサイズで最低3枚必要：
- **6.7" Display**: 1290 x 2796 px

**スクリーンショット作成方法**：

```bash
# iPhoneシミュレーターを起動
open -a Simulator

# メニューから: File > Open Simulator > iPhone 15 Pro Max
# アプリを起動してスクリーンショット撮影: Command + S

# 保存先:
~/Desktop/
```

#### アプリの説明

```
Cyrillic Japanese IME は、キリル文字キーボードを使用して日本語を入力できる革新的な入力メソッドです。

【主な機能】
・ロシア語、セルビア語、ウクライナ語キーボードに対応
・リアルタイム変換
・カスタマイズ可能なプロファイル
・オフラインで動作

【使い方】
1. アプリをインストール
2. 設定 → 一般 → キーボード → キーボード → 新しいキーボードを追加
3. "Cyrillic Japanese IME" を選択
4. フルアクセスを許可
```

#### キーワード

```
キリル文字,ロシア語,日本語,IME,キーボード,入力,セルビア語,ウクライナ語
```

#### サポートURL

```
https://github.com/yourname/cyrillicJapaneseInput
```

#### プライバシーポリシーURL（必須）

```
https://yourwebsite.com/privacy-policy
```

---

### ステップ2: ビルドの選択

1. **Build** セクションで **+** をクリック
2. TestFlightでテスト済みのビルドを選択
3. `Done` をクリック

---

### ステップ3: App Privacyの設定

1. 左側のメニューで **App Privacy** を選択
2. **Get Started** をクリック
3. 質問に回答:
   - **Does this app collect data from users?**
     - オフラインで動作し、データ収集しない場合: `No`
4. `Save` → `Publish`

---

### ステップ4: 審査への提出

1. `1.0 Prepare for Submission` ページに戻る
2. すべての必須項目が✅になっていることを確認
3. 右上の **Add for Review** をクリック
4. **Export Compliance**の質問に回答:
   - 標準的なHTTPS通信のみ: `No`
5. **Submit for Review** をクリック

---

### ステップ5: 審査状況の確認

```bash
# App Store Connectを開いて確認
open https://appstoreconnect.apple.com/
```

**ステータスの意味**：

- **Waiting for Review**: 審査待ち（通常1〜3日）
- **In Review**: 審査中（通常24〜48時間）
- **Pending Developer Release**: 承認済み（手動リリース設定の場合）
- **Ready for Sale**: App Storeで公開中

**メール通知**：審査状況が変わるとAppleからメールが届きます。

---

## トラブルシューティング

### 問題1: `xcode-select: error: tool 'xcodebuild' requires Xcode`

**原因**: Xcodeが正しくインストールされていない

**解決策**:

```bash
# Xcodeのパスを設定
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# ライセンスに同意
sudo xcodebuild -license accept
```

---

### 問題2: `cargo lipo` でビルドエラー

**原因**: iOS向けのターゲットが追加されていない

**解決策**:

```bash
# ターゲットを再追加
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios

# キャッシュをクリア
cargo clean

# 再ビルド
cargo lipo --release
```

---

### 問題3: Xcodeで "No valid provisioning profiles found"

**原因**: プロビジョニングプロファイルが正しく設定されていない

**解決策**:

```bash
# Xcodeを開く
open -a Xcode

# Xcode > Settings > Accounts でApple IDを選択
# "Download Manual Profiles" をクリック
```

または、Apple Developer Portalでプロファイルを再作成。

---

### 問題4: TestFlightで "Missing compliance"

**原因**: Export Complianceが設定されていない

**解決策**:

App Store Connectの **TestFlight** → ビルドを選択 → **Export Compliance** セクションを完了

---

### 問題5: 審査でReject（拒否）

**原因**: ガイドライン違反

**解決策**:

1. App Store Connectで拒否理由を確認
2. Resolution Centerで詳細を確認
3. 指摘された問題を修正
4. 新しいビルドをアップロード（必要な場合）
5. Resolution Centerで返信
6. 再度 **Submit for Review**

---

## まとめ

### 全体のフロー（コマンドライン中心）

```bash
# 1. 環境準備
xcodebuild -version                    # Xcode確認
rustc --version                        # Rust確認

# 2. Rust Coreビルド
cd rust_core
cargo lipo --release
cp target/universal/release/libcyrillic_ime_core.a ../mobile/iOS/CyrillicIME/libs/

# 3. Xcodeプロジェクト設定（GUI）
open ../mobile/iOS/CyrillicIME.xcodeproj
# → Build Settings設定
# → Keyboard Extension追加

# 4. アーカイブ作成
cd ../mobile/iOS
xcodebuild -scheme CyrillicIME -archivePath build/CyrillicIME.xcarchive archive

# 5. 検証とアップロード（GUI推奨）
# Xcode Organizerから実施

# 6. App Store Connect設定（ブラウザ）
open https://appstoreconnect.apple.com/

# 7. TestFlightテスト
# → 内部テスター追加
# → 動作確認

# 8. App Store申請
# → メタデータ入力
# → Submit for Review
```

---

## 参考リンク

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect ヘルプ](https://help.apple.com/app-store-connect/)
- [TestFlight ガイド](https://developer.apple.com/testflight/)
- [Xcode Command Line Tools](https://developer.apple.com/xcode/resources/)
- [cargo-lipo Documentation](https://github.com/TimNN/cargo-lipo)

---

**最終更新**: 2025-11-06
**対象バージョン**: iOS 16.0 以降
**Xcode バージョン**: 15.0 以降
