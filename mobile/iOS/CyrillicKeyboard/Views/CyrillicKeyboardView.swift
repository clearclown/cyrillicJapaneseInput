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
}

// MARK: - Main View

class CyrillicKeyboardView: UIView {
    // MARK: - Properties

    weak var delegate: CyrillicKeyboardViewDelegate?

    private var profile: Profile
    private var keyButtons: [UIButton] = []

    /// 入力バッファ表示ラベル
    private let bufferLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .label
        label.backgroundColor = .systemBackground
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// キーボードコンテナ
    private let keyboardContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

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

        // バッファラベルを追加
        addSubview(bufferLabel)
        addSubview(keyboardContainer)

        NSLayoutConstraint.activate([
            bufferLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            bufferLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            bufferLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            bufferLabel.heightAnchor.constraint(equalToConstant: 30),

            keyboardContainer.topAnchor.constraint(equalTo: bufferLabel.bottomAnchor, constant: 4),
            keyboardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyboardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            keyboardContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // キーボードレイアウトを構築
        buildKeyboardLayout()
    }

    // MARK: - Keyboard Layout

    private func buildKeyboardLayout() {
        // 既存のボタンをクリア
        keyButtons.forEach { $0.removeFromSuperview() }
        keyButtons.removeAll()

        let layout = profile.keyboardLayout

        // 簡易的な3行レイアウト（10キーずつ）
        // 実際のプロダクションでは、より洗練されたレイアウトロジックが必要
        let keysPerRow = [10, 9, 7]  // 各行のキー数
        var currentIndex = 0

        let rowStackView = UIStackView()
        rowStackView.axis = .vertical
        rowStackView.distribution = .fillEqually
        rowStackView.spacing = 8
        rowStackView.translatesAutoresizingMaskIntoConstraints = false

        keyboardContainer.addSubview(rowStackView)

        NSLayoutConstraint.activate([
            rowStackView.topAnchor.constraint(equalTo: keyboardContainer.topAnchor, constant: 8),
            rowStackView.leadingAnchor.constraint(equalTo: keyboardContainer.leadingAnchor, constant: 4),
            rowStackView.trailingAnchor.constraint(equalTo: keyboardContainer.trailingAnchor, constant: -4),
            rowStackView.bottomAnchor.constraint(equalTo: keyboardContainer.bottomAnchor, constant: -8)
        ])

        // 第1行〜第3行
        for rowIndex in 0..<3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 4

            let keyCount = keysPerRow[rowIndex]
            for _ in 0..<keyCount {
                guard currentIndex < layout.count else { break }
                let key = layout[currentIndex]
                let button = createKeyButton(title: key, action: #selector(handleCyrillicKeyPress(_:)))
                rowStack.addArrangedSubview(button)
                keyButtons.append(button)
                currentIndex += 1
            }

            rowStackView.addArrangedSubview(rowStack)
        }

        // 第4行：特殊キー（Globe, Space, Delete, Return）
        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.distribution = .fill
        bottomRow.spacing = 4

        let globeButton = createKeyButton(title: "🌐", action: #selector(handleGlobePress))
        globeButton.widthAnchor.constraint(equalToConstant: 50).isActive = true

        let spaceButton = createKeyButton(title: "空白", action: #selector(handleSpacePress))

        let deleteButton = createKeyButton(title: "⌫", action: #selector(handleDeletePress))
        deleteButton.widthAnchor.constraint(equalToConstant: 70).isActive = true

        let returnButton = createKeyButton(title: "改行", action: #selector(handleReturnPress))
        returnButton.widthAnchor.constraint(equalToConstant: 70).isActive = true

        bottomRow.addArrangedSubview(globeButton)
        bottomRow.addArrangedSubview(spaceButton)
        bottomRow.addArrangedSubview(deleteButton)
        bottomRow.addArrangedSubview(returnButton)

        rowStackView.addArrangedSubview(bottomRow)
    }

    private func createKeyButton(title: String, action: Selector) -> UIButton {
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

    // MARK: - Button Actions

    @objc private func handleCyrillicKeyPress(_ sender: UIButton) {
        guard let key = sender.currentTitle else { return }
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
