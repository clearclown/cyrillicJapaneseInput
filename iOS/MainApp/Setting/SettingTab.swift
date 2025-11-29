//
//  SettingTab.swift
//  MainApp
//
//  Created by ensan on 2020/09/16.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import KeyboardViews
import StoreKit
import SwiftUI

struct SettingTabView: View {
    @State private var searchQuery: String = ""
    @State private var path: [CustomizeTabView.Path] = []
    @Environment(\.requestReview) var requestReview
    @EnvironmentObject private var appStates: MainAppStates

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                Section("キーボードの種類") {
                    NavigationLink("キーボードの種類を設定する") {
                        KeyboardLayoutTypeDetailsView()
                    }
                }
                .searchKeys("キーボードの種類", "レイアウト", "キリル", "テンキー", "数字", "数字入力")

                Section("ライブ変換") {
                    BoolSettingView(.liveConversion)
                    NavigationLink("詳しい設定") {
                        LiveConversionSettingView()
                    }
                }
                .searchKeys("ライブ変換", "自動変換", "自動確定")

                Section("バー") {
                    BoolSettingView(.useReflectStyleCursorBar)
                        .searchKeys("カーソルバー", "バー")
                    BoolSettingView(.enableClipboardHistoryManagerTab)
                        .searchKeys("コピー履歴", "クリップボード履歴", "履歴")
                    if SemiStaticStates.shared.hasFullAccess {
                        NavigationLink("「ペーストを許可」のダイアログについて") {
                            PasteFromOtherAppsPermissionTipsView()
                        }
                        .searchKeys("ペースト", "コピー履歴", "クリップボード履歴", "履歴")
                    }
                    NavigationLink("タブバーを編集") {
                        EditingTabBarView(manager: $appStates.custardManager)
                    }
                    .searchKeys("タブバー", "バー")
                }
                .inheritSearchKeys()

                // デバイスが触覚フィードバックをサポートしている場合のみ表示する
                if SemiStaticStates.shared.hapticsAvailable {
                    Section("サウンドと振動") {
                        BoolSettingView(.enableKeySound)
                            .searchKeys("サウンド", "音")
                        BoolSettingView(.enableKeyHaptics)
                            .searchKeys("サウンド", "振動")
                    }
                    .inheritSearchKeys()
                } else {
                    Section("サウンド") {
                        BoolSettingView(.enableKeySound)
                    }
                    .searchKeys("サウンド", "音")
                }

                Section("表示") {
                    FontSizeSettingView(.keyViewFontSize, .key, availableValueRange: 15 ... 28)
                        .searchKeys("フォント", "サイズ", "文字サイズ")
                    FontSizeSettingView(.resultViewFontSize, .result, availableValueRange: 12...24)
                        .searchKeys("フォント", "サイズ", "文字サイズ")
                }
                .inheritSearchKeys()

                Section("操作性") {
                    BoolSettingView(.hideResetButtonInOneHandedMode)
                        .searchKeys("片手モード", "解除ボタン")
                }
                .inheritSearchKeys()

                Section("変換") {
                    BoolSettingView(.zenzaiEnable)
                        .searchKeys("Zenzai")
                    NavigationLink("Zenzaiについて") {
                        ZenzaiSettingView()
                    }
                    .searchKeys("Zenzai", "エフォート", "詳細設定")
                    BoolSettingView(.englishCandidate)
                        .searchKeys("英単語変換", "変換", "英語", "英語変換")
                    BoolSettingView(.typographyLetter)
                        .searchKeys("太字", "フォント", "タイポグラフィ", "装飾文字")
                    MarkedTextSettingView(.markedTextSetting)
                        .searchKeys("入力中のテキストを保護", "下線", "テキストを保護")
                    ContactImportSettingView()
                        .searchKeys("連絡先変換", "氏名", "知り合い")
                    NavigationLink("絵文字と顔文字") {
                        AdditionalDictManageView()
                    }
                    .searchKeys("絵文字", "顔文字", "特殊文字")
                }
                .inheritSearchKeys()

                Section("ユーザ辞書") {
                    BoolSettingView(.useOSUserDict)
                        .searchKeys("ユーザ辞書", "追加辞書")
                    NavigationLink("Pismoユーザ辞書") {
                        PismoUserDictionaryView()
                    }
                    .searchKeys("ユーザ辞書", "追加辞書")
                    // MARK: ホットフィックスの項目はデバッグ版のみで表示
                    #if DEBUG
                    if let cachedTag = HotfixDictionaryV1.cachedTag {
                        LabeledContent("ホットフィックス") {
                            Text(cachedTag)
                                .monospaced()
                        }
                        .onTapGesture {
                            Task {
                                // タッチされたらアップデートをトリガーする（隠し機能）
                                try await HotfixDictionaryV1.updateIfRequired(ignoreFrequency: true)
                            }
                        }
                    } else {
                        Text("Hotfix not found")
                    }
                    #endif
                }
                .inheritSearchKeys()

