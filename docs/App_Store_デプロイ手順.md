# App Store デプロイ手順書

Cyrillic Japanese IME iOS アプリを Apple App Store へデプロイするための手順書です。

## 📋 前提条件

- macOS 搭載のマシン（macOS 13.0 以降推奨）
- Xcode 15.0 以降がインストール済み
- Apple Developer Program への登録（年間 $99）
- 有効な Apple ID

## 🔧 Phase 1: Xcode プロジェクトのセットアップ

### 1.1 Rust Core ライブラリのビルド

```bash
cd rust_core

# iOS 用のターゲットを追加（初回のみ）
rustup target add aarch64-apple-ios
rustup target add aarch64-apple-ios-sim
rustup target add x86_64-apple-ios

# cargo-lipo のインストール（初回のみ）
cargo install cargo-lipo

# iOS 用ライブラリのビルド
cargo lipo --release --targets aarch64-apple-ios,aarch64-apple-ios-sim,x86_64-apple-ios

# ライブラリを iOS プロジェクトにコピー
mkdir -p ../mobile/iOS/CyrillicIME/libs
cp target/universal/release/libcyrillic_ime_core.a ../mobile/iOS/CyrillicIME/libs/
```

### 1.2 Xcode プロジェクトの作成

詳細は `mobile/iOS/XCODE_SETUP.md` を参照してください。

1. Xcode を起動
2. "Create a new Xcode project" を選択
3. テンプレート選択:
   - **iOS** → **App** を選択
4. プロジェクト設定:
   - **Product Name**: `CyrillicIME`
   - **Team**: Apple Developer アカウントを選択
   - **Organization Identifier**: `com.yourcompany`（適宜変更）
   - **Bundle Identifier**: `com.yourcompany.CyrillicIME`
   - **Interface**: SwiftUI
   - **Language**: Swift
5. 保存場所: `mobile/iOS/` ディレクトリ

### 1.3 既存のソースコードをプロジェクトに追加

1. Xcode のプロジェクトナビゲータで `CyrillicIME` を右クリック
2. **Add Files to "CyrillicIME"...** を選択
3. 以下のファイル/フォルダを追加:
   - `mobile/iOS/CyrillicIME/Sources/` 内のすべての `.swift` ファイル
   - `mobile/iOS/CyrillicIME/Tests/` 内のすべてのテストファイル
   - `mobile/iOS/CyrillicIME/libs/libcyrillic_ime_core.a`
   - `mobile/iOS/CyrillicIME/Resources/` 内のリソースファイル
4. **Options** で以下を確認:
   - ✅ **Copy items if needed**
   - ✅ **Create groups**
   - ✅ **Add to targets: CyrillicIME**

### 1.4 Build Settings の設定

1. プロジェクト設定を開く（プロジェクトナビゲータで CyrillicIME をクリック）
2. **Build Settings** タブを選択
3. 以下を設定:

#### Library Search Paths
```
$(PROJECT_DIR)/CyrillicIME/libs
```

#### Other Linker Flags
```
-lcyrillic_ime_core
```

#### Header Search Paths
```
$(PROJECT_DIR)/CyrillicIME/libs
```

### 1.5 Keyboard Extension の追加

1. **File** → **New** → **Target** を選択
2. **iOS** → **Keyboard Extension** を選択
3. 設定:
   - **Product Name**: `CyrillicKeyboard`
   - **Language**: Swift
4. **Activate "CyrillicKeyboard" scheme?** → **Activate**

## 🍎 Phase 2: Apple Developer アカウント設定

### 2.1 Apple Developer Program への登録

