//
//  EnablePismoView.swift
//  MainApp
//
//  Created by ensan on 2020/11/18.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import SwiftUI
import SwiftUIUtils
import func SwiftUtils.debug

enum EnablePismoViewProgress: String, Hashable, Codable, Sendable {
    case menu
    case append
    case setting
    case finish
}

@MainActor
struct EnablePismoView: View {
    @EnvironmentObject private var appStates: MainAppStates
    @State private var step: EnablePismoViewProgress = .menu {
        didSet {
            self.appStates.setTutorialProgress(step)
        }
    }
    @State private var text = ""
    @State private var showDoneMessage = false

    init(resumeProgress: EnablePismoViewProgress? = nil) {
        if let resumeProgress {
            self._step = .init(initialValue: resumeProgress)
        }
    }

    var body: some View {
        ScrollView {
            ScrollViewReader {value in
                CenterAlignedView(padding: 30) {
                    switch self.step {
                    case .menu:
                        VStack(alignment: .leading, spacing: 20) {
                            Spacer()
                            CenterAlignedView {
                                HeaderLogoView()
                            }
                            EnablePismoViewText("Pismoを使う前に、iPhoneのキーボードのリストにPismoを追加する必要があります", with: "exclamationmark.triangle.fill")
                            CenterAlignedView {
                                EnablePismoViewButton("手順を見る", systemName: "arrowtriangle.right.fill") {
                                    self.step = .append
                                }
                            }
                        }
                        .onAppear {
                            value.scrollTo(0, anchor: .top)
                        }
                    case .append:
                        VStack(alignment: .leading, spacing: 20) {

                            EnablePismoViewHeader("追加する")
                            EnablePismoViewText("下にスクロールして「追加する」を押して", with: "plus.circle")
                            EnablePismoViewText("「キーボード」を押して", with: "keyboard")
                            CenterAlignedView {
                                EnablePismoViewImage(.initSettingKeyboardImageHand)
                            }
                            EnablePismoViewText("Pismoをオンにして", with: "square.and.line.vertical.and.square.fill")
                            CenterAlignedView {
                                EnablePismoViewImage(.initSettingPismoSwitchImageHand)
                            }
                            EnablePismoViewText("このアプリを再び開いてください", with: "arrow.turn.down.left")
                            CenterAlignedView {
                                EnablePismoViewButton("追加する", systemName: "plus.circle") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                    }
                                }
                            }
                            EnablePismoViewText("この設定をしないとキーボードが使えません", with: "exclamationmark.triangle.fill")
                            CenterAlignedView {
                                EnablePismoViewButton("閉じる", systemName: "xmark", style: .destructive) {
                                    appStates.requireFirstOpenView = false
                                }
                            }
                        }
                        .onAppear {
                            value.scrollTo(0, anchor: .top)
                        }
                    case .setting:
                        VStack(alignment: .leading, spacing: 20) {
                            EnablePismoViewHeader("最初の設定")
                            Group {
                                Divider()
                                EnablePismoViewText("キーボードの種類をお選びください", with: "keyboard")
                                LanguageLayoutSettingView(.japaneseKeyboardLayout, setTogether: true)
                            }
                            Group {
                                Divider()
                                EnablePismoViewText("ライブ変換を使用しますか？", with: "character.cursor.ibeam")
                                BoolSettingView(.liveConversion)
                            }
                            Group {
                                Divider()
                                EnablePismoViewText("Zenzai（高性能端末向けの高精度なニューラルかな漢字変換システム）を使用しますか？", with: "z.square.fill")
                                BoolSettingView(.zenzaiEnable)
                            }
                            Divider()
                            EnablePismoViewText("設定は「設定タブ」でいつでも変えられます", with: "gearshape")
                            CenterAlignedView {
                                EnablePismoViewButton("完了", systemName: "checkmark") {
                                    self.step = .finish
                                }
                            }
                        }
                        .onAppear {
                            value.scrollTo(0, anchor: .top)
                        }

                    case .finish:
                        VStack(alignment: .leading, spacing: 20) {
                            EnablePismoViewHeader("Pismoが使えます！")
                            EnablePismoViewText("準備は完了です！", with: "checkmark")
                            if showDoneMessage {
                                EnablePismoViewText("Pismoが開かれました！", with: "checkmark")
                                CenterAlignedView {
                                    EnablePismoViewButton("始める", systemName: "arrowshape.turn.up.right.fill") {
                                        appStates.requireFirstOpenView = false
                                    }
                                }
                            } else {
                                EnablePismoViewText("キーボードの地球儀ボタンを長押しし、Pismoを選択してください", with: "globe")
                            }
                            TextField("キーボードを開く", text: $text)
                                .textFieldStyle(.roundedBorder)
                                .submitLabel(.continue)
                                .onSubmit {
                                    appStates.requireFirstOpenView = false
                                }
                            if !showDoneMessage {
                                CenterAlignedView {
                                    EnablePismoViewImage(.initSettingGlobeTap)
                                }
                            }
                            EnablePismoViewText("Pismoをお楽しみください！", with: "star.fill")
                            if !showDoneMessage {
                                CenterAlignedView {
                                    EnablePismoViewButton("始める", systemName: "arrowshape.turn.up.right.fill") {
                                        appStates.requireFirstOpenView = false
                                    }
                                }
                            }
                        }
                        .onAppear {
                            value.scrollTo(0, anchor: .top)
                        }
                        .onTapGesture {
                            UIApplication.shared.closeKeyboard()
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.keyboardDidShowNotification)) {_ in
                            // キーボードが開いた時
                            if checkActiveKeyboardIsPismo() {
                                showDoneMessage = true
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UITextInputMode.currentInputModeDidChangeNotification)) {_ in
                            // アクティブなキーボードが変化したとき
                            if checkActiveKeyboardIsPismo() {
                                showDoneMessage = true
                            }
                        }
                    }
                }
                .id(0)
            }
        }
        .animation(.interactiveSpring(), value: step)
        .animation(.spring(), value: showDoneMessage)
        .task {
            // 0.2秒に一度チェックを挟んでkeyboardの状態をチェックする
            while !Task.isCancelled && !appStates.isKeyboardActivated {
                if SharedStore.checkKeyboardActivation() {
                    self.step = .setting
                    appStates.isKeyboardActivated = true
                }
                do {
                    try await Task.sleep(nanoseconds: 0_200_000_000)
                } catch {
                    debug(error)
                }
            }
        }
    }

    private func checkActiveKeyboardIsPismo() -> Bool {
        // キーボードが開いた時
        // 参考：https://stackoverflow.com/questions/26153336/how-do-i-find-out-the-current-keyboard-used-on-ios8
        let currentKeyboardIdentifier = NSArray(array: UITextInputMode.activeInputModes)
            .filtered(using: NSPredicate(format: "isDisplayed = YES"))
            .first
            .flatMap {($0 as? UITextInputMode)?.value(forKey: "identifier") as? String}
        return currentKeyboardIdentifier?.hasPrefix(SharedStore.bundleName) == true
    }
}
