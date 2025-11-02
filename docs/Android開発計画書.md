# Android開発計画書 (v1.0)

## 1. プロジェクト概要

### 1.1. 目的
キリル文字配列を用いて日本語（ひらがな）を入力するAndroid向けIME（Input Method Editor）を開発する。
Rust CoreエンジンとKotlin/Jetpack ComposeUIを統合し、Material Design 3に準拠した高パフォーマンスな入力体験を提供する。

### 1.2. ターゲット
- Android 10.0 (API 29) 以降
- スマートフォン / タブレット / Chromebook 対応
- Foldableデバイス対応

---

## 2. アーキテクチャ設計

### 2.1. プロジェクト構成

```
mobile/android/
├── app/                                    # メインアプリモジュール（設定UI）
│   ├── src/main/
│   │   ├── kotlin/com/yourcompany/cyrillicime/
│   │   │   ├── MainActivity.kt             # アプリエントリーポイント
│   │   │   ├── ui/
│   │   │   │   ├── ProfileSelectionScreen.kt  # プロファイル選択画面
│   │   │   │   ├── TutorialScreen.kt          # チュートリアル
│   │   │   │   └── AboutScreen.kt             # アプリ情報
│   │   │   ├── viewmodel/
│   │   │   │   └── ProfileViewModel.kt        # プロファイル管理VM
│   │   │   └── CyrillicIMEApplication.kt      # Applicationクラス
│   │   ├── res/
│   │   │   ├── layout/                         # XML レイアウト（互換性）
│   │   │   ├── values/                         # 文字列、色、テーマ
│   │   │   ├── drawable/                       # アイコン、画像
│   │   │   └── xml/
│   │   │       └── method.xml                  # IME定義（システム登録用）
│   │   └── assets/
│   │       └── profiles/                       # JSONスキーマ
│   │           ├── profiles.json
│   │           ├── japaneseKanaEngine.json
│   │           └── schemas/
│   └── build.gradle.kts                        # アプリビルド設定
├── ime/                                    # IMEサービスモジュール
│   ├── src/main/
│   │   ├── kotlin/com/yourcompany/cyrillicime/ime/
│   │   │   ├── CyrillicInputMethodService.kt   # IMEサービス本体
│   │   │   ├── ui/
│   │   │   │   ├── KeyboardView.kt             # キーボードレイアウト（Compose）
│   │   │   │   ├── KeyButton.kt                # 個別キーボタン
│   │   │   │   ├── ProfileIndicator.kt         # プロファイル表示
│   │   │   │   └── CandidateView.kt            # 変換候補表示
│   │   │   ├── engine/
│   │   │   │   ├── RustCoreJNI.kt              # Rust Core JNIブリッジ
│   │   │   │   ├── InputBuffer.kt              # 入力バッファ管理
│   │   │   │   └── ProfileManager.kt           # プロファイル管理
│   │   │   ├── model/
│   │   │   │   ├── Profile.kt                  # プロファイルデータクラス
│   │   │   │   ├── KeyLayout.kt                # キーレイアウトモデル
│   │   │   │   └── ConversionResult.kt         # 変換結果
│   │   │   └── util/
│   │   │       └── HapticFeedback.kt           # 触覚フィードバック
│   │   └── res/
│   │       └── xml/
│   │           └── method.xml                  # IMEメタデータ
│   └── build.gradle.kts
├── core/                                   # Rust Coreネイティブライブラリ
│   ├── src/main/
│   │   ├── jniLibs/                            # Rustビルド成果物
│   │   │   ├── arm64-v8a/
│   │   │   │   └── libcyrillic_ime_core.so
│   │   │   ├── armeabi-v7a/
│   │   │   │   └── libcyrillic_ime_core.so
│   │   │   ├── x86/
│   │   │   │   └── libcyrillic_ime_core.so
│   │   │   └── x86_64/
│   │   │       └── libcyrillic_ime_core.so
│   │   └── kotlin/com/yourcompany/cyrillicime/core/
│   │       └── NativeLib.kt                    # JNI宣言
│   └── build.gradle.kts
├── build.gradle.kts                        # ルートビルド設定
├── settings.gradle.kts                     # モジュール設定
├── gradle.properties                       # Gradle設定
└── local.properties                        # ローカル環境設定（SDK path等）
```