                Section("学習機能") {
                    LearningTypeSettingView()
                        .searchKeys("学習", "履歴")
                    MemoryResetSettingItemView()
                        .searchKeys("リセット", "学習", "履歴")
                }
                .inheritSearchKeys()

                ContributionSettingsSection()
                    .searchKeys("協力", "レポート", "誤変換")

                Section("カスタムタブ") {
                    NavigationLink("カスタムタブの管理") {
                        ManageCustardView(manager: $appStates.custardManager, path: $path)
                    }
                }
                .searchKeys("カスタムタブ", "タブ", "カスタマイズ")

                Section("言語") {
                    NavigationLink("アプリの表示言語") {
                        AppLanguageSettingView()
                    }
                }
                .searchKeys("言語", "Language", "English", "日本語")

                Section("オープンソースソフトウェア") {
                    Text("Pismoはオープンソースソフトウェアであり、GitHubでソースコードを公開しています。")
                    FallbackLink("View Pismo on GitHub", destination: URL(string: "https://github.com/clearclown/cyrillicJapaneseInput")!)
                    NavigationLink("Acknowledgements") {
                        OpenSourceSoftwaresLicenseView()
                    }
                }
                .searchKeys("オープンソース", "ライセンス", "謝辞", "OSS", "ソフトウェア")

                Section("謝辞・クレジット") {
                    Text("PismoはazooKey（MIT License）のフォークです。オリジナルプロジェクトに最大限の感謝を申し上げます。")
                    FallbackLink("azooKey 公式サイト", destination: URL(string: "https://azookey.com")!)
                    Text("このプロジェクトは生成AI（Anthropic Claude Opus 4.5）を使用して開発されました。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .searchKeys("謝辞", "クレジット", "azooKey", "フォーク", "AI")

                Section("このアプリについて") {
                    NavigationLink("お問い合わせ") {
                        ContactView()
                    }
                    .searchKeys("お問い合わせ", "質問", "連絡", "メール")
                    FallbackLink("プライバシーポリシー", destination: URL(string: "https://pismo-web-page.vercel.app/privacy")!)
                        .foregroundStyle(.primary)
                        .searchKeys("プライバシーポリシー", "個人情報", "ライセンス")
                    FallbackLink("利用規約", destination: URL(string: "https://pismo-web-page.vercel.app/privacy")!)
                        .foregroundStyle(.primary)
                        .searchKeys("利用規約", "規約", "ライセンス")
                    NavigationLink("更新履歴") {
                        UpdateInformationView()
                    }
                    .searchKeys("更新履歴", "アップデート情報", "変更", "バージョン")
                    LabeledContent("URL Scheme") {
                        Text(verbatim: "Pismo://")
                            .monospaced()
                    }
                    .searchKeys("URLスキーム")
                    LabeledContent("バージョン") {
                        Text(verbatim: SharedStore.currentAppVersion?.description ?? "取得中です")
                    }
                    .searchKeys("バージョン")
                }
                .inheritSearchKeys()

            }
            .searchQuery(searchQuery.isEmpty ? nil : searchQuery.toKatakana())
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: CustomizeTabView.Path.self) { destination in
                switch destination {
                case let .information(identifier):
                    if let custard = try? appStates.custardManager.custard(identifier: identifier) {
                        CustardInformationView(custard: custard, path: $path)
                    }
                case .zenzaiSettings:
                    ZenzaiSettingView()
                }
            }
            .onAppear {
                if appStates.requestReviewManager.shouldTryRequestReview, appStates.requestReviewManager.shouldRequestReview() {
                    requestReview()
                }
                // Handle pending deep link when Settings tab appears
                if appStates.deepLink == .settingsZenzai {
                    path.append(.zenzaiSettings)
                    appStates.deepLink = nil
                }
            }
            .onChange(of: appStates.deepLink) { _, newValue in
                if newValue == .settingsZenzai {
                    path.append(.zenzaiSettings)
                    appStates.deepLink = nil
                }
            }
        }
        .searchable(text: $searchQuery, prompt: Text("検索"))
    }
}
