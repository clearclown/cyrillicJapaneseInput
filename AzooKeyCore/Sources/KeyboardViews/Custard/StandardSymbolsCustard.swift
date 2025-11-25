//
//  StandardSymbolsCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/25.
//

import CustardKit

public extension Custard {
    /// 標準記号キーボード (iOS標準スタイル)
    static let standardSymbols = Custard(
        identifier: "standard_symbols",
        language: .none,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "標準記号"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 10, columnCount: 4)),
            keys: [
                // Row 1: [ ] { } # % ^ * + =
                .gridFit(.init(x: 0, y: 0)): .custom(.symbolInput("[")),
                .gridFit(.init(x: 1, y: 0)): .custom(.symbolInput("]")),
                .gridFit(.init(x: 2, y: 0)): .custom(.symbolInput("{")),
                .gridFit(.init(x: 3, y: 0)): .custom(.symbolInput("}")),
                .gridFit(.init(x: 4, y: 0)): .custom(.symbolInput("#")),
                .gridFit(.init(x: 5, y: 0)): .custom(.symbolInput("%")),
                .gridFit(.init(x: 6, y: 0)): .custom(.symbolInput("^")),
                .gridFit(.init(x: 7, y: 0)): .custom(.symbolInput("*")),
                .gridFit(.init(x: 8, y: 0)): .custom(.symbolInput("+")),
                .gridFit(.init(x: 9, y: 0)): .custom(.symbolInput("=")),

                // Row 2: _ \ | ~ < > € £ ¥ •
                .gridFit(.init(x: 0, y: 1)): .custom(.symbolInput("_")),
                .gridFit(.init(x: 1, y: 1)): .custom(.symbolInput("\\")),
                .gridFit(.init(x: 2, y: 1)): .custom(.symbolInput("|")),
                .gridFit(.init(x: 3, y: 1)): .custom(.symbolInput("~")),
                .gridFit(.init(x: 4, y: 1)): .custom(.symbolInput("<")),
                .gridFit(.init(x: 5, y: 1)): .custom(.symbolInput(">")),
                .gridFit(.init(x: 6, y: 1)): .custom(.symbolInput("€")),
                .gridFit(.init(x: 7, y: 1)): .custom(.symbolInput("£")),
                .gridFit(.init(x: 8, y: 1)): .custom(.symbolInput("¥")),
                .gridFit(.init(x: 9, y: 1)): .custom(.symbolInput("•")),

                // Row 3: 123 . , ? ! ' " Del
                .gridFit(.init(x: 0, y: 2, width: 2, height: 1)): .custom(.numbersKey()),
                .gridFit(.init(x: 2, y: 2)): .custom(.symbolInput(".")),
                .gridFit(.init(x: 3, y: 2)): .custom(.symbolInput(",")),
                .gridFit(.init(x: 4, y: 2)): .custom(.symbolInput("?")),
                .gridFit(.init(x: 5, y: 2)): .custom(.symbolInput("!")),
                .gridFit(.init(x: 6, y: 2)): .custom(.symbolInput("'")),
                .gridFit(.init(x: 7, y: 2)): .custom(.symbolInput("\"")),
                .gridFit(.init(x: 8, y: 2, width: 2, height: 1)): .custom(.flickDelete()),

                // Row 4: АБВ Globe Space Enter
                .gridFit(.init(x: 0, y: 3, width: 2, height: 1)): .custom(.cyrillicTabKey()),
                .gridFit(.init(x: 2, y: 3)): .system(.changeKeyboard),
                .gridFit(.init(x: 3, y: 3, width: 4, height: 1)): .custom(.flickSpace()),
                .gridFit(.init(x: 7, y: 3, width: 3, height: 1)): .system(.enter),
            ]
        )
    )
}

private extension CustardInterfaceCustomKey {
    static func symbolInput(_ char: String) -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text(char), color: .normal),
            press_actions: [.input(char)],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func numbersKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("123"), color: .special),
            press_actions: [.moveTab(.system(.flick_numbersymbols))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []),
            variations: []
        )
    }

    static func cyrillicTabKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("АБВ"), color: .special),
            press_actions: [.moveTab(.system(.user_japanese))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []),
            variations: []
        )
    }
}
