//
//  ContentView.swift
//  CyrillicIME
//
//  Main app content view
//  Phase 5: Profile and Settings UI
//

import SwiftUI

struct ContentView: View {
    @AppStorage("has_shown_tutorial", store: UserDefaults.shared) private var hasShownTutorial = false
    @State private var showingTutorial = false

    var body: some View {
        TabView {
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }

            HelpView()
                .tabItem {
                    Label("ヘルプ", systemImage: "questionmark.circle.fill")
                }
        }
        .sheet(isPresented: $showingTutorial) {
            TutorialView()
        }
        .onAppear {
            // Show tutorial on first launch
            if !hasShownTutorial {
                showingTutorial = true
                hasShownTutorial = true
            }
        }
    }
}

// MARK: - Help View

struct HelpView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pismoへようこそ")
                            .font(.largeTitle)
                            .bold()

                        Text("キリル文字で日本語を入力できる革新的なIMEです")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding()

                    // How it Works
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("使い方")
                                .font(.headline)

                            HelpStep(
                                number: "1",
                                title: "キーボードを有効化",
                                description: "設定 > 一般 > キーボード > キーボード で Pismo を追加"
                            )

                            HelpStep(
                                number: "2",
                                title: "プロファイルを選択",
                                description: "ロシア語、セルビア語、ウクライナ語など、お好みの配列を選択"
                            )

                            HelpStep(
                                number: "3",
                                title: "入力開始",
                                description: "キリル文字を入力すると自動的に平仮名に変換されます"
                            )

                            HelpStep(
                                number: "4",
                                title: "漢字変換",
                                description: "Spaceキーを押すと漢字候補が表示されます"
                            )
                        }
                        .padding()
                    }
                    .padding(.horizontal)

                    // Examples
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("入力例")
                                .font(.headline)

                            ExampleRow(
                                cyrillic: "КАЈША",
                                hiragana: "かいしゃ",
                                kanji: "会社"
                            )

                            ExampleRow(
                                cyrillic: "СЭНСЭЈ",
                                hiragana: "せんせい",
                                kanji: "先生"
                            )

                            ExampleRow(
                                cyrillic: "ГАККО:",
                                hiragana: "がっこう",
                                kanji: "学校"
                            )
                        }
                        .padding()
                    }
                    .padding(.horizontal)

                    // Tips
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ヒント")
                                .font(.headline)

                            TipRow(
                                icon: "hand.tap.fill",
                                text: "候補をタップして直接選択できます"
                            )

                            TipRow(
                                icon: "hand.draw.fill",
                                text: "左右スワイプで候補を切り替えられます"
                            )

                            TipRow(
                                icon: "number.circle.fill",
                                text: "数字キー（1-9）で候補を素早く選択"
                            )
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("ヘルプ")
        }
    }
}

// MARK: - Helper Views

struct HelpStep: View {
    let number: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ExampleRow: View {
    let cyrillic: String
    let hiragana: String
    let kanji: String

    var body: some View {
        HStack(spacing: 16) {
            Text(cyrillic)
                .font(.system(.body, design: .monospaced))
                .frame(width: 80, alignment: .leading)
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
            Text(hiragana)
                .frame(width: 80, alignment: .leading)
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
            Text(kanji)
                .font(.headline)
                .frame(width: 60, alignment: .leading)
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 30)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
