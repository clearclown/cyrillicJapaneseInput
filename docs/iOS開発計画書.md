# iOS開発計画書 (v1.1)

**更新履歴**:
- v1.1 (2024年11月): FFI関数の戻り値型を更新（エラーメッセージ返却方式に変更）、JSONファイル名を `japaneseKanaEngine.json` に統一
- v1.0: 初版

## 1. プロジェクト概要

### 1.1. 目的
キリル文字配列を用いて日本語（ひらがな）を入力するiOS向けカスタムキーボード拡張機能を開発する。
Rust CoreエンジンとSwift UIを統合し、ネイティブIMEに匹敵するパフォーマンスと優れたUXを提供する。

### 1.2. ターゲット
- iOS 16.0以降
- iPhone / iPad (ユニバーサルアプリ)
- iPadOSのステージマネージャー対応

---

## 2. アーキテクチャ設計

### 2.1. プロジェクト構成

```
mobile/iOS/
├── CyrillicIME.xcodeproj/          # Xcodeプロジェクトファイル
├── CyrillicIME/                     # メインアプリ（設定UI）
│   ├── App/
│   │   ├── CyrillicIMEApp.swift    # アプリエントリーポイント
│   │   └── AppDelegate.swift       # アプリライフサイクル管理
│   ├── Views/
│   │   ├── ProfileSelectionView.swift   # プロファイル選択画面
│   │   ├── TutorialView.swift           # 使い方チュートリアル
│   │   └── AboutView.swift              # アプリ情報画面
│   ├── ViewModels/
│   │   └── ProfileViewModel.swift       # プロファイル管理ロジック
│   └── Resources/
│       ├── Assets.xcassets/             # アセット（アイコン等）
│       └── Localizable.strings          # 多言語対応文字列
├── CyrillicKeyboard/                # キーボード拡張機能
│   ├── KeyboardViewController.swift     # キーボードUI制御
│   ├── Views/
│   │   ├── KeyboardView.swift           # キーボードレイアウトUI
│   │   ├── KeyButton.swift              # 個別キーボタン
│   │   ├── ProfileIndicator.swift       # プロファイル表示インジケーター
│   │   └── CandidateBar.swift           # 変換候補表示バー（OS連携）
│   ├── Engine/
│   │   ├── RustCoreFFI.swift            # Rust Core FFIブリッジ
│   │   ├── InputBuffer.swift            # 入力バッファ管理（Swift側状態）
│   │   └── ProfileManager.swift         # プロファイル切替ロジック
│   ├── Models/
│   │   ├── Profile.swift                # プロファイルデータモデル
│   │   ├── KeyLayout.swift              # キーレイアウトモデル
│   │   └── ConversionResult.swift       # 変換結果モデル
│   └── Resources/
│       └── profiles/                    # JSONスキーマ（バンドル）
│           ├── profiles.json
│           ├── japaneseKanaEngine.json
│           └── schemas/
├── CyrillicIMECore/                 # Rust Coreライブラリ統合
│   ├── libcyrillic_ime_core.xcframework/  # Rustビルド成果物
│   └── bridge.h                           # C言語ヘッダ（FFI定義）
├── CyrillicIMETests/                # ユニットテスト
│   ├── ProfileManagerTests.swift
│   ├── RustCoreFFITests.swift
│   └── KeyboardLogicTests.swift
└── CyrillicIMEUITests/              # UIテスト
    └── KeyboardIntegrationTests.swift
```

### 2.2. 技術スタック

| レイヤー | 技術 | 用途 |
|---------|------|------|
| UI | SwiftUI | プロファイル選択画面、設定UI |
| Keyboard | UIKit (UIInputViewController) | キーボード拡張機能（iOS標準API） |
| State | Combine / @Observable | 状態管理、リアクティブUI更新 |
| Core | Rust (FFI) | 変換ロジック、スキーマパース |
| Storage | UserDefaults (App Group) | プロファイル選択状態の共有 |
| Build | Swift Package Manager | 依存管理 |
| CI/CD | Xcode Cloud / GitHub Actions | 自動ビルド・テスト |

### 2.3. Rust Core統合戦略

#### 2.3.1. ビルドプロセス
```bash
# Rust Core を iOS向けにクロスコンパイル
cd rust_core
cargo install cargo-lipo
cargo lipo --release  # arm64, x86_64 (simulator) の Universal Binary 生成

# XCFramework 作成
xcodebuild -create-xcframework \
  -library target/universal/release/libcyrillic_ime_core.a \
  -headers include/ \
  -output ../mobile/iOS/CyrillicIMECore/libcyrillic_ime_core.xcframework
```

