# Cyrillic IME for Japanese

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/example/cyrillic-ime)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

キリル文字配列を用いて日本語（ひらがな）を入力するための、クロスプラットフォームIME（インプット・メソッド・エディタ）。

## 1. 思想と目的 (Philosophy & Purpose)

本プロジェクトは、単なる日本語入力ツールではない。これは、**「キリル文字は単一の文化圏の所有物ではなく、多様な言語的文脈で適応・進化したインターフェースである」**という事実を、入力体験そのものを通じて実証する試みである。

* **学習の促進**: 日本語話者がキリル文字（ロシア語、セルビア語、ウクライナ語など）のキー配列を学習するためのツールとして機能する。
* **多様性の実証**: ユーザーが「言語プロファイル」を切り替える（例: ロシア語 $\rightarrow$ セルビア語）ことで、同じ「ち (`[chi]`)」の音を入力するために押すキーが `ЧИ` から `Ћ` に変わる体験を通じ、文字体系の多様性を体感させる。

## 2. 特徴 (Features)

* **多プロファイル対応**: ロシア語、セルビア語、ウクライナ語、分析モードなど、複数のキリル文字配列（スキーマ）を動的に切り替え可能。
* **ハイブリッド・ネイティブアーキテクチャ**: 変換ロジック（Core）を **Rust** で記述し、UI（Shell）を **Swift (iOS)** と **Kotlin (Android)** で実装。これにより、ネイティブ同等のパフォーマンスとロジックの保守性（DRY原則）を両立する。
* **完全オフライン動作**: 全ての変換ロジック（JSONスキーマ）はアプリ本体に同梱（ネイティブ・バンドル）。インストール後は一切のネットワーク通信を必要としない。
* **ハイパフォーマンス**: 入力バッファ管理と変換ロジックは全てメモリ上で完結し、ネイティブIMEに匹敵する低遅延（Low Latency）を実現する。

## 3. 技術スタック (Tech Stack)

* **Core Engine**: **Rust**
    * `serde_json`: 変換スキーマ（JSON）のパースとメモリ展開。
    * `HashMap`: メモリ上での高速な辞書ルックアップ。
* **iOS**: **Swift** (SwiftUI / UIKit)
    * `UIInputViewController`: iOSキーボード拡張機能。
    * `Swift Package Manager`: Rustコアライブラリ（`.xcframework`）の連携。
* **Android**: **Kotlin** (Jetpack Compose / XML)
    * `InputMethodService`: Androidキーボードサービス。
    * `JNI (Java Native Interface)`: Rustコアライブラリ（`.so`）の連携。

## 4. プロジェクト開発状況 (Development Status)

### 📊 ブランチ構成

| ブランチ | 状態 | 説明 | 最終更新 |
|---------|------|------|---------|
| `main` | ✅ 安定版 | メインブランチ（ドキュメント・設計書） | - |
| `feature/integration` | ✅ 完了 | Rust Core + プロファイル統合 | Phase 1 完了 |
| `mobile/iOS` | ✅ 実装完了 | iOS アプリ実装（テストあり） | Phase 2 完了 |
| `mobile/android` | ✅ 実装完了 | Android アプリ実装（テストあり） | Phase 3 完了 |

### 🎯 Phase別の達成状況

#### Phase 1: Rust Core エンジン開発 ✅
**ブランチ**: `feature/integration`

**完了項目**:
- ✅ 変換エンジン実装（`rust_core/src/engine.rs`）
- ✅ キリル文字→かな変換ロジック
- ✅ プロファイル管理システム
- ✅ JSONスキーマパーサー（ロシア語、セルビア語、ウクライナ語対応）
- ✅ 83個のユニットテスト（全てパス）
- ✅ FFI/JNI インターフェース

**テスト結果**:
```
running 83 tests
test result: ok. 83 passed; 0 failed
```

#### Phase 2: iOS アプリ開発 ✅
**ブランチ**: `mobile/iOS`

**完了項目**:
- ✅ SwiftUI ベースのメインアプリ（設定画面）
- ✅ Keyboard Extension（UIInputViewController）
- ✅ Rust Core FFI ブリッジ（`RustCoreFFI.swift`）
- ✅ プロファイル管理（`ProfileManager.swift`）
- ✅ キーボードUI（`CyrillicKeyboardView.swift`）
- ✅ 862行のテストコード（XCTest）
- ✅ ビルドスクリプト（`rust_core/build_ios.sh`）
- ✅ 詳細なセットアップガイド（`XCODE_SETUP.md`）

**状態**: コード実装は完了。Xcodeプロジェクトファイルは手動作成が必要。

#### Phase 3: Android アプリ開発 ✅
**ブランチ**: `mobile/android`

