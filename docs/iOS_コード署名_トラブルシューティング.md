# iOS コード署名トラブルシューティングガイド

**対象**: コード署名エラーに悩む全てのiOS開発者
**難易度**: 初級〜中級

---

## 🔥 よくあるエラー TOP 3

### 1位: "unable to build chain to self-signed root" 🏆

```
Warning: unable to build chain to self-signed root for signer
"Apple Development: YOUR NAME"
errSecInternalComponent
Command CodeSign failed with a nonzero exit code
```

#### 原因
WWDR（Apple Worldwide Developer Relations）中間証明書の問題

#### 即効解決方法

```bash
# 1. 最新のWWDR証明書をダウンロード
curl -O https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
curl -O https://www.apple.com/certificateauthority/AppleWWDRCAG6.cer

# 2. ファイルをダブルクリックして開く
open AppleWWDRCAG3.cer
open AppleWWDRCAG6.cer

# 3. Keychain Accessで「システム」キーチェーンに追加
```

**重要**: ログインキーチェーンではなく、**システムキーチェーン**にインストールすること！

#### 詳細手順

1. **Keychain Access を開く**
   - アプリケーション → ユーティリティ → Keychain Access

2. **古いWWDR証明書を削除**
   - 左側で "システム" と "ログイン" の両方を確認
   - "Apple Worldwide Developer Relations Certification Authority" を検索
   - **2023年期限のもの**を削除（2030年期限のものは残す）

3. **新しい証明書をインストール**
   - ダウンロードした .cer ファイルをダブルクリック
   - キーチェーン選択で **"システム"** を選択
   - "追加" をクリック

4. **開発者証明書を再作成**
   - Xcode → Settings → Accounts
   - Manage Certificates...
   - 古い "Apple Development" を削除（"-" ボタン）
   - "+" → "Apple Development" で再作成

5. **検証**
```bash
security find-identity -v -p codesigning
# "Apple Development" が "valid" と表示されればOK
```

---

### 2位: "Apple Distribution certificate not found"

```
No code signing identity found and can not create a new one
because you enabled manual signing.
```

#### 原因
App Store提出にはDistribution証明書が必要だが、Development証明書しかない

#### 解決方法

**方法A: Xcodeで作成（推奨）**

1. Xcode → Settings → Accounts
2. Apple IDを選択
3. "Manage Certificates..." をクリック
4. "+" → **"Apple Distribution"** を選択
5. 証明書が自動作成される

**方法B: Developer Portalで手動作成**

1. https://developer.apple.com/account/resources/certificates/list にアクセス
2. "+" → "Apple Distribution"
3. CSR（Certificate Signing Request）をアップロード
4. ダウンロードして Keychain にインストール

#### 証明書の種類まとめ

| 証明書 | 用途 | Xcodeでの作成 |
|--------|------|--------------|
| **Apple Development** | 開発・デバッグ | ✅ 可能 |
| **Apple Distribution** | App Store提出 | ✅ 可能 |
| iOS Development (Legacy) | 旧形式 | ❌ 非推奨 |
| iOS Distribution (Legacy) | 旧形式 | ❌ 非推奨 |

---

### 3位: "Provisioning profile doesn't include signing certificate"

```
Provisioning profile "iOS Team Provisioning Profile: com.example.app"
doesn't include signing certificate "Apple Development: YOUR NAME".
```

#### 原因
プロビジョニングプロファイルと証明書の不一致

#### 解決方法

**自動署名を使う（最も簡単）**

1. Xcode でプロジェクトを開く
2. Targets → "Signing & Capabilities"
3. ✅ **"Automatically manage signing"** にチェック
4. Team を選択

これで Xcode が自動的にプロファイルを管理します。

**手動署名の場合**

1. 古いプロビジョニングプロファイルを削除
```bash
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*
```

2. Xcode で再度ビルド
3. `-allowProvisioningUpdates` フラグを使用
```bash
xcodebuild archive -allowProvisioningUpdates
```

---

## 🛠️ デバッグコマンド集

### 証明書の確認

```bash
# コード署名証明書一覧
security find-identity -v -p codesigning

# 開発用証明書のみ
security find-identity -v -p codesigning | grep "Apple Development"

# 配布用証明書のみ
security find-identity -v -p codesigning | grep "Apple Distribution"

# WWDR証明書の確認
security find-certificate -a -c "Apple Worldwide Developer Relations" -Z
```

### プロビジョニングプロファイルの確認

```bash
# インストール済みプロファイル一覧
ls -l ~/Library/MobileDevice/Provisioning\ Profiles/

# プロファイルの詳細表示
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision
```

### Xcodeの設定確認

```bash
# ビルド設定を表示
xcodebuild -project YourProject.xcodeproj \
  -scheme YourScheme \
  -showBuildSettings | grep -i sign

# 利用可能なスキーム確認
xcodebuild -list
```

### キャッシュのクリア

```bash
# Derived Data を削除
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# ビルドキャッシュをクリア（Xcode内）
# Shift + Command + K
```

---

## 📋 チェックリスト

Archive & Upload前に確認：

### 証明書
- [ ] Apple Development 証明書がある
- [ ] Apple Distribution 証明書がある
- [ ] WWDR G3/G6 中間証明書がシステムキーチェーンにある
- [ ] 証明書の有効期限が切れていない

