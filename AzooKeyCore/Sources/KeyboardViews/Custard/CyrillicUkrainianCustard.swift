//
//  CyrillicUkrainianCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/23.
//

import CustardKit

public extension Custard {
    /// ウクライナ語配列 (Standard JCUKEN based with I, Yi, Ye, Ghe-upturn)
    static let cyrillicUkrainian = Custard(
        identifier: "cyrillic_ukrainian",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "ウクライナ語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: Й Ц У К Е Н Г Ш Щ З Х
                // UKR: Ґ is usually on separate key or AltGr-G. Here we might need to replace or add.
                // Standard UKR layout: Й Ц У К Е Н Г Ш Щ З Х Ї
                // We have 11 columns. 12th key "Ї" might need to be squeezed or placed elsewhere.
                // Let's put Ґ on Longpress of Г, and Ї on Longpress of Ъ (or separate key if space allows).
                // Wait, UKR doesn't use Ъ. It uses Ї there.

                .gridFit(.init(x: 0, y: 0)): .custom(.input("й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.input("ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.input("у")),
                .gridFit(.init(x: 3, y: 0)): .custom(.input("к")),
                .gridFit(.init(x: 4, y: 0)): .custom(.input("е")),
                .gridFit(.init(x: 5, y: 0)): .custom(.input("н")),
                .gridFit(.init(x: 6, y: 0)): .custom(.input("г").withLongPress("ґ")), // г with ґ
                .gridFit(.init(x: 7, y: 0)): .custom(.input("ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.input("щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.input("з")),
                .gridFit(.init(x: 10, y: 0)): .custom(.input("х")),

                // Row 2: ф і в а п р о л д ж є (小文字デフォルト)
                .gridFit(.init(x: 0, y: 1)): .custom(.input("ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.input("і")), // і instead of ы
                .gridFit(.init(x: 2, y: 1)): .custom(.input("в")),
                .gridFit(.init(x: 3, y: 1)): .custom(.input("а")),
                .gridFit(.init(x: 4, y: 1)): .custom(.input("п")),
                .gridFit(.init(x: 5, y: 1)): .custom(.input("р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.input("о")),
                .gridFit(.init(x: 7, y: 1)): .custom(.input("л")),
                .gridFit(.init(x: 8, y: 1)): .custom(.input("д")),
                .gridFit(.init(x: 9, y: 1)): .custom(.input("ж")),
                .gridFit(.init(x: 10, y: 1)): .custom(.input("є")), // є instead of э

                // Row 3: Shift я ч с м и т ь б ю Del (小文字デフォルト)
                .gridFit(.init(x: 0, y: 2)): .custom(.shiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.input("я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.input("ч")),
                .gridFit(.init(x: 3, y: 2)): .custom(.input("с")),
                .gridFit(.init(x: 4, y: 2)): .custom(.input("м")),
                .gridFit(.init(x: 5, y: 2)): .custom(.input("и").withLongPress("ї")), // и, ї on longpress
                .gridFit(.init(x: 6, y: 2)): .custom(.input("т")),
                .gridFit(.init(x: 7, y: 2)): .custom(.input("ь")),
                .gridFit(.init(x: 8, y: 2)): .custom(.input("б")),
                .gridFit(.init(x: 9, y: 2)): .custom(.input("ю")),
                .gridFit(.init(x: 10, y: 2)): .custom(.flickDelete()),

                // Row 4: ☆123 Globe Space ー Enter
                .gridFit(.init(x: 0, y: 3)): .custom(.symbolsTabKey()), // Numbers/Symbols
                .gridFit(.init(x: 1, y: 3)): .system(.changeKeyboard), // Globe
                .gridFit(.init(x: 2, y: 3, width: 6, height: 1)): .custom(.flickSpace()), // Space (wider)
                .gridFit(.init(x: 8, y: 3)): .custom(.input("ー")), // 長音符 (伸ばし棒)
                .gridFit(.init(x: 9, y: 3, width: 2, height: 1)): .system(.enter), // Enter (iOS標準)
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
