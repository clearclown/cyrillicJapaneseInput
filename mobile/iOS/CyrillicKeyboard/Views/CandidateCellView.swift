//
//  CandidateCellView.swift
//  CyrillicKeyboard
//
//  Individual candidate cell for display in candidate bar
//

import UIKit

/// Candidate cell in candidate bar
final class CandidateCellView: UICollectionViewCell {
    static let reuseIdentifier = "CandidateCellView"

    // MARK: - UI Components

    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let mainLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let readingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGray
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let typeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.textColor = .systemGray2
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray4.cgColor
        contentView.backgroundColor = .systemBackground

        contentView.addSubview(numberLabel)
        contentView.addSubview(mainLabel)
        contentView.addSubview(readingLabel)
        contentView.addSubview(typeLabel)

        NSLayoutConstraint.activate([
            // Number label (top-left corner)
            numberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            numberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),

            // Main label (centered, larger)
            mainLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -8),
            mainLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            mainLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            // Reading label (below main)
            readingLabel.topAnchor.constraint(equalTo: mainLabel.bottomAnchor, constant: 2),
            readingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            readingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),

            // Type label (bottom)
            typeLabel.topAnchor.constraint(equalTo: readingLabel.bottomAnchor, constant: 2),
            typeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            typeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            typeLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -4)
        ])
    }

    // MARK: - Configuration

    /// Configures the cell with a candidate
    /// - Parameters:
    ///   - candidate: The candidate to display
    ///   - number: Optional number (1-9) for quick selection
    ///   - isSelected: Whether this candidate is currently selected
    func configure(candidate: Candidate, number: Int?, isSelected: Bool) {
        // Number (①②③④⑤⑥⑦⑧⑨)
        if let number = number, number >= 1 && number <= 9 {
            let circledNumbers = ["①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨"]
            numberLabel.text = circledNumbers[number - 1]
            numberLabel.isHidden = false
        } else {
            numberLabel.isHidden = true
        }

        // Main text
        mainLabel.text = candidate.text

        // Reading (for kanji candidates)
        if candidate.type == .kanji, let reading = candidate.metadata?.reading {
            readingLabel.text = reading
            readingLabel.isHidden = false
        } else {
            readingLabel.isHidden = true
        }

        // Type label
        let typeText = typeDescription(for: candidate.type)
        if typeText.isEmpty {
            typeLabel.isHidden = true
        } else {
            typeLabel.text = typeText
            typeLabel.isHidden = false
        }

        // Selection state
        updateSelectionState(isSelected: isSelected)
    }

    /// Updates the visual selection state
    private func updateSelectionState(isSelected: Bool) {
        if isSelected {
            contentView.backgroundColor = .systemBlue
            contentView.layer.borderColor = UIColor.systemBlue.cgColor
            mainLabel.textColor = .white
            readingLabel.textColor = .white
            typeLabel.textColor = .white
            numberLabel.textColor = .white

            // Scale animation
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut]) {
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }
        } else {
            contentView.backgroundColor = .systemBackground
            contentView.layer.borderColor = UIColor.systemGray4.cgColor
            mainLabel.textColor = .label
            readingLabel.textColor = .systemGray
            typeLabel.textColor = .systemGray2
            numberLabel.textColor = .systemGray

            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut]) {
                self.transform = .identity
            }
        }
    }

    /// Returns type description for display
    private func typeDescription(for type: CandidateType) -> String {
        switch type {
        case .kanji:
            return ""  // Don't show type for kanji (reading is shown instead)
        case .hiragana:
            return "ひらがな"
        case .katakana:
            return "カタカナ"
        case .userDictionary:
            return "ユーザー"
        }
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        mainLabel.text = nil
        readingLabel.text = nil
        typeLabel.text = nil
        numberLabel.text = nil
        transform = .identity
    }
}
