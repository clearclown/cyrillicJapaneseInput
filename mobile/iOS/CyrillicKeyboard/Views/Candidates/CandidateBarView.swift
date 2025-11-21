//
//  CandidateBarView.swift
//  CyrillicKeyboard
//
//  Horizontal scrollable candidate bar for kanji conversion
//  Phase 4: Candidate UI Enhancement
//

import UIKit

/// Horizontal candidate bar displaying conversion candidates
final class CandidateBarView: UIView {
    // MARK: - Properties

    /// Collection view for displaying candidates
    private let collectionView: UICollectionView

    /// Current candidates to display
    private var candidates: [Candidate] = []

    /// Currently selected candidate index
    private var selectedIndex: Int = 0

    /// Maximum number of candidates to show with numbers
    private let maxNumberedCandidates = 9

    // MARK: - Callbacks

    /// Called when user selects a candidate
    var onCandidateSelected: ((Candidate, Int) -> Void)?

    /// Called when user requests more candidates
    var onLoadMore: (() -> Void)?

    // MARK: - UI Components

    /// Expand button to show all candidates
    private let expandButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("▼", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .label
        return button
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        // Create collection view layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(frame: frame)

        setupUI()
        setupCollectionView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .systemBackground
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 4
    }

    private func setupCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CandidateCellView.self, forCellWithReuseIdentifier: CandidateCellView.reuseIdentifier)

        addSubview(collectionView)
        addSubview(expandButton)

        expandButton.addTarget(self, action: #selector(expandButtonTapped), for: .touchUpInside)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Collection view
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: expandButton.leadingAnchor, constant: -8),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Expand button
            expandButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            expandButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            expandButton.widthAnchor.constraint(equalToConstant: 30),
            expandButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    // MARK: - Public Methods

    /// Updates candidates and reloads the view
    /// - Parameters:
    ///   - candidates: New candidates to display
    ///   - selectedIndex: Index of the currently selected candidate
    func updateCandidates(_ candidates: [Candidate], selectedIndex: Int = 0) {
        self.candidates = candidates
        self.selectedIndex = min(selectedIndex, candidates.count - 1)

        collectionView.reloadData()

        // Scroll to selected candidate with animation
        if selectedIndex < candidates.count {
            let indexPath = IndexPath(item: selectedIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }

        // Animate appearance
        animateAppearance()
    }

    /// Clears all candidates
    func clearCandidates() {
        candidates.removeAll()
        collectionView.reloadData()
    }

    /// Selects next candidate
    func selectNext() {
        guard !candidates.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % candidates.count
        collectionView.reloadData()
        scrollToSelectedCandidate()
    }

    /// Selects previous candidate
    func selectPrevious() {
        guard !candidates.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + candidates.count) % candidates.count
        collectionView.reloadData()
        scrollToSelectedCandidate()
    }

    /// Selects candidate by number (1-9)
    /// - Parameter number: Number key pressed (1-9)
    func selectByNumber(_ number: Int) {
        guard number >= 1, number <= maxNumberedCandidates,
              number <= candidates.count else { return }

        let index = number - 1
        let candidate = candidates[index]
        onCandidateSelected?(candidate, index)
    }

    // MARK: - Private Methods

    private func scrollToSelectedCandidate() {
        guard selectedIndex < candidates.count else { return }

        let indexPath = IndexPath(item: selectedIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    private func animateAppearance() {
        alpha = 0
        transform = CGAffineTransform(scaleX: 1.0, y: 0.8)

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                self.alpha = 1.0
                self.transform = .identity
            }
        )
    }

    @objc private func expandButtonTapped() {
        onLoadMore?()
    }

    // MARK: - Size Calculation

    /// Recommended height for the candidate bar
    static var preferredHeight: CGFloat {
        return 60.0
    }
}

// MARK: - UICollectionViewDataSource

extension CandidateBarView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return candidates.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CandidateCellView.reuseIdentifier,
            for: indexPath
        ) as? CandidateCellView else {
            return UICollectionViewCell()
        }

        let candidate = candidates[indexPath.item]
        let isSelected = indexPath.item == selectedIndex
        let number = (indexPath.item < maxNumberedCandidates) ? indexPath.item + 1 : nil

        cell.configure(with: candidate, number: number, isSelected: isSelected)

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension CandidateBarView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let candidate = candidates[indexPath.item]
        selectedIndex = indexPath.item
        collectionView.reloadData()
        onCandidateSelected?(candidate, indexPath.item)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CandidateBarView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let candidate = candidates[indexPath.item]
        let isSelected = indexPath.item == selectedIndex

        // Calculate width based on text content
        let text = candidate.text
        let font = isSelected ? UIFont.systemFont(ofSize: 18, weight: .bold) : UIFont.systemFont(ofSize: 16)
        let width = (text as NSString).size(withAttributes: [.font: font]).width + 40 // Padding

        return CGSize(width: max(width, 60), height: 50)
    }
}
