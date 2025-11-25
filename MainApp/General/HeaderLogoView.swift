//
//  HeaderIconView.swift
//  MainApp
//
//  Created by ensan on 2020/10/03.
//  Copyright © 2020 ensan. All rights reserved.
//

import KeyboardViews
import SwiftUI

struct HeaderLogoView: View {
    @Environment(\.colorScheme) private var colorScheme
    private var iconColor: Color {
        Color("IconColor")
    }
    private var iconSize: CGFloat = 40

    var body: some View {
        Group {
            switch colorScheme {
            case .light:
                Text(verbatim: "A")
                    .font(Design.fonts.PismoIconFont(iconSize * 0.75))
                    .accessibilityLabel("Pismoのロゴ")
            case .dark:
                Text(verbatim: "B")
                    .font(Design.fonts.PismoIconFont(iconSize * 0.75))
                    .accessibilityLabel("Pismoのロゴ")
            @unknown default:
                Text(verbatim: "Pismo")
                    .font(Font(UIFont.systemFont(ofSize: iconSize)))
            }
        }
        .foregroundStyle(iconColor)
    }
}

#Preview {
    HeaderLogoView()
}
