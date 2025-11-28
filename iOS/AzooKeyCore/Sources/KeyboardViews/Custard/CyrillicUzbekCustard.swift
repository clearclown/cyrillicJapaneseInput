//
//  CyrillicUzbekCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/28.
//

import CustardKit

public extension Custard {
    /// ウズベク語配列 (Uzbek Cyrillic with Ғ, Қ, Ҳ, Ў)
    /// 特徴: ロシア語ベース + ウズベク固有文字
    static let cyrillicUzbek = Custard(
        identifier: "cyrillic_uzbek",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "ウズベク語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: й ц у к е н г ш щ з х
                .gridFit(.init(x: 0, y: 0)): .custom(.uzbekInput("й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.uzbekInput("ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.uzbekInput("у").withUzbekLongPress("ў")), // у with ў
                .gridFit(.init(x: 3, y: 0)): .custom(.uzbekInput("к").withUzbekLongPress("қ")), // к with қ
                .gridFit(.init(x: 4, y: 0)): .custom(.uzbekInputWithVariation("ё", variation: "е")),
                .gridFit(.init(x: 5, y: 0)): .custom(.uzbekInput("н")),
                .gridFit(.init(x: 6, y: 0)): .custom(.uzbekInput("г").withUzbekLongPress("ғ")), // г with ғ
                .gridFit(.init(x: 7, y: 0)): .custom(.uzbekInput("ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.uzbekInput("щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.uzbekInput("з")),
                .gridFit(.init(x: 10, y: 0)): .custom(.uzbekInput("х").withUzbekLongPress("ҳ")), // х with ҳ

                // Row 2: ф ы в а п р о л д ж э
                .gridFit(.init(x: 0, y: 1)): .custom(.uzbekInput("ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.uzbekInput("ы")),
                .gridFit(.init(x: 2, y: 1)): .custom(.uzbekInput("в")),
                .gridFit(.init(x: 3, y: 1)): .custom(.uzbekInput("а")),
                .gridFit(.init(x: 4, y: 1)): .custom(.uzbekInput("п")),
                .gridFit(.init(x: 5, y: 1)): .custom(.uzbekInput("р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.uzbekInput("о")),
                .gridFit(.init(x: 7, y: 1)): .custom(.uzbekInput("л")),
                .gridFit(.init(x: 8, y: 1)): .custom(.uzbekInput("д")),
                .gridFit(.init(x: 9, y: 1)): .custom(.uzbekInput("ж")),
                .gridFit(.init(x: 10, y: 1)): .custom(.uzbekInput("э")),

                // Row 3: Shift я ч с м и т ь б ю Del
                .gridFit(.init(x: 0, y: 2)): .custom(.uzbekShiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.uzbekInput("я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.uzbekInput("ч")),
                .gridFit(.init(x: 3, y: 2)): .custom(.uzbekInput("с")),
                .gridFit(.init(x: 4, y: 2)): .custom(.uzbekInput("м")),
                .gridFit(.init(x: 5, y: 2)): .custom(.uzbekInput("и")),
                .gridFit(.init(x: 6, y: 2)): .custom(.uzbekInput("т")),
                .gridFit(.init(x: 7, y: 2)): .custom(.uzbekInputWithVariation("ь", variation: "ъ")),
                .gridFit(.init(x: 8, y: 2)): .custom(.uzbekInput("б")),
                .gridFit(.init(x: 9, y: 2)): .custom(.uzbekInput("ю")),
                .gridFit(.init(x: 10, y: 2)): .custom(.uzbekFlickDelete()),

                // Row 4: ☆123 Globe Space ー Enter
                .gridFit(.init(x: 0, y: 3)): .custom(.uzbekSymbolsTabKey()),
                .gridFit(.init(x: 1, y: 3)): .system(.changeKeyboard),
                .gridFit(.init(x: 2, y: 3, width: 6, height: 1)): .custom(.uzbekFlickSpace()),
                .gridFit(.init(x: 8, y: 3)): .custom(.uzbekInput("ー")),
                .gridFit(.init(x: 9, y: 3, width: 2, height: 1)): .system(.enter),
            ]
        )
    )
}

private extension CustardInterfaceCustomKey {
    static func uzbekInput(_ char: String) -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text(char), color: .normal),
            press_actions: [.input(char)],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func uzbekInputWithVariation(_ char: String, variation: String) -> CustardInterfaceCustomKey {
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

    func withUzbekLongPress(_ char: String) -> CustardInterfaceCustomKey {
        var copy = self
        copy.longpress_actions.start = [.input(char)]
        return copy
    }

    static func uzbekShiftKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .systemImage("shift"), color: .special),
            press_actions: [.toggleCapsLockState],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func uzbekSymbolsTabKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("☆123"), color: .special),
            press_actions: [.moveTab(.system(.flick_numbersymbols))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []),
            variations: []
        )
    }

    static func uzbekFlickDelete() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .systemImage("delete.left"), color: .special),
            press_actions: [.delete(1)],
            longpress_actions: .init(start: [], repeat: [.delete(1)]),
            variations: [
                CustardInterfaceVariation(
                    type: .flickVariation(.left),
                    key: CustardInterfaceVariationKey(
                        design: CustardVariationKeyDesign(label: .systemImage("delete.left.fill")),
                        press_actions: [.smartDeleteDefault],
                        longpress_actions: .none
                    )
                )
            ]
        )
    }

    static func uzbekFlickSpace() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("空白"), color: .special),
            press_actions: [.input(" ")],
            longpress_actions: .init(start: [.toggleCursorBar], repeat: []),
            variations: [
                CustardInterfaceVariation(
                    type: .flickVariation(.left),
                    key: CustardInterfaceVariationKey(
                        design: CustardVariationKeyDesign(label: .text("←")),
                        press_actions: [.moveCursor(-1)],
                        longpress_actions: .none
                    )
                ),
                CustardInterfaceVariation(
                    type: .flickVariation(.top),
                    key: CustardInterfaceVariationKey(
                        design: CustardVariationKeyDesign(label: .text("全角")),
                        press_actions: [.input("　")],
                        longpress_actions: .none
                    )
                ),
                CustardInterfaceVariation(
                    type: .flickVariation(.right),
                    key: CustardInterfaceVariationKey(
                        design: CustardVariationKeyDesign(label: .text("→")),
                        press_actions: [.moveCursor(1)],
                        longpress_actions: .none
                    )
                )
            ]
        )
    }
}
