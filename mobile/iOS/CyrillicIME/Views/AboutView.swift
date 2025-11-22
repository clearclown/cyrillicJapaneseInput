//
//  AboutView.swift
//  CyrillicIME
//
//  About screen with app information
//  Phase 5: Settings & User Experience
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            // App Info Section
            Section {
                VStack(spacing: 16) {
                    // App Icon (placeholder - you can add actual icon later)
                    Image(systemName: "keyboard.badge.ellipsis")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)

                    Text("Pismo")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("キリル文字で日本語入力")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .listRowBackground(Color.clear)
            }

            // Description Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pismoについて")
                        .font(.headline)

                    Text("Pismoは、キリル文字配列を使って日本語を入力できる革新的なIME（Input Method Editor）です。")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Text("ロシア語、セルビア語、ウクライナ語、ブルガリア語など、複数のキリル文字配列に対応しており、使い慣れた配列で日本語を入力できます。")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } header: {
                Text("概要")
            }

            // Features Section
            Section {
                FeatureRow(
                    icon: "globe",
                    title: "多言語対応",
                    description: "5つのキリル文字配列に対応"
                )

                FeatureRow(
                    icon: "bolt.fill",
                    title: "高速変換",
                    description: "Rust製コアエンジンで高速処理"
                )

                FeatureRow(
                    icon: "brain",
                    title: "学習機能",
                    description: "使うほど賢くなる変換候補"
                )

                FeatureRow(
                    icon: "book.fill",
                    title: "ユーザー辞書",
                    description: "よく使う単語を登録可能"
                )

                FeatureRow(
                    icon: "paintbrush.fill",
                    title: "iOS標準デザイン",
                    description: "iOSキーボードと同じ見た目"
                )
            } header: {
                Text("主な機能")
            }

            // Technology Section
            Section {
                TechRow(technology: "SwiftUI", description: "モダンなUI構築")
                TechRow(technology: "Rust Core", description: "高速変換エンジン")
                TechRow(technology: "UIKit", description: "カスタムキーボード")
                TechRow(technology: "Combine", description: "リアクティブプログラミング")
            } header: {
                Text("技術スタック")
            }

            // Links Section
            Section {
                Link(destination: URL(string: "https://github.com/clearclown/cyrillicJapaneseInput")!) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .foregroundColor(.blue)
                        Text("GitHubリポジトリ")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Link(destination: URL(string: "https://github.com/clearclown/cyrillicJapaneseInput/issues")!) {
                    HStack {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .foregroundColor(.orange)
                        Text("問題を報告")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Link(destination: URL(string: "https://github.com/clearclown/cyrillicJapaneseInput/blob/main/README.md")!) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.green)
                        Text("ドキュメント")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("リンク")
            }

            // License Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MIT License")
                        .font(.headline)

                    Text("Copyright © 2025 Pismo Project")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("このソフトウェアはMITライセンスの下で配布されています。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } header: {
                Text("ライセンス")
            }

            // Credits Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    CreditRow(
                        title: "開発",
                        description: "clearclown"
                    )

                    CreditRow(
                        title: "コンセプト",
                        description: "キリル文字による日本語入力の実現"
                    )

                    CreditRow(
                        title: "名前の由来",
                        description: "Письмо（ピースモー）- ロシア語で「書くこと」「手紙」"
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Text("クレジット")
            }
        }
        .navigationTitle("Pismoについて")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TechRow: View {
    let technology: String
    let description: String

    var body: some View {
        HStack {
            Text(technology)
                .font(.body)
                .fontWeight(.medium)
            Spacer()
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct CreditRow: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutView()
        }
    }
}
