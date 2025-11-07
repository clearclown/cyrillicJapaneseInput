# GitHub Actions Android 自動デプロイ設定ガイド

**対象**: GitHub Actionsを使ってAndroidアプリを自動的にGoogle Play Storeへデプロイしたい開発者
**難易度**: 中級
**所要時間**: 40〜60分

---

## 🎯 このガイドの目的

**ローカル環境なしでAndroidアプリをデプロイできるようにする**

GitHub Actionsは**Ubuntu Linuxランナー**（Linux環境の仮想マシン）を無料で提供しています（パブリックリポジトリの場合）。これにより：

✅ **Android Studioがなくても、Androidアプリをビルド・デプロイ可能**
✅ **コード修正をGitにpushするだけで自動ビルド**
✅ **チーム全員が同じビルド環境を使用（環境差異なし）**
✅ **履歴が残り、いつでも過去のバージョンを再ビルド可能**
✅ **完全無料** (パブリックリポジトリの場合)

---

## 📋 前提条件

### 必須

- ✅ GitHub リポジトリ（パブリックまたはGitHub Proアカウント）
- ✅ Google Play Console アカウント（初回$25、1回のみ）
- ✅ Google Play Console にアプリ登録済み
- ✅ Javaがインストールされている（keystore作成用）

### あると便利

- Android Studio（ローカルテスト用）
- Androidデバイスまたはエミュレーター（テスト用）

---

## 🚀 セットアップ手順

### ステップ1: Keystore（署名用キー）の作成

Androidアプリをリリースするには、署名用のkeystoreファイルが必要です。

#### 1-1. Keystoreファイルの生成

```bash
# Java JDKが必要（インストールされていない場合）
# macOS: brew install openjdk
# Ubuntu: sudo apt install openjdk-17-jdk

# Keystoreを生成
keytool -genkey -v \
  -keystore pismo-release.keystore \
  -alias pismo \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

**入力項目**:
- `keystore password`: 強力なパスワードを設定（記録しておく）
- `key password`: keystoreパスワードと同じでもOK（記録しておく）
- `名前と組織`: 適当に入力（例: Pismo, Pismo Team）

**⚠️ 重要**: このkeystoreファイルは**永久に保管**してください。紛失すると、アプリの更新ができなくなります。

#### 1-2. Keystoreの情報を確認

```bash
keytool -list -v -keystore pismo-release.keystore
```

以下の情報をメモ：
- **Alias**: `pismo`（上記で指定したもの）
- **Valid until**: 有効期限（約27年後）

#### 1-3. KeystoreをBase64エンコード

```bash
# macOS/Linux
base64 -i pismo-release.keystore | pbcopy

# またはファイルに保存
base64 -i pismo-release.keystore -o keystore-base64.txt
```

このBase64文字列を後でGitHub Secretsに登録します。

---

### ステップ2: Google Play Service Account の作成

Google Play Consoleへの自動アップロードには、Service Accountが必要です。

#### 2-1. Google Play Console で API Access を有効化

1. https://play.google.com/console にアクセス
2. **設定** → **API アクセス** をクリック
3. 初回の場合、Google Cloud プロジェクトとリンク
4. **新しいサービスアカウントを作成** をクリック

#### 2-2. Google Cloud Console でService Account作成

1. リンク先のGoogle Cloud Consoleが開く
2. **サービスアカウントを作成** をクリック
3. **名前**: `github-actions-deploy`
4. **役割**: `サービスアカウントユーザー`
5. **完了** をクリック

#### 2-3. JSONキーを作成

1. 作成したサービスアカウントをクリック
2. **キー** タブ → **鍵を追加** → **新しい鍵を作成**
3. **JSON** を選択
4. JSONファイルがダウンロードされる（例: `pismo-xxxxxx.json`）

**⚠️ 重要**: このJSONファイルは機密情報です。安全に保管してください。

#### 2-4. Google Play Console で権限を付与

1. Google Play Console に戻る
2. **API アクセス** → 作成したサービスアカウントが表示される
3. **アクセス権を付与** をクリック
4. **アプリのアクセス権** → 対象アプリを選択
5. **アカウント権限** → **リリース** の権限を付与
   - ✅ リリースを作成する
   - ✅ リリースを管理する
6. **変更を適用**

---

### ステップ3: GitHub Secrets の設定

GitHubリポジトリの Settings → Secrets and variables → Actions → "New repository secret"

#### 必須のSecrets一覧

| Secret名 | 説明 | 取得元 |
|---------|------|--------|
| `ANDROID_KEYSTORE_BASE64` | Keystoreファイル（Base64） | ステップ1-3 |
| `ANDROID_KEYSTORE_PASSWORD` | Keystoreのパスワード | ステップ1-1で設定したもの |
| `ANDROID_KEY_ALIAS` | Keystoreのエイリアス | ステップ1-1で設定（例: `pismo`） |
| `ANDROID_KEY_PASSWORD` | Keyのパスワード | ステップ1-1で設定したもの |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Service AccountのJSON（全体をコピー） | ステップ2-3でダウンロードしたJSONファイルの内容 |

#### Secretsの登録方法

```bash
# 1. GitHubリポジトリページを開く
# 2. Settings → Secrets and variables → Actions
# 3. "New repository secret" をクリック
# 4. Name に上記のSecret名を入力
# 5. Secret に対応する値を貼り付け
# 6. "Add secret" をクリック
```

**GOOGLE_PLAY_SERVICE_ACCOUNT_JSON の登録**:
- JSONファイルを開く
- **ファイル全体**をコピー（`{` から `}` まで）
- Secretとして貼り付け

---

### ステップ4: ワークフローの動作確認

#### 4-1. 手動トリガーでテスト（推奨）

GitHubリポジトリの Actions タブ → "Android Play Store Deploy" → "Run workflow"

入力項目：
- **version_name**: `1.0.0`（アプリのバージョン名）
- **version_code**: `1`（ビルド番号、整数）

"Run workflow" をクリック

#### 4-2. ログを確認

ワークフローが実行されたら、各ステップのログを確認：

✅ **緑色のチェックマーク**: 成功
❌ **赤色のバツマーク**: 失敗

失敗した場合、該当ステップのログを展開してエラーメッセージを確認。

#### 4-3. よくあるエラーと対処法

**エラー1: "Keystore was tampered with, or password was incorrect"**

```
❌ 原因: ANDROID_KEYSTORE_PASSWORD が間違っている
✅ 解決: パスワードを再確認してSecretを更新
```

**エラー2: "Service account not authorized"**

```
❌ 原因: Service Accountに権限が付与されていない
✅ 解決: Google Play Console でリリース権限を付与
```

**エラー3: "Package not found"**

```
❌ 原因: Google Play Console にアプリが登録されていない
✅ 解決: Play Consoleで手動でアプリを作成
```

---

### ステップ5: タグベースの自動デプロイ

#### 5-1. バージョンタグを作成してpush

```bash
# ローカルでタグを作成
git tag -a android-v1.0.0 -m "Release version 1.0.0"