#### 2.3.2. FFIブリッジ設計
```swift
// RustCoreFFI.swift
import Foundation

// C言語インターフェース（bridge.hで定義）
// 戻り値: null = 成功, non-null = エラーメッセージ（rust_free_stringで解放が必要）
@_silgen_name("rust_init_engine")
func rust_init_engine(_ profiles_json: UnsafePointer<CChar>, _ kana_engine_json: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?

@_silgen_name("rust_load_schema")
func rust_load_schema(_ schema_json: UnsafePointer<CChar>, _ schema_id: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?

@_silgen_name("rust_process_key")
func rust_process_key(_ cyrillic_key: UnsafePointer<CChar>, _ current_buffer: UnsafePointer<CChar>, _ profile_id: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?

@_silgen_name("rust_free_string")
func rust_free_string(_ ptr: UnsafeMutablePointer<CChar>)

@_silgen_name("rust_get_version")
func rust_get_version() -> UnsafePointer<CChar>?

// Swift ラッパークラス
class RustCoreFFI {
    static let shared = RustCoreFFI()
    private var isInitialized = false

    /// エンジンを初期化
    /// - Returns: 成功時はnil、エラー時はエラーメッセージ
    func initEngine(profilesJSON: String, kanaEngineJSON: String) -> String? {
        guard !isInitialized else {
            return "Engine already initialized"
        }

        let errorPtr = profilesJSON.withCString { profilesPtr in
            kanaEngineJSON.withCString { kanaPtr in
                rust_init_engine(profilesPtr, kanaPtr)
            }
        }

        // null = 成功, non-null = エラーメッセージ
        if let errorMessage = consumeRustString(errorPtr) {
            return errorMessage
        }

        isInitialized = true
        return nil
    }

    /// スキーマをロード
    func loadSchema(schemaJSON: String, schemaId: String) -> String? {
        guard isInitialized else {
            return "Engine not initialized"
        }

        let errorPtr = schemaJSON.withCString { schemaPtr in
            schemaId.withCString { idPtr in
                rust_load_schema(schemaPtr, idPtr)
            }
        }

        return consumeRustString(errorPtr)
    }

    /// キー入力を処理
    func processKey(cyrillicKey: String, currentBuffer: String, profileId: String) -> ConversionResult? {
        guard isInitialized else { return nil }

        let jsonPtr = cyrillicKey.withCString { keyPtr in
            currentBuffer.withCString { bufferPtr in
                profileId.withCString { profilePtr in
                    rust_process_key(keyPtr, bufferPtr, profilePtr)
                }
            }
        }

        guard let jsonString = consumeRustString(jsonPtr) else { return nil }
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }

        return try? JSONDecoder().decode(ConversionResult.self, from: jsonData)
    }

    /// Rustから返されたC文字列をSwift Stringに変換してメモリ解放
    private func consumeRustString(_ ptr: UnsafeMutablePointer<CChar>?) -> String? {
        guard let ptr = ptr else { return nil }
        defer { rust_free_string(ptr) }
        return String(cString: ptr)
    }
}
```

**注意**:
- `rust_init_engine` と `rust_load_schema` は、成功時は `null`、失敗時はエラーメッセージのC文字列を返します。
- エラーメッセージは `rust_free_string` で解放する必要があります。
- この設計により、詳細なエラー情報を取得できるようになりました（2024年11月修正）。

---

## 3. コンポーネント詳細設計

### 3.1. ProfileManager（プロファイル管理）

**責務**：
- `profiles.json` の読み込みとパース
- ユーザー選択プロファイルの永続化（App Group共有）
- プロファイル切替時の通知

**実装方針**：
```swift
@Observable
class ProfileManager {
    static let shared = ProfileManager()

    private let appGroupId = "group.com.yourcompany.cyrillicime"
    private var userDefaults: UserDefaults

    private(set) var profiles: [Profile] = []
    var currentProfile: Profile? {
        didSet {
            saveCurrentProfileId()
            NotificationCenter.default.post(name: .profileDidChange, object: currentProfile)
        }
    }

    func loadProfiles() throws {
        guard let url = Bundle.main.url(forResource: "profiles", withExtension: "json") else {
            throw ProfileError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        self.profiles = try JSONDecoder().decode([Profile].self, from: data)
    }

    func loadCurrentProfile() {
        let savedId = userDefaults.string(forKey: "currentProfileId") ?? "rus_standard"
        currentProfile = profiles.first { $0.id == savedId }
    }

    private func saveCurrentProfileId() {
        userDefaults.set(currentProfile?.id, forKey: "currentProfileId")
    }
}
```