### 2.2. 技術スタック

| レイヤー | 技術 | 用途 |
|---------|------|------|
| UI | Jetpack Compose | モダンな宣言的UI（設定画面、キーボードUI） |
| IME | InputMethodService | Android標準IMEフレームワーク |
| State | ViewModel + StateFlow | 状態管理、リアクティブUI |
| Core | Rust (JNI) | 変換ロジック、スキーマパース |
| Storage | SharedPreferences | プロファイル選択状態の永続化 |
| DI | Hilt (Dagger) | 依存性注入 |
| Build | Gradle (Kotlin DSL) | ビルドシステム |
| CI/CD | GitHub Actions | 自動ビルド・テスト・署名 |

### 2.3. Rust Core統合戦略

#### 2.3.1. ビルドプロセス
```bash
# Rust Core を Android向けにクロスコンパイル
cd rust_core
cargo install cargo-ndk

# 全アーキテクチャ向けにビルド
cargo ndk --target aarch64-linux-android \
          --target armv7-linux-androideabi \
          --target i686-linux-android \
          --target x86_64-linux-android \
          --platform 29 \
          build --release

# .soファイルをAndroidプロジェクトにコピー
cp target/aarch64-linux-android/release/libcyrillic_ime_core.so \
   ../mobile/android/core/src/main/jniLibs/arm64-v8a/
cp target/armv7-linux-androideabi/release/libcyrillic_ime_core.so \
   ../mobile/android/core/src/main/jniLibs/armeabi-v7a/
cp target/i686-linux-android/release/libcyrillic_ime_core.so \
   ../mobile/android/core/src/main/jniLibs/x86/
cp target/x86_64-linux-android/release/libcyrillic_ime_core.so \
   ../mobile/android/core/src/main/jniLibs/x86_64/
```

#### 2.3.2. JNIブリッジ設計
```kotlin
// NativeLib.kt (core モジュール)
package com.yourcompany.cyrillicime.core

object NativeLib {
    init {
        System.loadLibrary("cyrillic_ime_core")
    }

    @JvmStatic
    external fun initEngine(profilesJson: String, kanaEngineJson: String): Boolean

    @JvmStatic
    external fun processKey(key: String, buffer: String, profileId: String): String?

    @JvmStatic
    external fun getVersion(): String
}

// RustCoreJNI.kt (ime モジュール - ラッパークラス)
package com.yourcompany.cyrillicime.ime.engine

import com.yourcompany.cyrillicime.core.NativeLib
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
data class ConversionResult(
    val output: String,
    val buffer: String,
    val action: String  // "commit", "composing", "clear"
)

class RustCoreEngine private constructor() {
    companion object {
        val instance by lazy { RustCoreEngine() }
    }

    private val json = Json { ignoreUnknownKeys = true }

    fun initialize(profilesJson: String, kanaEngineJson: String): Boolean {
        return NativeLib.initEngine(profilesJson, kanaEngineJson)
    }

    fun processKey(key: String, buffer: String, profileId: String): ConversionResult? {
        val resultJson = NativeLib.processKey(key, buffer, profileId) ?: return null
        return try {
            json.decodeFromString<ConversionResult>(resultJson)
        } catch (e: Exception) {
            null
        }
    }
}
```

