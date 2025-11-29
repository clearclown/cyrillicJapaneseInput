//
//  CyrillicBashkirCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/28.
//

import CustardKit

public extension Custard {
    /// バシキール語配列 (Bashkir Cyrillic with Ә, Ө, Ү, Ғ, Ҡ, Ң, Ҙ, Ҫ, Һ)
    /// 特徴: ロシア語ベース + バシキール固有文字
    static let cyrillicBashkir = Custard(
        identifier: "cyrillic_bashkir",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "バシキール語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: й ц у к е н г ш щ з х
                .gridFit(.init(x: 0, y: 0)): .custom(.bashkirInput("й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.bashkirInput("ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.bashkirInput("у").withBashkirLongPress("ү")), // у with ү
                .gridFit(.init(x: 3, y: 0)): .custom(.bashkirInput("к").withBashkirLongPress("ҡ")), // к with ҡ
                .gridFit(.init(x: 4, y: 0)): .custom(.bashkirInputWithVariation("ё", variation: "е")),
                .gridFit(.init(x: 5, y: 0)): .custom(.bashkirInput("н").withBashkirLongPress("ң")), // н with ң
                .gridFit(.init(x: 6, y: 0)): .custom(.bashkirInput("г").withBashkirLongPress("ғ")), // г with ғ
                .gridFit(.init(x: 7, y: 0)): .custom(.bashkirInput("ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.bashkirInput("щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.bashkirInput("з").withBashkirLongPress("ҙ")), // з with ҙ
                .gridFit(.init(x: 10, y: 0)): .custom(.bashkirInput("х").withBashkirLongPress("һ")), // х with һ

                // Row 2: ф ы в а п р о л д ж э
                .gridFit(.init(x: 0, y: 1)): .custom(.bashkirInput("ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.bashkirInput("ы")),
                .gridFit(.init(x: 2, y: 1)): .custom(.bashkirInput("в")),
                .gridFit(.init(x: 3, y: 1)): .custom(.bashkirInput("а").withBashkirLongPress("ә")), // а with ә
                .gridFit(.init(x: 4, y: 1)): .custom(.bashkirInput("п")),
                .gridFit(.init(x: 5, y: 1)): .custom(.bashkirInput("р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.bashkirInput("о").withBashkirLongPress("ө")), // о with ө
                .gridFit(.init(x: 7, y: 1)): .custom(.bashkirInput("л")),
                .gridFit(.init(x: 8, y: 1)): .custom(.bashkirInput("д")),
                .gridFit(.init(x: 9, y: 1)): .custom(.bashkirInput("ж")),
                .gridFit(.init(x: 10, y: 1)): .custom(.bashkirInput("э")),

                // Row 3: Shift я ч с м и т ь б ю Del
                .gridFit(.init(x: 0, y: 2)): .custom(.bashkirShiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.bashkirInput("я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.bashkirInput("ч")),
                .gridFit(.init(x: 3, y: 2)): .custom(.bashkirInput("с").withBashkirLongPress("ҫ")), // с with ҫ
                .gridFit(.init(x: 4, y: 2)): .custom(.bashkirInput("м")),
                .gridFit(.init(x: 5, y: 2)): .custom(.bashkirInput("и")),
                .gridFit(.init(x: 6, y: 2)): .custom(.bashkirInput("т")),
                .gridFit(.init(x: 7, y: 2)): .custom(.bashkirInputWithVariation("ь", variation: "ъ")),
                .gridFit(.init(x: 8, y: 2)): .custom(.bashkirInput("б")),
                .gridFit(.init(x: 9, y: 2)): .custom(.bashkirInput("ю")),
                .gridFit(.init(x: 10, y: 2)): .custom(.flickDelete()),

                // Row 4: ☆123 Globe Space ー Enter
                .gridFit(.init(x: 0, y: 3)): .custom(.bashkirSymbolsTabKey()),
                .gridFit(.init(x: 1, y: 3)): .system(.changeKeyboard),
                .gridFit(.init(x: 2, y: 3, width: 6, height: 1)): .custom(.flickSpace()),
                .gridFit(.init(x: 8, y: 3)): .custom(.bashkirInput("ー")),
                .gridFit(.init(x: 9, y: 3, width: 2, height: 1)): .system(.enter),
            ]
        )
    )
}

private extension CustardInterfaceCustomKey {
    static func bashkirInput(_ char: String) -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text(char), color: .normal),
            press_actions: [.input(char)],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func bashkirInputWithVariation(_ char: String, variation: String) -> CustardInterfaceCustomKey {
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

    func withBashkirLongPress(_ char: String) -> CustardInterfaceCustomKey {
        var copy = self
        copy.longpress_actions.start = [.input(char)]
        return copy
    }

    static func bashkirShiftKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .systemImage("shift"), color: .special),
            press_actions: [.toggleCapsLockState],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func bashkirSymbolsTabKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("☆123"), color: .special),
            press_actions: [.moveTab(.system(.flick_numbersymbols))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []),
            variations: []
        )
    }
}
