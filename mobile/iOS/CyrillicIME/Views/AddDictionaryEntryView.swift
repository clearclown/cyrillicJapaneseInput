//
//  AddDictionaryEntryView.swift
//  CyrillicIME
//
//  Sheet for adding new user dictionary entries
//  Phase 5: Settings & User Dictionary
//

import SwiftUI

struct AddDictionaryEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dictionaryManager = UserDictionaryManager.shared

    @State private var reading = ""
    @State private var output = ""
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("例: かんじ", text: $reading)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.default)
                        .onChange(of: reading) { _ in
                            validateReading()
                        }
                } header: {
                    Text("読み（ひらがな）")
                } footer: {
                    Text("ひらがなで入力してください")
                }

                Section {
                    TextField("例: 漢字", text: $output)
                        .autocorrectionDisabled()
                } header: {
                    Text("変換結果")
                } footer: {
                    Text("変換後の文字列を入力してください（漢字、カタカナ、英数字など）")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("プレビュー")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if !reading.isEmpty && !output.isEmpty {
                            HStack {
                                Text(reading)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.blue)
                                Text(output)
                                    .font(.headline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        } else {
                            Text("読みと変換結果を入力してください")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
            }
            .navigationTitle("単語登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("登録") {
                        addEntry()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("入力エラー", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationErrorMessage)
            }
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        return !reading.isEmpty &&
               !output.isEmpty &&
               reading != output &&
               isHiragana(reading)
    }

    private func validateReading() {
        // リアルタイムでひらがなチェック
        if !reading.isEmpty && !isHiragana(reading) {
            // 非ひらがな文字が含まれている場合の視覚的フィードバック
            // （エラーはsubmit時に表示）
        }
    }

    private func isHiragana(_ text: String) -> Bool {
        let hiraganaRange = "\u{3040}"..."\u{309F}"
        return text.allSatisfy { char in
            hiraganaRange.contains(String(char))
        }
    }

    // MARK: - Actions

    private func addEntry() {
        // 最終バリデーション
        guard !reading.isEmpty else {
            validationErrorMessage = "読みを入力してください"
            showingValidationError = true
            return
        }

        guard !output.isEmpty else {
            validationErrorMessage = "変換結果を入力してください"
            showingValidationError = true
            return
        }

        guard isHiragana(reading) else {
            validationErrorMessage = "読みはひらがなで入力してください"
            showingValidationError = true
            return
        }

        guard reading != output else {
            validationErrorMessage = "読みと変換結果は異なる必要があります"
            showingValidationError = true
            return
        }

        // エントリを作成して追加
        let entry = UserDictionaryEntry(
            reading: reading.trimmingCharacters(in: .whitespaces),
            output: output.trimmingCharacters(in: .whitespaces),
            frequency: 0
        )

        dictionaryManager.addEntry(entry)
        print("[AddDictionaryEntry] Added: \(entry.reading) → \(entry.output)")

        dismiss()
    }
}

// MARK: - Preview

struct AddDictionaryEntryView_Previews: PreviewProvider {
    static var previews: some View {
        AddDictionaryEntryView()
    }
}
