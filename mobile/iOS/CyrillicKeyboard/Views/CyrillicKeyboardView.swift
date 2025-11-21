//
//  CyrillicKeyboardView.swift
//  CyrillicKeyboard
//
//  Keyboard UI layout view
//

import UIKit

// MARK: - Delegate Protocol

protocol CyrillicKeyboardViewDelegate: AnyObject {
    func keyboardView(_ view: CyrillicKeyboardView, didPressCyrillicKey key: String)
    func keyboardViewDidPressDelete(_ view: CyrillicKeyboardView)
    func keyboardViewDidPressReturn(_ view: CyrillicKeyboardView)
    func keyboardViewDidPressSpace(_ view: CyrillicKeyboardView)
    func keyboardViewDidPressGlobe(_ view: CyrillicKeyboardView)
    func keyboardView(_ view: CyrillicKeyboardView, didSelectCandidateAt index: Int)
    func keyboardView(_ view: CyrillicKeyboardView, didPressNumberKey number: Int)
}

// MARK: - Main View

class CyrillicKeyboardView: UIView {
    // MARK: - Properties

    weak var delegate: CyrillicKeyboardViewDelegate?

    private var profile: Profile
    private var keyButtons: [UIButton] = []

    /// キーボードモード
    enum KeyboardMode {
        case cyrillic
        case numbers
        case symbols
    }

    private(set) var currentMode: KeyboardMode = .cyrillic

