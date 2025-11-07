# コントリビューションガイド (Contributing Guide)

Cyrillic Japanese IMEプロジェクトへの貢献に興味を持っていただき、ありがとうございます！

このガイドでは、プロジェクトへの貢献方法について説明します。

---

## 📋 目次

1. [行動規範](#行動規範)
2. [貢献の種類](#貢献の種類)
3. [開発環境のセットアップ](#開発環境のセットアップ)
4. [プルリクエストの流れ](#プルリクエストの流れ)
5. [コーディング規約](#コーディング規約)
6. [コミットメッセージ規約](#コミットメッセージ規約)
7. [テスト](#テスト)
8. [ドキュメント](#ドキュメント)

---

## 行動規範

このプロジェクトは[Code of Conduct](CODE_OF_CONDUCT.md)を遵守しています。参加することで、あなたもこの行動規範を遵守することに同意したものとみなされます。

---

## 貢献の種類

以下のような貢献を歓迎します：

### 🐛 バグ報告

バグを発見した場合は、[Issue](https://github.com/yourname/cyrillicJapaneseInput/issues/new)を作成してください。

**含めるべき情報**:
- バグの説明
- 再現手順
- 期待される動作
- 実際の動作
- 環境情報（OS、バージョン等）
- スクリーンショット（あれば）

### ✨ 機能提案

新機能のアイデアがある場合は、[Issue](https://github.com/yourname/cyrillicJapaneseInput/issues/new)で提案してください。

**含めるべき情報**:
- 機能の説明
- なぜその機能が必要か
- 具体的なユースケース
- 実装案（あれば）

### 📝 ドキュメント改善

ドキュメントの改善も大歓迎です：
- タイポの修正
- 説明の追加・明確化
- 新しいガイドの作成
- 翻訳

### 🌍 新しい言語プロファイルの追加

新しいキリル文字言語（ブルガリア語、モンゴル語等）のプロファイルを追加できます：
1. `profiles/schemas/schema_<language>_v1.json` を作成
2. `profiles/profiles.json` にエントリを追加
3. テストを追加

---

## 開発環境のセットアップ

### 前提条件

- **Rust** 1.70.0 以降
- **macOS** (iOS開発の場合)
  - Xcode 15.0 以降
  - cargo-lipo
- **Linux/macOS/Windows** (Android開発の場合)
  - JDK 17 以降
  - Android Studio
  - cargo-ndk

### リポジトリのクローン

```bash
git clone https://github.com/yourname/cyrillicJapaneseInput.git
cd cyrillicJapaneseInput
```

### Rust Coreのセットアップ

```bash
cd rust_core

# 依存関係のインストール
cargo build

# テストの実行
cargo test

# フォーマットチェック
cargo fmt -- --check

# Lintチェック
cargo clippy -- -D warnings
```

### iOS開発のセットアップ

詳細は[iOS開発計画書](docs/iOS開発計画書.md)または[iOS デプロイ 初心者向けコマンドライン完全ガイド](docs/iOS_デプロイ_初心者向けコマンドライン完全ガイド.md)を参照してください。

```bash
# iOS向けターゲットの追加
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios

# cargo-lipoのインストール
cargo install cargo-lipo

# Rust Coreのビルド
cd rust_core
cargo lipo --release
```

### Android開発のセットアップ

詳細は[Android開発計画書](docs/Android開発計画書.md)または[Android デプロイ 初心者向けコマンドライン完全ガイド](docs/Android_デプロイ_初心者向けコマンドライン完全ガイド.md)を参照してください。

```bash
# Android向けターゲットの追加
rustup target add aarch64-linux-android armv7-linux-androideabi \
                  x86_64-linux-android i686-linux-android

# cargo-ndkのインストール
cargo install cargo-ndk

# Rust Coreのビルド
cd rust_core
cargo ndk --target aarch64-linux-android --platform 29 -- build --release
```

---

## プルリクエストの流れ

### 1. Issueの確認または作成

大きな変更を行う前に、Issueで議論することをお勧めします。

### 2. ブランチの作成

```bash
# mainブランチから最新の状態を取得
git checkout main
git pull origin main

# 新しいブランチを作成
git checkout -b feature/your-feature-name
```

**ブランチ命名規則**:
- `feature/`：新機能
- `fix/`：バグ修正
- `docs/`：ドキュメント
- `refactor/`：リファクタリング
- `test/`：テスト追加

例：`feature/add-bulgarian-profile`

### 3. コードの変更

コーディング規約に従ってコードを記述してください（後述）。

### 4. テストの追加

新機能やバグ修正には、必ずテストを追加してください。

### 5. テストの実行

```bash
# Rust Coreのテスト
cd rust_core
cargo test

# iOS のテスト
cd mobile/iOS
xcodebuild test -scheme CyrillicIME -destination 'platform=iOS Simulator,name=iPhone 15'

# Android のテスト
cd mobile/android
./gradlew test
```

### 6. コミット

```bash
git add .
git commit -m "feat: add Bulgarian profile support"
```

コミットメッセージ規約は後述します。

### 7. プッシュ

```bash
git push origin feature/your-feature-name
```

### 8. プルリクエストの作成

GitHubでプルリクエストを作成します。

**プルリクエストのテンプレート**:

```markdown
## 変更内容

<!-- 何を変更したかを説明 -->

## 動機・背景

<!-- なぜこの変更が必要か -->

## テスト

<!-- どのようにテストしたか -->

## スクリーンショット（あれば）

<!-- UIの変更がある場合 -->

## チェックリスト

- [ ] テストを追加した
- [ ] ドキュメントを更新した
- [ ] コーディング規約に従った
- [ ] コミットメッセージ規約に従った
```

### 9. レビュー対応

レビュアーからのフィードバックに対応してください。

### 10. マージ

承認されたら、メンテナがマージします。

---

## コーディング規約

### Rust

- **Rustfmt**: `cargo fmt`で自動フォーマット
- **Clippy**: `cargo clippy -- -D warnings`でLint
- **命名規則**:
  - 変数・関数: `snake_case`
  - 型・構造体: `PascalCase`
  - 定数: `SCREAMING_SNAKE_CASE`

**例**:

```rust
// 良い例
pub struct ConversionEngine {
    profiles: HashMap<String, Profile>,
}

impl ConversionEngine {
    pub fn process_key(&self, key: &str) -> Result<String, Error> {
        // 実装
    }
}

const MAX_BUFFER_SIZE: usize = 256;
```

### Swift（iOS）

- **SwiftFormat**: Xcodeの自動フォーマット
- **SwiftLint**: 可能であれば使用
- **命名規則**:
  - 変数・関数: `camelCase`
  - 型・クラス: `PascalCase`
  - 定数: `camelCase`

**例**:

```swift
// 良い例
class ProfileManager {
    private var currentProfile: Profile?

    func switchProfile(to profileId: String) {
        // 実装
    }
}
```

### Kotlin（Android）

- **Ktlint**: `./gradlew ktlintCheck`
- **命名規則**:
  - 変数・関数: `camelCase`
  - クラス: `PascalCase`
  - 定数: `SCREAMING_SNAKE_CASE`

**例**:

```kotlin
// 良い例
class ProfileManager {
    private var currentProfile: Profile? = null

    fun switchProfile(profileId: String) {
        // 実装
    }

    companion object {
        const val MAX_PROFILES = 10
    }
}
```

---

## コミットメッセージ規約

### フォーマット

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメントのみの変更
- `style`: コードの意味に影響しない変更（スペース、フォーマット等）
- `refactor`: リファクタリング
- `test`: テストの追加・修正
- `chore`: ビルドプロセスやツールの変更

### Scope（任意）

- `core`: Rust Core
- `ios`: iOS
- `android`: Android
- `docs`: ドキュメント
- `ci`: CI/CD

### 例

```
feat(core): add Bulgarian profile support

- Add schema_bulgarian_v1.json
- Update profile loader to include Bulgarian
- Add tests for Bulgarian input

Closes #123
```

```
fix(ios): resolve keyboard layout issue on iPad

The keyboard was not displaying correctly on iPad in landscape mode.
This fix adjusts the key sizing algorithm.

Fixes #45
```

```
docs: update iOS deployment guide

- Add troubleshooting section
- Update Xcode version requirements
```

---

## テスト

### テストの種類

#### Rust Core

```bash
cd rust_core

# ユニットテスト
cargo test

# 特定のテストのみ
cargo test test_russian_input

# カバレッジ（tarpaulinを使用）
cargo install cargo-tarpaulin
cargo tarpaulin --out Html
```

#### iOS

```bash
cd mobile/iOS

# ユニットテスト
xcodebuild test \
  -scheme CyrillicIME \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# 特定のテストのみ
xcodebuild test \
  -scheme CyrillicIME \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:CyrillicIMETests/ProfileManagerTests
```

#### Android

```bash
cd mobile/android

# ユニットテスト
./gradlew test

# Instrumentedテスト
./gradlew connectedAndroidTest

# 特定のテストのみ
./gradlew test --tests ProfileManagerTest
```

### テストカバレッジ

- **目標**: 80%以上
- 新しいコードには必ずテストを追加

---

## ドキュメント

### ドキュメントの更新

コードの変更に伴い、ドキュメントも更新してください：

1. **APIの変更**: コメント・ドキュメント文字列を更新
2. **新機能**: ユーザーガイドを更新
3. **設定の変更**: 設定ドキュメントを更新

### ドキュメントの場所

- **プロジェクト全体**: `README.md`
- **詳細ドキュメント**: `docs/` ディレクトリ
- **コード内ドキュメント**:
  - Rust: `///` または `//!`
  - Swift: `///`
  - Kotlin: `/**  */`

### ドキュメントの書き方

- 簡潔で分かりやすく
- 例を含める
- 初心者にも理解できるように
- 日本語または英語（両方歓迎）

---

## プロファイル（JSON）の追加

新しいキリル文字言語のプロファイルを追加する手順：

### 1. スキーマファイルの作成

`profiles/schemas/schema_<language>_v1.json` を作成：

```json
{
  "А": { "kana_key": "a" },
  "И": { "kana_key": "i" },
  "КА": { "kana_key": "ka" },
  "КЯ": { "kana_key": "kya" }
}
```

### 2. プロファイル定義の追加

`profiles/profiles.json` に追加：

```json
{
  "id": "bul_cyrillic",
  "name_ja": "ブルガリア語",
  "name_en": "Bulgarian",
  "keyboardLayout": ["А", "Б", "В", ...],
  "inputSchemaId": "schema_bulgarian_v1"
}
```

### 3. テストの追加

`rust_core/tests/` にテストを追加：

```rust
#[test]
fn test_bulgarian_profile() {
    let engine = ConversionEngine::new();
    engine.load_profile("bul_cyrillic").unwrap();

    let result = engine.process_key("К").unwrap();
    // テスト
}
```

### 4. ドキュメントの更新

- `README.md` の対応言語リストに追加
- `docs/` のドキュメントに言及

---

## CI/CDパイプライン

プルリクエストを作成すると、以下のチェックが自動実行されます：

1. **Rust Core Tests**: `cargo test`
2. **iOS Tests**: Xcode Build & Test
3. **Android Tests**: Gradle Test
4. **Documentation Lint**: Markdownのチェック
5. **Security Scan**: 脆弱性スキャン

これらのチェックが全てパスする必要があります。

---

## コミュニティ

### 質問・議論

- **GitHub Discussions**: 一般的な質問・議論
- **GitHub Issues**: バグ報告・機能提案
- **Pull Requests**: コードレビュー

### サポート

問題がある場合は、遠慮なくIssueを作成してください。

---

## ライセンス

このプロジェクトに貢献することで、あなたのコントリビューションは[MIT License](LICENSE)の下でライセンスされることに同意したものとみなされます。

---

## 謝辞

コントリビューターの皆様に感謝します！

---

**最終更新**: 2025-11-06
