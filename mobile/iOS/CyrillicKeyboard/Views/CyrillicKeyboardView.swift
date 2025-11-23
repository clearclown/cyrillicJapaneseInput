//
//  CyrillicKeyboardView.swift
//  CyrillicKeyboard
//
//  Keyboard UI layout view
//  Phase 2: Enhanced with ThemeProvider and HapticManager
//

import UIKit

// MARK: - Delegate Protocol

protocol CyrillicKeyboardViewDelegate: AnyObject {
    func keyboardView(_ view: CyrillicKeyboardView, didPressCyrillicKey key: String)
    func keyboardViewDidPressDelete(_ view: CyrillicKeyboardView)
    func keyboardViewDidPressReturn(_ view: CyrillicKeyboardView)
    func keyboardViewDidPressSpace(_ view: CyrillicKeyboardView)
    func keyboardViewDidPressGlobe(_ view: CyrillicKeyboardView)
    func keyboardView(_ view: CyrillicKeyboardView, didSelectCandidate candidate: String)
}

// MARK: - Main View

class CyrillicKeyboardView: UIView {
    // MARK: - Properties

    weak var delegate: CyrillicKeyboardViewDelegate?

    private var profile: Profile
    private var keyButtons: [UIButton] = []

    /// Theme provider for iOS HIG-compliant colors
    private let themeProvider: ThemeProvider = ThemeManager.shared.currentTheme

    /// Haptic manager for tactile feedback
    private let hapticManager = HapticManager.shared

    /// キーボードモード
    enum KeyboardMode {
        case cyrillic
        case numbers
        case symbols
    }

    private(set) var currentMode: KeyboardMode = .cyrillic

    /// 入力バッファ表示ラベル（未確定文字列）
    private lazy var bufferLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = themeProvider.bufferTextColor
        label.backgroundColor = themeProvider.bufferBackgroundColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 変換候補表示バー (Phase 4: Enhanced UI)
    private let candidateBarView: CandidateBarView = {
        let bar = CandidateBarView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.isHidden = true
        return bar
    }()

    /// 候補バーのジェスチャーハンドラー
    private var candidateGestureHandler: CandidateGestureHandler?

    /// キーボードコンテナ
    private let keyboardContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 現在の入力モード
    // Smartphone-appropriate: Always use japaneseIME mode (automatic live conversion)
    // No mode switching needed for smartphone keyboards
    private let inputMode: InputMode = .japaneseIME

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
        // Apply theme to keyboard background
        themeProvider.applyTheme(to: self)

        // バッファラベルと候補バーを追加
        addSubview(bufferLabel)
        addSubview(candidateBarView)
        addSubview(keyboardContainer)

        // Prepare haptics for better responsiveness
        hapticManager.prepareHaptics()

