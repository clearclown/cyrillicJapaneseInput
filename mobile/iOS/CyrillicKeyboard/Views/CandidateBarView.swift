//
//  CandidateBarView.swift
//  CyrillicKeyboard
//
//  Horizontal scrollable candidate bar with gesture support
//

import UIKit

/// Horizontal candidate bar with swipe gestures
final class CandidateBarView: UIView {
    // MARK: - Properties

    /// Collection view for candidates
    private let collectionView: UICollectionView

    /// Candidates to display
    private var candidates: [Candidate] = []

    /// Currently selected index
    private var selectedIndex: Int = 0

    /// Selection callback
    var onCandidateSelected: ((Int) -> Void)?

    /// Candidate change callback (for Space key cycling)
    var onSelectedIndexChanged: ((Int) -> Void)?

    // MARK: - Initialization

    override init(frame: CGRect) {
        // Setup collection view layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: frame)

        setupViews()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 4

        addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            CandidateCellView.self,
            forCellWithReuseIdentifier: CandidateCellView.reuseIdentifier
        )
    }

    private func setupGestures() {
        // Swipe gestures for candidate navigation
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipe.direction = .left
        addGestureRecognizer(leftSwipe)

        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipe.direction = .right
        addGestureRecognizer(rightSwipe)
    }

    // MARK: - Public Methods

    /// Updates candidates and displays them
    /// - Parameters:
    ///   - candidates: Array of candidates to display
    ///   - selectedIndex: Initially selected index (default 0)
    func updateCandidates(_ candidates: [Candidate], selectedIndex: Int = 0) {
        print("[CandidateBarView] Updating candidates: \(candidates.count) items, selected: \(selectedIndex)")

        self.candidates = candidates
        self.selectedIndex = min(selectedIndex, max(0, candidates.count - 1))

        collectionView.reloadData()

        // Scroll to selected
        if !candidates.isEmpty && self.selectedIndex < candidates.count {
            let indexPath = IndexPath(item: self.selectedIndex, section: 0)
            // Use performBatchUpdates to ensure layout is complete before scrolling
            collectionView.performBatchUpdates(nil) { _ in
                self.collectionView.scrollToItem(
                    at: indexPath,
                    at: .centeredHorizontally,
                    animated: false
                )
            }
        }

        // Animate appearance
        animateAppearance()
    }

    /// Selects candidate at specific index
    /// - Parameter index: Index to select
    func selectCandidate(at index: Int) {
        guard index >= 0 && index < candidates.count else {
            print("[CandidateBarView] Invalid index: \(index)")
            return
        }

        let previousIndex = selectedIndex
        selectedIndex = index

        print("[CandidateBarView] Selected candidate at index \(index): \(candidates[index].text)")

        // Update cells
        var indexPathsToReload: [IndexPath] = []
        if previousIndex < candidates.count {
            indexPathsToReload.append(IndexPath(item: previousIndex, section: 0))
        }
        if index < candidates.count {
            indexPathsToReload.append(IndexPath(item: index, section: 0))
        }

        collectionView.reloadItems(at: indexPathsToReload)

        // Scroll to selected
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)

        // Notify observers
        onSelectedIndexChanged?(index)
    }

    /// Moves to next candidate (wraps around)
    func selectNextCandidate() {
        guard !candidates.isEmpty else { return }
        let next = (selectedIndex + 1) % candidates.count
        selectCandidate(at: next)
    }

    /// Moves to previous candidate (wraps around)
    func selectPreviousCandidate() {
        guard !candidates.isEmpty else { return }
        let prev = (selectedIndex - 1 + candidates.count) % candidates.count
        selectCandidate(at: prev)
    }

    /// Commits the currently selected candidate
    func commitSelectedCandidate() {
        guard selectedIndex < candidates.count else { return }
        onCandidateSelected?(selectedIndex)
    }

    /// Clears all candidates and hides the bar
    func clear() {
        candidates = []
        selectedIndex = 0
        collectionView.reloadData()
    }

    /// Returns the currently selected candidate index
    var currentSelectedIndex: Int {
        return selectedIndex
    }

    /// Returns whether there are any candidates
    var hasCandidates: Bool {
        return !candidates.isEmpty
    }

    // MARK: - Gesture Handlers

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left:
            selectNextCandidate()
        case .right:
            selectPreviousCandidate()
        default:
            break
        }
    }

    // MARK: - Animations

    private func animateAppearance() {
        alpha = 0
        transform = CGAffineTransform(scaleY: 0.8)

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

    /// Animates disappearance and calls completion
    func animateDisappearance(completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleY: 0.8)
            },
            completion: { _ in
                completion?()
            }
        )
    }
}

// MARK: - UICollectionViewDataSource

extension CandidateBarView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return candidates.count
    }

    func collectionView(_ collectionView: UICollectionView,
                       cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CandidateCellView.reuseIdentifier,
            for: indexPath
        ) as! CandidateCellView

        let candidate = candidates[indexPath.item]
        let isSelected = indexPath.item == selectedIndex
        let number = indexPath.item < 9 ? indexPath.item + 1 : nil

        cell.configure(
            candidate: candidate,
            number: number,
            isSelected: isSelected
        )

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension CandidateBarView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("[CandidateBarView] Candidate tapped at index: \(indexPath.item)")
        selectCandidate(at: indexPath.item)
        onCandidateSelected?(indexPath.item)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CandidateBarView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                       layout collectionViewLayout: UICollectionViewLayout,
                       sizeForItemAt indexPath: IndexPath) -> CGSize {
        let candidate = candidates[indexPath.item]
        let width = estimatedWidth(for: candidate)
        let height = collectionView.bounds.height - 8  // Account for insets
        return CGSize(width: width, height: height)
    }

    /// Estimates cell width based on candidate text length
    private func estimatedWidth(for candidate: Candidate) -> CGFloat {
        // Calculate based on text length
        let text = candidate.text as NSString
        let textWidth = text.size(
            withAttributes: [.font: UIFont.systemFont(ofSize: 18, weight: .medium)]
        ).width

        // Add padding for number label and margins
        let padding: CGFloat = 32
        let minWidth: CGFloat = 60

        return max(minWidth, textWidth + padding)
    }
}