#### 2.3.3. Rust側JNIエクスポート
```rust
// rust_core/src/jni.rs
use jni::JNIEnv;
use jni::objects::{JClass, JString};
use jni::sys::jstring;

#[no_mangle]
pub extern "C" fn Java_com_yourcompany_cyrillicime_core_NativeLib_initEngine(
    mut env: JNIEnv,
    _class: JClass,
    profiles_json: JString,
    kana_engine_json: JString,
) -> jboolean {
    let profiles: String = env.get_string(&profiles_json).unwrap().into();
    let kana_engine: String = env.get_string(&kana_engine_json).unwrap().into();

    match init_engine_internal(&profiles, &kana_engine) {
        Ok(_) => JNI_TRUE,
        Err(_) => JNI_FALSE,
    }
}

#[no_mangle]
pub extern "C" fn Java_com_yourcompany_cyrillicime_core_NativeLib_processKey(
    mut env: JNIEnv,
    _class: JClass,
    key: JString,
    buffer: JString,
    profile_id: JString,
) -> jstring {
    let key_str: String = env.get_string(&key).unwrap().into();
    let buffer_str: String = env.get_string(&buffer).unwrap().into();
    let profile_id_str: String = env.get_string(&profile_id).unwrap().into();

    match process_key_internal(&key_str, &buffer_str, &profile_id_str) {
        Ok(result_json) => {
            let output = env.new_string(result_json).unwrap();
            output.into_raw()
        }
        Err(_) => std::ptr::null_mut(),
    }
}
```

---

## 3. コンポーネント詳細設計

### 3.1. CyrillicInputMethodService（IMEサービス）

**責務**：
- IMEライフサイクル管理
- キーボードビューの作成・破棄
- 入力イベントのハンドリング
- InputConnectionへのテキスト挿入

**実装骨子**：
```kotlin
class CyrillicInputMethodService : InputMethodService() {

    private lateinit var composeView: ComposeView
    private lateinit var profileManager: ProfileManager
    private var inputBuffer = mutableStateOf("")

    override fun onCreateInputView(): View {
        // Rust Core初期化
        initializeRustCore()

        // Jetpack ComposeでキーボードUIを構築
        composeView = ComposeView(this).apply {
            setContent {
                MaterialTheme {
                    KeyboardView(
                        profile = profileManager.currentProfile.collectAsState().value,
                        onKeyPress = ::handleKeyPress,
                        onProfileSwitch = { profileManager.switchProfile(it) }
                    )
                }
            }
        }

        return composeView
    }

    private fun initializeRustCore() {
        val profilesJson = assets.open("profiles/profiles.json").bufferedReader().use { it.readText() }
        val kanaEngineJson = assets.open("profiles/japaneseKanaEngine.json").bufferedReader().use { it.readText() }

        if (!RustCoreEngine.instance.initialize(profilesJson, kanaEngineJson)) {
            throw RuntimeException("Failed to initialize Rust Core")
        }
    }

    private fun handleKeyPress(key: String) {
        val profile = profileManager.currentProfile.value ?: return

        val result = RustCoreEngine.instance.processKey(
            key = key,
            buffer = inputBuffer.value,
            profileId = profile.id
        ) ?: return

        when (result.action) {
            "commit" -> {
                currentInputConnection?.commitText(result.output, 1)
                inputBuffer.value = result.buffer
            }
            "composing" -> {
                currentInputConnection?.setComposingText(result.output, 1)
                inputBuffer.value = result.buffer
            }
            "clear" -> {
                currentInputConnection?.finishComposingText()
                inputBuffer.value = ""
            }
        }

        // 触覚フィードバック
        performHapticFeedback()
    }

    private fun performHapticFeedback() {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(10, VibrationEffect.DEFAULT_AMPLITUDE))
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Rust Coreクリーンアップ（必要に応じて）
    }
}
```

### 3.2. ProfileManager（プロファイル管理）

