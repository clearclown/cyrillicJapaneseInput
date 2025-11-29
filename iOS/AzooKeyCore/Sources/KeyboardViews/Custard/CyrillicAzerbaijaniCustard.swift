//
//  CyrillicAzerbaijaniCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/28.
//

import CustardKit

public extension Custard {
    /// アゼルバイジャン語配列 (Historical Cyrillic with Ҝ, Ғ, Ҹ, Ҷ, Ө, Ү, Ә)
    /// 特徴: ロシア語ベース + アゼルバイジャン固有文字
    /// 注: 現在はラテン文字が主流だが、歴史的にキリル文字が使用されていた
    static let cyrillicAzerbaijani = Custard(
        identifier: "cyrillic_azerbaijani",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "アゼルバイジャン語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: й ц у к е н г ш щ з х
                .gridFit(.init(x: 0, y: 0)): .custom(.input("й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.input("ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.inputWithVariation("у", variation: "ү")), // у with ү
                .gridFit(.init(x: 3, y: 0)): .custom(.input("к")),
                .gridFit(.init(x: 4, y: 0)): .custom(.inputWithVariation("ё", variation: "е")),
                .gridFit(.init(x: 5, y: 0)): .custom(.input("н")),
                .gridFit(.init(x: 6, y: 0)): .custom(.inputWithMultipleVariations("г", variations: ["ғ", "ҝ"])), // г with ғ (top), ҝ (left)
                .gridFit(.init(x: 7, y: 0)): .custom(.input("ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.input("щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.input("з")),
                .gridFit(.init(x: 10, y: 0)): .custom(.input("х")),

                // Row 2: ф ы в а п р о л д ж э
                .gridFit(.init(x: 0, y: 1)): .custom(.input("ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.input("ы")),
                .gridFit(.init(x: 2, y: 1)): .custom(.input("в")),
                .gridFit(.init(x: 3, y: 1)): .custom(.inputWithVariation("а", variation: "ә")), // а with ә
                .gridFit(.init(x: 4, y: 1)): .custom(.input("п")),
                .gridFit(.init(x: 5, y: 1)): .custom(.input("р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.inputWithVariation("о", variation: "ө")), // о with ө
                .gridFit(.init(x: 7, y: 1)): .custom(.input("л")),
                .gridFit(.init(x: 8, y: 1)): .custom(.input("д")),
                .gridFit(.init(x: 9, y: 1)): .custom(.inputWithVariation("ж", variation: "ҹ")), // ж with ҹ
                .gridFit(.init(x: 10, y: 1)): .custom(.input("э")),

                // Row 3: Shift я ч с м и т ь б ю Del
                .gridFit(.init(x: 0, y: 2)): .custom(.shiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.input("я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.inputWithVariation("ч", variation: "ҷ")), // ч with ҷ
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

    static func inputWithMultipleVariations(_ char: String, variations: [String]) -> CustardInterfaceCustomKey {
        let flickDirections: [FlickDirection] = [.top, .left, .right, .bottom]
        var flickVariations: [CustardInterfaceVariation] = []

        for (index, variation) in variations.enumerated() where index < flickDirections.count {
            flickVariations.append(CustardInterfaceVariation(
                type: .flickVariation(flickDirections[index]),
                key: CustardInterfaceVariationKey(
                    design: CustardVariationKeyDesign(label: .text(variation)),
                    press_actions: [.input(variation)],
                    longpress_actions: .none
                )
            ))
        }

        return CustardInterfaceCustomKey(
            design: .init(label: .text(char), color: .normal),
            press_actions: [.input(char)],
            longpress_actions: .init(start: [], repeat: []),
            variations: flickVariations
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