### 3.2. KeyboardViewController（キーボードUI制御）

**責務**：
- キーボードUIのライフサイクル管理
- キータップイベントのハンドリング
- Rust Coreへのキー入力転送
- OS（UITextDocumentProxy）への出力

**状態機械**：
```
[Idle] --[Key Tap]--> [Processing] --[Rust Core Call]--> [Result Received]
  ^                                                              |
  |                                                              v
  +----[Insert to Proxy]<----[Buffer Update?]<----[Parse Result]
```

**実装骨子**：
```swift
class KeyboardViewController: UIInputViewController {
    private var keyboardView: KeyboardView!
    private var profileManager = ProfileManager.shared
    private var inputBuffer = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Rust Core 初期化
        initializeRustCore()

        // キーボードUI構築
        setupKeyboardView()

        // プロファイル変更通知監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(profileDidChange),
            name: .profileDidChange,
            object: nil
        )
    }

    private func initializeRustCore() {
        let profilesJson = loadBundledJSON("profiles")
        let kanaEngineJson = loadBundledJSON("japaneseKanaEngine")

        if let error = RustCoreFFI.shared.initEngine(
            profilesJSON: profilesJson,
            kanaEngineJSON: kanaEngineJson
        ) {
            fatalError("Failed to initialize Rust Core: \(error)")
        }
    }

    @objc private func handleKeyTap(_ key: String) {
        guard let profile = profileManager.currentProfile else { return }

        // Rust Coreで変換処理
        guard let result = RustCoreFFI.shared.processKey(
            cyrillicKey: key,
            currentBuffer: inputBuffer,
            profileId: profile.id
        ) else { return }

        // 結果に応じて処理
        switch result.action {
        case "commit":
            if !result.output.isEmpty {
                textDocumentProxy.insertText(result.output)
            }
            inputBuffer = result.buffer

        case "composing":
            inputBuffer = result.buffer
            // 入力中の文字列表示（必要に応じて実装）

        case "clear":
            inputBuffer = ""

        default:
            break
        }
    }

    @objc private func profileDidChange() {
        // UIを再描画（新しいプロファイルのキーレイアウトを反映）
        keyboardView.updateLayout(profile: profileManager.currentProfile)
    }
}
```

### 3.3. KeyboardView（キーボードレイアウトUI）

**レスポンシブデザイン**：
- iPhone SE (320pt幅) 〜 iPad Pro (1024pt幅) 対応
- Safe Area対応（ホームインジケーター回避）
- ダークモード対応

**キー配置アルゴリズム**：
```
Row 1: 10キー（数字行）
Row 2: プロファイル依存（例: А Б В Г Д Е Ё Ж З И）
Row 3: プロファイル依存（例: Й К Л М Н О П Р С Т）
Row 4: プロファイル依存（例: У Ф Х Ц Ч Ш Щ Ъ Ы Ь）
Row 5: Shift, 濁点, Space, Profile Switcher, Backspace, Enter
```

---

## 4. 開発フェーズ計画

### Phase 1: Rust Core統合（Week 1-2）
- [ ] Rust Coreの基本FFIインターフェース実装
- [ ] `cargo-lipo`によるiOSビルドパイプライン構築
- [ ] XCFramework生成スクリプト作成
- [ ] Swift側FFIブリッジ実装
- [ ] 単体テスト（ProfileManagerTests, RustCoreFFITests）

**成果物**：
- `rust_core/src/ffi.rs`（FFIエクスポート関数）
- `mobile/iOS/CyrillicIMECore/libcyrillic_ime_core.xcframework`
- `mobile/iOS/CyrillicKeyboard/Engine/RustCoreFFI.swift`

**Commit例**：
```
feat(ios): Add Rust Core FFI bridge and XCFramework integration
- Implement C-compatible FFI functions in rust_core/src/ffi.rs
- Create iOS universal binary build script (build_ios.sh)
- Add Swift FFI wrapper (RustCoreFFI.swift)
- Bundle JSON schemas in keyboard extension
```