**実装方針**：
```kotlin
@Singleton
class ProfileManager @Inject constructor(
    private val context: Context,
    private val sharedPreferences: SharedPreferences
) {
    private val _currentProfile = MutableStateFlow<Profile?>(null)
    val currentProfile: StateFlow<Profile?> = _currentProfile.asStateFlow()

    private val _profiles = MutableStateFlow<List<Profile>>(emptyList())
    val profiles: StateFlow<List<Profile>> = _profiles.asStateFlow()

    init {
        loadProfiles()
        loadCurrentProfile()
    }

    private fun loadProfiles() {
        val profilesJson = context.assets.open("profiles/profiles.json")
            .bufferedReader().use { it.readText() }

        _profiles.value = Json.decodeFromString<List<Profile>>(profilesJson)
    }

    private fun loadCurrentProfile() {
        val savedId = sharedPreferences.getString("current_profile_id", "rus_standard")
        _currentProfile.value = _profiles.value.find { it.id == savedId }
    }

    fun switchProfile(profileId: String) {
        val profile = _profiles.value.find { it.id == profileId } ?: return
        _currentProfile.value = profile

        sharedPreferences.edit()
            .putString("current_profile_id", profileId)
            .apply()
    }
}
```

### 3.3. KeyboardView（Jetpack Compose UI）

**レスポンシブデザイン**：
```kotlin
@Composable
fun KeyboardView(
    profile: Profile?,
    onKeyPress: (String) -> Unit,
    onProfileSwitch: (String) -> Unit
) {
    val configuration = LocalConfiguration.current
    val screenWidth = configuration.screenWidthDp.dp

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surface)
    ) {
        // プロファイルインジケーター
        ProfileIndicator(
            profile = profile,
            onClick = { /* プロファイル選択ダイアログを表示 */ }
        )

        // キーボードレイアウト
        profile?.let { prof ->
            val keys = prof.keyboardLayout
            val keysPerRow = when {
                screenWidth > 600.dp -> 12  // タブレット
                else -> 10                   // スマートフォン
            }

            KeyGrid(
                keys = keys,
                keysPerRow = keysPerRow,
                onKeyPress = onKeyPress
            )
        }

        // 機能キー行
        FunctionKeyRow(
            onBackspace = { onKeyPress("⌫") },
            onSpace = { onKeyPress(" ") },
            onEnter = { onKeyPress("\n") }
        )
    }
}

@Composable
fun KeyGrid(
    keys: List<String>,
    keysPerRow: Int,
    onKeyPress: (String) -> Unit
) {
    val rows = keys.chunked(keysPerRow)

    Column {
        rows.forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                row.forEach { key ->
                    KeyButton(
                        key = key,
                        onClick = { onKeyPress(key) },
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}

@Composable
fun KeyButton(
    key: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Button(
        onClick = onClick,
        modifier = modifier
            .padding(2.dp)
            .aspectRatio(1f),
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        ),
        shape = RoundedCornerShape(8.dp)
    ) {
        Text(
            text = key,
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.onPrimaryContainer
        )
    }
}
```

---

## 4. 開発フェーズ計画

### Phase 1: Rust Core統合（Week 1-2）
- [ ] Rust CoreのJNIインターフェース実装
- [ ] `cargo-ndk`によるAndroidビルドパイプライン構築
- [ ] Gradle統合（ネイティブライブラリ自動ビルド）
- [ ] Kotlin側JNIブリッジ実装
- [ ] 単体テスト（RustCoreJNITest）

**成果物**：
- `rust_core/src/jni.rs`（JNIエクスポート関数）
- `mobile/android/core/src/main/jniLibs/*/*.so`
- `mobile/android/ime/src/main/kotlin/.../RustCoreJNI.kt`

**Commit例**：
```
feat(android): Add Rust Core JNI bridge and native library integration
- Implement JNI-compatible functions in rust_core/src/jni.rs
- Create Android multi-arch build script (build_android.sh)
- Add Kotlin JNI wrapper (RustCoreJNI.kt)
- Bundle JSON schemas in assets
```

### Phase 2: IMEサービス基本実装（Week 3-4）
- [ ] InputMethodService基本実装
- [ ] Jetpack ComposeによるKeyboardView構築
- [ ] KeyButtonタップハンドリング
- [ ] ProfileManager統合
- [ ] InputConnectionへのテキスト挿入

**成果物**：
- `mobile/android/ime/src/main/kotlin/.../CyrillicInputMethodService.kt`
- `mobile/android/ime/src/main/kotlin/.../ui/KeyboardView.kt`