1. [Apple Developer](https://developer.apple.com/) にアクセス
2. Apple ID でサインイン
3. **Account** → **Membership** で登録状況を確認
4. 未登録の場合: **Enroll** から登録（年間 $99）

### 2.2 App ID の作成

1. [Apple Developer Portal](https://developer.apple.com/account/) にアクセス
2. **Certificates, Identifiers & Profiles** を選択
3. **Identifiers** → **+** ボタンをクリック
4. **App IDs** を選択 → **Continue**
5. 設定:
   - **Description**: `Cyrillic Japanese IME`
   - **Bundle ID**: `com.yourcompany.CyrillicIME`（Explicit を選択）
6. **Capabilities** で以下を有効化:
   - ✅ **App Groups** (キーボード拡張機能で必要)
7. **Continue** → **Register**

### 2.3 Keyboard Extension 用の App ID 作成

1. 同様の手順で Keyboard Extension 用の App ID を作成:
   - **Bundle ID**: `com.yourcompany.CyrillicIME.CyrillicKeyboard`

### 2.4 App Group の作成

1. **Identifiers** → **+** ボタンをクリック
2. **App Groups** を選択 → **Continue**
3. 設定:
   - **Description**: `Cyrillic IME App Group`
   - **Identifier**: `group.com.yourcompany.CyrillicIME`
4. **Register**

### 2.5 プロビジョニングプロファイルの作成

#### メインアプリ用

1. **Profiles** → **+** ボタンをクリック
2. **iOS App Development** を選択（開発用）
3. **App ID**: `com.yourcompany.CyrillicIME` を選択
4. **Certificates**: 自分の開発証明書を選択
5. **Devices**: テスト用デバイスを選択
6. **Profile Name**: `CyrillicIME Development`
7. **Generate** → ダウンロード

#### Keyboard Extension 用

1. 同様の手順で Keyboard Extension 用のプロファイルを作成:
   - **App ID**: `com.yourcompany.CyrillicIME.CyrillicKeyboard`
   - **Profile Name**: `CyrillicKeyboard Development`

## 📱 Phase 3: App Store Connect の設定

### 3.1 App Store Connect でアプリを作成

1. [App Store Connect](https://appstoreconnect.apple.com/) にアクセス
2. **My Apps** → **+** → **New App** を選択
3. 設定:
   - **Platforms**: iOS
   - **Name**: `Cyrillic Japanese IME`
   - **Primary Language**: 日本語
   - **Bundle ID**: `com.yourcompany.CyrillicIME` を選択
   - **SKU**: `CYRILLICIME001`（任意のユニークな値）
   - **User Access**: Full Access

### 3.2 アプリ情報の入力

1. **App Information** セクション:
   - **Name**: `Cyrillic Japanese IME`
   - **Subtitle**: `キリル文字で日本語入力`
   - **Privacy Policy URL**: プライバシーポリシーの URL（必須）
   - **Category**: **Utilities** または **Productivity**
   - **Content Rights**: 適切なものを選択

2. **Pricing and Availability**:
   - **Price**: 無料 または 有料（価格を選択）
   - **Availability**: 全世界 または 特定の国を選択

### 3.3 アプリのスクリーンショット準備

必要なスクリーンショットサイズ（最低限必要なもの）:
- **6.7" Display (iPhone 15 Pro Max)**: 1290 x 2796 px
- **6.5" Display (iPhone 11 Pro Max)**: 1242 x 2688 px
- **5.5" Display (iPhone 8 Plus)**: 1242 x 2208 px

各サイズで **3〜10枚** のスクリーンショットが必要です。

### 3.4 アプリのメタデータ入力

1. **App Store** タブで新しいバージョンを作成:
   - **Version**: `1.0.0`

2. **What's New in This Version**:
   ```
   初回リリース
   - ロシア語キーボードで日本語入力
   - セルビア語キーボードで日本語入力
   - ウクライナ語キーボードで日本語入力
   - 高速な変換エンジン
   ```

3. **Description**:
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

4. **Keywords**:
   ```
   キリル文字,ロシア語,日本語,IME,キーボード,入力,セルビア語,ウクライナ語
   ```

5. **Support URL**: サポートサイトの URL
6. **Marketing URL**: (オプション) マーケティングサイトの URL

## 🏗️ Phase 4: ビルドとアーカイブ

### 4.1 配布用ビルド設定

1. Xcode でプロジェクトを開く
2. ターゲット設定で **Signing & Capabilities** タブを選択
3. **Automatically manage signing** のチェックを外す
4. **Provisioning Profile**: 作成したプロビジョニングプロファイルを選択
5. **Team**: Apple Developer アカウントを選択

### 4.2 アーカイブの作成

1. Xcode でスキームを **CyrillicIME** に設定
2. デバイスを **Any iOS Device** に設定
3. **Product** → **Archive** を選択
4. ビルドが完了するまで待機（数分かかる場合があります）

### 4.3 アーカイブの検証

1. アーカイブが完了すると **Organizer** ウィンドウが開きます
2. 最新のアーカイブを選択
3. **Validate App** をクリック
4. **App Store Connect** を選択 → **Next**
5. 配布証明書を選択 → **Next**
6. すべてのチェック項目を確認 → **Validate**
7. 検証が成功することを確認

## 🚀 Phase 5: TestFlight による内部テスト

### 5.1 TestFlight へのアップロード

1. Organizer で同じアーカイブを選択
2. **Distribute App** をクリック
3. **App Store Connect** を選択 → **Next**
4. **Upload** を選択 → **Next**
5. 配布証明書とプロビジョニングプロファイルを確認 → **Next**
6. **Upload** をクリック

アップロードには 5〜15 分かかります。

### 5.2 TestFlight での内部テスター追加

1. App Store Connect にアクセス
2. **TestFlight** タブを選択
3. **Internal Testing** → **Default Group** を選択
4. **Testers** → **+** で内部テスターを追加
5. テスターは Apple Developer アカウントメンバーである必要があります

### 5.3 内部テストの実施

1. テスターに招待メールが送信されます
2. テスターは TestFlight アプリをインストール
3. 招待を承諾してアプリをインストール
4. 動作確認とフィードバック収集

**確認項目**:
- ✅ キーボード拡張機能が正しく動作するか
- ✅ ロシア語、セルビア語、ウクライナ語の入力が正常か
- ✅ 変換精度が十分か
- ✅ クラッシュが発生しないか
- ✅ UI が正しく表示されるか

## 🌟 Phase 6: App Store への申請

### 6.1 最終チェックリスト

- ✅ すべての必須スクリーンショットをアップロード済み
- ✅ アプリの説明文、キーワードを入力済み
- ✅ プライバシーポリシー URL を設定済み
- ✅ サポート URL を設定済み
- ✅ TestFlight でのテストが完了
- ✅ すべての主要な機能が動作確認済み
- ✅ App Store Review Guidelines に準拠していることを確認

### 6.2 Export Compliance の設定

1. App Store Connect でアプリを選択
2. **App Privacy** セクションで暗号化の使用について回答:
   - 標準的な HTTPS 通信のみの場合: **No**
   - カスタム暗号化を使用している場合: **Yes** (追加情報が必要)

### 6.3 App Privacy の設定

1. **App Privacy** → **Get Started** をクリック
2. 収集するデータについて回答:
   - このアプリがオフラインで動作し、個人データを収集しない場合: **No**
   - ユーザーデータを収集する場合: 適切に回答

### 6.4 審査への提出

1. **App Store** タブで最新バージョンを選択
2. すべての情報が入力されていることを確認
3. **Add for Review** をクリック
4. **Export Compliance** の質問に回答
5. **Submit for Review** をクリック

### 6.5 審査状況の確認

審査状況は以下のステータスで確認できます:

1. **Waiting for Review**: 審査待ち（通常 1〜3日）
2. **In Review**: 審査中（通常 24〜48時間）
3. **Pending Developer Release**: 承認済み（手動リリース設定の場合）
4. **Ready for Sale**: App Store で公開中

**審査が Rejected された場合**:
1. App Store Connect で拒否理由を確認
2. 指摘された問題を修正
3. 新しいビルドをアップロード（必要な場合）
4. Resolution Center で返信
5. 再度 **Submit for Review**

## 📊 Phase 7: リリース後の管理

### 7.1 リリース

1. **Pending Developer Release** 状態になったら **Release This Version** をクリック
2. 数時間以内に App Store で公開されます

### 7.2 ユーザーレビューの監視

1. App Store Connect の **Ratings and Reviews** で確認
2. 問題報告やフィードバックに対応

### 7.3 アップデートの提供

1. コードを修正・改善
2. バージョン番号をインクリメント（例: 1.0.0 → 1.0.1）
3. 新しいアーカイブを作成してアップロード
4. "What's New" セクションを更新
5. 再度審査に提出

## ⚠️ よくある問題と解決策

### 問題 1: "No valid provisioning profiles found"

**解決策**:
1. Apple Developer Portal でプロビジョニングプロファイルを再作成
2. Xcode で **Preferences** → **Accounts** → アカウントを選択 → **Download Manual Profiles**

### 問題 2: "Missing compliance"

**解決策**:
App Store Connect で **Export Compliance** セクションを完了する

### 問題 3: TestFlight で "This beta has expired"

**解決策**:
新しいビルドをアップロード（TestFlight ビルドは 90 日で期限切れ）

### 問題 4: "Guideline 4.0 - Design - Keyboard Extensions"

**解決策**:
- キーボード拡張機能が Apple のガイドラインに準拠していることを確認
- フルアクセスが本当に必要かを再検討
- 不要な場合は Info.plist で `RequestsOpenAccess` を `NO` に設定

## 📚 参考リンク

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect ヘルプ](https://help.apple.com/app-store-connect/)
- [TestFlight ガイド](https://developer.apple.com/testflight/)
- [Keyboard Extension Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

## ✅ デプロイ完了

上記の手順をすべて完了すると、Cyrillic Japanese IME が App Store で公開されます！

---

**最終更新**: 2025-11-02
**対象バージョン**: iOS 14.0 以降
**Xcode バージョン**: 15.0 以降