### Phase 2: キーボード拡張機能実装（Week 3-4）
- [ ] UIInputViewController基本実装
- [ ] KeyboardView UIレイアウト構築
- [ ] KeyButtonタップハンドリング
- [ ] ProfileManager統合
- [ ] 入力バッファ管理ロジック

**成果物**：
- `mobile/iOS/CyrillicKeyboard/KeyboardViewController.swift`
- `mobile/iOS/CyrillicKeyboard/Views/KeyboardView.swift`

**Commit例**：
```
feat(ios): Implement keyboard extension with profile switching
- Create KeyboardViewController with Rust Core integration
- Build responsive KeyboardView supporting iPhone/iPad
- Add ProfileIndicator for visual profile feedback
- Implement input buffer state management
```

### Phase 3: メインアプリ（設定UI）実装（Week 5）
- [ ] SwiftUIベースのプロファイル選択画面
- [ ] App GroupによるKeyboard Extensionとのデータ共有
- [ ] チュートリアル画面（初回起動時）
- [ ] アプリ情報画面

**成果物**：
- `mobile/iOS/CyrillicIME/Views/ProfileSelectionView.swift`

**Commit例**：
```
feat(ios): Add main app with profile selection UI
- Build ProfileSelectionView with SwiftUI
- Implement App Group data sharing with keyboard extension
- Create onboarding tutorial for first-time users
```

### Phase 4: パフォーマンス最適化とテスト（Week 6）
- [ ] キータップレイテンシ計測（目標: 16ms以下）
- [ ] メモリリーク検査（Instruments）
- [ ] UIテスト自動化（XCUITest）
- [ ] アクセシビリティ対応（VoiceOver）

**Commit例**：
```
test(ios): Add comprehensive test suite and performance optimization
- Implement XCUITest for keyboard integration testing
- Add latency benchmarks (avg: 12ms per keystroke)
- Fix memory leak in RustCoreFFI string handling
- Add VoiceOver labels for accessibility
```

### Phase 5: App Store準備（Week 7）
- [ ] アプリアイコン作成（1024x1024）
- [ ] スクリーンショット撮影（全デバイスサイズ）
- [ ] App Store説明文作成（日本語・英語）
- [ ] Privacy Manifest作成
- [ ] TestFlight配布（内部テスト）

---

## 5. 技術的課題と対策

### 5.1. キーボード拡張機能の制約
**課題**：iOS Keyboard Extensionはメモリ使用量が厳しく制限される（約50MB）。
**対策**：
- Rust Coreのバイナリサイズ最小化（`strip`, `opt-level="z"`）
- JSONスキーマのメモリ展開を遅延ロード
- 未使用プロファイルのスキーマはアンロード

### 5.2. Full Accessパーミッション問題
**課題**：ネットワークアクセス不要だが、ユーザーに「フルアクセス」許可を求めるとプライバシー懸念が生じる。
**対策**：
- App Store説明文で「完全オフライン動作」を明記
- ネットワーク通信を一切含まないコードであることを証明（Privacy Manifest）

### 5.3. Rust Panic処理
**課題**：Rust側でpanicが発生すると、キーボード拡張全体がクラッシュする。
**対策**：
```rust
// rust_core/src/ffi.rs
#[no_mangle]
pub extern "C" fn rust_process_key(...) -> *const c_char {
    match std::panic::catch_unwind(|| {
        // 実際の処理
    }) {
        Ok(result) => result,
        Err(_) => {
            // エラー時はnullを返し、Swift側でフォールバック処理
            std::ptr::null()
        }
    }
}
```

---

## 6. ビルドコマンド一覧

### 開発ビルド
```bash
# Rust Coreビルド（iOS向け）
cd rust_core
./build_ios.sh

# Xcodeでキーボード拡張をビルド
cd ../mobile/iOS
xcodebuild -scheme CyrillicIME -configuration Debug -sdk iphonesimulator
```

### リリースビルド
```bash
# Rust Coreリリースビルド
cd rust_core
./build_ios.sh --release

# Xcodeでアーカイブ作成
cd ../mobile/iOS
xcodebuild -scheme CyrillicIME -configuration Release -archivePath build/CyrillicIME.xcarchive archive
xcodebuild -exportArchive -archivePath build/CyrillicIME.xcarchive -exportPath build/ -exportOptionsPlist ExportOptions.plist
```

