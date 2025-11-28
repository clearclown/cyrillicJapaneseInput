//
//  CyrillicTatarCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/28.
//

import CustardKit

public extension Custard {
    /// タタール語配列 (Tatar Cyrillic with Ә, Ө, Ү, Җ, Ң, Һ)
    /// 特徴: ロシア語ベース + タタール固有文字
    static let cyrillicTatar = Custard(
        identifier: "cyrillic_tatar",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "タタール語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: й ц у к е н г ш щ з х
                .gridFit(.init(x: 0, y: 0)): .custom(.tatarInput("й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.tatarInput("ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.tatarInput("у").withTatarLongPress("ү")), // у with ү
                .gridFit(.init(x: 3, y: 0)): .custom(.tatarInput("к")),
                .gridFit(.init(x: 4, y: 0)): .custom(.tatarInputWithVariation("ё", variation: "е")),
                .gridFit(.init(x: 5, y: 0)): .custom(.tatarInput("н").withTatarLongPress("ң")), // н with ң
                .gridFit(.init(x: 6, y: 0)): .custom(.tatarInput("г")),
                .gridFit(.init(x: 7, y: 0)): .custom(.tatarInput("ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.tatarInput("щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.tatarInput("з")),
                .gridFit(.init(x: 10, y: 0)): .custom(.tatarInput("х").withTatarLongPress("һ")), // х with һ

                // Row 2: ф ы в а п р о л д ж э
                .gridFit(.init(x: 0, y: 1)): .custom(.tatarInput("ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.tatarInput("ы")),
                .gridFit(.init(x: 2, y: 1)): .custom(.tatarInput("в")),
                .gridFit(.init(x: 3, y: 1)): .custom(.tatarInput("а").withTatarLongPress("ә")), // а with ә
                .gridFit(.init(x: 4, y: 1)): .custom(.tatarInput("п")),
                .gridFit(.init(x: 5, y: 1)): .custom(.tatarInput("р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.tatarInput("о").withTatarLongPress("ө")), // о with ө
                .gridFit(.init(x: 7, y: 1)): .custom(.tatarInput("л")),
                .gridFit(.init(x: 8, y: 1)): .custom(.tatarInput("д")),
                .gridFit(.init(x: 9, y: 1)): .custom(.tatarInput("ж").withTatarLongPress("җ")), // ж with җ
                .gridFit(.init(x: 10, y: 1)): .custom(.tatarInput("э")),

                // Row 3: Shift я ч с м и т ь б ю Del
                .gridFit(.init(x: 0, y: 2)): .custom(.tatarShiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.tatarInput("я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.tatarInput("ч")),
                .gridFit(.init(x: 3, y: 2)): .custom(.tatarInput("с")),
                .gridFit(.init(x: 4, y: 2)): .custom(.tatarInput("м")),
                .gridFit(.init(x: 5, y: 2)): .custom(.tatarInput("и")),
                .gridFit(.init(x: 6, y: 2)): .custom(.tatarInput("т")),
                .gridFit(.init(x: 7, y: 2)): .custom(.tatarInputWithVariation("ь", variation: "ъ")),
                .gridFit(.init(x: 8, y: 2)): .custom(.tatarInput("б")),
                .gridFit(.init(x: 9, y: 2)): .custom(.tatarInput("ю")),
                .gridFit(.init(x: 10, y: 2)): .custom(.flickDelete()),

                // Row 4: ☆123 Globe Space ー Enter
                .gridFit(.init(x: 0, y: 3)): .custom(.tatarSymbolsTabKey()),
                .gridFit(.init(x: 1, y: 3)): .system(.changeKeyboard),
                .gridFit(.init(x: 2, y: 3, width: 6, height: 1)): .custom(.flickSpace()),
                .gridFit(.init(x: 8, y: 3)): .custom(.tatarInput("ー")),
                .gridFit(.init(x: 9, y: 3, width: 2, height: 1)): .system(.enter),
            ]
        )
    )
}

private extension CustardInterfaceCustomKey {
    static func tatarInput(_ char: String) -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text(char), color: .normal),
            press_actions: [.input(char)],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func tatarInputWithVariation(_ char: String, variation: String) -> CustardInterfaceCustomKey {
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

    func withTatarLongPress(_ char: String) -> CustardInterfaceCustomKey {
        var copy = self
        copy.longpress_actions.start = [.input(char)]
        return copy
    }

    static func tatarShiftKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .systemImage("shift"), color: .special),
            press_actions: [.toggleCapsLockState],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func tatarSymbolsTabKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("☆123"), color: .special),
            press_actions: [.moveTab(.system(.flick_numbersymbols))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []),
            variations: []
        )
    }
}
