//
//  CyrillicChuvashCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/28.
//

import CustardKit

public extension Custard {
    /// チュヴァシ語配列 (Chuvash Cyrillic with Ӑ, Ӗ, Ҫ, Ӳ)
    /// 特徴: ロシア語ベース + チュヴァシ固有文字
    static let cyrillicChuvash = Custard(
        identifier: "cyrillic_chuvash",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "チュヴァシ語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: й ц у к е н г ш щ з х
                .gridFit(.init(x: 0, y: 0)): .custom(.chuvashInput("й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.chuvashInput("ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.chuvashInput("у").withChuvashLongPress("ӳ")), // у with ӳ
                .gridFit(.init(x: 3, y: 0)): .custom(.chuvashInput("к")),
                .gridFit(.init(x: 4, y: 0)): .custom(.chuvashInput("е").withChuvashLongPress("ӗ")), // е with ӗ
                .gridFit(.init(x: 5, y: 0)): .custom(.chuvashInput("н")),
                .gridFit(.init(x: 6, y: 0)): .custom(.chuvashInput("г")),
                .gridFit(.init(x: 7, y: 0)): .custom(.chuvashInput("ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.chuvashInput("щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.chuvashInput("з")),
                .gridFit(.init(x: 10, y: 0)): .custom(.chuvashInput("х")),

                // Row 2: ф ы в а п р о л д ж э
                .gridFit(.init(x: 0, y: 1)): .custom(.chuvashInput("ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.chuvashInput("ы")),
                .gridFit(.init(x: 2, y: 1)): .custom(.chuvashInput("в")),
                .gridFit(.init(x: 3, y: 1)): .custom(.chuvashInput("а").withChuvashLongPress("ӑ")), // а with ӑ
                .gridFit(.init(x: 4, y: 1)): .custom(.chuvashInput("п")),
                .gridFit(.init(x: 5, y: 1)): .custom(.chuvashInput("р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.chuvashInput("о")),
                .gridFit(.init(x: 7, y: 1)): .custom(.chuvashInput("л")),
                .gridFit(.init(x: 8, y: 1)): .custom(.chuvashInput("д")),
                .gridFit(.init(x: 9, y: 1)): .custom(.chuvashInput("ж")),
                .gridFit(.init(x: 10, y: 1)): .custom(.chuvashInput("э")),

                // Row 3: Shift я ч с м и т ь б ю Del
                .gridFit(.init(x: 0, y: 2)): .custom(.chuvashShiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.chuvashInput("я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.chuvashInput("ч")),
                .gridFit(.init(x: 3, y: 2)): .custom(.chuvashInput("с").withChuvashLongPress("ҫ")), // с with ҫ
                .gridFit(.init(x: 4, y: 2)): .custom(.chuvashInput("м")),
                .gridFit(.init(x: 5, y: 2)): .custom(.chuvashInput("и")),
                .gridFit(.init(x: 6, y: 2)): .custom(.chuvashInput("т")),
                .gridFit(.init(x: 7, y: 2)): .custom(.chuvashInputWithVariation("ь", variation: "ъ")),
                .gridFit(.init(x: 8, y: 2)): .custom(.chuvashInput("б")),
                .gridFit(.init(x: 9, y: 2)): .custom(.chuvashInput("ю")),
                .gridFit(.init(x: 10, y: 2)): .custom(.flickDelete()),

                // Row 4: ☆123 Globe Space ー Enter
                .gridFit(.init(x: 0, y: 3)): .custom(.chuvashSymbolsTabKey()),
                .gridFit(.init(x: 1, y: 3)): .system(.changeKeyboard),
                .gridFit(.init(x: 2, y: 3, width: 6, height: 1)): .custom(.flickSpace()),
                .gridFit(.init(x: 8, y: 3)): .custom(.chuvashInput("ー")),
                .gridFit(.init(x: 9, y: 3, width: 2, height: 1)): .system(.enter),
            ]
        )
    )
}

private extension CustardInterfaceCustomKey {
    static func chuvashInput(_ char: String) -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text(char), color: .normal),
            press_actions: [.input(char)],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func chuvashInputWithVariation(_ char: String, variation: String) -> CustardInterfaceCustomKey {
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

    func withChuvashLongPress(_ char: String) -> CustardInterfaceCustomKey {
        var copy = self
        copy.longpress_actions.start = [.input(char)]
        return copy
    }

    static func chuvashShiftKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .systemImage("shift"), color: .special),
            press_actions: [.toggleCapsLockState],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func chuvashSymbolsTabKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("☆123"), color: .special),
            press_actions: [.moveTab(.system(.flick_numbersymbols))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []),
            variations: []
        )
    }
}
