//
//  SelctInputStyle.swift
//  MainApp
//
//  Created by ensan on 2020/10/03.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUI

struct SelctInputStyleTipsView: View {
    var body: some View {
        TipsContentView("キーボードの種類を選ぶ") {
            TipsContentParagraph {
                Text("キリル文字キーボードの種類を選択できます。")
            }
            LanguageLayoutSettingView(.japaneseKeyboardLayout, language: .japanese, setTogether: true).padding(.vertical)
            TipsContentParagraph {
                Text("macOSなどに搭載されている、入力中の文字列を自動的に変換する「ライブ変換」が利用できます。")
                BoolSettingView(.liveConversion)
            }
            TipsContentParagraph(style: .caption) {
                Text("日本語・英語に対応したカスタムタブを読み込んだ場合、これを選ぶことも可能です")
            }
            TipsContentParagraph(style: .caption) {
                Text("現在は携帯電話式の入力については対応していません。")
            }
        }
    }
}
