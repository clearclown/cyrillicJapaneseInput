//
//  CyrillicKhantyCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/28.
//

import CustardKit

public extension Custard {
    /// ハンティー語配列 (Khanty/Ostyak with Ә, Ӛ, Є, Ԑ, Ӆ, Ӈ, etc.)
    /// 特徴: ロシア語ベース + ハンティー固有文字
    /// 注: シベリア少数言語
    static let cyrillicKhanty = Custard(
        identifier: "cyrillic_khanty",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "ハンティー語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: й ц у к е н г ш щ з х
                .gridFit(.init(x: 0, y: 0)): .custom(.input("й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.input("ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.inputWithVariation("у", variation: "ў")), // у with ў
                .gridFit(.init(x: 3, y: 0)): .custom(.input("к")),
                .gridFit(.init(x: 4, y: 0)): .custom(.inputWithVariation("е", variation: "є")), // е with є (Ukrainian ye)
                .gridFit(.init(x: 5, y: 0)): .custom(.inputWithVariation("н", variation: "ӈ")), // н with ӈ (velar nasal)
                .gridFit(.init(x: 6, y: 0)): .custom(.input("г")),
                .gridFit(.init(x: 7, y: 0)): .custom(.input("ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.input("щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.input("з")),
                .gridFit(.init(x: 10, y: 0)): .custom(.input("х")),

                // Row 2: ф ы в а п р о л д ж э
                .gridFit(.init(x: 0, y: 1)): .custom(.input("ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.input("ы")),
                .gridFit(.init(x: 2, y: 1)): .custom(.input("в")),
                .gridFit(.init(x: 3, y: 1)): .custom(.inputWithVariation("а", variation: "ә")), // а with ә (schwa)
                .gridFit(.init(x: 4, y: 1)): .custom(.input("п")),
                .gridFit(.init(x: 5, y: 1)): .custom(.input("р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.inputWithVariation("о", variation: "ԑ")), // о with ԑ (open e)
                .gridFit(.init(x: 7, y: 1)): .custom(.inputWithVariation("л", variation: "ӆ")), // л with ӆ (palatal l)
                .gridFit(.init(x: 8, y: 1)): .custom(.input("д")),
                .gridFit(.init(x: 9, y: 1)): .custom(.input("ж")),
                .gridFit(.init(x: 10, y: 1)): .custom(.inputWithVariation("э", variation: "ӛ")), // э with ӛ (umlaut schwa)

                // Row 3: Shift я ч с м и т ь б ю Del
                .gridFit(.init(x: 0, y: 2)): .custom(.shiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.input("я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.input("ч")),
                .gridFit(.init(x: 3, y: 2)): .custom(.input("с")),
                .gridFit(.init(x: 4, y: 2)): .custom(.input("м")),
                .gridFit(.init(x: 5, y: 2)): .custom(.input("и")),
                .gridFit(.init(x: 6, y: 2)): .custom(.input("т")),
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
