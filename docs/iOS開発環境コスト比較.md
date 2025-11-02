# iOS開発環境のコスト比較

このドキュメントでは、Cyrillic IME iOSアプリのビルド・テスト環境の選択肢とコストを比較します。

## 📊 コスト比較表

| 環境 | 初期費用 | 月額費用 | 従量課金 | 最小契約期間 | 推奨度 |
|------|---------|---------|---------|-------------|--------|
| GitHub Actions | $0 | $0-$100 | $0.08/分 | なし | ⭐⭐⭐⭐⭐ |
| ローカルMac | $0 | $0 | $0 | なし | ⭐⭐⭐⭐⭐ |
| MacStadium | $0-$99 | $79-$199 | なし | 1-12ヶ月 | ⭐⭐⭐⭐ |
| AWS mac2.metal | $0 | $792 | $1.10/時間 | 24時間単位 | ⭐⭐ |
| AWS mac1.metal | $0 | $780 | $1.083/時間 | 24時間単位 | ⭐⭐ |

## 💡 推奨アプローチ

### 1. GitHub Actions（最推奨）

**料金体系**:
- 無料枠: プライベートリポジトリで月2,000分（Freeプラン）
- macOS runner: $0.08/分（約$4.8/時間）
- 使用した分のみ課金（秒単位）

**実際のコスト例**:
```
# 1回のビルド・テスト: 10分
$0.08/分 × 10分 = $0.80

# 月30回のビルド
$0.80 × 30回 = $24/月

# 月100回のビルド
$0.80 × 100回 = $80/月
```

**メリット**:
- ✅ セットアップ不要
- ✅ 従量課金でコスト効率が高い
- ✅ 自動スケーリング
- ✅ 最新のmacOS/Xcodeが利用可能
- ✅ 並列実行可能

**デメリット**:
- ❌ ビルド時間が長い場合はコスト増加
- ❌ 同時実行数に制限（Freeプランは1つまで）

**設定方法**:
```yaml
# .github/workflows/ios-tests.yml
name: iOS Tests

on:
  push:
    branches: [main, develop]

jobs:
  test:
    runs-on: macos-14  # または macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and Test
        run: |
          cd rust_core && ./build_ios.sh
          cd ../mobile/iOS
          xcodebuild test -scheme CyrillicIME
```

**このプロジェクトでの推奨設定**: ✅ **既に設定済み**

### 2. ローカルMac（開発用）

**料金**: $0（既存のMacを使用）

**対象**:
- Apple Silicon Mac（M1/M2/M3/M4）を所有している場合
- Intel Mac（macOS 12以降）

**メリット**:
- ✅ 完全無料
- ✅ 最速のビルド時間
- ✅ デバッグが容易
- ✅ オフライン作業可能

**デメリット**:
- ❌ CI/CD自動化には不向き
- ❌ チーム共有が困難

**セットアップ**:
```bash
# 必要なツールのインストール
brew install rustup
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
cargo install cargo-lipo

# ビルド
cd rust_core
./build_ios.sh --release

# Xcodeプロジェクトを開く
open mobile/iOS/CyrillicIME.xcodeproj
```

**推奨**: 日常的な開発作業に使用

### 3. MacStadium（中長期運用）

**料金**:
- Mac mini M2: $79/月（年契約）または $99/月（月契約）
- Mac mini M1: $139/月（年契約）
- Mac Studio: $199/月〜

**メリット**:
- ✅ 固定料金で使い放題
- ✅ 専用ハードウェア
- ✅ 24時間の制約なし
- ✅ VPN接続可能

**デメリット**:
- ❌ 初期セットアップが必要
- ❌ 最低契約期間あり（通常1-12ヶ月）
- ❌ 管理・メンテナンスが必要

**推奨**:
- 月100時間以上のビルド時間が必要な場合
- チームで専用CI環境が必要な場合

### 4. AWS macOS EC2（非推奨）

**料金**:
- mac2.metal (M2): $1.10/時間 = $26.4/日 = $792/月
- mac1.metal (Intel): $1.083/時間 = $26/日 = $780/月
- **最小割り当て期間**: 24時間（解放後も24時間分課金）

