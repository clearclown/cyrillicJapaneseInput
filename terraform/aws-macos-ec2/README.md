# AWS macOS EC2 Terraform Configuration

このディレクトリには、iOS開発用のmacOS EC2インスタンスをAWS上に構築するためのTerraform設定が含まれています。

## 📋 前提条件

1. **AWS アカウント**
   - EC2 mac1.metal または mac2.metal インスタンスの利用権限
   - Dedicated Hostの割り当て権限

2. **ツール**
   - Terraform 1.0以降
   - AWS CLI v2
   - SSH鍵ペア

3. **AWS VPC**
   - 既存のVPCとサブネット
   - インターネットゲートウェイ設定済み

## 💰 重要な料金情報

⚠️ **macOS EC2インスタンスは非常に高額です！**

- **最小割り当て期間**: 24時間（解放後も24時間分課金）
- **料金例（us-east-1）**:
  - mac2.metal (M2): 約 $1.10/時間 = 約 $26.4/日 = 約 $792/月
  - mac1.metal (Intel): 約 $1.083/時間 = 約 $26/日 = 約 $780/月

**必ず使用後は適切に停止・削除してください！**

## 💡 コスト最適化の推奨事項

### 推奨アプローチ 1: GitHub Actions Hosted Runners（最もコスト効率が良い）

**料金**: macOS runners = $0.08/分 = $4.8/時間（使用した分のみ）

```yaml
# .github/workflows/ios-tests.yml
jobs:
  test:
    runs-on: macos-14  # または macos-latest
```

**メリット**:
- 使用した分のみ課金（秒単位）
- セットアップ不要
- 自動スケーリング
- 月3,000分まで無料（Teamプランの場合）

**デメリット**:
- ビルド時間が長い場合はコストが増加
- 同時実行数に制限あり

### 推奨アプローチ 2: MacStadium / Mac Mini Colocation（中長期運用）

**料金**: $79-$139/月（固定）

**メリット**:
- 固定料金で使い放題
- 24時間の最小割り当て制約なし
- 専用ハードウェア

**デメリット**:
- 初期セットアップが必要
- 最低契約期間あり

### 推奨アプローチ 3: ローカル開発環境

**料金**: $0（既存のMacを使用）

Apple Silicon Mac（M1/M2/M3）があれば:
```bash
# ローカルでビルド
cd rust_core && ./build_ios.sh
cd ../mobile/iOS
xcodebuild -scheme CyrillicIME
```

### AWS macOS EC2を使う場合のコスト最適化

1. **使用時間を最小化**
   - ビルドスクリプトを事前にテスト
   - 必要な時だけ起動
   - 24時間以内に作業完了

2. **Spot Instances は使用不可**（macOS EC2はOn-Demandのみ）

3. **自動停止の設定**
   ```bash
   # 2時間後に自動削除（例）
   echo "sudo shutdown -h +120" | at now
   ```

## 🚀 セットアップ手順

### 1. SSH鍵ペアの生成

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/cyrillic-ime-macos-key
chmod 600 ~/.ssh/cyrillic-ime-macos-key
```

### 2. 最新のmacOS AMI IDを取得

```bash
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn-ec2-macos-*" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].[ImageId,Name,CreationDate]' \
  --region us-east-1 \
  --output table
```

macOS バージョン選択:
- `amzn-ec2-macos-14.*` - Sonoma (最新)
- `amzn-ec2-macos-13.*` - Ventura
- `amzn-ec2-macos-12.*` - Monterey

### 3. terraform.tfvars を作成

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を編集して以下を設定:

```hcl
macos_ami_id = "ami-xxxxxxxxxxxxxxxxx"  # ステップ2で取得したAMI ID
vpc_id       = "vpc-xxxxxxxxxxxxxxxxx"  # あなたのVPC ID
subnet_id    = "subnet-xxxxxxxxxxxxxxxxx"  # あなたのサブネット ID
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."  # ~/.ssh/cyrillic-ime-macos-key.pub の内容
allowed_ssh_cidr_blocks = ["YOUR_IP/32"]  # あなたのIP アドレス
```

### 4. Terraformの初期化

```bash
cd terraform/aws-macos-ec2
terraform init
```

### 5. 実行プランの確認

```bash
terraform plan
```

作成されるリソースを確認:
- EC2 Dedicated Host (mac2.metal用)
- macOS EC2 インスタンス
- Security Group (SSH, VNC)
- IAM Role & Instance Profile
- Elastic IP (オプション)

### 6. インフラの作成

```bash
terraform apply
```

`yes` と入力して実行を確認。

**作成には約10-15分かかります。**

### 7. インスタンスへの接続

```bash
# Terraform outputからSSHコマンドを取得
terraform output ssh_command