**完了項目**:
- ✅ Jetpack Compose ベースのメインアプリ
- ✅ InputMethodService（`CyrillicInputMethodService.kt`）
- ✅ Rust Core JNI ブリッジ（`NativeLib.kt`）
- ✅ プロファイル管理（`ProfileManager.kt`）
- ✅ キーボードUI（`KeyboardView.kt` - Compose）
- ✅ 24個のテスト（Unit + Instrumented）
- ✅ Gradleビルド設定（3モジュール構成）
- ✅ ビルドスクリプト（`rust_core/build_android.sh`）

**モジュール構成**:
- `app`: メインアプリ（設定UI）
- `ime`: IMEサービス実装
- `core`: Rust Core JNI ラッパー

### 🔄 CI/CD 状況

**GitHub Actions**: ✅ 設定済み（`.github/workflows/`）

| ワークフロー | 対象 | トリガー | 状態 |
|-------------|------|---------|------|
| `rust-core-tests.yml` | Rust Core | push時 | ✅ 動作確認済み |
| `ios-tests.yml` | iOS | push時 | ✅ 設定済み |
| `android-tests.yml` | Android | push時 | ✅ 設定済み |

**実行環境**:
- Rust: `ubuntu-latest`
- iOS: `macos-latest` (GitHub hosted)
- Android: `ubuntu-latest` + Android Emulator

**コスト**: GitHub Actionsの無料枠内で運用可能（詳細は`docs/iOS開発環境コスト比較.md`）

### 📂 プロジェクト構造

```
cyrillicJapaneseInput/
├── rust_core/              # Phase 1: Rust変換エンジン ✅
│   ├── src/
│   │   ├── engine.rs       # 変換エンジン本体
│   │   ├── jni.rs          # Android JNI インターフェース
│   │   └── ffi.rs          # iOS FFI インターフェース
│   ├── tests/              # 83個のテスト
│   ├── build_ios.sh        # iOSビルドスクリプト
│   └── build_android.sh    # Androidビルドスクリプト
│
├── mobile/
│   ├── iOS/                # Phase 2: iOS実装 ✅
│   │   ├── CyrillicIME/          # メインアプリ
│   │   ├── CyrillicKeyboard/     # Keyboard Extension
│   │   ├── Shared/               # 共通モデル
│   │   ├── CyrillicIMETests/     # テスト（862行）
│   │   └── XCODE_SETUP.md        # セットアップガイド
│   │
│   └── android/            # Phase 3: Android実装 ✅
│       ├── app/                  # メインアプリ
│       ├── ime/                  # IMEサービス
│       ├── core/                 # JNIブリッジ
│       └── */src/test/           # 24個のテスト
│
├── profiles/               # 変換プロファイル ✅
│   ├── profiles.json             # プロファイル定義
│   ├── japaneseKanaEngine.json   # かなエンジン
│   └── schemas/                  # 各言語スキーマ
│       ├── russian_standard.json
│       ├── serbian_standard.json
│       └── ukrainian_standard.json
│
├── docs/                   # ドキュメント
│   ├── アプリ設計書.md
│   ├── 要件定義書.md
│   └── iOS開発環境コスト比較.md
│
├── terraform/              # インフラ（参考）
│   └── aws-macos-ec2/            # AWS macOS EC2設定（非推奨）
│
└── .github/workflows/      # CI/CD ✅
    ├── rust-core-tests.yml
    ├── ios-tests.yml
    └── android-tests.yml
```

### 🚀 次のステップ

現在、全てのコア機能の実装が完了しています。以下は任意の拡張項目です：

1. **実機テスト**
   - iOS: Xcodeプロジェクト作成 → 実機ビルド → App Store提出
   - Android: APKビルド → 実機テスト → Google Play提出

2. **UI/UX改善**
   - キーボードテーマ追加
   - 候補表示機能
   - サウンドフィードバック

3. **追加プロファイル**
   - ブルガリア語
   - モンゴル語（キリル文字）
   - カザフ語

4. **Desktop版**
   - macOS/Windows/Linux向けIME実装

## 5. ビルドとセットアップ (Build & Setup)

### Rust Core のビルド

```bash
# 依存関係のインストール
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
cargo install cargo-lipo cargo-ndk

# iOS向けビルド
cd rust_core
./build_ios.sh --release

# Android向けビルド
./build_android.sh
```

### iOS アプリのセットアップ

詳細は `mobile/iOS/XCODE_SETUP.md` を参照してください。

```bash
# Xcodeプロジェクトを作成後
cd mobile/iOS
open CyrillicIME.xcodeproj
```

### Android アプリのビルド

```bash
cd mobile/android
./gradlew assembleDebug

# テストの実行
./gradlew test                    # ユニットテスト
./gradlew connectedAndroidTest    # Instrumentedテスト
```

## 6. 貢献 (Contribution)

変換スキーマ（`schemas/*.json`）の改善、新しい言語プロファイル（例: ブルガリア語、モンゴル語）の追加、ローカルな入力方法に関するフィードバックは、GitHubのIssuesにて歓迎する。
