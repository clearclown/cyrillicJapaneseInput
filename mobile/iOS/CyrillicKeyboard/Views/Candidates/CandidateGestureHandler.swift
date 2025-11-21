//
//  CandidateGestureHandler.swift
//  CyrillicKeyboard
//
//  Handles swipe gestures for candidate bar interactions
//  Phase 4: Candidate UI Enhancement
//

import UIKit

/// Handles gestures for candidate bar
final class CandidateGestureHandler: NSObject {
    // MARK: - Properties

    /// Candidate bar to manage
    private weak var candidateBar: CandidateBarView?

    /// Minimum swipe distance to trigger action (points)
    private let minimumSwipeDistance: CGFloat = 50

    /// Swipe velocity threshold (points per second)
    private let velocityThreshold: CGFloat = 500

    // MARK: - Callbacks

    /// Called when user swipes right (previous candidate)
    var onSwipeRight: (() -> Void)?

    /// Called when user swipes left (next candidate)
    var onSwipeLeft: (() -> Void)?

    /// Called when user swipes up (expand candidates)
    var onSwipeUp: (() -> Void)?

    /// Called when user swipes down (collapse candidates)
    var onSwipeDown: (() -> Void)?

    // MARK: - Gesture Recognizers

    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!

    // MARK: - Initialization

    /// Initializes gesture handler for a candidate bar
    /// - Parameter candidateBar: The candidate bar to attach gestures to
    init(candidateBar: CandidateBarView) {
        self.candidateBar = candidateBar
        super.init()
        setupGestures()
    }

    // MARK: - Setup

    private func setupGestures() {
        guard let candidateBar = candidateBar else { return }

        // Pan gesture for swipe detection
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGestureRecognizer.delegate = self
        candidateBar.addGestureRecognizer(panGestureRecognizer)

        // Tap gesture (handled by collection view delegate, but we add this for backup)
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGestureRecognizer.delegate = self
        candidateBar.addGestureRecognizer(tapGestureRecognizer)
    }

    // MARK: - Gesture Handlers

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }

        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .ended, .cancelled:
            handlePanEnded(translation: translation, velocity: velocity)

        default:
            break
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // Tap is primarily handled by collection view delegate
        // This is here for completeness
    }

    // MARK: - Private Methods

    private func handlePanEnded(translation: CGPoint, velocity: CGPoint) {
        // Determine swipe direction based on translation and velocity
        let horizontalSwipe = abs(translation.x) > abs(translation.y)
        let verticalSwipe = abs(translation.y) > abs(translation.x)

        // Horizontal swipe (left/right)
        if horizontalSwipe {
            if translation.x > minimumSwipeDistance || velocity.x > velocityThreshold {
                // Swipe right (previous candidate)
                onSwipeRight?()
                hapticFeedback(.light)
            } else if translation.x < -minimumSwipeDistance || velocity.x < -velocityThreshold {
                // Swipe left (next candidate)
                onSwipeLeft?()
                hapticFeedback(.light)
            }
        }

        // Vertical swipe (up/down)
        if verticalSwipe {
            if translation.y < -minimumSwipeDistance || velocity.y < -velocityThreshold {
                // Swipe up (expand)
                onSwipeUp?()
                hapticFeedback(.light)
            } else if translation.y > minimumSwipeDistance || velocity.y > velocityThreshold {
                // Swipe down (collapse)
                onSwipeDown?()
                hapticFeedback(.light)
            }
        }
    }

    /// Triggers haptic feedback
    /// - Parameter style: Feedback style
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension CandidateGestureHandler: UIGestureRecognizerDelegate {
    /// Allows simultaneous gesture recognition
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow pan and tap to work together
        if gestureRecognizer == panGestureRecognizer && otherGestureRecognizer == tapGestureRecognizer {
            return true
        }
        if gestureRecognizer == tapGestureRecognizer && otherGestureRecognizer == panGestureRecognizer {
            return true
        }

        // Allow collection view scrolling to work
        return otherGestureRecognizer.view is UICollectionView
    }

    /// Determines if gesture should begin
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }

            let velocity = pan.velocity(in: pan.view)
            let translation = pan.translation(in: pan.view)

            // Only handle vertical swipes or fast horizontal swipes
            // Let collection view handle slow horizontal scrolling
            if abs(velocity.y) > abs(velocity.x) {
                // Vertical swipe - handle it
                return true
            } else if abs(velocity.x) > velocityThreshold {
                // Fast horizontal swipe - handle it
                return true
            } else if abs(translation.x) > minimumSwipeDistance {
                // Large horizontal movement - handle it
                return true
            }

            // Let collection view handle normal scrolling
            return false
        }

        return true
    }
}
