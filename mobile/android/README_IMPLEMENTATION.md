# Android Implementation Progress

## 完了した作業

### Phase 1: Rust Core JNI統合
- ✅ Rust Core JNIインターフェース実装済み (`rust_core/src/jni.rs`)
- ✅ Android向けビルドスクリプト作成済み (`rust_core/build_android.sh`)
- ✅ Kotlinデータモデル作成済み
  - `Profile.kt`: プロファイルデータモデル
  - `ConversionResult.kt`: 変換結果モデル
- ✅ JNI宣言作成済み (`NativeLib.kt`)
- ✅ Rust Coreラッパー作成済み (`RustCoreEngine.kt`)

## 次に必要な作業

### Phase 2: IMEサービス基本実装
以下のファイルを作成する必要があります（Android Studioで）:

1. **ProfileManager.kt** - プロファイル管理
   - パス: `ime/src/main/kotlin/com/yourcompany/cyrillicime/ime/engine/ProfileManager.kt`
   - 役割: JSONからプロファイル読み込み、StateFlow管理
   
2. **CyrillicInputMethodService.kt** - メインIMEサービス
   - パス: `ime/src/main/kotlin/com/yourcompany/cyrillicime/ime/CyrillicInputMethodService.kt`
   - 役割: InputMethodService実装、Rust Core統合
   
3. **KeyboardView.kt** - Jetpack Compose UI
   - パス: `ime/src/main/kotlin/com/yourcompany/cyrillicime/ime/ui/KeyboardView.kt`
   - 役割: キーボードレイアウト、Material Design 3

4. **KeyButton.kt** - 個別キーボタン
   - パス: `ime/src/main/kotlin/com/yourcompany/cyrillicime/ime/ui/KeyButton.kt`

### Phase 3: メインアプリ
5. **MainActivity.kt** - 設定画面
   - パス: `app/src/main/kotlin/com/yourcompany/cyrillicime/MainActivity.kt`

6. **ProfileSelectionScreen.kt** - プロファイル選択UI
   - パス: `app/src/main/kotlin/com/yourcompany/cyrillicime/ui/ProfileSelectionScreen.kt`

### Phase 4: ビルド設定
7. **build.gradle.kts** ファイル
   - `build.gradle.kts` (ルート)
   - `app/build.gradle.kts`
   - `ime/build.gradle.kts`
   - `core/build.gradle.kts`

8. **AndroidManifest.xml** ファイル
   - `app/src/main/AndroidManifest.xml`
   - `ime/src/main/AndroidManifest.xml`

9. **method.xml** - IME定義
   - `ime/src/main/res/xml/method.xml`

## ビルド手順（AWS環境で実行）

### 1. Android NDKのインストール
```bash
# Android SDK Managerを使用
sdkmanager --install "ndk;26.1.10909125"
export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/26.1.10909125
```

### 2. Rust Coreのビルド
```bash
cd rust_core
./build_android.sh --release
```

### 3. Gradleビルド
```bash
cd mobile/android
./gradlew assembleDebug
```

## リソースファイル

### 必要なJSONファイル（assetsディレクトリ）
- `app/src/main/assets/profiles/profiles.json` (profiles/profiles.jsonからコピー)
- `app/src/main/assets/profiles/japaneseKanaEngine.json` (profiles/kana_engine.jsonからコピー)
- `app/src/main/assets/profiles/schemas/*.json` (profiles/schemas/からコピー)

## 参考資料
- Android開発計画書: `docs/Android開発計画書.md`
- Rust Core JNI実装: `rust_core/src/jni.rs`
- ビルドスクリプト: `rust_core/build_android.sh`
