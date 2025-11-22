//
//  KeyboardLayoutPreview.swift
//  CyrillicIME
//
//  Preview of keyboard layouts for different profiles
//  Phase 5: Settings & User Experience
//

import SwiftUI

struct KeyboardLayoutPreview: View {
    @StateObject private var profileManager = ProfileManager.shared
    @State private var selectedProfileId: String

    init() {
        let currentId = ProfileManager.shared.currentProfile?.id ?? "rus_standard"
        _selectedProfileId = State(initialValue: currentId)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Profile Selector
            if profileManager.availableProfiles.count > 1 {
                Picker("プロファイル", selection: $selectedProfileId) {
                    ForEach(profileManager.availableProfiles) { profile in
                        Text(profile.nameJa).tag(profile.id)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }

            // Profile Info
            if let profile = profileManager.availableProfiles.first(where: { $0.id == selectedProfileId }) {
                VStack(spacing: 8) {
                    Text(profile.nameJa)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(profile.nameEn)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                // Keyboard Layout Preview
                ScrollView {
                    KeyboardPreviewGrid(profile: profile)
                        .padding()
                }
            }

            Spacer()
        }
        .navigationTitle("レイアウトプレビュー")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Keyboard Preview Grid

struct KeyboardPreviewGrid: View {
    let profile: Profile

    var body: some View {
        VStack(spacing: 12) {
            // Row 1
            KeyboardRow(keys: profile.keyboardLayout.row1)

            // Row 2
            KeyboardRow(keys: profile.keyboardLayout.row2)

            // Row 3 with Shift key
            HStack(spacing: 6) {
                // Shift key
                KeyPreviewButton(
                    label: "⇧",
                    width: 44,
                    isSpecial: true
                )

                KeyboardRow(keys: profile.keyboardLayout.row3)

                // Delete key
                KeyPreviewButton(
                    label: "⌫",
                    width: 44,
                    isSpecial: true
                )
            }

            // Bottom row (Space, Return, etc.)
            HStack(spacing: 6) {
                KeyPreviewButton(
                    label: "🌐",
                    width: 44,
                    isSpecial: true
                )

                KeyPreviewButton(
                    label: "スペース",
                    width: 200,
                    isSpecial: true
                )

                KeyPreviewButton(
                    label: "改行",
                    width: 60,
                    isSpecial: false,
                    backgroundColor: .blue,
                    foregroundColor: .white
                )
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

struct KeyboardRow: View {
    let keys: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(keys, id: \.self) { key in
                KeyPreviewButton(label: key, width: 32)
            }
        }
    }
}

// MARK: - Key Preview Button

struct KeyPreviewButton: View {
    let label: String
    var width: CGFloat = 32
    var isSpecial: Bool = false
    var backgroundColor: Color = .white
    var foregroundColor: Color = .primary

    var body: some View {
        Text(label)
            .font(.system(size: isSpecial ? 16 : 20))
            .fontWeight(isSpecial ? .regular : .medium)
            .frame(width: width, height: 44)
            .background(isSpecial ? Color(.systemGray4) : backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(5)
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Preview

struct KeyboardLayoutPreview_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            KeyboardLayoutPreview()
        }
    }
}
