# Xcode Project Setup Guide

このガイドでは、macOS環境でXcodeプロジェクトをセットアップし、Cyrillic IME iOSアプリをビルドする手順を説明します。

## 前提条件

- macOS 13.0以降
- Xcode 15.0以降
- Rust toolchain（cargo-lipoインストール済み）
- Apple Developer アカウント（実機テスト用）

## セットアップ手順

### 1. Rust Core XCFramework のビルド

```bash
cd rust_core
./build_ios.sh
```

このスクリプトは以下を実行します：
- iOS向けRustターゲットをインストール
- 複数アーキテクチャ（arm64, x86_64 simulator）でビルド
- XCFrameworkを生成
- `rust_core/target/CyrillicIMECore.xcframework` を出力

### 2. Xcodeプロジェクトの作成

#### 2.1 新規プロジェクトを作成

1. Xcodeを起動
2. "Create a new Xcode project" を選択
3. **iOS > App** テンプレートを選択
4. プロジェクト設定：
   - Product Name: `CyrillicIME`
   - Team: あなたの開発チーム
   - Organization Identifier: `com.yourcompany`（実際の識別子に変更）
   - Interface: **SwiftUI**
   - Language: **Swift**
   - ✅ Include Tests
5. 保存場所: `mobile/iOS/`

#### 2.2 App Groupの設定

1. **CyrillicIME target** を選択
2. **Signing & Capabilities** タブ
3. **+ Capability** → **App Groups** を追加
4. **+** ボタンで新しいApp Groupを追加
5. Group ID: `group.com.yourcompany.cyrillicime`（Bundle IDに合わせる）
6. ✅ チェックを入れて有効化

### 3. Keyboard Extensionの追加

#### 3.1 Extensionターゲットの作成

1. プロジェクトナビゲータでプロジェクトを選択
2. 下部の **+** ボタン → **Target** を追加
3. **iOS > Custom Keyboard Extension** を選択
4. Product Name: `CyrillicKeyboard`
5. Activate schemeのダイアログで **Activate** を選択

#### 3.2 Extension App Groupの設定

1. **CyrillicKeyboard target** を選択
2. **Signing & Capabilities** タブ
3. **+ Capability** → **App Groups** を追加
4. 同じGroup ID `group.com.yourcompany.cyrillicime` を選択

### 4. ファイルのインポート

#### 4.1 Shared フォルダ

1. Xcodeプロジェクトナビゲータで右クリック
2. **Add Files to "CyrillicIME"...** を選択
3. `mobile/iOS/Shared` フォルダを選択
4. ✅ **Create groups**
5. ✅ **Add to targets**: CyrillicIME, CyrillicKeyboard の両方にチェック

#### 4.2 Main App ファイル

1. `mobile/iOS/CyrillicIME` フォルダ内のファイルを追加
2. ✅ **Add to targets**: CyrillicIME のみ

#### 4.3 Keyboard Extension ファイル

1. `mobile/iOS/CyrillicKeyboard` フォルダ内のファイルを追加
2. ✅ **Add to targets**: CyrillicKeyboard のみ
3. `KeyboardViewController.swift` を既存のデフォルトファイルと置き換え

#### 4.4 Test ファイル

1. `mobile/iOS/CyrillicIMETests` フォルダ内のファイルを追加
2. ✅ **Add to targets**: CyrillicIMETests

### 5. XCFrameworkのリンク

#### 5.1 CyrillicIMECore.xcframework を追加

1. プロジェクトナビゲータでプロジェクトを選択
2. **CyrillicIME target** → **General** タブ
3. **Frameworks, Libraries, and Embedded Content** セクション
4. **+** ボタン → **Add Other...** → **Add Files...**
5. `rust_core/target/CyrillicIMECore.xcframework` を選択
6. **Embed & Sign** に設定

#### 5.2 Keyboard Extensionにもリンク

1. **CyrillicKeyboard target** → **General** タブ
2. **Frameworks, Libraries, and Embedded Content** セクション
3. **+** ボタン → 既に追加済みの `CyrillicIMECore.xcframework` を選択
4. **Embed & Sign** に設定

