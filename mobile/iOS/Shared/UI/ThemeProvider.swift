//
//  ThemeProvider.swift
//  Shared
//
//  iOS HIG-compliant theme provider with dark mode support
//  Phase 2: iOS HIG Compliance & UI/UX Improvements
//

import UIKit

// MARK: - Theme Provider Protocol

/// Protocol defining theme properties for the keyboard
protocol ThemeProvider {
    // Key colors
    var keyBackgroundColor: UIColor { get }
    var keyTextColor: UIColor { get }
    var keyHighlightColor: UIColor { get }
    var keyBorderColor: UIColor { get }
    var keyShadowColor: UIColor { get }

    // Keyboard background
    var keyboardBackgroundColor: UIColor { get }

    // Buffer label
    var bufferBackgroundColor: UIColor { get }
    var bufferTextColor: UIColor { get }

    // Candidate bar colors
    var candidateBarBackgroundColor: UIColor { get }
    var candidateTextColor: UIColor { get }
    var selectedCandidateColor: UIColor { get }
    var selectedCandidateBackgroundColor: UIColor { get }

    // Special keys (space, delete, return)
    var specialKeyBackgroundColor: UIColor { get }
    var specialKeyTextColor: UIColor { get }

    // Apply theme to a view
    func applyTheme(to view: UIView)
}

// MARK: - Default iOS HIG-Compliant Theme

/// Default theme implementation following iOS Human Interface Guidelines
/// Supports both light and dark modes with dynamic color adaptation
class DefaultThemeProvider: ThemeProvider {

    // MARK: - Key Colors

    /// Background color for regular keys
    /// Light mode: White, Dark mode: Dark gray
    var keyBackgroundColor: UIColor {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(white: 0.25, alpha: 1.0)
            default:
                return UIColor.white
            }
        }
    }

    /// Text color for key labels (automatically adapts to light/dark mode)
    var keyTextColor: UIColor {
        return .label
    }

    /// Highlight color when key is pressed
    var keyHighlightColor: UIColor {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(white: 0.35, alpha: 1.0)
            default:
                return UIColor.systemGray5
            }
        }
    }

    /// Border color for keys
    var keyBorderColor: UIColor {
        return .separator
    }

    /// Shadow color for keys
    var keyShadowColor: UIColor {
        return UIColor.black.withAlphaComponent(0.1)
    }

    // MARK: - Keyboard Background

    /// Background color for the entire keyboard
    /// Matches iOS standard keyboard appearance
    var keyboardBackgroundColor: UIColor {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
            default:
                return UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1.0)
            }
        }
    }

    // MARK: - Buffer Label

    /// Background color for buffer label
    var bufferBackgroundColor: UIColor {
        return .systemBackground
    }

    /// Text color for buffer label
    var bufferTextColor: UIColor {
        return .label
    }

    // MARK: - Candidate Bar Colors

    /// Background color for candidate bar
    var candidateBarBackgroundColor: UIColor {
        return .secondarySystemBackground
    }

    /// Text color for candidates
    var candidateTextColor: UIColor {
        return .label
    }

    /// Highlight color for selected candidate
    var selectedCandidateColor: UIColor {
        return .systemBlue
    }

    /// Background color for selected candidate
    var selectedCandidateBackgroundColor: UIColor {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor.systemBlue.withAlphaComponent(0.3)
            default:
                return UIColor.systemBlue.withAlphaComponent(0.15)
            }
        }
    }

    // MARK: - Special Keys

    /// Background color for special keys (space, delete, return)
    var specialKeyBackgroundColor: UIColor {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(white: 0.20, alpha: 1.0)
            default:
                return UIColor.systemGray6
            }
        }
    }

    /// Text color for special keys
    var specialKeyTextColor: UIColor {
        return .label
    }

    // MARK: - Apply Theme

    /// Applies theme to a view
    /// - Parameter view: View to apply theme to
    func applyTheme(to view: UIView) {
        view.backgroundColor = keyboardBackgroundColor
        view.tintColor = .systemBlue

        // Ensure view updates when trait collection changes (light/dark mode switch)
        if #available(iOS 13.0, *) {
            view.overrideUserInterfaceStyle = .unspecified
        }
    }
}

// MARK: - Theme Manager

/// Singleton manager for accessing the current theme
class ThemeManager {
    static let shared = ThemeManager()

    /// Current theme provider
    private(set) var currentTheme: ThemeProvider

    private init() {
        self.currentTheme = DefaultThemeProvider()
    }

    /// Updates the current theme
    /// - Parameter theme: New theme to use
    func setTheme(_ theme: ThemeProvider) {
        self.currentTheme = theme
        // Post notification for views to update
        NotificationCenter.default.post(name: .themeDidChange, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when theme changes
    static let themeDidChange = Notification.Name("themeDidChange")
}
