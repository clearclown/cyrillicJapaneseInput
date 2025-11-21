//
//  ProfileSelectionView.swift
//  CyrillicIME
//
//  Profile selection sheet
//  Phase 5: Profile and Settings UI
//

import SwiftUI

struct ProfileSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileManager = ProfileManager.shared
    @State private var selectedProfileId: String

    init() {
        _selectedProfileId = State(initialValue: ProfileManager.shared.currentProfile?.id ?? "rus_standard")
    }

    var body: some View {
        NavigationView {
            List(profileManager.availableProfiles, id: \.id) { profile in
                Button(action: {
                    selectedProfileId = profile.id
                    selectProfile(profile)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.nameJa)
                                .font(.headline)
                            Text(profile.nameEn)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if selectedProfileId == profile.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("プロファイル選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func selectProfile(_ profile: Profile) {
        if let error = profileManager.switchProfile(to: profile.id) {
            print("[ProfileSelectionView] Error switching profile: \(error)")
        } else {
            print("[ProfileSelectionView] Switched to profile: \(profile.nameJa)")
        }
    }
}

// MARK: - Preview

struct ProfileSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSelectionView()
    }
}