**Commit例**：
```
feat(android): Implement IME service with Jetpack Compose keyboard
- Create CyrillicInputMethodService with Rust Core integration
- Build KeyboardView using Compose with Material Design 3
- Add ProfileIndicator for visual profile feedback
- Implement InputConnection text insertion
```

### Phase 3: メインアプリ（設定UI）実装（Week 5）
- [ ] Jetpack Composeベースのプロファイル選択画面
- [ ] Hiltによる依存性注入セットアップ
- [ ] チュートリアル画面（初回起動時）
- [ ] IME有効化ガイド（Settings.ACTION_INPUT_METHOD_SETTINGS）

**成果物**：
- `mobile/android/app/src/main/kotlin/.../ui/ProfileSelectionScreen.kt`

**Commit例**：
```
feat(android): Add main app with profile selection UI
- Build ProfileSelectionScreen with Jetpack Compose
- Implement Hilt dependency injection
- Create onboarding tutorial with IME activation guide
```

### Phase 4: パフォーマンス最適化とテスト（Week 6）
- [ ] キータップレイテンシ計測（目標: 16ms以下）
- [ ] メモリプロファイリング（Android Profiler）
- [ ] UIテスト自動化（Espresso / Compose Test）
- [ ] アクセシビリティ対応（TalkBack）

**Commit例**：
```
test(android): Add comprehensive test suite and performance optimization
- Implement Espresso tests for IME integration
- Add latency benchmarks (avg: 11ms per keystroke)
- Optimize Compose recomposition for key presses
- Add TalkBack content descriptions
```

### Phase 5: Google Play準備（Week 7）
- [ ] アプリアイコン作成（適応型アイコン）
- [ ] スクリーンショット撮影（全デバイスサイズ）
- [ ] Google Play説明文作成（日本語・英語）
- [ ] Privacy Policy作成
- [ ] 内部テストトラック配信

---

## 5. 技術的課題と対策

### 5.1. IMEパーミッション問題
**課題**：IMEは「信頼されたアプリ」として機能するため、ユーザーにセキュリティ警告が表示される。
**対策**：
- Google Play説明文で「完全オフライン動作」「ネットワーク権限不要」を明記
- Privacy Policyでデータ収集ゼロを宣言
- オープンソース化を検討（透明性確保）

### 5.2. Rust JNIメモリ管理
**課題**：JNI経由で渡す文字列のメモリリーク防止。
**対策**：
```rust
// Rust側でJStringを適切に解放
#[no_mangle]
pub extern "C" fn Java_..._processKey(...) -> jstring {
    // ...処理...
    let output = env.new_string(result_json).unwrap();
    output.into_raw()  // Javaに所有権を移譲
}

// Kotlin側ではGCが自動管理（追加処理不要）
```

### 5.3. Foldableデバイス対応
**課題**：Galaxy Z Fold等で画面サイズが動的に変化する。
**対策**：
```kotlin
@Composable
fun KeyboardView(...) {
    BoxWithConstraints {
        val keySize = maxWidth / keysPerRow
        // 動的にキーサイズを計算
    }
}
```

---

## 6. ビルドコマンド一覧

### 開発ビルド
```bash
# Rust Coreビルド（Android向け）
cd rust_core
./build_android.sh

# Gradleでアプリビルド
cd ../mobile/android
./gradlew assembleDebug

# エミュレータにインストール
./gradlew installDebug
```

### リリースビルド
```bash
# Rust Coreリリースビルド
cd rust_core
./build_android.sh --release

# Gradleでリリースビルド（署名付き）
cd ../mobile/android
./gradlew bundleRelease  # AAB形式（Google Play推奨）
# または
./gradlew assembleRelease  # APK形式
```

### テスト実行
```bash
# ユニットテスト
./gradlew test

# Instrumented Test（エミュレータ上）
./gradlew connectedAndroidTest

# 特定のテストクラス実行
./gradlew connectedAndroidTest --tests com.yourcompany.cyrillicime.ime.RustCoreJNITest
```