    /// 入力バッファ表示ラベル（未確定文字列）
    private let bufferLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .label
        label.backgroundColor = .systemBackground
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 変換候補表示バー (Phase 4: Enhanced UI)
    private let candidateBarView: CandidateBarView = {
        let view = CandidateBarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// キーボードコンテナ
    private let keyboardContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 現在の入力モード
    private var inputMode: InputMode {
        get { UserDefaults.shared.currentInputMode }
        set {
            UserDefaults.shared.currentInputMode = newValue
            updateInputModeButton()
        }
    }

    /// 入力モード切り替えボタン（参照保持用）
    private var inputModeButton: UIButton?

    // MARK: - Initialization

    init(profile: Profile) {
        self.profile = profile
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .systemGray5

        // バッファラベルと候補バーを追加
        addSubview(bufferLabel)
        addSubview(candidateBarView)
        addSubview(keyboardContainer)

        NSLayoutConstraint.activate([
            // 未確定文字列バッファ
            bufferLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            bufferLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            bufferLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            bufferLabel.heightAnchor.constraint(equalToConstant: 24),

            // 変換候補バー (Phase 4: Enhanced CandidateBarView)
            candidateBarView.topAnchor.constraint(equalTo: bufferLabel.bottomAnchor, constant: 2),
            candidateBarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            candidateBarView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            candidateBarView.heightAnchor.constraint(equalToConstant: 50),

            // キーボード本体
            keyboardContainer.topAnchor.constraint(equalTo: candidateBarView.bottomAnchor, constant: 4),
            keyboardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyboardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            keyboardContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // 初期状態では候補バーを非表示
        candidateBarView.isHidden = true

        // Setup candidate bar callbacks
        setupCandidateBarCallbacks()

        // キーボードレイアウトを構築
        buildKeyboardLayout()
    }

    /// Setup candidate bar callbacks
    private func setupCandidateBarCallbacks() {
        candidateBarView.onCandidateSelected = { [weak self] index in
            guard let self = self else { return }
            print("[CyrillicKeyboardView] Candidate selected at index: \(index)")
            self.delegate?.keyboardView(self, didSelectCandidateAt: index)
        }

        candidateBarView.onSelectedIndexChanged = { index in
            print("[CyrillicKeyboardView] Selected index changed to: \(index)")
        }
    }

    // MARK: - Keyboard Layout

    private func buildKeyboardLayout() {
        // 既存のボタンをクリア
        keyButtons.forEach { $0.removeFromSuperview() }
        keyButtons.removeAll()

        // モードに応じた行データを取得
        let rows: [[String]]
        switch currentMode {
        case .cyrillic:
            rows = profile.keyboardLayout.rows
        case .numbers:
            rows = [
                ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
                ["-", "/", ":", ";", "(", ")", "¥", "&", "@"],
                [".", ",", "?", "!", "'", "«", "»"]
            ]
        case .symbols:
            rows = [
                ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
                ["_", "\\", "|", "~", "<", ">", "$", "€", "£"],
                [".", ",", "?", "!", "'", "·"]
            ]
        }

        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.distribution = .fillEqually
        mainStackView.spacing = 8
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        keyboardContainer.addSubview(mainStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: keyboardContainer.topAnchor, constant: 8),
            mainStackView.leadingAnchor.constraint(equalTo: keyboardContainer.leadingAnchor, constant: 4),
            mainStackView.trailingAnchor.constraint(equalTo: keyboardContainer.trailingAnchor, constant: -4),
            mainStackView.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor, constant: -8)
        ])

        // スキーマを取得
        let schema = ProfileManager.shared.currentSchema

        // 行ごとのインセット（階段状レイアウト）
        let rowInsets: [CGFloat] = [0, 10, 20]  // 第1行: 0pt, 第2行: 10pt, 第3行: 20pt

        // 第1行〜第3行
        for (rowIndex, rowKeys) in rows.enumerated() {
            // 行コンテナ（インセット用）
            let rowContainer = UIView()
            rowContainer.translatesAutoresizingMaskIntoConstraints = false

            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 4
            rowStack.translatesAutoresizingMaskIntoConstraints = false

            rowContainer.addSubview(rowStack)

            // インセットを適用
            let inset = rowInsets[min(rowIndex, rowInsets.count - 1)]
            NSLayoutConstraint.activate([
                rowStack.topAnchor.constraint(equalTo: rowContainer.topAnchor),
                rowStack.bottomAnchor.constraint(equalTo: rowContainer.bottomAnchor),
                rowStack.leadingAnchor.constraint(equalTo: rowContainer.leadingAnchor, constant: inset),
                rowStack.trailingAnchor.constraint(equalTo: rowContainer.trailingAnchor, constant: -inset)
            ])

            // 各キーのボタンを作成
            for key in rowKeys {
                // キリル文字モードの場合、スキーマからhintLabelとpopupCharactersを取得
                var hintLabel: String? = nil
                var popupCharacters: [String]? = nil

                if currentMode == .cyrillic, let entry = schema?[key] {
                    hintLabel = entry.hintLabel
                    popupCharacters = entry.popupCharacters
                }

                let button = createKeyButton(
                    title: key,
                    action: #selector(handleCyrillicKeyPress(_:)),
                    hintLabel: hintLabel,
                    popupCharacters: popupCharacters
                )
                rowStack.addArrangedSubview(button)
                keyButtons.append(button)
            }

            mainStackView.addArrangedSubview(rowContainer)
        }

        // 第4行：特殊キー
        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.distribution = .fill
        bottomRow.spacing = 4

        // 123/АБВ切り替えボタン
        let modeToggleTitle = currentMode == .cyrillic ? "123" : "АБВ"
        let modeToggleButton = createKeyButton(title: modeToggleTitle, action: #selector(handleModeToggle))
        modeToggleButton.widthAnchor.constraint(equalToConstant: 50).isActive = true

        let globeButton = createKeyButton(title: "🌐", action: #selector(handleGlobePress))
        globeButton.widthAnchor.constraint(equalToConstant: 40).isActive = true

        // 入力モード切り替えボタン（АБВ/あ/あ変）
        let inputModeBtn = createKeyButton(title: inputMode.shortName, action: #selector(handleInputModeToggle))
        inputModeBtn.widthAnchor.constraint(equalToConstant: 45).isActive = true
        inputModeBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        self.inputModeButton = inputModeBtn

        let spaceButton = createKeyButton(title: "空白", action: #selector(handleSpacePress))

        let deleteButton = createKeyButton(title: "⌫", action: #selector(handleDeletePress))
        deleteButton.widthAnchor.constraint(equalToConstant: 60).isActive = true

        let returnButton = createKeyButton(title: "改行", action: #selector(handleReturnPress))
        returnButton.widthAnchor.constraint(equalToConstant: 60).isActive = true

        bottomRow.addArrangedSubview(modeToggleButton)
        bottomRow.addArrangedSubview(globeButton)
        bottomRow.addArrangedSubview(inputModeBtn)
        bottomRow.addArrangedSubview(spaceButton)
        bottomRow.addArrangedSubview(deleteButton)
        bottomRow.addArrangedSubview(returnButton)

        mainStackView.addArrangedSubview(bottomRow)
    }

    private func createKeyButton(title: String, action: Selector, hintLabel: String? = nil, popupCharacters: [String]? = nil) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 5
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 2
        button.addTarget(self, action: action, for: .touchUpInside)

        // ヒントラベルを追加
        if let hint = hintLabel {
            let hintLabelView = UILabel()
            hintLabelView.text = hint
            hintLabelView.font = .systemFont(ofSize: 10)
            hintLabelView.textColor = .secondaryLabel
            hintLabelView.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(hintLabelView)

            NSLayoutConstraint.activate([
                hintLabelView.topAnchor.constraint(equalTo: button.topAnchor, constant: 2),
                hintLabelView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -4)
            ])
        }

        // 長押しバリエーションがある場合、長押しジェスチャーを追加
        if let popupChars = popupCharacters, !popupChars.isEmpty {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            longPress.minimumPressDuration = 0.4
            button.addGestureRecognizer(longPress)

            // popupCharactersをbutton.accessibilityValueに保存（後で取得するため）
            button.accessibilityValue = popupChars.joined(separator: ",")
        }

        return button
    }

    // MARK: - Public Methods

    func updateLayout(for profile: Profile) {
        self.profile = profile
        buildKeyboardLayout()
    }

    func updateBufferDisplay(_ buffer: String) {
        bufferLabel.text = buffer.isEmpty ? "" : buffer
    }

    /// 現在の入力モードを取得
    var currentInputMode: InputMode {
        return inputMode
    }

    // MARK: - Button Actions

    @objc private func handleCyrillicKeyPress(_ sender: UIButton) {
        guard let key = sender.currentTitle else { return }

        // Phase 4: Check if this is a number key and candidates are showing
        if candidateBarView.hasCandidates, let number = Int(key), number >= 1 && number <= 9 {
            print("[CyrillicKeyboardView] Number key \(number) pressed, selecting candidate")
            delegate?.keyboardView(self, didPressNumberKey: number)
            animateButtonPress(sender)
            return
        }

        // Normal key press
        delegate?.keyboardView(self, didPressCyrillicKey: key)

        // ボタンフィードバック
        animateButtonPress(sender)
    }

    @objc private func handleDeletePress(_ sender: UIButton) {
        delegate?.keyboardViewDidPressDelete(self)
        animateButtonPress(sender)
    }

    @objc private func handleReturnPress(_ sender: UIButton) {
        delegate?.keyboardViewDidPressReturn(self)
        animateButtonPress(sender)
    }

    @objc private func handleSpacePress(_ sender: UIButton) {
        delegate?.keyboardViewDidPressSpace(self)
        animateButtonPress(sender)
    }

    @objc private func handleGlobePress(_ sender: UIButton) {
        delegate?.keyboardViewDidPressGlobe(self)
        animateButtonPress(sender)
    }

    @objc private func handleModeToggle(_ sender: UIButton) {
        // モードを切り替え
        switch currentMode {
        case .cyrillic:
            currentMode = .numbers
        case .numbers, .symbols:
            currentMode = .cyrillic
        }

        // レイアウトを再構築
        buildKeyboardLayout()
        animateButtonPress(sender)
    }

    @objc private func handleInputModeToggle(_ sender: UIButton) {
        // 入力モードを切り替え（АБВ → あ → あ変 → АБВ...）
        switch inputMode {
        case .directCyrillic:
            inputMode = .japaneseHiragana
        case .japaneseHiragana:
            inputMode = .japaneseIME
        case .japaneseIME:
            inputMode = .directCyrillic
        }
        animateButtonPress(sender)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let button = gesture.view as? UIButton,
              let keyLabel = button.currentTitle,
              let popupCharsString = button.accessibilityValue else { return }

        let popupChars = popupCharsString.split(separator: ",").map { String($0) }

        // アラートスタイルのポップアップメニューを表示
        let alert = UIAlertController(title: keyLabel, message: "バリエーションを選択", preferredStyle: .actionSheet)

        for char in popupChars {
            alert.addAction(UIAlertAction(title: char, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.keyboardView(self, didPressCyrillicKey: char)
            })
        }

        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))

        // キーボード拡張ではviewControllerが必要
        if let viewController = self.window?.rootViewController {
            alert.popoverPresentationController?.sourceView = button
            alert.popoverPresentationController?.sourceRect = button.bounds
            viewController.present(alert, animated: true)
        }

        animateButtonPress(button)
    }

    // MARK: - Helper Methods

    /// 入力モードボタンのタイトルを更新
    private func updateInputModeButton() {
        inputModeButton?.setTitle(inputMode.shortName, for: .normal)
    }

    /// 変換候補を表示 (Phase 4: Enhanced with Candidate model)
    func showCandidates(_ candidates: [Candidate], selectedIndex: Int = 0) {
        if candidates.isEmpty {
            hideCandidates()
            return
        }

        print("[CyrillicKeyboardView] Showing \(candidates.count) candidates")
        candidateBarView.updateCandidates(candidates, selectedIndex: selectedIndex)
        candidateBarView.isHidden = false
    }

    /// 変換候補を非表示
    func hideCandidates() {
        candidateBarView.animateDisappearance { [weak self] in
            self?.candidateBarView.isHidden = true
            self?.candidateBarView.clear()
        }
    }

    /// 次の候補を選択 (Space key)
    func selectNextCandidate() {
        candidateBarView.selectNextCandidate()
    }

    /// 前の候補を選択
    func selectPreviousCandidate() {
        candidateBarView.selectPreviousCandidate()
    }

    /// 指定インデックスの候補を選択
    func selectCandidate(at index: Int) {
        candidateBarView.selectCandidate(at: index)
    }

    /// 現在選択中の候補インデックスを取得
    var selectedCandidateIndex: Int {
        return candidateBarView.currentSelectedIndex
    }

    /// 候補が表示されているかどうか
    var hasCandidates: Bool {
        return candidateBarView.hasCandidates && !candidateBarView.isHidden
    }

    // MARK: - Animation

    private func animateButtonPress(_ button: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = .identity
            }
        }
    }
}
