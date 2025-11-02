//
//  KeyboardViewController.swift
//  CyrillicKeyboard
//
//  Main keyboard extension view controller
//

import UIKit

class KeyboardViewController: UIInputViewController {
    // MARK: - Properties

    /// 現在の入力バッファ（Rust Coreから返される composing buffer）
    private var inputBuffer: String = ""

    /// キーボードビュー
    private var keyboardView: CyrillicKeyboardView?

    /// 初期化エラーメッセージ（デバッグ用）
    private var initializationError: String?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // エンジンとプロファイルを初期化
        initializeEngine()

        // キーボードビューをセットアップ
        setupKeyboardView()

        // プロファイル変更通知を購読
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProfileChanged),
            name: .profileDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // プロファイル変更を反映
        updateKeyboardLayout()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Engine Initialization

    private func initializeEngine() {
        // ProfileManagerを初期化
        if let error = ProfileManager.shared.initialize() {
            print("[KeyboardViewController] Initialization error: \(error)")
            initializationError = error
            return
        }

        // 現在のプロファイルのスキーマをロード
        if let error = ProfileManager.shared.loadCurrentSchema() {
            print("[KeyboardViewController] Schema load error: \(error)")
            initializationError = error
            return
        }

        print("[KeyboardViewController] Engine initialized successfully")
        print("[KeyboardViewController] Rust Core version: \(RustCoreFFI.shared.getVersion())")
    }

    // MARK: - Keyboard View Setup

    private func setupKeyboardView() {
        // 初期化エラーがある場合はエラービューを表示
        if let error = initializationError {
            showErrorView(message: error)
            return
        }

        guard let profile = ProfileManager.shared.currentProfile else {
            showErrorView(message: "No profile selected")
            return
        }

        // キーボードビューを作成
        let keyboard = CyrillicKeyboardView(profile: profile)
        keyboard.delegate = self
        keyboard.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(keyboard)

        NSLayoutConstraint.activate([
            keyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboard.topAnchor.constraint(equalTo: view.topAnchor),
            keyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        keyboardView = keyboard
    }

    private func showErrorView(message: String) {
        let label = UILabel()
        label.text = "Error: \(message)"
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Profile Management

    @objc private func handleProfileChanged(_ notification: Notification) {
        guard let newProfile = notification.object as? Profile else { return }

        print("[KeyboardViewController] Profile changed to: \(newProfile.id)")

        // スキーマをロード
        if let error = ProfileManager.shared.loadSchemaForProfile(newProfile) {
            print("[KeyboardViewController] Failed to load schema: \(error)")
            return
        }

        // キーボードレイアウトを更新
        updateKeyboardLayout()

        // バッファをクリア
        inputBuffer = ""
        updateComposingText()
    }

    private func updateKeyboardLayout() {
        guard let profile = ProfileManager.shared.currentProfile else { return }
        keyboardView?.updateLayout(for: profile)
    }

    // MARK: - Text Output

    /// 確定文字列をテキストフィールドに挿入
    private func commitText(_ text: String) {
        textDocumentProxy.insertText(text)
        inputBuffer = ""
        updateComposingText()
    }

    /// 入力中の文字列（composing text）を更新
    private func updateComposingText() {
        // iOS標準のcomposing text表示は制限があるため、
        // キーボードビュー内にバッファを表示する
        keyboardView?.updateBufferDisplay(inputBuffer)
    }

    /// バッファをクリア
    private func clearBuffer() {
        inputBuffer = ""
        updateComposingText()
    }
}

// MARK: - CyrillicKeyboardViewDelegate

extension KeyboardViewController: CyrillicKeyboardViewDelegate {
    /// キリル文字キーが押された
    func keyboardView(_ view: CyrillicKeyboardView, didPressCyrillicKey key: String) {
        guard let profile = ProfileManager.shared.currentProfile else {
            print("[KeyboardViewController] Error: No current profile")
            return
        }

        // Rust Coreで変換処理
        guard let result = RustCoreFFI.shared.processKey(
            cyrillicKey: key,
            currentBuffer: inputBuffer,
            profileId: profile.id
        ) else {
            print("[KeyboardViewController] Error: Failed to process key")
            return
        }

        // 結果に応じて処理
        handleConversionResult(result)
    }

    /// Deleteキーが押された
    func keyboardViewDidPressDelete(_ view: CyrillicKeyboardView) {
        if !inputBuffer.isEmpty {
            // バッファがある場合はバッファから削除
            inputBuffer = String(inputBuffer.dropLast())
            updateComposingText()
        } else {
            // バッファが空の場合はテキストフィールドから削除
            textDocumentProxy.deleteBackward()
        }
    }

    /// Returnキーが押された
    func keyboardViewDidPressReturn(_ view: CyrillicKeyboardView) {
        // バッファがあれば確定
        if !inputBuffer.isEmpty {
            commitText(inputBuffer)
        }
        // 改行を挿入
        textDocumentProxy.insertText("\n")
    }

    /// Spaceキーが押された
    func keyboardViewDidPressSpace(_ view: CyrillicKeyboardView) {
        // バッファがあれば確定
        if !inputBuffer.isEmpty {
            commitText(inputBuffer)
        }
        // スペースを挿入
        textDocumentProxy.insertText(" ")
    }

    /// Globe（キーボード切り替え）キーが押された
    func keyboardViewDidPressGlobe(_ view: CyrillicKeyboardView) {
        advanceToNextInputMode()
    }

    // MARK: - Conversion Result Handling

    private func handleConversionResult(_ result: ConversionResult) {
        switch result.action {
        case "commit":
            // 確定：outputを挿入し、バッファをクリア
            if !result.output.isEmpty {
                commitText(result.output)
            }

        case "composing":
            // 入力中：バッファを更新
            inputBuffer = result.buffer
            updateComposingText()

        case "clear":
            // クリア：バッファをクリア
            clearBuffer()

        default:
            print("[KeyboardViewController] Warning: Unknown action: \(result.action)")
        }
    }
}
