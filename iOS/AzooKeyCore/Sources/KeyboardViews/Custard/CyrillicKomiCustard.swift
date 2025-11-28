//
//  CyrillicKomiCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/28.
//

import CustardKit

public extension Custard {
    /// コミ語配列 (Komi with special letters Ӧ, І, Ԁ, Ԃ, etc.)
    /// 特徴: ロシア語ベース + コミ固有文字
    static let cyrillicKomi = Custard(
        identifier: "cyrillic_komi",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "コミ語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: й ц у к е н г ш щ з х
                .gridFit(.init(x: 0, y: 0)): .custom(.input("й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.input("ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.input("у")),
                .gridFit(.init(x: 3, y: 0)): .custom(.input("к")),
                .gridFit(.init(x: 4, y: 0)): .custom(.inputWithVariation("ё", variation: "е")),
                .gridFit(.init(x: 5, y: 0)): .custom(.input("н")),
                .gridFit(.init(x: 6, y: 0)): .custom(.input("г")),
                .gridFit(.init(x: 7, y: 0)): .custom(.input("ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.input("щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.input("з").withLongPress("ԅ")), // з with ԅ (dz)
                .gridFit(.init(x: 10, y: 0)): .custom(.input("х")),

                // Row 2: ф ы в а п р о л д ж э
                .gridFit(.init(x: 0, y: 1)): .custom(.input("ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.input("ы")),
                .gridFit(.init(x: 2, y: 1)): .custom(.input("в")),
                .gridFit(.init(x: 3, y: 1)): .custom(.input("а")),
                .gridFit(.init(x: 4, y: 1)): .custom(.input("п")),
                .gridFit(.init(x: 5, y: 1)): .custom(.input("р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.input("о").withLongPress("ӧ")), // о with ӧ
                .gridFit(.init(x: 7, y: 1)): .custom(.input("л").withLongPress("ԇ")), // л with ԇ (voiceless l)
                .gridFit(.init(x: 8, y: 1)): .custom(.input("д").withLongPress("ԁ")), // д with ԁ (soft d)
                .gridFit(.init(x: 9, y: 1)): .custom(.input("ж").withLongPress("ԃ")), // ж with ԃ (dzh)
                .gridFit(.init(x: 10, y: 1)): .custom(.input("э")),

                // Row 3: Shift я ч с м і т ь б ю Del
                .gridFit(.init(x: 0, y: 2)): .custom(.shiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.input("я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.input("ч").withLongPress("ԉ")), // ч with ԉ (soft ch)
                .gridFit(.init(x: 3, y: 2)): .custom(.input("с").withLongPress("ԍ")), // с with ԍ (soft s)
                .gridFit(.init(x: 4, y: 2)): .custom(.input("м")),
                .gridFit(.init(x: 5, y: 2)): .custom(.input("і")), // і - Komi specific
                .gridFit(.init(x: 6, y: 2)): .custom(.input("т").withLongPress("ԏ")), // т with ԏ (soft t)
                .gridFit(.init(x: 7, y: 2)): .custom(.inputWithVariation("ь", variation: "ъ")),
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