### テスト実行
```bash
# ユニットテスト
xcodebuild test -scheme CyrillicIME -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# UIテスト
xcodebuild test -scheme CyrillicIMEUITests -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

## 7. Git運用方針

### ブランチ戦略
```
main
 └── feature/integration
      └── ios/develop (iOS開発メインブランチ)
           ├── ios/phase1-rust-ffi
           ├── ios/phase2-keyboard-ui
           ├── ios/phase3-main-app
           └── ios/phase4-testing
```

### Commit規約
```
<type>(ios): <subject>

<body>

<footer>
```

**Type**:
- `feat`: 新機能追加
- `fix`: バグ修正
- `refactor`: リファクタリング
- `test`: テスト追加
- `docs`: ドキュメント更新
- `build`: ビルドシステム変更

**例**:
```
feat(ios): Implement Serbian profile keyboard layout

- Add Њ, Љ, Ђ, Ћ, Џ special key rendering
- Update KeyboardView to support 30-key Serbian layout
- Test on iPhone SE (cramped layout) and iPad Pro

Closes #12
```

### 定期的なPush
各論理的な作業単位（1機能、1バグ修正）ごとにcommit + pushを実行：
```bash
git add mobile/iOS/CyrillicKeyboard/Views/KeyboardView.swift
git commit -m "feat(ios): Build responsive KeyboardView with dynamic key sizing"
git push origin ios/phase2-keyboard-ui
```

---

## 8. 成功基準

### パフォーマンス
- [ ] キータップ → ひらがな挿入までのレイテンシ: 平均16ms以下（60fps維持）
- [ ] メモリ使用量: 40MB以下（iOS Keyboard Extension制限内）
- [ ] バッテリー消費: システムキーボードとの差異±5%以内

### 品質
- [ ] ユニットテストカバレッジ: 80%以上
- [ ] クラッシュフリー率: 99.9%以上（TestFlight期間）
- [ ] App Store審査一発合格

### UX
- [ ] プロファイル切替: 2タップ以内
- [ ] VoiceOver完全対応
- [ ] ダークモード完全対応

---

## 9. App Store Connect 申請用説明文

### 9.1. アプリ基本情報

**アプリ名（App Name）**:
- 日本語: `PISMO (Письмо)`
- 英語: `PISMO (Письмо)`

**サブタイトル（Subtitle）**:
- 日本語: `キリル文字で日本語入力`
- 英語: `Type Japanese with Cyrillic`

**バンドルID（Bundle Identifier）**: `com.yourcompany.cyrillicime`
- メインアプリ: `com.yourcompany.cyrillicime`
- キーボード拡張: `com.yourcompany.cyrillicime.keyboard`

**カテゴリ（Primary Category）**: `Utilities`
**カテゴリ（Secondary Category）**: `Education`

### 9.2. アプリ説明文（日本語版）

**タイトル**: PISMO - キリル文字で日本語を書く

**説明文（4,000文字以内）**:

```
PISMO（Письмо、Писмо、Письмо）は、キリル文字キーボード配列を用いて日本語（ひらがな）を入力する、革新的なiOSカスタムキーボードです。

【特徴】
✨ キリル文字で日本語を書く
ロシア語、セルビア語、ウクライナ語など、様々なキリル文字配列を使って、日本語のひらがなを入力できます。キリル文字を学習中の方や、言語学に興味のある方に最適です。

🌍 複数のプロファイル対応
・ロシア語標準配列
・セルビア語配列（Њ, Љ, Ђ, Ћ, Џ対応）
・ウクライナ語配列
・ロシア語分析モード

各プロファイルは、設定画面から簡単に切り替えられます。キーボード上にもプロファイル表示があり、現在の配列を常に確認できます。

⚡ 高速で正確な変換
Rust Coreエンジンによる、高パフォーマンスな変換処理を実現。OS標準の日本語キーボードと同等のレスポンス性を提供します。

🔒 完全オフライン動作
すべてのデータは端末内に保存されており、インターネット接続は一切不要です。プライバシーを完全に保護します。

📱 iPhone・iPad対応
ユニバーサルアプリとして、iPhoneとiPadの両方で最適化された表示を提供します。iPadの大きな画面でも快適に利用できます。

【使い方】
1. アプリを開いて、システム設定でキーボードを有効化します
2. プロファイル（ロシア語、セルビア語など）を選択します
3. 任意のアプリでキーボードを切り替えて、キリル文字で日本語を入力開始！