        // Listen for theme changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: .themeDidChange,
            object: nil
        )

        NSLayoutConstraint.activate([
            // 未確定文字列バッファ
            bufferLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            bufferLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            bufferLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            bufferLabel.heightAnchor.constraint(equalToConstant: 24),

            // 変換候補バー (Phase 4: Enhanced UI)
            candidateBarView.topAnchor.constraint(equalTo: bufferLabel.bottomAnchor, constant: 2),
            candidateBarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            candidateBarView.trailingAnchor.constraint(equalTo: trailingAnchor),
            candidateBarView.heightAnchor.constraint(equalToConstant: CandidateBarView.preferredHeight),

            // キーボード本体
            keyboardContainer.topAnchor.constraint(equalTo: candidateBarView.bottomAnchor, constant: 4),
            keyboardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyboardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            keyboardContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Setup gesture handler for candidate bar
        candidateGestureHandler = CandidateGestureHandler(candidateBar: candidateBarView)
        setupCandidateBarCallbacks()

        // キーボードレイアウトを構築
        buildKeyboardLayout()
    }

    private func setupCandidateBarCallbacks() {
        // Candidate selection callback
        candidateBarView.onCandidateSelected = { [weak self] candidate, index in
            guard let self = self else { return }
            print("[CyrillicKeyboardView] Candidate selected: \(candidate.text)")

            // Haptic feedback for successful selection
            self.hapticManager.candidateSelect()

            self.delegate?.keyboardView(self, didSelectCandidate: candidate.text)
            self.hideCandidates()
        }

        // Gesture callbacks
        candidateGestureHandler?.onSwipeLeft = { [weak self] in
            self?.candidateBarView.selectNext()
        }

        candidateGestureHandler?.onSwipeRight = { [weak self] in
            self?.candidateBarView.selectPrevious()
        }

        candidateGestureHandler?.onSwipeUp = { [weak self] in
            // TODO: Expand candidate view (future enhancement)
            print("[CyrillicKeyboardView] Swipe up - expand candidates")
        }

        candidateGestureHandler?.onSwipeDown = { [weak self] in
            self?.hideCandidates()
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

        // Smartphone-appropriate: No input mode switcher needed
        // Always use automatic live conversion (japaneseIME)

        let spaceButton = createKeyButton(title: "空白", action: #selector(handleSpacePress))

        let deleteButton = createKeyButton(title: "⌫", action: #selector(handleDeletePress))
        deleteButton.widthAnchor.constraint(equalToConstant: 60).isActive = true

        let returnButton = createKeyButton(title: "改行", action: #selector(handleReturnPress))
        returnButton.widthAnchor.constraint(equalToConstant: 60).isActive = true

        bottomRow.addArrangedSubview(modeToggleButton)
        bottomRow.addArrangedSubview(globeButton)
        // Removed: inputModeBtn (smartphone-appropriate - no mode switcher needed)
        bottomRow.addArrangedSubview(spaceButton)
        bottomRow.addArrangedSubview(deleteButton)
        bottomRow.addArrangedSubview(returnButton)

        mainStackView.addArrangedSubview(bottomRow)
    }

    private func createKeyButton(title: String, action: Selector, hintLabel: String? = nil, popupCharacters: [String]? = nil) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)

        // Determine if this is a special key based on action
        let isSpecialKey = (action == #selector(handleDeletePress(_:)) ||
                           action == #selector(handleReturnPress(_:)) ||
                           action == #selector(handleSpacePress(_:)) ||
                           action == #selector(handleGlobePress(_:)) ||
                           action == #selector(handleModeToggle(_:)))

        // Apply theme colors
        if isSpecialKey {
            button.backgroundColor = themeProvider.specialKeyBackgroundColor
            button.setTitleColor(themeProvider.specialKeyTextColor, for: .normal)
        } else {
            button.backgroundColor = themeProvider.keyBackgroundColor
            button.setTitleColor(themeProvider.keyTextColor, for: .normal)
        }

        // iOS HIG-compliant styling
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 0.5
        button.layer.borderColor = themeProvider.keyBorderColor.cgColor

        // Subtle shadow for depth
        button.layer.shadowColor = themeProvider.keyShadowColor.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 0

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

        // Haptic feedback
        hapticManager.keyPress()

        // Visual feedback
        animateButtonPress(sender)

        // Delegate callback
        delegate?.keyboardView(self, didPressCyrillicKey: key)
    }

    @objc private func handleDeletePress(_ sender: UIButton) {
        // Haptic feedback
        hapticManager.deleteKey()

        // Visual feedback
        animateButtonPress(sender)

        // Delegate callback
        delegate?.keyboardViewDidPressDelete(self)
    }

    @objc private func handleReturnPress(_ sender: UIButton) {
        // Haptic feedback
        hapticManager.returnKey()

        // Visual feedback
        animateButtonPress(sender)

        // Delegate callback
        delegate?.keyboardViewDidPressReturn(self)
    }

    @objc private func handleSpacePress(_ sender: UIButton) {
        // Haptic feedback
        hapticManager.spaceKey()

        // Visual feedback
        animateButtonPress(sender)

        // Delegate callback
        delegate?.keyboardViewDidPressSpace(self)
    }

    @objc private func handleGlobePress(_ sender: UIButton) {
        // Haptic feedback
        hapticManager.globeKey()

        // Visual feedback
        animateButtonPress(sender)

        // Delegate callback
        delegate?.keyboardViewDidPressGlobe(self)
    }

    @objc private func handleModeToggle(_ sender: UIButton) {
        // Haptic feedback
        hapticManager.modeToggle()

        // Visual feedback
        animateButtonPress(sender)

        // モードを切り替え
        switch currentMode {
        case .cyrillic:
            currentMode = .numbers
        case .numbers, .symbols:
            currentMode = .cyrillic
        }

        // レイアウトを再構築
        buildKeyboardLayout()
    }

    // Smartphone-appropriate: No input mode toggling needed
    // Always use japaneseIME mode with automatic live conversion

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let button = gesture.view as? UIButton,
              let keyLabel = button.currentTitle,
              let popupCharsString = button.accessibilityValue else { return }

        let popupChars = popupCharsString.split(separator: ",").map { String($0) }

        // Haptic feedback for long press
        hapticManager.longPress()

        // Visual feedback
        animateButtonPress(button)

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
    }

    // MARK: - Helper Methods

    // Smartphone-appropriate: No input mode button to update
    // Always use japaneseIME mode with automatic live conversion

    /// 変換候補を表示 (Phase 4: Updated for enhanced UI)
    func showCandidates(_ candidates: [String]) {
        // Convert String candidates to Candidate model
        let candidateModels = candidates.enumerated().map { index, text in
            Candidate(
                id: UUID(),
                text: text,
                reading: text, // For simple string candidates, reading = text
                score: Double(candidates.count - index), // Higher score for earlier candidates
                isLearned: false,
                partOfSpeech: nil
            )
        }
        showCandidates(candidateModels)
    }

    /// 変換候補を表示 (Phase 4: New method with Candidate model)
    func showCandidates(_ candidates: [Candidate], animated: Bool = true) {
        if candidates.isEmpty {
            hideCandidates(animated: animated)
            return
        }

        candidateBarView.updateCandidates(candidates, selectedIndex: 0, animated: animated)
    }

    /// 変換候補を非表示
    func hideCandidates(animated: Bool = true) {
        candidateBarView.hide(animated: animated)
        candidateBarView.clearCandidates()
    }

    // MARK: - Animation

    /// Enhanced button press animation with highlight color
    private func animateButtonPress(_ button: UIButton) {
        let originalBackgroundColor = button.backgroundColor

        // Spring animation for more natural feel
        UIView.animate(
            withDuration: 0.1,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: {
                button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                button.backgroundColor = self.themeProvider.keyHighlightColor
            },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.1,
                    delay: 0,
                    options: [.curveEaseOut, .allowUserInteraction],
                    animations: {
                        button.transform = .identity
                        button.backgroundColor = originalBackgroundColor
                    }
                )
            }
        )
    }

    // MARK: - Theme Management

    /// Called when theme changes (e.g., light/dark mode switch)
    @objc private func themeDidChange() {
        // Rebuild keyboard to apply new theme
        buildKeyboardLayout()

        // Update buffer label colors
        bufferLabel.textColor = themeProvider.bufferTextColor
        bufferLabel.backgroundColor = themeProvider.bufferBackgroundColor

        // Update keyboard background
        themeProvider.applyTheme(to: self)
    }

    // MARK: - Cleanup

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
