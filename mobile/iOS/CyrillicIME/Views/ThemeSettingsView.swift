//
//  ThemeSettingsView.swift
//  Cyrillic IME
//
//  Keyboard theme and appearance settings
//

import SwiftUI

struct ThemeSettingsView: View {
    @StateObject private var settings = SettingsStore.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Form {
            // Theme selection section
            themeSelectionSection

            // Theme preview section
            themePreviewSection
        }
        .navigationTitle("テーマ")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - View Components

    private var themeSelectionSection: some View {
        Section {
            ForEach(KeyboardTheme.allCases, id: \.self) { theme in
                ThemeOptionRow(
                    theme: theme,
                    isSelected: settings.keyboardTheme == theme,
                    onSelect: {
                        settings.keyboardTheme = theme
                    }
                )
            }
        } header: {
            Text("外観")
        } footer: {
            Text("キーボードの配色を選択します。「システム連動」を選択すると、iOSのダークモード設定に従います")
        }
    }

    private var themePreviewSection: some View {
        Section {
            VStack(spacing: 16) {
                Text("プレビュー")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                KeyboardThemePreview(
                    theme: effectiveTheme,
                    colorScheme: colorScheme
                )
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Computed Properties

    private var effectiveTheme: KeyboardTheme {
        if settings.keyboardTheme == .system {
            return colorScheme == .dark ? .dark : .light
        }
        return settings.keyboardTheme
    }
}

// MARK: - Theme Option Row

struct ThemeOptionRow: View {
    let theme: KeyboardTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.displayName)
                        .font(.body)
                        .foregroundColor(.primary)

                    if theme == .system {
                        Text("iOSの設定に従う")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Keyboard Theme Preview

struct KeyboardThemePreview: View {
    let theme: KeyboardTheme
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 6) {
            // Row 1
            HStack(spacing: 4) {
                ForEach(["Й", "Ц", "У", "К", "Е", "Н", "Г"], id: \.self) { key in
                    KeyPreview(key: key, theme: theme, colorScheme: colorScheme)
                }
            }

            // Row 2
            HStack(spacing: 4) {
                Spacer().frame(width: 20)
                ForEach(["Ф", "Ы", "В", "А", "П", "Р", "О"], id: \.self) { key in
                    KeyPreview(key: key, theme: theme, colorScheme: colorScheme)
                }
                Spacer()
            }

            // Row 3
            HStack(spacing: 4) {
                Spacer().frame(width: 40)
                ForEach(["Я", "Ч", "С", "М", "И", "Т"], id: \.self) { key in
                    KeyPreview(key: key, theme: theme, colorScheme: colorScheme)
                }
                Spacer()
            }
        }
        .padding()
        .background(keyboardBackground)
        .cornerRadius(12)
    }

    private var keyboardBackground: Color {
        switch theme {
        case .light:
            return Color(.systemGray5)
        case .dark:
            return Color(.systemGray6)
        case .system:
            return colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5)
        }
    }
}

// MARK: - Key Preview

struct KeyPreview: View {
    let key: String
    let theme: KeyboardTheme
    let colorScheme: ColorScheme

    var body: some View {
        Text(key)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(keyTextColor)
            .frame(minWidth: 28, minHeight: 36)
            .background(keyBackground)
            .cornerRadius(5)
            .shadow(color: keyShadow, radius: 1, x: 0, y: 1)
    }

    private var keyBackground: Color {
        switch theme {
        case .light:
            return .white
        case .dark:
            return Color(.systemGray4)
        case .system:
            return colorScheme == .dark ? Color(.systemGray4) : .white
        }
    }

    private var keyTextColor: Color {
        switch theme {
        case .light:
            return .black
        case .dark:
            return .white
        case .system:
            return colorScheme == .dark ? .white : .black
        }
    }

    private var keyShadow: Color {
        switch theme {
        case .light:
            return Color.black.opacity(0.1)
        case .dark:
            return Color.black.opacity(0.3)
        case .system:
            return colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ThemeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                ThemeSettingsView()
            }
            .preferredColorScheme(.light)

            NavigationView {
                ThemeSettingsView()
            }
            .preferredColorScheme(.dark)
        }
    }
}
#endif