【技術仕様】
・正規化マッピング方式により、将来的な拡張が容易
・プロファイル追加は、スキーマファイル1つの追加のみで完了
・メモリ効率的な遅延ロード方式を採用

【プライバシー】
・ネットワークアクセス: なし
・データ収集: なし
・外部送信: なし
完全にオフラインで動作するため、入力データが外部に送信されることは一切ありません。

【対象ユーザー】
・キリル文字を学習している方
・言語学・文字体系に興味のある方
・新しい入力方法を試したい方
・日本語入力の多様性を体験したい方

キリル文字と日本語をつなぐ、新しい体験をお楽しみください。

PISMO（Письмо）= 文字、書くこと、コミュニケーション
```

### 9.3. アプリ説明文（英語版）

**Title**: PISMO - Write Japanese with Cyrillic

**Description (up to 4,000 characters)**:

```
PISMO (Письмо, Писмо, Письмо) is an innovative iOS custom keyboard that allows you to type Japanese hiragana using Cyrillic keyboard layouts.

【Features】
✨ Type Japanese with Cyrillic
Use Russian, Serbian, Ukrainian, and other Cyrillic keyboard layouts to input Japanese hiragana characters. Perfect for Cyrillic language learners and linguistics enthusiasts.

🌍 Multiple Profile Support
・Russian Standard Layout
・Serbian Layout (supporting Њ, Љ, Ђ, Ћ, Џ)
・Ukrainian Layout
・Russian Analytical Mode

Switch between profiles easily from the settings screen. Visual profile indicator on the keyboard always shows your current layout.

⚡ Fast and Accurate Conversion
Powered by a high-performance Rust Core engine, providing response time comparable to iOS native Japanese keyboard.

🔒 Fully Offline Operation
All data is stored locally on your device. No internet connection required. Complete privacy protection.

📱 iPhone & iPad Support
Universal app optimized for both iPhone and iPad. Enjoy comfortable typing on iPad's larger screen.

【How to Use】
1. Open the app and enable the keyboard in System Settings
2. Select your profile (Russian, Serbian, etc.)
3. Switch to PISMO keyboard in any app and start typing Japanese with Cyrillic!

【Technical Specifications】
・Normalized mapping architecture for easy future expansion
・Adding new profiles requires only adding one schema file
・Memory-efficient lazy loading system

【Privacy】
・Network Access: None
・Data Collection: None
・External Transmission: None
Completely offline operation ensures your input data never leaves your device.

【Target Users】
・Cyrillic language learners
・Linguistics and writing system enthusiasts
・Users who want to try new input methods
・Those interested in experiencing the diversity of Japanese input

Experience the new connection between Cyrillic and Japanese.

PISMO (Письмо) = writing, letter, communication
```

### 9.4. キーワード

**キーワード（Keywords）**（100文字以内）:
```
キリル文字,日本語入力,ロシア語,セルビア語,ウクライナ語,IME,キーボード,ひらがな,多言語,言語学習,キリル,Cyrillic,Japanese,input,keyboard,hiragana,Russian,Serbian,Ukrainian
```

### 9.5. プロモーション用テキスト

**プロモーション用テキスト（Promotional Text）**（170文字以内）:

**日本語版**:
```
キリル文字で日本語を書く、革新的なカスタムキーボード。ロシア語・セルビア語・ウクライナ語の配列に対応。完全オフライン動作でプライバシー保護。無料。
```

**英語版**:
```
Innovative custom keyboard to type Japanese with Cyrillic. Supports Russian, Serbian, and Ukrainian layouts. Fully offline for privacy. Free.
```

### 9.6. プライバシー説明（Privacy Description）

**プライバシー説明（日本語版）**:

```
【データ収集】
本アプリは、いかなるデータも収集しません。

【ネットワークアクセス】
本アプリは、ネットワークアクセス権限を一切要求しません。完全にオフラインで動作します。

【データ送信】
入力データ、位置情報、個人情報など、あらゆるデータを外部に送信することはありません。

【必要な権限】
・「フルアクセス」: カスタムキーボード拡張機能の動作に必要です。この権限は、システムがキーボード拡張機能に要求する標準的な権限であり、本アプリではネットワークアクセスには使用しません。

