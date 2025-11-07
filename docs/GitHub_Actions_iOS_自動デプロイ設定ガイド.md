# GitHub Actions iOS 自動デプロイ設定ガイド

**対象**: GitHub Actionsを使ってiOSアプリを自動的にApp Store Connectへデプロイしたい開発者
**難易度**: 中級
**所要時間**: 30〜60分

---

## 🎯 このガイドの目的

**macOSパソコンがなくてもiOSアプリをデプロイできるようにする**

GitHub Actionsは**macOSランナー**（macOS環境の仮想マシン）を無料で提供しています（パブリックリポジトリの場合）。これにより：

✅ **個人のMacがなくても、iOSアプリをビルド・デプロイ可能**
✅ **アイコン変更やコード修正をGitにpushするだけで自動ビルド**
✅ **チーム全員が同じビルド環境を使用（環境差異なし）**
✅ **履歴が残り、いつでも過去のバージョンを再ビルド可能**

---

## 📋 前提条件

### 必須

- ✅ GitHub リポジトリ（パブリックまたはGitHub Proアカウント）
- ✅ Apple Developer Program アカウント（年間99ドル）
- ✅ App Store Connect にアプリ登録済み
- ✅ 証明書とプロビジョニングプロファイル作成済み

### あると便利

- macOS環境（証明書の初回作成時のみ必要）
- Xcode（ローカルテスト用）

---

## 🚀 セットアップ手順

### ステップ1: Apple Distribution証明書の準備

#### 1-1. 証明書の作成（macOSで実行）

```bash
# Keychain Accessを開く
open "/Applications/Utilities/Keychain Access.app"

# Xcode → Settings → Accounts → Manage Certificates
# "+" ボタンから "Apple Distribution" を作成
```

または、Apple Developer Portalから手動作成：

1. https://developer.apple.com/account/resources/certificates/list
2. "+" → "Apple Distribution"
3. CSR（Certificate Signing Request）をアップロード
4. ダウンロードしてKeychain Accessにインストール

#### 1-2. 証明書を.p12形式でエクスポート

```bash
# Keychain Accessで "Apple Distribution" 証明書を右クリック
# "Export" → "Personal Information Exchange (.p12)" を選択
# パスワードを設定（後で使用）
```

保存先例: `~/Desktop/AppleDistribution.p12`

#### 1-3. .p12ファイルをBase64エンコード

```bash
# macOS/Linux
base64 -i ~/Desktop/AppleDistribution.p12 | pbcopy

# またはファイルに保存
base64 -i ~/Desktop/AppleDistribution.p12 -o ~/Desktop/certificate.txt
```

このBase64文字列を後でGitHub Secretsに登録します。

---

### ステップ2: プロビジョニングプロファイルの準備

#### 2-1. App Store用プロビジョニングプロファイルを作成

1. https://developer.apple.com/account/resources/profiles/list
2. "+" → "App Store" を選択
3. App ID を選択（例: `com.pismo.Pismo`）
4. Distribution証明書を選択
5. プロファイル名を入力（例: `Pismo App Store`）
6. ダウンロード: `Pismo_App_Store.mobileprovision`

#### 2-2. キーボード拡張用プロファイルも作成

1. 同様の手順で、キーボード拡張のBundle ID用に作成
2. Bundle ID: `com.pismo.Pismo.PismoKeyboard`
3. ダウンロード: `PismoKeyboard_App_Store.mobileprovision`

#### 2-3. プロビジョニングプロファイルをBase64エンコード

```bash
# メインアプリ
base64 -i ~/Downloads/Pismo_App_Store.mobileprovision | pbcopy

# キーボード拡張
base64 -i ~/Downloads/PismoKeyboard_App_Store.mobileprovision | pbcopy
```

---

### ステップ3: App Store Connect API Key の作成

#### 3-1. API Keyを作成

