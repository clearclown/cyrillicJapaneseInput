//
//  CyrillicBuryatCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/28.
//

import CustardKit

public extension Custard {
    /// ブリヤート語配列 (Buryat Cyrillic with Ө, Ү, Һ)
    /// 特徴: ロシア語ベース + ブリヤート固有文字
    static let cyrillicBuryat = Custard(
        identifier: "cyrillic_buryat",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "ブリヤート語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: й ц у к е н г ш щ з х
                .gridFit(.init(x: 0, y: 0)): .custom(.buryatInput("й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.buryatInput("ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.buryatInput("у").withBuryatLongPress("ү")), // у with ү
                .gridFit(.init(x: 3, y: 0)): .custom(.buryatInput("к")),
                .gridFit(.init(x: 4, y: 0)): .custom(.buryatInputWithVariation("ё", variation: "е")),
                .gridFit(.init(x: 5, y: 0)): .custom(.buryatInput("н")),
                .gridFit(.init(x: 6, y: 0)): .custom(.buryatInput("г")),
                .gridFit(.init(x: 7, y: 0)): .custom(.buryatInput("ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.buryatInput("щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.buryatInput("з")),
                .gridFit(.init(x: 10, y: 0)): .custom(.buryatInput("х").withBuryatLongPress("һ")), // х with һ

                // Row 2: ф ы в а п р о л д ж э
                .gridFit(.init(x: 0, y: 1)): .custom(.buryatInput("ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.buryatInput("ы")),
                .gridFit(.init(x: 2, y: 1)): .custom(.buryatInput("в")),
                .gridFit(.init(x: 3, y: 1)): .custom(.buryatInput("а")),
                .gridFit(.init(x: 4, y: 1)): .custom(.buryatInput("п")),
                .gridFit(.init(x: 5, y: 1)): .custom(.buryatInput("р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.buryatInput("о").withBuryatLongPress("ө")), // о with ө
                .gridFit(.init(x: 7, y: 1)): .custom(.buryatInput("л")),
                .gridFit(.init(x: 8, y: 1)): .custom(.buryatInput("д")),
                .gridFit(.init(x: 9, y: 1)): .custom(.buryatInput("ж")),
                .gridFit(.init(x: 10, y: 1)): .custom(.buryatInput("э")),

                // Row 3: Shift я ч с м и т ь б ю Del
                .gridFit(.init(x: 0, y: 2)): .custom(.buryatShiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.buryatInput("я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.buryatInput("ч")),
                .gridFit(.init(x: 3, y: 2)): .custom(.buryatInput("с")),
                .gridFit(.init(x: 4, y: 2)): .custom(.buryatInput("м")),
                .gridFit(.init(x: 5, y: 2)): .custom(.buryatInput("и")),
                .gridFit(.init(x: 6, y: 2)): .custom(.buryatInput("т")),
                .gridFit(.init(x: 7, y: 2)): .custom(.buryatInputWithVariation("ь", variation: "ъ")),
                .gridFit(.init(x: 8, y: 2)): .custom(.buryatInput("б")),
                .gridFit(.init(x: 9, y: 2)): .custom(.buryatInput("ю")),
                .gridFit(.init(x: 10, y: 2)): .custom(.flickDelete()),

                // Row 4: ☆123 Globe Space ー Enter
                .gridFit(.init(x: 0, y: 3)): .custom(.buryatSymbolsTabKey()),
                .gridFit(.init(x: 1, y: 3)): .system(.changeKeyboard),
                .gridFit(.init(x: 2, y: 3, width: 6, height: 1)): .custom(.flickSpace()),
                .gridFit(.init(x: 8, y: 3)): .custom(.buryatInput("ー")),
                .gridFit(.init(x: 9, y: 3, width: 2, height: 1)): .system(.enter),
            ]
        )
    )
}

private extension CustardInterfaceCustomKey {
    static func buryatInput(_ char: String) -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text(char), color: .normal),
            press_actions: [.input(char)],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func buryatInputWithVariation(_ char: String, variation: String) -> CustardInterfaceCustomKey {
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

    func withBuryatLongPress(_ char: String) -> CustardInterfaceCustomKey {
        var copy = self
        copy.longpress_actions.start = [.input(char)]
        return copy
    }

    static func buryatShiftKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .systemImage("shift"), color: .special),
            press_actions: [.toggleCapsLockState],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func buryatSymbolsTabKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("☆123"), color: .special),
            press_actions: [.moveTab(.system(.flick_numbersymbols))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []),
            variations: []
        )
    }
}
