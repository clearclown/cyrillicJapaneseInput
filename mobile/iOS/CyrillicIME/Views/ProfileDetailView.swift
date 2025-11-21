//
//  ProfileDetailView.swift
//  Cyrillic IME
//
//  Profile detail view with keyboard layout preview and conversion examples
//

import SwiftUI

struct ProfileDetailView: View {
    let profile: Profile
    @StateObject private var profileManager = ProfileManager.shared
    @State private var showingActivationAlert = false
    @State private var conversionExamples: [ConversionExample] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                profileHeader

                // Keyboard Layout Preview
                keyboardPreviewSection

                // Conversion Examples
                conversionExamplesSection

                // Activate Button
                activateButton
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("プロファイル変更完了", isPresented: $showingActivationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(profile.displayName) に切り替えました")
        }
        .onAppear {
            loadConversionExamples()
        }
    }

    // MARK: - View Components

    private var profileHeader: some View {
        VStack(spacing: 8) {
            Text(profile.nameJa)
                .font(.title)
                .fontWeight(.bold)

            Text(profile.nameEn)
                .font(.title3)
                .foregroundColor(.secondary)

            if isCurrentProfile {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("使用中")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }

    private var keyboardPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("キーボードレイアウト")
                .font(.headline)
                .padding(.horizontal)

            KeyboardPreviewView(layout: profile.keyboardLayout)
                .padding(.horizontal, 8)
        }
    }

    private var conversionExamplesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("変換例")
                .font(.headline)
                .padding(.horizontal)

            if conversionExamples.isEmpty {
                Text("変換例を読み込み中...")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(conversionExamples) { example in
                        ConversionExampleRow(example: example)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }

    private var activateButton: some View {
        Button(action: activateProfile) {
            Text(isCurrentProfile ? "使用中" : "このプロファイルを使用")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isCurrentProfile ? Color.green : Color.blue)
                .cornerRadius(12)
        }
        .disabled(isCurrentProfile)
        .padding(.horizontal)
        .padding(.bottom)
    }

    // MARK: - Computed Properties

    private var isCurrentProfile: Bool {
        profile.id == profileManager.currentProfile?.id
    }

    // MARK: - Methods

    private func activateProfile() {
        if let error = profileManager.switchProfile(to: profile.id) {
            print("[ProfileDetailView] Error switching profile: \(error)")
        } else {
            showingActivationAlert = true
        }
    }

    private func loadConversionExamples() {
        // Load schema to get conversion examples
        if let error = profileManager.loadSchemaForProfile(profile) {
            print("[ProfileDetailView] Error loading schema: \(error)")
            return
        }

        guard let schema = profileManager.schemaCache[profile.inputSchemaId] else {
            print("[ProfileDetailView] Schema not found")
            return
        }

        // Extract interesting conversion examples
        var examples: [ConversionExample] = []

        // Common patterns to show
        let interestingPatterns = [
            "КА", "КЯ", "ЧИ", "ЖИ", "ШИ", "ТЯ", "НЯ", "РЮ",
            "КЈА", "КЈУ", "ЋИ", "ЏИ", "ЊА", "ЉА",  // Serbian
            "ҐА", "ЄА", "ЇА", "ІА"  // Ukrainian
        ]

        for pattern in interestingPatterns {
            if let entry = schema[pattern] {
                examples.append(ConversionExample(
                    cyrillic: pattern,
                    kanaKey: entry.kanaKey,
                    hiragana: convertKanaKeyToHiragana(entry.kanaKey)
                ))
            }
        }

        // Limit to 8 examples
        conversionExamples = Array(examples.prefix(8))
    }

    private func convertKanaKeyToHiragana(_ kanaKey: String) -> String {
        // Basic kana key to hiragana conversion
        // This is a simplified version; in production, use japaneseKanaEngine.json
        let basicMappings: [String: String] = [
            "ka": "か", "ki": "き", "ku": "く", "ke": "け", "ko": "こ",
            "kya": "きゃ", "kyu": "きゅ", "kyo": "きょ",
            "sa": "さ", "shi": "し", "su": "す", "se": "せ", "so": "そ",
            "sha": "しゃ", "shu": "しゅ", "sho": "しょ",
            "ta": "た", "chi": "ち", "tsu": "つ", "te": "て", "to": "と",
            "cha": "ちゃ", "chu": "ちゅ", "cho": "ちょ",
            "na": "な", "ni": "に", "nu": "ぬ", "ne": "ね", "no": "の",
            "nya": "にゃ", "nyu": "にゅ", "nyo": "にょ",
            "ha": "は", "hi": "ひ", "fu": "ふ", "he": "へ", "ho": "ほ",
            "hya": "ひゃ", "hyu": "ひゅ", "hyo": "ひょ",
            "ma": "ま", "mi": "み", "mu": "む", "me": "め", "mo": "も",
            "mya": "みゃ", "myu": "みゅ", "myo": "みょ",
            "ya": "や", "yu": "ゆ", "yo": "よ",
            "ra": "ら", "ri": "り", "ru": "る", "re": "れ", "ro": "ろ",
            "rya": "りゃ", "ryu": "りゅ", "ryo": "りょ",
            "wa": "わ", "wo": "を", "n": "ん",
            "ga": "が", "gi": "ぎ", "gu": "ぐ", "ge": "げ", "go": "ご",
            "gya": "ぎゃ", "gyu": "ぎゅ", "gyo": "ぎょ",
            "za": "ざ", "ji": "じ", "zu": "ず", "ze": "ぜ", "zo": "ぞ",
            "ja": "じゃ", "ju": "じゅ", "jo": "じょ",
            "da": "だ", "di": "ぢ", "du": "づ", "de": "で", "do": "ど",
            "ba": "ば", "bi": "び", "bu": "ぶ", "be": "べ", "bo": "ぼ",
            "bya": "びゃ", "byu": "びゅ", "byo": "びょ",
            "pa": "ぱ", "pi": "ぴ", "pu": "ぷ", "pe": "ぺ", "po": "ぽ",
            "pya": "ぴゃ", "pyu": "ぴゅ", "pyo": "ぴょ"
        ]

        return basicMappings[kanaKey] ?? kanaKey
    }
}

