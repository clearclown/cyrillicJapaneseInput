//
//  TipsNewsSection.swift
//  Pismo
//
//  Created by miwa on 2023/11/11.
//  Copyright © 2023 DevEn3. All rights reserved.
//

import SwiftUI

struct TipsNewsSection: View {
    @AppStorage("read_terms_of_use_update_2025_05_31") private var readTermsOfUseUpdate_2025_05_31 = false

    var body: some View {
        if !readTermsOfUseUpdate_2025_05_31 {
            Section("利用規約の更新") {
                NavigationLink {
                    TermsOfServiceUpdateNews(readTermsOfUseUpdate_2025_05_31: $readTermsOfUseUpdate_2025_05_31)
                } label: {
                    Label(
                        title: {
                            Text("利用規約を更新しました")
                        },
                        icon: {
                            Image(systemName: "bell.badge")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    )
                }
            }
        }
        // Pismo: キリル文字キーボードなので、日本語IME向けのZenzai等の宣伝は非表示
    }
}
