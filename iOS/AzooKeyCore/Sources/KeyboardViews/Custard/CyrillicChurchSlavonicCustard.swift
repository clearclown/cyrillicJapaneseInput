//
//  CyrillicChurchSlavonicCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/28.
//

import CustardKit

public extension Custard {
    /// 教会スラヴ語配列 (Church Slavonic with historical letters)
    /// 特徴: 古代キリル文字 (Ѣ, Ѳ, Ѵ, Ѯ, Ѱ, ユス類)
    /// 注: 宗教・歴史的用途
    static let cyrillicChurchSlavonic = Custard(
        identifier: "cyrillic_church_slavonic",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "教会スラヴ語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: й ц у к е н г ш щ з х
                .gridFit(.init(x: 0, y: 0)): .custom(.input("й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.input("ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.inputWithVariation("у", variation: "ѵ")), // у with ѵ (izhitsa)
                .gridFit(.init(x: 3, y: 0)): .custom(.inputWithVariation("к", variation: "ѯ")), // к with ѯ (ksi)
                .gridFit(.init(x: 4, y: 0)): .custom(.inputWithVariation("е", variation: "ѣ")), // е with ѣ (yat)
                .gridFit(.init(x: 5, y: 0)): .custom(.input("н")),
                .gridFit(.init(x: 6, y: 0)): .custom(.input("г")),
                .gridFit(.init(x: 7, y: 0)): .custom(.input("ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.input("щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.inputWithVariation("з", variation: "ѕ")), // з with ѕ (dze)
                .gridFit(.init(x: 10, y: 0)): .custom(.input("х")),

                // Row 2: ф ы в а п р о л д ж э
                .gridFit(.init(x: 0, y: 1)): .custom(.inputWithVariation("ф", variation: "ѳ")), // ф with ѳ (fita)
                .gridFit(.init(x: 1, y: 1)): .custom(.input("ы")),
                .gridFit(.init(x: 2, y: 1)): .custom(.input("в")),
                .gridFit(.init(x: 3, y: 1)): .custom(.inputWithVariation("а", variation: "ѧ")), // а with ѧ (small yus)
                .gridFit(.init(x: 4, y: 1)): .custom(.inputWithVariation("п", variation: "ѱ")), // п with ѱ (psi)
                .gridFit(.init(x: 5, y: 1)): .custom(.input("р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.inputWithVariation("о", variation: "ѫ")), // о with ѫ (big yus)
                .gridFit(.init(x: 7, y: 1)): .custom(.input("л")),
                .gridFit(.init(x: 8, y: 1)): .custom(.input("д")),
                .gridFit(.init(x: 9, y: 1)): .custom(.input("ж")),
                .gridFit(.init(x: 10, y: 1)): .custom(.input("э")),

                // Row 3: Shift я ч с м и т ь б ю Del
                .gridFit(.init(x: 0, y: 2)): .custom(.shiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.inputWithVariation("я", variation: "ѩ")), // я with ѩ (iotified small yus)
                .gridFit(.init(x: 2, y: 2)): .custom(.input("ч")),
                .gridFit(.init(x: 3, y: 2)): .custom(.input("с")),
                .gridFit(.init(x: 4, y: 2)): .custom(.input("м")),
                .gridFit(.init(x: 5, y: 2)): .custom(.inputWithVariation("и", variation: "і")), // и with і (dotted i)
                .gridFit(.init(x: 6, y: 2)): .custom(.input("т")),
                .gridFit(.init(x: 7, y: 2)): .custom(.inputWithVariation("ь", variation: "ъ")),
                .gridFit(.init(x: 8, y: 2)): .custom(.input("б")),
                .gridFit(.init(x: 9, y: 2)): .custom(.inputWithVariation("ю", variation: "ѫ")), // ю with ѫ (big yus variant)
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
