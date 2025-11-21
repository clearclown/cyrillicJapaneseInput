//
//  KeyboardSettingsView.swift
//  Cyrillic IME
//
//  Keyboard input settings and customization
//

import SwiftUI

struct KeyboardSettingsView: View {
    @StateObject private var settings = SettingsStore.shared

    var body: some View {
        Form {
            // Default input mode section
            defaultInputModeSection

            // Live conversion section
            liveConversionSection

            // Candidate display section
            candidateDisplaySection

            // Sound section
            soundSection
        }
        .navigationTitle("入力設定")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - View Components

    private var defaultInputModeSection: some View {
        Section {
            Picker("デフォルトモード", selection: $settings.defaultInputMode) {
                ForEach([InputMode.japaneseHiragana, InputMode.direct], id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
        } header: {
            Text("入力モード")
        } footer: {
            Text("キーボード起動時のデフォルト入力モード")
        }
    }

    private var liveConversionSection: some View {
        Section {
            Toggle("ライブ変換", isOn: $settings.liveConversionEnabled)

            if settings.liveConversionEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("変換遅延")
                        Spacer()
                        Text("\(settings.liveConversionDelay, specifier: "%.1f")秒")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $settings.liveConversionDelay, in: 0.1...2.0, step: 0.1)
                }
            }
        } header: {
            Text("ライブ変換")
        } footer: {
            Text(settings.liveConversionEnabled
                ? "入力中に自動的に漢字変換を行います。変換遅延は入力停止後に変換を開始するまでの時間です"
                : "ライブ変換を有効にすると、入力中に自動的に漢字変換を行います")
        }
    }

    private var candidateDisplaySection: some View {
        Section {
            Stepper(value: $settings.candidateCount, in: 5...20, step: 5) {
                HStack {
                    Text("候補表示数")
                    Spacer()
                    Text("\(settings.candidateCount)件")
                        .foregroundColor(.secondary)
                }
            }

            Toggle("詳細表示", isOn: $settings.showDetailedCandidates)
        } header: {
            Text("候補表示")
        } footer: {
            Text(settings.showDetailedCandidates
                ? "候補に読み仮名や品詞情報を表示します"
                : "詳細表示を有効にすると、候補に読み仮名や品詞情報が表示されます")
        }
    }

    private var soundSection: some View {
        Section {
            Toggle("キークリック音", isOn: $settings.soundEnabled)
        } header: {
            Text("サウンド")
        } footer: {
            Text("キーをタップしたときに音を再生します")
        }
    }
}

// MARK: - Input Mode Extension

extension InputMode {
    var displayName: String {
        switch self {
        case .japaneseHiragana:
            return "ひらがな（変換あり）"
        case .direct:
            return "直接ひらがな（変換なし）"
        case .ascii:
            return "ASCII"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct KeyboardSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            KeyboardSettingsView()
        }
    }
}
#endif
