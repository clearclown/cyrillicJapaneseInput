//
//  KeyboardLayoutTypeDetailsView.swift
//  MainApp
//
//  Created by ensan on 2020/12/30.
//  Copyright © 2020 ensan. All rights reserved.
//

import AzooKeyUtils
import Foundation
import SwiftUI

struct KeyboardLayoutTypeDetailsView: View {
    @AppStorage(UseStandardNumpad.key) private var useStandardNumpad = UseStandardNumpad.defaultValue

    var body: some View {
        Form {
            Section("キーボードの種類") {
                LanguageLayoutSettingView(.japaneseKeyboardLayout, language: .japanese).padding(.vertical)
            }
            Section("数字入力の方法") {
                Picker("数字入力の方法", selection: $useStandardNumpad) {
                    Text("標準式").tag(true)
                    Text("フリック式").tag(false)
                }
                .pickerStyle(.segmented)
                Text("標準式は一般的なiOSの数字・記号キーボードです。フリック式はフリック入力で数字を入力します。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }.navigationBarTitle(Text("キーボードの設定"), displayMode: .inline)
    }
}
