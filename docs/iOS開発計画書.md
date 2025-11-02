# iOS開発計画書 (v1.0)

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
@_silgen_name("rust_init_engine")
func rustInitEngine(profilesJson: UnsafePointer<CChar>, kanaEngineJson: UnsafePointer<CChar>) -> Bool

@_silgen_name("rust_process_key")
func rustProcessKey(
    key: UnsafePointer<CChar>,
    buffer: UnsafePointer<CChar>,
    profileId: UnsafePointer<CChar>
) -> UnsafePointer<CChar>?

@_silgen_name("rust_free_string")
func rustFreeString(ptr: UnsafeMutablePointer<CChar>)

// Swift ラッパークラス
class RustCoreEngine {
    static let shared = RustCoreEngine()

    func initialize(profilesJson: String, kanaEngineJson: String) -> Bool {
        return profilesJson.withCString { profilesPtr in
            kanaEngineJson.withCString { kanaPtr in
                rustInitEngine(profilesJson: profilesPtr, kanaEngineJson: kanaPtr)
            }
        }
    }

    func processKey(key: String, buffer: String, profileId: String) -> String? {
        return key.withCString { keyPtr in
            buffer.withCString { bufferPtr in
                profileId.withCString { profilePtr in
                    guard let resultPtr = rustProcessKey(
                        key: keyPtr,
                        buffer: bufferPtr,
                        profileId: profilePtr
                    ) else { return nil }

                    defer { rustFreeString(UnsafeMutablePointer(mutating: resultPtr)) }
                    return String(cString: resultPtr)
                }
            }
        }
    }
}
```

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

        guard RustCoreEngine.shared.initialize(
            profilesJson: profilesJson,
            kanaEngineJson: kanaEngineJson
        ) else {
            fatalError("Failed to initialize Rust Core")
        }
    }

    @objc private func handleKeyTap(_ key: String) {
        guard let profile = profileManager.currentProfile else { return }

        // Rust Coreで変換処理
        guard let result = RustCoreEngine.shared.processKey(
            key: key,
            buffer: inputBuffer,
            profileId: profile.id
        ) else { return }

        // 結果をパース（JSON形式: {"output": "きゃ", "buffer": "", "action": "commit"}）
        let decoded = try? JSONDecoder().decode(ConversionResult.self, from: result.data(using: .utf8)!)

        if let output = decoded?.output {
            textDocumentProxy.insertText(output)
        }

        inputBuffer = decoded?.buffer ?? ""
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

## 9. 参考資料

- [Creating a Custom Keyboard - Apple Developer](https://developer.apple.com/documentation/uikit/keyboards_and_input/creating_a_custom_keyboard)
- [The Rust FFI Omnibus](http://jakegoulding.com/rust-ffi-omnibus/)
- [cargo-lipo Documentation](https://github.com/TimNN/cargo-lipo)