// MARK: - Conversion Example Model

struct ConversionExample: Identifiable {
    let id = UUID()
    let cyrillic: String
    let kanaKey: String
    let hiragana: String
}

// MARK: - Keyboard Preview View

struct KeyboardPreviewView: View {
    let layout: KeyboardLayout

    var body: some View {
        VStack(spacing: 6) {
            ForEach(Array(layout.rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 4) {
                    // Add spacing for visual alignment (row 2 and 3 are slightly indented)
                    if index == 1 {
                        Spacer().frame(width: 20)
                    } else if index == 2 {
                        Spacer().frame(width: 40)
                    }

                    ForEach(row, id: \.self) { key in
                        Text(key)
                            .font(.system(size: 16, weight: .medium))
                            .frame(minWidth: 32, minHeight: 40)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                    }

                    if index == 1 || index == 2 {
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Conversion Example Row

struct ConversionExampleRow: View {
    let example: ConversionExample

    var body: some View {
        HStack(spacing: 16) {
            // Cyrillic input
            Text(example.cyrillic)
                .font(.system(size: 20, weight: .bold))
                .frame(width: 60, alignment: .center)
                .foregroundColor(.primary)

            // Arrow
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .font(.caption)

            // Hiragana output
            Text(example.hiragana)
                .font(.system(size: 24))
                .frame(width: 60, alignment: .center)
                .foregroundColor(.blue)

            // Romaji
            Text("(\(example.kanaKey))")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(alignment: .leading)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#if DEBUG
struct ProfileDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileDetailView(profile: Profile.preview)
        }
    }
}
#endif
