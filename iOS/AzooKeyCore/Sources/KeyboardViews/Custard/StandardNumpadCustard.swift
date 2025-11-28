//
//  StandardNumpadCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/25.
//

import CustardKit

public extension Custard {
    /// 標準数字キーボード (iOS標準スタイル 10列×4行)
    static let standardNumpad = Custard(
        identifier: "standard_numpad",
        language: .none,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "標準数字"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 10, columnCount: 4)),
            keys: [
                // Row 1: 1 2 3 4 5 6 7 8 9 0
                .gridFit(.init(x: 0, y: 0)): .custom(.numpadInput("1")),
                .gridFit(.init(x: 1, y: 0)): .custom(.numpadInput("2")),
                .gridFit(.init(x: 2, y: 0)): .custom(.numpadInput("3")),
                .gridFit(.init(x: 3, y: 0)): .custom(.numpadInput("4")),
                .gridFit(.init(x: 4, y: 0)): .custom(.numpadInput("5")),
                .gridFit(.init(x: 5, y: 0)): .custom(.numpadInput("6")),
                .gridFit(.init(x: 6, y: 0)): .custom(.numpadInput("7")),
                .gridFit(.init(x: 7, y: 0)): .custom(.numpadInput("8")),
                .gridFit(.init(x: 8, y: 0)): .custom(.numpadInput("9")),
                .gridFit(.init(x: 9, y: 0)): .custom(.numpadInput("0")),

                // Row 2: - / : ; ( ) $ & @ "
                .gridFit(.init(x: 0, y: 1)): .custom(.numpadInput("-")),
                .gridFit(.init(x: 1, y: 1)): .custom(.numpadInput("/")),
                .gridFit(.init(x: 2, y: 1)): .custom(.numpadInput(":")),
                .gridFit(.init(x: 3, y: 1)): .custom(.numpadInput(";")),
                .gridFit(.init(x: 4, y: 1)): .custom(.numpadInput("(")),
                .gridFit(.init(x: 5, y: 1)): .custom(.numpadInput(")")),
                .gridFit(.init(x: 6, y: 1)): .custom(.numpadInput("$")),
                .gridFit(.init(x: 7, y: 1)): .custom(.numpadInput("&")),
                .gridFit(.init(x: 8, y: 1)): .custom(.numpadInput("@")),
                .gridFit(.init(x: 9, y: 1)): .custom(.numpadInput("\"")),

                // Row 3: #+= . ? ! ' 、 。 ⌫
                .gridFit(.init(x: 0, y: 2, width: 2, height: 1)): .custom(.numpadSymbolsKey()),
                .gridFit(.init(x: 2, y: 2)): .custom(.numpadInput(".")),
                .gridFit(.init(x: 3, y: 2)): .custom(.numpadInput("?")),
                .gridFit(.init(x: 4, y: 2)): .custom(.numpadInput("!")),
                .gridFit(.init(x: 5, y: 2)): .custom(.numpadInput("'")),
                .gridFit(.init(x: 6, y: 2)): .custom(.numpadInput("、")),
                .gridFit(.init(x: 7, y: 2)): .custom(.numpadInput("。")),
                .gridFit(.init(x: 8, y: 2, width: 2, height: 1)): .custom(.flickDelete()),

                // Row 4: АБВ Globe Space Enter
                .gridFit(.init(x: 0, y: 3, width: 2, height: 1)): .custom(.numpadCyrillicKey()),
                .gridFit(.init(x: 2, y: 3)): .system(.changeKeyboard),
                .gridFit(.init(x: 3, y: 3, width: 4, height: 1)): .custom(.flickSpace()),
                .gridFit(.init(x: 7, y: 3, width: 3, height: 1)): .system(.enter),
            ]
        )
    )
}

private extension CustardInterfaceCustomKey {
    static func numpadInput(_ char: String) -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text(char), color: .normal),
            press_actions: [.input(char)],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func numpadSymbolsKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("#+="), color: .special),
            press_actions: [.moveTab(.system(.qwerty_symbols))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []),
            variations: []
        )
    }

    static func numpadCyrillicKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("АБВ"), color: .special),
            press_actions: [.moveTab(.system(.user_japanese))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []),
            variations: []
        )
    }
}
