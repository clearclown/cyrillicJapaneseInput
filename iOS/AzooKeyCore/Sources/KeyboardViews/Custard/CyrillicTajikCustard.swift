//
//  CyrillicTajikCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/28.
//

import CustardKit

public extension Custard {
    /// タジク語配列 (Tajik Cyrillic with Ғ, Ӣ, Қ, Ӯ, Ҳ, Ҷ)
    /// 特徴: ロシア語ベース + タジク固有文字
    static let cyrillicTajik = Custard(
        identifier: "cyrillic_tajik",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "タジク語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: й ц у к е н г ш щ з х
                .gridFit(.init(x: 0, y: 0)): .custom(.tajikInput("й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.tajikInput("ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.tajikInput("у").withTajikLongPress("ӯ")), // у with ӯ
                .gridFit(.init(x: 3, y: 0)): .custom(.tajikInput("к").withTajikLongPress("қ")), // к with қ
                .gridFit(.init(x: 4, y: 0)): .custom(.tajikInputWithVariation("ё", variation: "е")),
                .gridFit(.init(x: 5, y: 0)): .custom(.tajikInput("н")),
                .gridFit(.init(x: 6, y: 0)): .custom(.tajikInput("г").withTajikLongPress("ғ")), // г with ғ
                .gridFit(.init(x: 7, y: 0)): .custom(.tajikInput("ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.tajikInput("щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.tajikInput("з")),
                .gridFit(.init(x: 10, y: 0)): .custom(.tajikInput("х").withTajikLongPress("ҳ")), // х with ҳ

                // Row 2: ф ы в а п р о л д ж э
                .gridFit(.init(x: 0, y: 1)): .custom(.tajikInput("ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.tajikInput("ы")),
                .gridFit(.init(x: 2, y: 1)): .custom(.tajikInput("в")),
                .gridFit(.init(x: 3, y: 1)): .custom(.tajikInput("а")),
                .gridFit(.init(x: 4, y: 1)): .custom(.tajikInput("п")),
                .gridFit(.init(x: 5, y: 1)): .custom(.tajikInput("р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.tajikInput("о")),
                .gridFit(.init(x: 7, y: 1)): .custom(.tajikInput("л")),
                .gridFit(.init(x: 8, y: 1)): .custom(.tajikInput("д")),
                .gridFit(.init(x: 9, y: 1)): .custom(.tajikInput("ж").withTajikLongPress("ҷ")), // ж with ҷ
                .gridFit(.init(x: 10, y: 1)): .custom(.tajikInput("э")),

                // Row 3: Shift я ч с м и т ь б ю Del
                .gridFit(.init(x: 0, y: 2)): .custom(.tajikShiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.tajikInput("я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.tajikInput("ч")),
                .gridFit(.init(x: 3, y: 2)): .custom(.tajikInput("с")),
                .gridFit(.init(x: 4, y: 2)): .custom(.tajikInput("м")),
                .gridFit(.init(x: 5, y: 2)): .custom(.tajikInput("и").withTajikLongPress("ӣ")), // и with ӣ
                .gridFit(.init(x: 6, y: 2)): .custom(.tajikInput("т")),
                .gridFit(.init(x: 7, y: 2)): .custom(.tajikInputWithVariation("ь", variation: "ъ")),
                .gridFit(.init(x: 8, y: 2)): .custom(.tajikInput("б")),
                .gridFit(.init(x: 9, y: 2)): .custom(.tajikInput("ю")),
                .gridFit(.init(x: 10, y: 2)): .custom(.tajikFlickDelete()),

                // Row 4: ☆123 Globe Space ー Enter
                .gridFit(.init(x: 0, y: 3)): .custom(.tajikSymbolsTabKey()),
                .gridFit(.init(x: 1, y: 3)): .system(.changeKeyboard),
                .gridFit(.init(x: 2, y: 3, width: 6, height: 1)): .custom(.tajikFlickSpace()),
                .gridFit(.init(x: 8, y: 3)): .custom(.tajikInput("ー")),
                .gridFit(.init(x: 9, y: 3, width: 2, height: 1)): .system(.enter),
            ]
        )
    )
}

private extension CustardInterfaceCustomKey {
    static func tajikInput(_ char: String) -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text(char), color: .normal),
            press_actions: [.input(char)],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func tajikInputWithVariation(_ char: String, variation: String) -> CustardInterfaceCustomKey {
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

    func withTajikLongPress(_ char: String) -> CustardInterfaceCustomKey {
        var copy = self
        copy.longpress_actions.start = [.input(char)]
        return copy
    }

    static func tajikShiftKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .systemImage("shift"), color: .special),
            press_actions: [.toggleCapsLockState],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func tajikSymbolsTabKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("☆123"), color: .special),
            press_actions: [.moveTab(.system(.flick_numbersymbols))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []),
            variations: []
        )
    }

    static func tajikFlickDelete() -> CustardInterfaceCustomKey {
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

    static func tajikFlickSpace() -> CustardInterfaceCustomKey {
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