### 6. リソースファイルの追加

#### 6.1 profiles.json

1. プロジェクトナビゲータで右クリック
2. **Add Files to "CyrillicIME"...** を選択
3. `profiles/profiles.json` を選択
4. ✅ **Add to targets**: CyrillicKeyboard

#### 6.2 kana_engine.json

1. `profiles/kana_engine.json` を追加
2. ✅ **Add to targets**: CyrillicKeyboard

#### 6.3 schemas フォルダ

1. `profiles/schemas/` フォルダを追加（Create folder references）
2. ✅ **Add to targets**: CyrillicKeyboard

### 7. ビルド設定

#### 7.1 Library Search Paths

両方のターゲット（CyrillicIME, CyrillicKeyboard）で：

1. **Build Settings** タブ
2. **Search Paths** セクション
3. **Library Search Paths** に追加:
   ```
   $(PROJECT_DIR)/../../rust_core/target
   ```

#### 7.2 Header Search Paths

両方のターゲットで：

1. **Header Search Paths** に追加:
   ```
   $(PROJECT_DIR)/../../rust_core/include
   ```

#### 7.3 Other Linker Flags

両方のターゲットで：

1. **Other Linker Flags** に追加:
   ```
   -lc++
   ```

### 8. Info.plist の設定

#### 8.1 Keyboard Extension Info.plist

`CyrillicKeyboard/Info.plist` を編集：

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>IsASCIICapable</key>
        <false/>
        <key>PrefersRightToLeft</key>
        <false/>
        <key>PrimaryLanguage</key>
        <string>ja</string>
        <key>RequestsOpenAccess</key>
        <false/>
    </dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.keyboard-service</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).KeyboardViewController</string>
</dict>
```

### 9. ビルドと実行

#### 9.1 シミュレータでビルド

1. スキームで **CyrillicIME** を選択
2. シミュレータデバイスを選択（iPhone 14以降推奨）
3. **Product → Build** (⌘B)
4. **Product → Run** (⌘R)

#### 9.2 実機でテスト

1. iOSデバイスを接続
2. **Signing & Capabilities** で開発チームを設定
3. デバイスを選択してビルド・実行
4. デバイスの **設定 → 一般 → キーボード → キーボード → 新しいキーボードを追加**
5. **Cyrillic IME** を選択して有効化

### 10. トラブルシューティング

#### XCFrameworkが見つからない

```bash
cd rust_core
./build_ios.sh
```

再度ビルドして、Xcodeで **Product → Clean Build Folder** を実行

#### Rust FFI関数が見つからない

- **Build Settings → Other Linker Flags** に `-lc++` が追加されているか確認
- XCFrameworkが両方のターゲットに正しくリンクされているか確認

#### App Group エラー

- Provisioning Profileが App Groups を含んでいるか確認
- Main App と Extension で同じ Group ID を使用しているか確認
- `UserDefaults+AppGroup.swift` の `appGroupIdentifier` が正しいか確認

#### プロファイルが読み込めない

- `profiles.json`, `kana_engine.json` が Keyboard Extension ターゲットに追加されているか確認
- **Build Phases → Copy Bundle Resources** に含まれているか確認

#### シミュレータでキーボードが表示されない

- シミュレータの設定でキーボードを有効化したか確認
- 一度アプリを削除して再インストール
- シミュレータをリセット: **Device → Erase All Content and Settings...**

## 次のステップ

- `UserDefaults+AppGroup.swift` の `appGroupIdentifier` をあなたのBundle IDに変更
- App IconとLaunch Screenを追加
- TestFlightでベータテスト
- App Store提出の準備

## 参考リンク

- [Custom Keyboard Extensions - Apple Developer](https://developer.apple.com/documentation/uikit/keyboards_and_input/creating_a_custom_keyboard)
- [App Groups - Apple Developer](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [XCFramework - Apple Developer](https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle)
