//
//  CandidateCellView.swift
//  CyrillicKeyboard
//
//  Individual candidate cell for the candidate bar
//  Phase 2: Enhanced with ThemeProvider support
//  Phase 4: Candidate UI Enhancement
//

import UIKit

/// Individual candidate cell displaying conversion candidate with number and reading
final class CandidateCellView: UICollectionViewCell {
    // MARK: - Properties

    static let reuseIdentifier = "CandidateCellView"

    /// Theme provider for consistent styling
    private let themeProvider: ThemeProvider = ThemeManager.shared.currentTheme

    // MARK: - UI Components

    /// Candidate number label (1-9)
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    /// Main candidate text label
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = themeProvider.candidateTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()

    /// Reading (hiragana) label
    private let readingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    /// Stack view containing all labels
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .center
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true

        // Add border
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.separator.cgColor

        // Add labels to stack
        stackView.addArrangedSubview(numberLabel)
        stackView.addArrangedSubview(textLabel)
        stackView.addArrangedSubview(readingLabel)

        contentView.addSubview(stackView)

        // Listen for theme changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: .themeDidChange,
            object: nil
        )
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])

        // Number label height
        numberLabel.heightAnchor.constraint(equalToConstant: 12).isActive = true

        // Text label gets most of the space
        textLabel.setContentHuggingPriority(.defaultLow, for: .vertical)

        // Reading label height
        readingLabel.heightAnchor.constraint(equalToConstant: 12).isActive = true
    }

    // MARK: - Configuration

    /// Configures the cell with candidate data
    /// - Parameters:
    ///   - candidate: The candidate to display
    ///   - number: Optional number (1-9) to show
    ///   - isSelected: Whether this candidate is currently selected
    func configure(with candidate: Candidate, number: Int?, isSelected: Bool) {
        // Set number
        if let number = number {
            numberLabel.text = "①②③④⑤⑥⑦⑧⑨"[number - 1]
            numberLabel.isHidden = false
        } else {
            numberLabel.isHidden = true
        }

        // Set main text
        textLabel.text = candidate.text

        // Set reading (if different from text)
        if candidate.reading != candidate.text {
            readingLabel.text = candidate.reading
            readingLabel.isHidden = false
        } else {
            readingLabel.isHidden = true
        }

        // Update appearance based on selection
        updateAppearance(isSelected: isSelected)
    }

    // MARK: - Private Methods

    private func updateAppearance(isSelected: Bool) {
        if isSelected {
            // Selected state - use theme colors
            contentView.backgroundColor = themeProvider.selectedCandidateBackgroundColor
            contentView.layer.borderColor = themeProvider.selectedCandidateColor.cgColor
            contentView.layer.borderWidth = 2

            textLabel.font = .systemFont(ofSize: 18, weight: .bold)
            textLabel.textColor = themeProvider.selectedCandidateColor

            numberLabel.textColor = themeProvider.selectedCandidateColor.withAlphaComponent(0.8)
            readingLabel.textColor = themeProvider.selectedCandidateColor.withAlphaComponent(0.8)

            // Scale animation with spring effect
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5,
                options: [.curveEaseOut],
                animations: {
                    self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                }
            )
        } else {
            // Normal state - use theme colors
            contentView.backgroundColor = .secondarySystemBackground
            contentView.layer.borderColor = UIColor.separator.cgColor
            contentView.layer.borderWidth = 1

            textLabel.font = .systemFont(ofSize: 16)
            textLabel.textColor = themeProvider.candidateTextColor

            numberLabel.textColor = .secondaryLabel
            readingLabel.textColor = .tertiaryLabel

            // Reset scale with spring effect
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.7,
                initialSpringVelocity: 0.5,
                options: [.curveEaseOut],
                animations: {
                    self.transform = .identity
                }
            )
        }
    }

    // MARK: - Theme Management

    @objc private func themeDidChange() {
        // Re-apply current selection state with new theme
        setNeedsLayout()
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        textLabel.text = nil
        readingLabel.text = nil
        numberLabel.text = nil
        numberLabel.isHidden = false
        readingLabel.isHidden = false
        transform = .identity
    }

    // MARK: - Cleanup

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - String Extension for Circled Numbers

private extension String {
    subscript(index: Int) -> String {
        let start = self.index(self.startIndex, offsetBy: index)
        let end = self.index(start, offsetBy: 1)
        return String(self[start..<end])
    }
}
