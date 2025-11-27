//
//  CyrillicSakhaCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/28.
//

import CustardKit

public extension Custard {
    /// サハ語（ヤクート語）配列 (Sakha/Yakut Cyrillic with Ҕ, Һ, Ө, Ү, Ҥ)
    /// 特徴: ロシア語ベース + サハ固有文字
    static let cyrillicSakha = Custard(
        identifier: "cyrillic_sakha",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "サハ語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: й ц у к е н г ш щ з х
                .gridFit(.init(x: 0, y: 0)): .custom(.sakhaInput("й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.sakhaInput("ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.sakhaInput("у").withSakhaLongPress("ү")), // у with ү
                .gridFit(.init(x: 3, y: 0)): .custom(.sakhaInput("к")),
                .gridFit(.init(x: 4, y: 0)): .custom(.sakhaInputWithVariation("ё", variation: "е")),
                .gridFit(.init(x: 5, y: 0)): .custom(.sakhaInput("н").withSakhaLongPress("ҥ")), // н with ҥ (ng)
                .gridFit(.init(x: 6, y: 0)): .custom(.sakhaInput("г").withSakhaLongPress("ҕ")), // г with ҕ
                .gridFit(.init(x: 7, y: 0)): .custom(.sakhaInput("ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.sakhaInput("щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.sakhaInput("з")),
                .gridFit(.init(x: 10, y: 0)): .custom(.sakhaInput("х").withSakhaLongPress("һ")), // х with һ

                // Row 2: ф ы в а п р о л д ж э
                .gridFit(.init(x: 0, y: 1)): .custom(.sakhaInput("ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.sakhaInput("ы")),
                .gridFit(.init(x: 2, y: 1)): .custom(.sakhaInput("в")),
                .gridFit(.init(x: 3, y: 1)): .custom(.sakhaInput("а")),
                .gridFit(.init(x: 4, y: 1)): .custom(.sakhaInput("п")),
                .gridFit(.init(x: 5, y: 1)): .custom(.sakhaInput("р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.sakhaInput("о").withSakhaLongPress("ө")), // о with ө
                .gridFit(.init(x: 7, y: 1)): .custom(.sakhaInput("л")),
                .gridFit(.init(x: 8, y: 1)): .custom(.sakhaInput("д")),
                .gridFit(.init(x: 9, y: 1)): .custom(.sakhaInput("ж")),
                .gridFit(.init(x: 10, y: 1)): .custom(.sakhaInput("э")),

                // Row 3: Shift я ч с м и т ь б ю Del
                .gridFit(.init(x: 0, y: 2)): .custom(.sakhaShiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.sakhaInput("я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.sakhaInput("ч")),
                .gridFit(.init(x: 3, y: 2)): .custom(.sakhaInput("с")),
                .gridFit(.init(x: 4, y: 2)): .custom(.sakhaInput("м")),
                .gridFit(.init(x: 5, y: 2)): .custom(.sakhaInput("и")),
                .gridFit(.init(x: 6, y: 2)): .custom(.sakhaInput("т")),
                .gridFit(.init(x: 7, y: 2)): .custom(.sakhaInputWithVariation("ь", variation: "ъ")),
                .gridFit(.init(x: 8, y: 2)): .custom(.sakhaInput("б")),
                .gridFit(.init(x: 9, y: 2)): .custom(.sakhaInput("ю")),
                .gridFit(.init(x: 10, y: 2)): .custom(.flickDelete()),

                // Row 4: ☆123 Globe Space ー Enter
                .gridFit(.init(x: 0, y: 3)): .custom(.sakhaSymbolsTabKey()),
                .gridFit(.init(x: 1, y: 3)): .system(.changeKeyboard),
                .gridFit(.init(x: 2, y: 3, width: 6, height: 1)): .custom(.flickSpace()),
                .gridFit(.init(x: 8, y: 3)): .custom(.sakhaInput("ー")),
                .gridFit(.init(x: 9, y: 3, width: 2, height: 1)): .system(.enter),
            ]
        )
    )
}

private extension CustardInterfaceCustomKey {
    static func sakhaInput(_ char: String) -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text(char), color: .normal),
            press_actions: [.input(char)],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func sakhaInputWithVariation(_ char: String, variation: String) -> CustardInterfaceCustomKey {
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

    func withSakhaLongPress(_ char: String) -> CustardInterfaceCustomKey {
        var copy = self
        copy.longpress_actions.start = [.input(char)]
        return copy
    }

    static func sakhaShiftKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .systemImage("shift"), color: .special),
            press_actions: [.toggleCapsLockState],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func sakhaSymbolsTabKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("☆123"), color: .special),
            press_actions: [.moveTab(.system(.flick_numbersymbols))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []),
            variations: []
        )
    }
}