### ネイティブライブラリ統合テスト
```bash
# JNI動作確認
adb shell am instrument -w -e class com.yourcompany.cyrillicime.core.NativeLibTest \
  com.yourcompany.cyrillicime.test/androidx.test.runner.AndroidJUnitRunner
```

---

## 7. Git運用方針

### ブランチ戦略
```
main
 └── feature/integration
      └── android/develop (Android開発メインブランチ)
           ├── android/phase1-rust-jni
           ├── android/phase2-ime-service
           ├── android/phase3-main-app
           └── android/phase4-testing
```

### Commit規約
```
<type>(android): <subject>

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
feat(android): Implement Serbian profile with special ligatures

- Add rendering support for Њ, Љ, Ђ, Ћ, Џ keys
- Update KeyboardView to dynamically adjust key grid
- Test on Pixel 6 (compact) and Galaxy Tab S8 (large)

Closes #23
```

### 定期的なPush
各論理的な作業単位（1機能、1バグ修正）ごとにcommit + pushを実行：
```bash
git add mobile/android/ime/src/main/kotlin/.../ui/KeyboardView.kt
git commit -m "feat(android): Build responsive KeyboardView with Jetpack Compose"
git push origin android/phase2-ime-service
```

---

## 8. 成功基準

### パフォーマンス
- [ ] キータップ → ひらがな挿入までのレイテンシ: 平均16ms以下（60fps維持）
- [ ] メモリ使用量: 60MB以下（システムIME基準）
- [ ] APKサイズ: 10MB以下（全アーキテクチャ含む）

### 品質
- [ ] ユニットテストカバレッジ: 80%以上
- [ ] クラッシュフリー率: 99.9%以上（Internal Test期間）
- [ ] Google Play審査一発合格

### UX
- [ ] プロファイル切替: 2タップ以内
- [ ] TalkBack完全対応
- [ ] ダークモード・ダイナミックカラー完全対応

---

## 9. AndroidManifest.xml設定

```xml
<!-- mobile/android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:name=".CyrillicIMEApplication"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/Theme.CyrillicIME">

        <!-- メインアクティビティ -->
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- IMEサービス -->
        <service
            android:name=".ime.CyrillicInputMethodService"
            android:permission="android.permission.BIND_INPUT_METHOD"
            android:exported="true">
            <intent-filter>
                <action android:name="android.view.InputMethod" />
            </intent-filter>
            <meta-data
                android:name="android.view.im"
                android:resource="@xml/method" />
        </service>
    </application>
</manifest>
```

```xml
<!-- mobile/android/ime/src/main/res/xml/method.xml -->
<input-method xmlns:android="http://schemas.android.com/apk/res/android"
    android:settingsActivity="com.yourcompany.cyrillicime.MainActivity"
    android:icon="@drawable/ic_keyboard"
    android:supportsSwitchingToNextInputMethod="true" />
```

---

## 10. 依存関係（build.gradle.kts）

```kotlin
// mobile/android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.dagger.hilt.android")
    kotlin("plugin.serialization")
}

android {
    namespace = "com.yourcompany.cyrillicime"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.yourcompany.cyrillicime"
        minSdk = 29
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.3"
    }
}

dependencies {
    // Jetpack Compose
    implementation(platform("androidx.compose:compose-bom:2024.01.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.activity:activity-compose:1.8.2")

    // ViewModel
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")

    // Hilt
    implementation("com.google.dagger:hilt-android:2.50")
    kapt("com.google.dagger:hilt-compiler:2.50")

    // Kotlin Serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")

    // IMEモジュール
    implementation(project(":ime"))

    // Test
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
}
```

---

## 11. 参考資料

- [Creating an Input Method - Android Developers](https://developer.android.com/develop/ui/views/touch-and-input/creating-input-method)
- [Jetpack Compose Documentation](https://developer.android.com/jetpack/compose)
- [JNI Programming Guide](https://docs.oracle.com/javase/8/docs/technotes/guides/jni/)
- [cargo-ndk Documentation](https://github.com/bbqsrc/cargo-ndk)
