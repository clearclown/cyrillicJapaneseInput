//
//  CyrillicMacedonianCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/28.
//

import CustardKit

public extension Custard {
    /// マケドニア語配列 (QWERTZ-based, similar to Serbian)
    /// 特徴: Ѓ, Ќ, Ѕ, Љ, Њ, Џ を使用
    static let cyrillicMacedonian = Custard(
        identifier: "cyrillic_macedonian",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "マケドニア語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: љ њ е р т ѕ у и о п ш
                .gridFit(.init(x: 0, y: 0)): .custom(.input("љ")),
                .gridFit(.init(x: 1, y: 0)): .custom(.input("њ")),
                .gridFit(.init(x: 2, y: 0)): .custom(.inputWithVariation("е", variation: "ё")),
                .gridFit(.init(x: 3, y: 0)): .custom(.input("р")),
                .gridFit(.init(x: 4, y: 0)): .custom(.input("т")),
                .gridFit(.init(x: 5, y: 0)): .custom(.input("ѕ")), // Ѕ - unique to Macedonian
                .gridFit(.init(x: 6, y: 0)): .custom(.input("у")),
                .gridFit(.init(x: 7, y: 0)): .custom(.input("и")),
                .gridFit(.init(x: 8, y: 0)): .custom(.input("о")),
                .gridFit(.init(x: 9, y: 0)): .custom(.input("п")),
                .gridFit(.init(x: 10, y: 0)): .custom(.input("ш")),

                // Row 2: а с д ф г х ј к л ч ќ
                .gridFit(.init(x: 0, y: 1)): .custom(.input("а")),
                .gridFit(.init(x: 1, y: 1)): .custom(.input("с")),
                .gridFit(.init(x: 2, y: 1)): .custom(.input("д")),
                .gridFit(.init(x: 3, y: 1)): .custom(.input("ф")),
                .gridFit(.init(x: 4, y: 1)): .custom(.input("г").withLongPress("ѓ")), // г with ѓ
                .gridFit(.init(x: 5, y: 1)): .custom(.input("х")),
                .gridFit(.init(x: 6, y: 1)): .custom(.input("ј")),
                .gridFit(.init(x: 7, y: 1)): .custom(.input("к").withLongPress("ќ")), // к with ќ
                .gridFit(.init(x: 8, y: 1)): .custom(.input("л")),
                .gridFit(.init(x: 9, y: 1)): .custom(.input("ч")),
                .gridFit(.init(x: 10, y: 1)): .custom(.input("ќ")), // Ќ - unique to Macedonian

                // Row 3: Shift з џ ц в б н м ѓ ж Del
                .gridFit(.init(x: 0, y: 2)): .custom(.shiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.input("з")),
                .gridFit(.init(x: 2, y: 2)): .custom(.input("џ")),
                .gridFit(.init(x: 3, y: 2)): .custom(.input("ц")),
                .gridFit(.init(x: 4, y: 2)): .custom(.input("в")),
                .gridFit(.init(x: 5, y: 2)): .custom(.input("б")),
                .gridFit(.init(x: 6, y: 2)): .custom(.input("н")),
                .gridFit(.init(x: 7, y: 2)): .custom(.input("м")),
                .gridFit(.init(x: 8, y: 2)): .custom(.input("ѓ")), // Ѓ - unique to Macedonian
                .gridFit(.init(x: 9, y: 2)): .custom(.input("ж")),
                .gridFit(.init(x: 10, y: 2)): .custom(.flickDelete()),

                // Row 4: ☆123 Globe Space ー Enter
                .gridFit(.init(x: 0, y: 3)): .custom(.symbolsTabKey()),
                .gridFit(.init(x: 1, y: 3)): .system(.changeKeyboard),
                .gridFit(.init(x: 2, y: 3, width: 6, height: 1)): .custom(.flickSpace()),
                .gridFit(.init(x: 8, y: 3)): .custom(.input("ー")),
                .gridFit(.init(x: 9, y: 3, width: 2, height: 1)): .system(.enter),
            ]
        )
    )
}

private extension CustardInterfaceCustomKey {
    static func input(_ char: String) -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text(char), color: .normal),
            press_actions: [.input(char)],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func inputWithVariation(_ char: String, variation: String) -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text(char), color: .normal),
            press_actions: [.input(char)],
            longpress_actions: .init(start: [], repeat: []),
            variations: [
                CustardInterfaceVariation(
                    type: .flickVariation(.top),
                    key: CustardInterfaceVariationKey(
                        design: CustardVariationKeyDesign(label: .text(variation)),
                        press_actions: [.input(variation)],
                        longpress_actions: .none
                    )
                )
            ]
        )
    }

    func withLongPress(_ char: String) -> CustardInterfaceCustomKey {
        var copy = self
        copy.longpress_actions.start = [.input(char)]
        return copy
    }

    static func shiftKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .systemImage("shift"), color: .special),
            press_actions: [.toggleCapsLockState],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func symbolsTabKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("☆123"), color: .special),
            press_actions: [.moveTab(.system(.flick_numbersymbols))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []),
            variations: []
        )
    }
}