# または直接接続
ssh -i ~/.ssh/cyrillic-ime-macos-key ec2-user@<PUBLIC_IP>
```

## 🔧 初期セットアップ（インスタンス内）

インスタンスに接続後、以下を実行:

### 1. Xcodeのインストール

```bash
# Xcodeのダウンロードとインストール（App Store経由）
# または xcodes を使用
brew install robotsandpencils/made/xcodes
xcodes install 15.0.0 --select
```

### 2. プロジェクトのセットアップ

```bash
cd ~/cyrillicJapaneseInput/mobile/iOS
# XCODE_SETUP.md の手順に従ってXcodeプロジェクトを作成
```

### 3. ビルドの実行

```bash
cd ~/cyrillicJapaneseInput/rust_core
./build_ios.sh --release

cd ~/cyrillicJapaneseInput/mobile/iOS
xcodebuild -scheme CyrillicIME -configuration Release
```

## 🤖 GitHub Actions Self-Hosted Runner（オプション）

### 1. GitHub Runner Tokenの取得

1. GitHubリポジトリ → **Settings** → **Actions** → **Runners**
2. **New self-hosted runner** をクリック
3. **Registration token** をコピー

### 2. terraform.tfvars に追加

```hcl
github_runner_token = "AXXXXXXXXXXXXXXXXXXXXXXXXXX"
github_repo_url     = "https://github.com/clearclown/cyrillicJapaneseInput"
```

### 3. 再デプロイ

```bash
terraform apply
```

インスタンスが起動時に自動的にGitHub Actions runnerとして登録されます。

### 4. GitHub Actionsワークフローの更新

`.github/workflows/ios-tests.yml` を更新:

```yaml
jobs:
  test:
    runs-on: [self-hosted, macos, ios, xcode]  # ← self-hosted ラベルを使用
```

## 📊 リソースの管理

### インスタンスの停止

```bash
# 一時停止（料金は継続）
aws ec2 stop-instances --instance-ids $(terraform output -raw instance_id)

# 再起動
aws ec2 start-instances --instance-ids $(terraform output -raw instance_id)
```

⚠️ **停止しても Dedicated Host の料金は発生し続けます！**

### 完全な削除

```bash
terraform destroy
```

`yes` と入力して確認。

⚠️ **Dedicated Hostは最低24時間分の料金が発生します**

## 🔍 トラブルシューティング

### "No Dedicated Hosts available" エラー

```bash
# 既存のDedicated Hostをリリース
aws ec2 release-hosts --host-ids <host-id>

# 24時間待機後、再度 terraform apply
```

### SSH接続できない

```bash
# Security Groupの確認
aws ec2 describe-security-groups --group-ids $(terraform output -raw security_group_id)

# インスタンスのステータス確認
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)
```

### User Dataが実行されない

```bash
# ログを確認
ssh -i ~/.ssh/cyrillic-ime-macos-key ec2-user@<IP>
tail -f /var/log/cloud-init-output.log
```

## 📁 ファイル構成

```
terraform/aws-macos-ec2/
├── main.tf                    # メインのTerraform設定
├── variables.tf               # 変数定義
├── outputs.tf                 # 出力定義
├── user_data.sh              # 初期セットアップスクリプト
├── terraform.tfvars.example  # 設定例
└── README.md                 # このファイル
```

## 🔐 セキュリティのベストプラクティス

1. **SSH アクセス制限**
   - `allowed_ssh_cidr_blocks` を自分のIPアドレスのみに設定

2. **秘密情報の管理**
   - `terraform.tfvars` を `.gitignore` に追加（既に設定済み）
   - GitHub Runner Token は Secrets Manager 使用を推奨

3. **定期的な更新**
   - macOS AMI を定期的に更新
   - Xcode/Rust toolchain のアップデート

## 📚 参考リンク

- [EC2 Mac Instances - AWS Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-mac-instances.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