**メリット**:
- ✅ AWS統合
- ✅ IAM/VPC設定可能
- ✅ Systems Manager対応

**デメリット**:
- ❌ 非常に高額
- ❌ 24時間の最小割り当て制約
- ❌ Dedicated Hostが必要
- ❌ スポットインスタンス非対応

**コスト例**:
```
# 1日だけ使用しても24時間分課金
1時間使用: $1.10 × 24時間 = $26.40

# 1週間に1回、3時間ビルド
週1回 × 24時間 × 4週間 = $105.6/月

# 常時稼働
$1.10 × 24時間 × 30日 = $792/月
```

**推奨**: ⚠️ コスト効率が悪いため非推奨

**どうしても使う場合の最適化**:
1. ビルドスクリプトを事前にローカルでテスト
2. 24時間以内に全作業を完了
3. 自動削除タイマーを設定
4. GitHub Actions Self-hosted Runnerとして活用

## 🎯 推奨構成（このプロジェクト）

### フェーズ別の推奨環境

#### Phase 1: 開発初期（現在）
```
✅ GitHub Actions（CI/CD）
✅ ローカルMac（日常開発）
```

**月額コスト**: $0-$50
- GitHub Actions: 月50回ビルド程度
- 無料枠を使い切ったとしても$50未満

#### Phase 2: チーム開発
```
✅ GitHub Actions（CI/CD）
✅ ローカルMac（日常開発）
✅ MacStadium（オプション: 専用ビルドサーバー）
```

**月額コスト**: $0-$179
- GitHub Actionsをメインに使用
- 必要に応じてMacStadiumを追加

#### Phase 3: 大規模運用
```
✅ GitHub Actions（プルリクエストCI）
✅ MacStadium（専用ビルドサーバー・ナイトリービルド）
✅ ローカルMac（開発）
```

**月額コスト**: $79-$300
- MacStadiumで常時ビルド環境を維持
- GitHub Actionsでプルリクエストチェック

## 📈 コスト削減のベストプラクティス

### 1. GitHub Actions最適化

```yaml
# キャッシュを活用してビルド時間を短縮
- name: Cache cargo
  uses: actions/cache@v4
  with:
    path: ~/.cargo
    key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}

# 不要なステップをスキップ
- name: Run tests
  if: github.event_name == 'pull_request'  # PRの時のみテスト
```

### 2. ビルド時間の最適化

```bash
# Rustのリリースビルドを並列化
cargo build --release --jobs 8

# Xcodeのビルド並列化
xcodebuild -jobs 8

# 不要なアーキテクチャをスキップ
# テスト時はシミュレータ用のみビルド
cargo lipo --targets aarch64-apple-ios-sim
```

### 3. ブランチ戦略

```yaml
# mainブランチのみフルビルド
on:
  push:
    branches: [main]
  pull_request:  # PRは最小限のチェックのみ
    paths:
      - '**.swift'
      - '**.rs'
```

## 🔢 実際のコストシミュレーション

### シナリオ 1: 個人開発者
- ローカルMacで開発
- GitHub Actionsでmainブランチのみテスト
- 月20回のpush

**月額コスト**: $0（無料枠内）

### シナリオ 2: 小規模チーム（3人）
- 各自ローカルMacで開発
- GitHub Actionsで全PRテスト
- 月150回のpush

**月額コスト**: $12-$40
- GitHub Actions: 150回 × 10分 × $0.08/分 = $120
- 無料枠（2,000分）を考慮すると $40程度

### シナリオ 3: 中規模チーム（10人）
- ローカルMac + MacStadium（専用ビルドサーバー）
- GitHub Actions（PR CI）
- 月500回のpush

**月額コスト**: $79-$200
- MacStadium Mac mini: $79/月
- GitHub Actions（超過分）: $50-$100/月

## 📝 結論

**このプロジェクトの推奨環境**:

1. **CI/CD**: GitHub Actions（既に設定済み） ✅
2. **開発**: ローカルMac
3. **必要に応じて**: MacStadium（中長期運用の場合）

**AWS macOS EC2は使用しない**（コスト効率が悪い）

GitHub Actionsの現在の設定で十分コスト効率が良く、追加のインフラは不要です。