### プロビジョニングプロファイル
- [ ] 自動署名が有効（推奨）
- [ ] または、手動プロファイルが最新

### プロジェクト設定
- [ ] Development Team が設定されている
- [ ] Bundle ID が App Store Connect と一致
- [ ] App Groups が設定されている（必要な場合）

### ビルド設定
- [ ] Code Signing Identity が正しい
  - Debug: Apple Development
  - Release/Archive: Apple Distribution
- [ ] Provisioning Profile が正しい

---

## 🚨 緊急対応フロー

### エラーが出たら、この順で試す

```
1. Xcode を再起動
   ↓ ダメなら
2. Derived Data を削除
   ↓ ダメなら
3. Keychain Access で証明書を確認・再作成
   ↓ ダメなら
4. WWDR証明書を再インストール
   ↓ ダメなら
5. プロビジョニングプロファイルを削除して再生成
   ↓ ダメなら
6. Mac を再起動（意外と効く）
```

---

## 💡 予防策

### 開発環境の初期セットアップ

新しいMacやチーム新メンバーのために：

```bash
#!/bin/bash
# setup_ios_codesigning.sh

echo "🔐 iOS Code Signing Setup"

# 1. WWDR証明書のインストール
echo "📥 Downloading WWDR certificates..."
curl -O https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
curl -O https://www.apple.com/certificateauthority/AppleWWDRCAG6.cer

echo "⚠️  Please install these certificates to System keychain:"
echo "   - AppleWWDRCAG3.cer"
echo "   - AppleWWDRCAG6.cer"
open .

# 2. Xcodeの確認
echo "📱 Checking Xcode..."
xcode-select -p
if [ $? -ne 0 ]; then
    echo "❌ Xcode Command Line Tools not found"
    echo "   Run: xcode-select --install"
    exit 1
fi

# 3. 証明書の確認
echo "🔍 Checking certificates..."
DEV_CERT=$(security find-identity -v -p codesigning | grep "Apple Development" | wc -l)
DIST_CERT=$(security find-identity -v -p codesigning | grep "Apple Distribution" | wc -l)

echo "   Development certificates: $DEV_CERT"
echo "   Distribution certificates: $DIST_CERT"

if [ $DEV_CERT -eq 0 ] || [ $DIST_CERT -eq 0 ]; then
    echo "⚠️  Missing certificates. Please create them in Xcode:"
    echo "   Xcode → Settings → Accounts → Manage Certificates"
fi

echo "✅ Setup check complete!"
```

### ドキュメント化

チーム内で共有すべき情報：

1. **Apple Developer Account情報**
   - Team Name
   - Team ID
   - 管理者の連絡先

2. **プロジェクト固有の設定**
   - Bundle ID
   - App Groups
   - 使用する Capabilities

3. **トラブルシューティング履歴**
   - 過去に遭遇したエラー
   - 解決方法
   - 参考リンク

---

## 📚 関連リソース

### 公式ドキュメント
- [Apple - Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Xcode Help - Signing](https://help.apple.com/xcode/mac/current/#/dev60b6fbbc7)
- [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/)

### 証明書のダウンロード
- [Apple PKI](https://www.apple.com/certificateauthority/)
  - WWDR G3: https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
  - WWDR G6: https://www.apple.com/certificateauthority/AppleWWDRCAG6.cer

### コミュニティ
- [Apple Developer Forums - Code Signing](https://developer.apple.com/forums/tags/code-signing)
- [Stack Overflow - ios code-signing](https://stackoverflow.com/questions/tagged/ios+code-signing)

---

## ✨ ベストプラクティス

### DO ✅
- **自動署名を使う**（特に初学者）
- **証明書は定期的に更新**（有効期限1年）
- **WWDR証明書はシステムキーチェーンに**
- **Gitに証明書をコミットしない**（.gitignoreに追加）
- **CI/CD環境では証明書を安全に管理**（GitHub Secrets等）

### DON'T ❌
- **証明書をメールで送らない**（セキュリティリスク）
- **複数のWWDR証明書を混在させない**
- **期限切れ証明書を放置しない**
- **他人の証明書を無断使用しない**
- **プロビジョニングプロファイルをGitに含めない**

---

## 🎓 初学者向けアドバイス

### コード署名の仕組みを理解する

```
[あなたのアプリ]
    ↓
[開発者証明書で署名] ← Xcodeが自動的にやってくれる
    ↓
[WWDR中間証明書で検証] ← ここでエラーが出やすい
    ↓
[Appleルート証明書で検証]
    ↓
[iOS デバイスにインストール可能！]
```

**ポイント**:
- 証明書は **信頼のチェーン** を形成している
- チェーンのどこかが切れると、署名に失敗
- WWDR証明書は**接着剤**のような役割

### エラーを恐れない

- エラーメッセージは**ヒント**
- Google検索で大抵は解決策が見つかる
- 同じエラーで悩んでいる人は世界中にいる
- **試行錯誤は学習の一部**

### 助けを求める

困ったときの質問先：
1. **公式ドキュメント**（まずはここ）
2. **Stack Overflow**（具体的なエラーメッセージで検索）
3. **Apple Developer Forums**（公式フォーラム）
4. **チームメンバー**（社内に経験者がいれば）

---

**最終更新**: 2025年11月8日
**作成者**: 実践経験に基づく
