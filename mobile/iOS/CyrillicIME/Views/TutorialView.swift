//
//  TutorialView.swift
//  CyrillicIME
//
//  Onboarding tutorial view
//  Phase 5: Settings & User Experience
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages = TutorialPage.allPages

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        TutorialPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Page Indicator & Navigation
                VStack(spacing: 16) {
                    // Custom Page Indicator
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }

                    // Navigation Buttons
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button(action: previousPage) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("戻る")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }

                        Button(action: nextPage) {
                            HStack {
                                Text(currentPage == pages.count - 1 ? "完了" : "次へ")
                                if currentPage < pages.count - 1 {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Pismoの使い方")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("スキップ") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Navigation

    private func previousPage() {
        withAnimation {
            currentPage = max(0, currentPage - 1)
        }
    }

    private func nextPage() {
        if currentPage < pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            // Last page - dismiss tutorial
            dismiss()
        }
    }
}

// MARK: - Tutorial Page View

struct TutorialPageView: View {
    let page: TutorialPage

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: page.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding(.top, 40)

                // Title
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                // Description
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Example Section (if available)
                if let example = page.example {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("例")
                            .font(.headline)

                        ForEach(example, id: \.self) { item in
                            ExampleRow(example: item)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                }

                // Additional Info (if available)
                if let info = page.additionalInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(info, id: \.self) { infoText in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(infoText)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                }

                Spacer(minLength: 40)
            }
        }
    }
}

struct ExampleRow: View {
    let example: String

    var body: some View {
        HStack(spacing: 8) {
            if example.contains("→") {
                let parts = example.components(separatedBy: " → ")
                if parts.count == 2 {
                    Text(parts[0])
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(parts[1])
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            } else {
                Text(example)
                    .font(.system(.body, design: .monospaced))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tutorial Page Model

struct TutorialPage {
    let iconName: String
    let title: String
    let description: String
    let example: [String]?
    let additionalInfo: [String]?

    static let allPages: [TutorialPage] = [
        TutorialPage(
            iconName: "hand.wave.fill",
            title: "Pismoへようこそ",
            description: "Pismoは、キリル文字配列で日本語を入力できる革新的なIMEです。",
            example: nil,
            additionalInfo: [
                "5つの言語プロファイル対応",
                "直感的なキーボード配列",
                "高速な変換エンジン"
            ]
        ),

        TutorialPage(
            iconName: "keyboard.fill",
            title: "キーボードを有効化",
            description: "まずiOSの設定でPismoキーボードを有効にしましょう。",
            example: nil,
            additionalInfo: [
                "設定 → 一般 → キーボード",
                "キーボード → 新しいキーボードを追加",
                "Pismo を選択",
                "フルアクセスを許可（推奨）"
            ]
        ),

        TutorialPage(
            iconName: "globe",
            title: "プロファイルを選択",
            description: "使いたいキリル文字配列（プロファイル）を選択してください。",
            example: [
                "ロシア語（ЙЦУКЕН配列）",
                "セルビア語（キリル）",
                "ウクライナ語",
                "ブルガリア語"
            ],
            additionalInfo: [
                "設定アプリからいつでも変更可能",
                "各プロファイルで同じ日本語を入力可能",
                "使い慣れた配列を選択しましょう"
            ]
        ),

        TutorialPage(
            iconName: "text.bubble.fill",
            title: "入力してみよう",
            description: "キリル文字を入力すると、自動的にひらがなに変換されます。",
            example: [
                "КА → か",
                "КАНДЗИ → かんじ",
                "НИХОНГО → にほんご"
            ],
            additionalInfo: [
                "スペースキーで漢字変換",
                "候補バーから選択",
                "学習機能で精度向上"
            ]
        ),

        TutorialPage(
            iconName: "book.fill",
            title: "ユーザー辞書を活用",
            description: "よく使う単語を登録すると、変換が便利になります。",
            example: [
                "ぴすも → Pismo",
                "にほんご → 日本語"
            ],
            additionalInfo: [
                "設定アプリから単語登録",
                "使用頻度で自動学習",
                "いつでも編集・削除可能"
            ]
        ),

        TutorialPage(
            iconName: "checkmark.circle.fill",
            title: "準備完了！",
            description: "これでPismoを使う準備が整いました。キリル文字で快適な日本語入力を楽しんでください。",
            example: nil,
            additionalInfo: [
                "困ったときは設定画面のヘルプを確認",
                "GitHubでフィードバック大歓迎",
                "楽しい入力体験を！"
            ]
        )
    ]
}

// MARK: - Preview

struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
    }
}