【プライバシーポリシー】
本アプリは完全にオフラインで動作し、ユーザーの入力データを外部に送信することは一切ありません。すべてのデータは端末内で処理され、インターネットへの接続は行いません。
```

**プライバシー説明（英語版）**:

```
【Data Collection】
This app does not collect any data.

【Network Access】
This app does not request any network access permissions. It operates completely offline.

【Data Transmission】
We do not transmit any data externally, including input data, location information, or personal information.

【Required Permissions】
・"Full Access": Required for custom keyboard extension functionality. This is a standard permission required by the system for keyboard extensions. This app does not use this permission for network access.

【Privacy Policy】
This app operates completely offline and does not transmit user input data externally. All data is processed on-device, and no internet connection is established.
```

### 9.7. App Store カテゴリ設定

**Primary Category**: Utilities
**Secondary Category**: Education

**App Age Rating**: 4+ (Everyone)

**理由**:
- 教育的な価値がある（キリル文字学習、言語学）
- ユーティリティ機能（カスタムキーボード）
- 不適切なコンテンツを含まない
- データ収集・広告なし

### 9.8. レビュー用ノート（Review Notes）

**レビュー用ノート（Review Notes）**（日本語・英語）:

```
【日本語】
テスト用アカウント情報:
- なし（オフライン動作のため、アカウントは不要です）

テスト方法:
1. アプリをインストール後、「設定」→「一般」→「キーボード」→「キーボードを追加」で「PISMO」を選択してください
2. 「フルアクセスを許可」を有効化してください（プライバシー説明参照）
3. 任意のアプリ（メモ帳など）を開き、キーボードを切り替えて「PISMO」を選択してください
4. キリル文字キーを入力すると、日本語のひらがなが表示されます

【English】
Test Account Information:
- None (no account required as the app operates offline)

Testing Instructions:
1. After installing the app, go to Settings → General → Keyboard → Keyboards → Add New Keyboard and select "PISMO"
2. Enable "Allow Full Access" (see Privacy Description)
3. Open any app (e.g., Notes) and switch to the "PISMO" keyboard
4. Type Cyrillic keys to see Japanese hiragana output
```

### 9.9. スクリーンショット推奨内容

**必須スクリーンショット**:

1. **メイン画面（設定画面）**
   - プロファイル選択画面
   - 各プロファイル（ロシア語、セルビア語、ウクライナ語）の一覧表示

2. **キーボード画面（実使用例）**
   - iPhone向け: キーボード表示、入力例（例: "ア" → "А"）
   - iPad向け: キーボード表示、大きな画面でのレイアウト

3. **変換デモ画面**
   - キリル文字入力 → ひらがな変換の流れを表示
   - 複数文字の組み合わせ例（例: "КЯ" → "きゃ"）

4. **プロファイル切替デモ**
   - プロファイルインジケーター
   - 切り替えの簡単さを示す

**スクリーンショットサイズ要件**:
- iPhone 6.7インチ（iPhone 14 Pro Max等）: 1290 x 2796 pixels
- iPhone 6.5インチ（iPhone 11 Pro Max等）: 1242 x 2688 pixels
- iPhone 5.5インチ（iPhone 8 Plus等）: 1242 x 2208 pixels
- iPad Pro 12.9インチ: 2048 x 2732 pixels

### 9.10. 申請時のチェックリスト

**必須項目**:
- [ ] アプリアイコン（1024×1024 pixels, PNG形式、透明度なし）
- [ ] スクリーンショット（最低3枚、推奨5枚以上）
- [ ] アプリ説明文（日本語・英語）
- [ ] プライバシー説明
- [ ] Privacy Manifest（Info.plistに追加）
- [ ] 年齢レーティング設定（4+）
- [ ] カテゴリ設定（Utilities / Education）
- [ ] TestFlightテスト（内部テストで動作確認）

**オプション項目**:
- [ ] App Preview（動画、30秒以内）
- [ ] ローカライゼーション（他の言語への対応）
- [ ] サポートURL（ウェブサイトがあれば）
- [ ] マーケティングURL（プレスリリース等）

---

## 10. 参考資料

- [Creating a Custom Keyboard - Apple Developer](https://developer.apple.com/documentation/uikit/keyboards_and_input/creating_a_custom_keyboard)
- [The Rust FFI Omnibus](http://jakegoulding.com/rust-ffi-omnibus/)
- [cargo-lipo Documentation](https://github.com/TimNN/cargo-lipo)
