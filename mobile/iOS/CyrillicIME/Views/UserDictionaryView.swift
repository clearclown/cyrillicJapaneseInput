//
//  UserDictionaryView.swift
//  Cyrillic IME
//
//  User dictionary management view with export/import functionality
//

import SwiftUI
import UniformTypeIdentifiers

struct UserDictionaryView: View {
    @StateObject private var viewModel = UserDictionaryViewModel()
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            // Dictionary entries section
            if viewModel.entries.isEmpty {
                emptyStateSection
            } else {
                entriesSection
            }

            // Actions section
            actionsSection
        }
        .navigationTitle("ユーザー辞書")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadEntries()
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(entries: viewModel.entries, onExport: viewModel.exportDictionary)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportView(onImport: viewModel.importDictionary)
        }
        .alert("ユーザー辞書を削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                viewModel.clearAllEntries()
            }
        } message: {
            Text("すべての学習データが削除されます。この操作は取り消せません。")
        }
        .alert("エラー", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - View Components

    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "book.closed")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("学習済み単語がありません")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("キーボードで変換した単語が自動的に学習されます")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }

    private var entriesSection: some View {
        Section(header: Text("学習済み単語 (\(viewModel.entries.count)件)")) {
            ForEach(viewModel.entries) { entry in
                DictionaryEntryRow(entry: entry)
            }
            .onDelete(perform: viewModel.deleteEntries)
        }
    }

    private var actionsSection: some View {
        Section {
            Button(action: { showingExportSheet = true }) {
                Label("エクスポート", systemImage: "square.and.arrow.up")
            }
            .disabled(viewModel.entries.isEmpty)

            Button(action: { showingImportSheet = true }) {
                Label("インポート", systemImage: "square.and.arrow.down")
            }

            Button(role: .destructive, action: { showingDeleteAlert = true }) {
                Label("すべて削除", systemImage: "trash")
            }
            .disabled(viewModel.entries.isEmpty)
        }
    }
}

// MARK: - Dictionary Entry Row

struct DictionaryEntryRow: View {
    let entry: DictionaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.reading)
                    .font(.body)
                    .foregroundColor(.primary)

                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(entry.word)
                    .font(.headline)
                    .foregroundColor(.blue)

                Spacer()
            }

            HStack {
                Text("使用: \(entry.usageCount)回")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("最終: \(formattedDate(entry.lastUsed))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Export View

struct ExportView: View {
    let entries: [DictionaryEntry]
    let onExport: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.up.circle")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                Text("ユーザー辞書をエクスポート")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(entries.count)件の学習済み単語をJSON形式でエクスポートします")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: exportToFile) {
                    Text("エクスポート")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("エクスポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func exportToFile() {
        // Create temporary file
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = temporaryDirectoryURL.appendingPathComponent("pismo_dictionary_\(Date().timeIntervalSince1970).json")

        onExport(fileURL)
        dismiss()
    }
}

// MARK: - Import View

struct ImportView: View {
    let onImport: (Data) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isImporting = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.down.circle")
                    .font(.system(size: 64))
                    .foregroundColor(.green)

                Text("ユーザー辞書をインポート")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("以前にエクスポートした辞書ファイルを選択してください")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: { isImporting = true }) {
                    Text("ファイルを選択")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("インポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            do {
                let data = try Data(contentsOf: url)
                onImport(data)
                dismiss()
            } catch {
                print("[ImportView] Error reading file: \(error)")
            }

        case .failure(let error):
            print("[ImportView] Error selecting file: \(error)")
        }
    }
}

// MARK: - View Model

class UserDictionaryViewModel: ObservableObject {
    @Published var entries: [DictionaryEntry] = []
    @Published var showError = false
    @Published var errorMessage = ""

    func loadEntries() {
        // TODO: Load from actual user dictionary
        // For now, load sample data
        entries = loadSampleEntries()
        SettingsStore.shared.updateUserDictionaryCount(entries.count)
    }

    func deleteEntries(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        SettingsStore.shared.updateUserDictionaryCount(entries.count)
        // TODO: Persist deletion
    }

    func clearAllEntries() {
        entries.removeAll()
        SettingsStore.shared.updateUserDictionaryCount(0)
        // TODO: Persist deletion
    }

    func exportDictionary(to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(entries)
            try data.write(to: url)

            print("[UserDictionaryViewModel] Exported \(entries.count) entries to \(url.path)")
        } catch {
            showErrorAlert("エクスポートに失敗しました: \(error.localizedDescription)")
        }
    }

    func importDictionary(from data: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let importedEntries = try decoder.decode([DictionaryEntry].self, from: data)
            entries.append(contentsOf: importedEntries)
            SettingsStore.shared.updateUserDictionaryCount(entries.count)

            print("[UserDictionaryViewModel] Imported \(importedEntries.count) entries")
        } catch {
            showErrorAlert("インポートに失敗しました: \(error.localizedDescription)")
        }
    }

    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func loadSampleEntries() -> [DictionaryEntry] {
        // Sample data for preview/testing
        return [
            DictionaryEntry(reading: "かいしゃ", word: "会社", usageCount: 15, lastUsed: Date()),
            DictionaryEntry(reading: "てすと", word: "テスト", usageCount: 8, lastUsed: Date().addingTimeInterval(-86400)),
            DictionaryEntry(reading: "にほんご", word: "日本語", usageCount: 25, lastUsed: Date().addingTimeInterval(-3600))
        ]
    }
}

// MARK: - Dictionary Entry Model

struct DictionaryEntry: Identifiable, Codable {
    let id: UUID
    let reading: String
    let word: String
    let usageCount: Int
    let lastUsed: Date

    init(id: UUID = UUID(), reading: String, word: String, usageCount: Int, lastUsed: Date) {
        self.id = id
        self.reading = reading
        self.word = word
        self.usageCount = usageCount
        self.lastUsed = lastUsed
    }
}

// MARK: - Preview

#if DEBUG
struct UserDictionaryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserDictionaryView()
        }
    }
}
#endif
