//
//  CyrillicKalmykCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/28.
//

import CustardKit

public extension Custard {
    /// カルムイク語配列 (Kalmyk Cyrillic with Ә, Һ, Җ, Ң, Ө, Ү)
    /// 特徴: ロシア語ベース + カルムイク固有文字
    static let cyrillicKalmyk = Custard(
        identifier: "cyrillic_kalmyk",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "カルムイク語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: й ц у к е н г ш щ з х
                .gridFit(.init(x: 0, y: 0)): .custom(.kalmykInput("й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.kalmykInput("ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.kalmykInput("у").withKalmykLongPress("ү")), // у with ү
                .gridFit(.init(x: 3, y: 0)): .custom(.kalmykInput("к")),
                .gridFit(.init(x: 4, y: 0)): .custom(.kalmykInputWithVariation("ё", variation: "е")),
                .gridFit(.init(x: 5, y: 0)): .custom(.kalmykInput("н").withKalmykLongPress("ң")), // н with ң
                .gridFit(.init(x: 6, y: 0)): .custom(.kalmykInput("г")),
                .gridFit(.init(x: 7, y: 0)): .custom(.kalmykInput("ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.kalmykInput("щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.kalmykInput("з")),
                .gridFit(.init(x: 10, y: 0)): .custom(.kalmykInput("х").withKalmykLongPress("һ")), // х with һ

                // Row 2: ф ы в а п р о л д ж э
                .gridFit(.init(x: 0, y: 1)): .custom(.kalmykInput("ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.kalmykInput("ы")),
                .gridFit(.init(x: 2, y: 1)): .custom(.kalmykInput("в")),
                .gridFit(.init(x: 3, y: 1)): .custom(.kalmykInput("а").withKalmykLongPress("ә")), // а with ә
                .gridFit(.init(x: 4, y: 1)): .custom(.kalmykInput("п")),
                .gridFit(.init(x: 5, y: 1)): .custom(.kalmykInput("р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.kalmykInput("о").withKalmykLongPress("ө")), // о with ө
                .gridFit(.init(x: 7, y: 1)): .custom(.kalmykInput("л")),
                .gridFit(.init(x: 8, y: 1)): .custom(.kalmykInput("д")),
                .gridFit(.init(x: 9, y: 1)): .custom(.kalmykInput("ж").withKalmykLongPress("җ")), // ж with җ
                .gridFit(.init(x: 10, y: 1)): .custom(.kalmykInput("э")),

                // Row 3: Shift я ч с м и т ь б ю Del
                .gridFit(.init(x: 0, y: 2)): .custom(.kalmykShiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.kalmykInput("я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.kalmykInput("ч")),
                .gridFit(.init(x: 3, y: 2)): .custom(.kalmykInput("с")),
                .gridFit(.init(x: 4, y: 2)): .custom(.kalmykInput("м")),
                .gridFit(.init(x: 5, y: 2)): .custom(.kalmykInput("и")),
                .gridFit(.init(x: 6, y: 2)): .custom(.kalmykInput("т")),
                .gridFit(.init(x: 7, y: 2)): .custom(.kalmykInputWithVariation("ь", variation: "ъ")),
                .gridFit(.init(x: 8, y: 2)): .custom(.kalmykInput("б")),
                .gridFit(.init(x: 9, y: 2)): .custom(.kalmykInput("ю")),
                .gridFit(.init(x: 10, y: 2)): .custom(.flickDelete()),

                // Row 4: ☆123 Globe Space ー Enter
                .gridFit(.init(x: 0, y: 3)): .custom(.kalmykSymbolsTabKey()),
                .gridFit(.init(x: 1, y: 3)): .system(.changeKeyboard),
                .gridFit(.init(x: 2, y: 3, width: 6, height: 1)): .custom(.flickSpace()),
                .gridFit(.init(x: 8, y: 3)): .custom(.kalmykInput("ー")),
                .gridFit(.init(x: 9, y: 3, width: 2, height: 1)): .system(.enter),
            ]
        )
    )
}

private extension CustardInterfaceCustomKey {
    static func kalmykInput(_ char: String) -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text(char), color: .normal),
            press_actions: [.input(char)],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func kalmykInputWithVariation(_ char: String, variation: String) -> CustardInterfaceCustomKey {
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

    func withKalmykLongPress(_ char: String) -> CustardInterfaceCustomKey {
        var copy = self
        copy.longpress_actions.start = [.input(char)]
        return copy
    }

    static func kalmykShiftKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .systemImage("shift"), color: .special),
            press_actions: [.toggleCapsLockState],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func kalmykSymbolsTabKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("☆123"), color: .special),
            press_actions: [.moveTab(.system(.flick_numbersymbols))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []),
            variations: []
        )
    }
}