1. https://appstoreconnect.apple.com/access/api にアクセス
2. "+" アイコンをクリック
3. **Name**: `GitHub Actions CI/CD`
4. **Access**: `App Manager` または `Developer`
5. "Generate" をクリック

#### 3-2. 必要な情報をメモ

- **Issuer ID**: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- **Key ID**: `XXXXXXXXXX` (例: `AB12CD34EF`)
- **Private Key**: `AuthKey_AB12CD34EF.p8` をダウンロード

⚠️ **重要**: Private Keyは**1回しかダウンロードできません**。安全に保管してください。

#### 3-3. Private KeyをBase64エンコード

```bash
base64 -i ~/Downloads/AuthKey_AB12CD34EF.p8 | pbcopy
```

---

### ステップ4: GitHub Secrets の設定

GitHubリポジトリの Settings → Secrets and variables → Actions → "New repository secret"

#### 必須のSecrets一覧

| Secret名 | 説明 | 取得元 |
|---------|------|--------|
| `IOS_BUILD_CERTIFICATE_BASE64` | Distribution証明書（.p12）のBase64 | ステップ1-3 |
| `IOS_P12_PASSWORD` | .p12ファイルのパスワード | ステップ1-2で設定したもの |
| `IOS_KEYCHAIN_PASSWORD` | CI用キーチェーンのパスワード | 任意の文字列（例: `temp-keychain-pass`） |
| `IOS_APP_PROVISIONING_PROFILE_BASE64` | メインアプリのプロビジョニングプロファイル（Base64） | ステップ2-3 |
| `IOS_KEYBOARD_PROVISIONING_PROFILE_BASE64` | キーボード拡張のプロビジョニングプロファイル（Base64） | ステップ2-3 |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID | ステップ3-2（例: `AB12CD34EF`） |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect Issuer ID | ステップ3-2（UUID形式） |
| `APP_STORE_CONNECT_API_KEY_BASE64` | App Store Connect API Private Key（Base64） | ステップ3-3 |

#### Secretsの登録方法

```bash
# 1. GitHubリポジトリページを開く
# 2. Settings → Secrets and variables → Actions
# 3. "New repository secret" をクリック
# 4. Name に上記のSecret名を入力
# 5. Secret に対応する値を貼り付け
# 6. "Add secret" をクリック
```

---

### ステップ5: ワークフローの動作確認

#### 5-1. 手動トリガーでテスト

GitHubリポジトリの Actions タブ → "iOS App Store Deploy" → "Run workflow"

入力項目：
- **version**: `1.0.0`（アプリのバージョン）
- **build_number**: `1`（ビルド番号）

"Run workflow" をクリック

#### 5-2. ログを確認

ワークフローが実行されたら、各ステップのログを確認：

✅ **緑色のチェックマーク**: 成功
❌ **赤色のバツマーク**: 失敗

失敗した場合、該当ステップのログを展開してエラーメッセージを確認。

#### 5-3. よくあるエラーと対処法

**エラー1: "Signing certificate not found"**

```
❌ 原因: Distribution証明書が正しくインポートされていない
✅ 解決: IOS_BUILD_CERTIFICATE_BASE64 と IOS_P12_PASSWORD を再確認
```

**エラー2: "Provisioning profile doesn't match"**

```
❌ 原因: プロビジョニングプロファイルのBundle IDが一致しない
✅ 解決: プロファイルを再作成し、Base64を再登録
```

**エラー3: "Authentication failed"**

```
❌ 原因: App Store Connect API Keyが無効
✅ 解決: Key ID、Issuer ID、Private Keyを再確認
```

---

### ステップ6: タグベースの自動デプロイ

#### 6-1. バージョンタグを作成してpush

```bash
# ローカルでタグを作成
git tag -a ios-v1.0.0 -m "Release version 1.0.0"

# GitHubにpush
git push origin ios-v1.0.0
```

#### 6-2. 自動的にワークフローが起動

タグが `ios-v*.*.*` パターンにマッチすると、自動的にビルド・デプロイが開始されます。