# GitHubにpush
git push origin android-v1.0.0
```

#### 5-2. 自動的にワークフローが起動

タグが `android-v*.*.*` パターンにマッチすると、自動的にビルド・デプロイが開始されます。

#### 5-3. Google Play Console で確認

5〜30分後、Google Play Console の内部テストトラックに新しいビルドが表示されます。

---

## 🔄 日常的な使い方

### コード修正

1. ローカルでKotlin/Rustコードを編集
2. コミット＆プッシュ（`main` ブランチ）
3. テストが自動実行される（`.github/workflows/android-tests.yml`）
4. 問題なければタグを作成してデプロイ

### バージョンアップ

```bash
# 新しいバージョンをタグ付け
git tag -a android-v1.1.0 -m "Added new features"
git push origin android-v1.1.0

# GitHub Actions が自動的に:
# 1. Rust Coreをビルド（4アーキテクチャ）
# 2. Gradleビルド（AAB作成）
# 3. 署名
# 4. Google Play Consoleへアップロード
```

---

## ⚠️ セキュリティのベストプラクティス

### 1. Keystoreの管理

- ❌ **NG**: KeystoreをGitリポジトリにコミット
- ✅ **OK**: GitHub Secretsに保存（Base64エンコード）
- ✅ **OK**: 別の安全な場所にバックアップ（例: パスワードマネージャー）

### 2. Service Account JSONキー

- ❌ **NG**: JSONファイルをリポジトリにコミット
- ✅ **OK**: GitHub Secretsに保存
- 不要になったキーは Google Cloud Console で削除

### 3. Keystoreの有効期限

- Android keystoreは**約27年間有効**（10000日）
- 有効期限が切れる前に**新しいkeystoreを作成**
- ただし、既存アプリの更新には**元のkeystoreが必要**

---

## 💰 コストについて

### GitHub Actions（Linuxランナー）

| リポジトリタイプ | Linux分数/月 | 料金 |
|----------------|--------------|------|
| **パブリックリポジトリ** | 無制限 | **無料** |
| **プライベート（Free）** | 2,000分 | 無料 |
| **プライベート（Team）** | 3,000分 | $4/月 |
| **プライベート（Enterprise）** | 50,000分 | $21/月 |

1回のAndroidビルド＆デプロイ: 約**8〜12分**

**パブリックリポジトリなら完全無料！**

### Google Play Developer Console

- **初回費用**: $25（1回のみ、生涯有効）
- その後の年間費用: **無料**

---

## 🔧 トラブルシューティング

### ワークフローが起動しない

**症状**: タグをpushしても Actions が実行されない

**確認事項**:
1. タグ名が `android-v*.*.*` パターンか？
2. `.github/workflows/android-deploy.yml` がリポジトリに存在するか？
3. GitHub Actions が有効か？（Settings → Actions → General）

### Rust Coreビルドが失敗

**症状**: "cargo ndk not found" または "NDK not installed"

**原因**: Android NDKのインストール失敗

**解決方法**:
- ワークフローログで NDK バージョンを確認
- 必要に応じて `.github/workflows/android-deploy.yml` の `NDK_VERSION` を更新

### AABビルドは成功するがアップロードで失敗

**症状**: Gradleビルド成功、Google Play アップロードで失敗

**確認事項**:
1. Service Accountの権限（リリース権限があるか）
2. Package名が Google Play Console と一致（`com.pismo.pismo`）
3. アプリが Google Play Console に作成済みか

---

## 📊 ワークフロー実行時間の目安

| ステップ | 所要時間 |
|---------|---------|
| セットアップ | 1分 |
| Rust Coreビルド（4アーキテクチャ） | 5〜7分 |
| Gradleビルド（AAB） | 2〜3分 |
| 署名とアップロード | 30秒〜1分 |
| **合計** | **約8〜12分** |

---

## 🎓 よくある質問（FAQ）

### Q1: 本当にAndroid Studioなしでデプロイできますか？

**A**: はい、**GitHub Actionsを使えば可能です**。

ただし、**keystoreの初回作成時だけはJavaが必要**です。その後は：
- コード変更
- ビルド
- デプロイ

すべてGitHub Actions上で自動実行されます。

### Q2: プライベートリポジトリでも使えますか？

**A**: はい、ただし**月2,000分まで無料**（GitHub Freeプラン）。

1回のビルドが約10分なので、月200回までデプロイ可能。

パブリックリポジトリなら**無制限・完全無料**。

### Q3: Keystoreを紛失したらどうなりますか？

**A**: **アプリの更新ができなくなります**。

- 新規アプリとして再リリースする必要がある
- 既存ユーザーは新しいアプリをインストールし直す必要がある

**対策**: Keystoreは複数の場所にバックアップ
- GitHub Secrets（自動バックアップとして）
- パスワードマネージャー
- 暗号化されたクラウドストレージ

### Q4: 内部テストトラックとは何ですか？

**A**: Google Play Consoleの**テスト配信機能**です。

トラックの種類：
- **内部テスト**: 最大100人、即時配信（審査なし）
- **クローズドテスト**: 一般公開前のベータテスト
- **オープンテスト**: 誰でも参加可能なベータテスト
- **本番**: 一般公開（Google審査あり）

ワークフローは**内部テストトラック**に自動アップロードします。

### Q5: 本番リリースも自動化できますか？

**A**: 技術的には可能ですが、**推奨しません**。

理由：
- Google Play審査が必要（自動承認ではない）
- 重大なバグを含むリリースを防ぐため
- 手動での最終確認が望ましい

**推奨フロー**:
1. GitHub Actions → 内部テスト（自動）
2. 内部テスト → クローズドテスト（手動）
3. クローズドテスト → 本番（手動）

---

## 🚀 次のステップ

### レベル1: 基本（完了予定）

- ✅ 手動デプロイ（ローカルから）
- ✅ GitHub Actionsでの自動デプロイ

### レベル2: 改善

- 🔄 **スクリーンショット自動生成**
  - Fastlane screengrab を使用
  - 複数言語のスクリーンショットを自動生成
- 🔄 **Slack通知**
  - デプロイ成功/失敗を通知

### レベル3: 最適化

- 🔄 **ビルドキャッシュの活用**
  - Gradleキャッシュ
  - Rust依存関係のキャッシュ
- 🔄 **並列ビルド**
  - Rust各アーキテクチャを並列処理

---

## 📚 関連ドキュメント

このプロジェクトの他のドキュメント：

- [Android_デプロイ_初心者向けコマンドライン完全ガイド.md](./Android_デプロイ_初心者向けコマンドライン完全ガイド.md) - ローカルでのデプロイ方法
- [Google_Play_Store_デプロイ手順.md](./Google_Play_Store_デプロイ手順.md) - Play Store提出手順

### 公式リソース

- [GitHub Actions - About billing](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions)
- [Google Play Console](https://developer.android.com/distribute/console)
- [Android Keystore System](https://developer.android.com/training/articles/keystore)

---

## ✨ まとめ

GitHub Actionsを使えば：

✅ **Android Studio不要** - Keystore作成後は、すべてGitHub上で完結
✅ **完全自動化** - タグをpushするだけでデプロイ
✅ **無料** - パブリックリポジトリなら完全無料
✅ **履歴管理** - すべてのビルドが記録される
✅ **チーム開発** - 環境差異がなくなる

**次のアップデート時は、GitHubにpushするだけ！**

---

**最終更新**: 2025年11月8日
**作成者**: 実践経験に基づく
