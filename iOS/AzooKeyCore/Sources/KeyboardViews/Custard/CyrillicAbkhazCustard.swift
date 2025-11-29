//
//  CyrillicAbkhazCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/28.
//

import CustardKit

public extension Custard {
    /// アブハズ語配列 (Abkhaz with extensive special characters)
    /// 特徴: 複雑な子音体系を持つカフカス言語
    /// 特殊文字: Ҕ, Ӡ, Ҙ, Ҟ, Ԥ, Ҧ, Ҽ, Ҿ, Ҳ, Ҵ, Ҷ, Ҩ, Ә, etc.
    static let cyrillicAbkhaz = Custard(
        identifier: "cyrillic_abkhaz",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "アブハズ語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: й ц у к е н г ш щ з х
                .gridFit(.init(x: 0, y: 0)): .custom(.input("й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.inputWithVariation("ц", variation: "ҵ")), // ц with ҵ (ejective ts)
                .gridFit(.init(x: 2, y: 0)): .custom(.input("у")),
                .gridFit(.init(x: 3, y: 0)): .custom(.inputWithVariation("к", variation: "ҟ")), // к with ҟ (ejective k)
                .gridFit(.init(x: 4, y: 0)): .custom(.inputWithVariation("ё", variation: "е")),
                .gridFit(.init(x: 5, y: 0)): .custom(.input("н")),
                .gridFit(.init(x: 6, y: 0)): .custom(.inputWithVariation("г", variation: "ҕ")), // г with ҕ (voiced uvular fricative)
                .gridFit(.init(x: 7, y: 0)): .custom(.inputWithVariation("ш", variation: "ҩ")), // ш with ҩ (o-hook)
                .gridFit(.init(x: 8, y: 0)): .custom(.input("щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.inputWithVariation("з", variation: "ӡ")), // з with ӡ (voiced alveolar affricate)
                .gridFit(.init(x: 10, y: 0)): .custom(.inputWithVariation("х", variation: "ҳ")), // х with ҳ (voiceless pharyngeal fricative)

                // Row 2: ф ы в а п р о л д ж э
                .gridFit(.init(x: 0, y: 1)): .custom(.input("ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.input("ы")),
                .gridFit(.init(x: 2, y: 1)): .custom(.input("в")),
                .gridFit(.init(x: 3, y: 1)): .custom(.inputWithVariation("а", variation: "ә")), // а with ә (schwa)
                .gridFit(.init(x: 4, y: 1)): .custom(.inputWithVariation("п", variation: "ԥ")), // п with ԥ (ejective p)
                .gridFit(.init(x: 5, y: 1)): .custom(.input("р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.input("о")),
                .gridFit(.init(x: 7, y: 1)): .custom(.input("л")),
                .gridFit(.init(x: 8, y: 1)): .custom(.inputWithVariation("д", variation: "ҙ")), // д with ҙ (voiced dental fricative)
                .gridFit(.init(x: 9, y: 1)): .custom(.inputWithVariation("ж", variation: "ҽ")), // ж with ҽ (che with descender)
                .gridFit(.init(x: 10, y: 1)): .custom(.input("э")),

                // Row 3: Shift я ч с м и т ь б ю Del
                .gridFit(.init(x: 0, y: 2)): .custom(.shiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.input("я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.inputWithVariation("ч", variation: "ҷ")), // ч with ҷ (che with descender)
                .gridFit(.init(x: 3, y: 2)): .custom(.input("с")),
                .gridFit(.init(x: 4, y: 2)): .custom(.input("м")),
                .gridFit(.init(x: 5, y: 2)): .custom(.input("и")),
                .gridFit(.init(x: 6, y: 2)): .custom(.inputWithVariation("т", variation: "ҿ")), // т with ҿ (che with vertical stroke)
                .gridFit(.init(x: 7, y: 2)): .custom(.inputWithVariation("ь", variation: "ҧ")), // ь with ҧ (pe with middle hook)
                .gridFit(.init(x: 8, y: 2)): .custom(.input("б")),
                .gridFit(.init(x: 9, y: 2)): .custom(.input("ю")),
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