#### 6-3. App Store Connect で確認

5〜30分後、App Store Connect の TestFlight タブに新しいビルドが表示されます。

---

## 🔄 日常的な使い方

### アイコン変更

1. ローカルで `mobile/iOS/CyrillicIME/Assets.xcassets/AppIcon.appiconset/` のアイコンを編集
2. コミット＆プッシュ
3. タグを作成: `git tag ios-v1.0.1 && git push origin ios-v1.0.1`
4. GitHub Actions が自動的にビルド・デプロイ

**macOS不要！** すべてGitHub Actions上で完結します。

### コード修正

1. ローカルで Swift/Rust コードを編集
2. コミット＆プッシュ（`main` ブランチ）
3. テストが自動実行される（`.github/workflows/ios-tests.yml`）
4. 問題なければタグを作成してデプロイ

### バージョンアップ

```bash
# 新しいバージョンをタグ付け
git tag -a ios-v1.1.0 -m "Added new features"
git push origin ios-v1.1.0

# GitHub Actions が自動的に:
# 1. Rust Coreをビルド
# 2. Xcodeプロジェクトを生成
# 3. アーカイブを作成
# 4. App Store Connectへアップロード
```

---

## ⚠️ セキュリティのベストプラクティス

### 1. Secretsの管理

- ❌ **NG**: 証明書やAPI Keyをリポジトリにコミット
- ✅ **OK**: GitHub Secretsに保存

### 2. アクセス制限

- App Store Connect APIキーは**App Manager**権限（必要最小限）
- 不要になったAPIキーは削除

### 3. 証明書の有効期限

- Distribution証明書: **1年間有効**
- プロビジョニングプロファイル: **1年間有効**
- 期限切れ前に再作成し、Secretsを更新

カレンダーに登録推奨: 📅 **証明書更新日の1ヶ月前にリマインダー**

---

## 💰 コストについて

### GitHub Actions（macOSランナー）

| リポジトリタイプ | macOS分数/月 | 料金 |
|----------------|--------------|------|
| **パブリックリポジトリ** | 無制限 | **無料** |
| **プライベート（Free）** | 0分 | 使えない |
| **プライベート（Team）** | 3,000分 | $4/月 |
| **プライベート（Enterprise）** | 50,000分 | $21/月 |

1回のiOSビルド＆デプロイ: 約**10〜15分**

パブリックリポジトリなら**完全無料**！

### Apple Developer Program

- **年間費用**: $99（約15,000円）
- 必須（App Store提出には必要）

---

## 🔧 トラブルシューティング

### ワークフローが起動しない

**症状**: タグをpushしても Actions が実行されない

**確認事項**:
1. タグ名が `ios-v*.*.*` パターンか？
2. `.github/workflows/ios-deploy.yml` がリポジトリに存在するか？
3. GitHub Actions が有効か？（Settings → Actions → General）

### ビルドは成功するがアップロードで失敗

**症状**: Archive作成まで成功、App Store Connect へのアップロードで失敗

**確認事項**:
1. App Store Connect API Key の権限（App Manager以上）
2. Bundle ID が App Store Connect と一致
3. アプリが App Store Connect に作成済み

```bash
# App Store Connectで確認:
# https://appstoreconnect.apple.com/apps
# Bundle ID: com.pismo.Pismo が登録されているか
```

### "No profiles for 'com.pismo.Pismo' were found"

**原因**: プロビジョニングプロファイルのBundle IDが異なる

**解決方法**:
1. Apple Developer Portalでプロファイルを確認
2. Bundle IDが正しいか確認
3. プロファイルを再ダウンロードしてBase64を再登録

---

## 📊 ワークフロー実行時間の目安

| ステップ | 所要時間 |
|---------|---------|
| セットアップ | 1〜2分 |
| Rust Coreビルド | 3〜5分 |
| Xcodeプロジェクト生成 | 10秒 |
| アーカイブ作成 | 5〜8分 |
| IPA エクスポート | 30秒 |
| アップロード | 1〜2分 |
| **合計** | **約10〜15分** |

