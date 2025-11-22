//
//  HapticManager.swift
//  Shared
//
//  Haptic feedback manager for iOS keyboard
//  Phase 2: iOS HIG Compliance & UI/UX Improvements
//

import UIKit

// MARK: - Haptic Manager

/// Manages haptic feedback for keyboard interactions
/// Provides consistent tactile feedback across all keyboard actions
class HapticManager {
    // MARK: - Singleton

    static let shared = HapticManager()

    // MARK: - Haptic Generators

    /// Light impact for regular key presses
    private let impactLight = UIImpactFeedbackGenerator(style: .light)

    /// Medium impact for special actions
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)

    /// Heavy impact for important actions
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)

    /// Selection feedback for navigating through options
    private let selectionFeedback = UISelectionFeedbackGenerator()

    /// Notification feedback for success/error states
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // MARK: - Settings

    /// Whether haptic feedback is enabled (can be set by user preferences)
    var isEnabled: Bool = true

    // MARK: - Initialization

    private init() {
        prepareHaptics()
    }

    // MARK: - Preparation

    /// Prepares all haptic generators for immediate use
    /// Call this when keyboard is about to be shown for better responsiveness
    func prepareHaptics() {
        guard isEnabled else { return }

        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }

    // MARK: - Haptic Triggers

    /// Triggers haptic feedback for a regular key press (Cyrillic character, number, symbol)
    func keyPress() {
        guard isEnabled else { return }
        impactLight.impactOccurred()
        impactLight.prepare() // Prepare for next use
    }

    /// Triggers haptic feedback for delete key
    /// Slightly softer than regular key press
    func deleteKey() {
        guard isEnabled else { return }
        impactLight.impactOccurred(intensity: 0.7)
        impactLight.prepare()
    }

    /// Triggers haptic feedback for space key
    func spaceKey() {
        guard isEnabled else { return }
        impactLight.impactOccurred(intensity: 0.8)
        impactLight.prepare()
    }

    /// Triggers haptic feedback for return/enter key
    func returnKey() {
        guard isEnabled else { return }
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }

    /// Triggers haptic feedback for globe key (keyboard switcher)
    func globeKey() {
        guard isEnabled else { return }
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }

    /// Triggers haptic feedback for mode toggle (123/АБВ, input mode switch)
    func modeToggle() {
        guard isEnabled else { return }
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }

    /// Triggers haptic feedback when starting kanji conversion
    func conversionStart() {
        guard isEnabled else { return }
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }

    /// Triggers haptic feedback when committing a conversion
    func conversionCommit() {
        guard isEnabled else { return }
        notificationFeedback.notificationOccurred(.success)
        notificationFeedback.prepare()
    }

    /// Triggers haptic feedback when canceling a conversion
    func conversionCancel() {
        guard isEnabled else { return }
        impactLight.impactOccurred()
        impactLight.prepare()
    }

    /// Triggers haptic feedback when selecting a candidate
    func candidateSelect() {
        guard isEnabled else { return }
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare()
    }

    /// Triggers haptic feedback when navigating between candidates
    func candidateNavigate() {
        guard isEnabled else { return }
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare()
    }

    /// Triggers haptic feedback for long press popup
    func longPress() {
        guard isEnabled else { return }
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }

    /// Triggers haptic feedback for error states
    func error() {
        guard isEnabled else { return }
        notificationFeedback.notificationOccurred(.error)
        notificationFeedback.prepare()
    }

    /// Triggers haptic feedback for warning states
    func warning() {
        guard isEnabled else { return }
        notificationFeedback.notificationOccurred(.warning)
        notificationFeedback.prepare()
    }

    /// Triggers haptic feedback for successful operations
    func success() {
        guard isEnabled else { return }
        notificationFeedback.notificationOccurred(.success)
        notificationFeedback.prepare()
    }

    // MARK: - Advanced Haptics

    /// Triggers a custom impact with specific intensity
    /// - Parameter intensity: Intensity value between 0.0 and 1.0
    func customImpact(intensity: CGFloat) {
        guard isEnabled else { return }
        let clampedIntensity = max(0.0, min(1.0, intensity))

        if clampedIntensity < 0.4 {
            impactLight.impactOccurred(intensity: clampedIntensity)
            impactLight.prepare()
        } else if clampedIntensity < 0.7 {
            impactMedium.impactOccurred(intensity: clampedIntensity)
            impactMedium.prepare()
        } else {
            impactHeavy.impactOccurred(intensity: clampedIntensity)
            impactHeavy.prepare()
        }
    }

    // MARK: - Cleanup

    /// Releases all haptic generators
    /// Call this when keyboard is dismissed to free resources
    func cleanup() {
        // Haptic generators are automatically released when not in use
        // This method is provided for explicit cleanup if needed
    }
}

// MARK: - UserDefaults Extension for Haptic Settings

extension UserDefaults {
    private static let hapticEnabledKey = "com.pismo.hapticEnabled"

    /// Whether haptic feedback is enabled in user preferences
    var isHapticEnabled: Bool {
        get {
            // Default to true if not set
            if object(forKey: Self.hapticEnabledKey) == nil {
                return true
            }
            return bool(forKey: Self.hapticEnabledKey)
        }
        set {
            set(newValue, forKey: Self.hapticEnabledKey)
            HapticManager.shared.isEnabled = newValue
        }
    }
}