---

## 🎓 よくある質問（FAQ）

### Q1: 本当にMacなしでデプロイできますか？

**A**: はい、**GitHub Actionsを使えば可能です**。

ただし、**証明書の初回作成時だけはmacOSが必要**です。その後は：
- コード変更
- アイコン変更
- バージョンアップ
- デプロイ

すべてGitHub Actions上で自動実行されます。

### Q2: プライベートリポジトリでも使えますか？

**A**: はい、ただし**GitHub Team以上のプラン**（月$4〜）が必要です。

パブリックリポジトリなら**完全無料**で使えます。

### Q3: 証明書の有効期限が切れたらどうなりますか？

**A**: ビルドが失敗します。

**対処法**:
1. 新しい証明書を作成
2. .p12をエクスポート＆Base64エンコード
3. GitHub Secrets の `IOS_BUILD_CERTIFICATE_BASE64` を更新
4. プロビジョニングプロファイルも再作成して更新

### Q4: TestFlightへの自動配信もできますか？

**A**: はい、可能です。

現在のワークフローは App Store Connect へのアップロードまでです。TestFlightへの配信は手動で行う必要がありますが、`altool` コマンドを拡張すれば自動化できます：

```bash
# TestFlightへ自動配信（追加可能）
xcrun altool --upload-app \
  -f Pismo.ipa \
  --distribute-to-testers \
  --apiKey $API_KEY_ID \
  --apiIssuer $ISSUER_ID
```

### Q5: Android版も同じように自動化できますか？

**A**: はい、`.github/workflows/android-deploy.yml` を作成すれば可能です。

Androidの場合：
- macOS不要（Linuxランナーで実行可能）
- Play Console API Keyが必要
- Rust Coreのビルドは同じ

---

## 🚀 次のステップ

### レベル1: 基本（完了）

- ✅ 手動デプロイ（ローカルMacから）
- ✅ GitHub Actionsでの自動デプロイ

### レベル2: 改善

- 🔄 **TestFlight自動配信**
  - 内部テスターに自動配信
  - Slackへ通知
- 🔄 **スクリーンショット自動生成**
  - Fastlane snapshot を使用
  - 複数言語のスクリーンショットを自動生成

### レベル3: 最適化

- 🔄 **ビルドキャッシュの活用**
  - Rust依存関係のキャッシュ（すでに実装済み）
  - Xcodeビルドキャッシュ
- 🔄 **並列ビルド**
  - iOS/Androidを同時ビルド
  - 複数アーキテクチャを並列処理

---

## 📚 関連ドキュメント

このプロジェクトの他のドキュメント：

- [iOS_App_Store_提出_実践記録.md](./iOS_App_Store_提出_実践記録.md) - 初回デプロイの詳細記録
- [iOS_コード署名_トラブルシューティング.md](./iOS_コード署名_トラブルシューティング.md) - 証明書エラーの解決方法
- [iOS_デプロイ_初心者向けコマンドライン完全ガイド.md](./iOS_デプロイ_初心者向けコマンドライン完全ガイド.md) - ローカルでのデプロイ方法

### 公式リソース

- [GitHub Actions - About billing for GitHub Actions](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions)
- [Apple - App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [Xcode - xcodebuild manual](https://developer.apple.com/library/archive/technotes/tn2339/_index.html)

---

**最終更新**: 2025年11月8日
**作成者**: 実践経験に基づく

---

## ✨ まとめ

GitHub Actionsを使えば：

✅ **macOS不要** - 証明書作成後は、すべてGitHub上で完結
✅ **完全自動化** - タグをpushするだけでデプロイ
✅ **無料** - パブリックリポジトリなら完全無料
✅ **履歴管理** - すべてのビルドが記録される
✅ **チーム開発** - 環境差異がなくなる

**次のアップデート時は、GitHubにpushするだけ！**
