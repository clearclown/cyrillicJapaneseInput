//
//  CyrillicSerbianCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/23.
//

import CustardKit

public extension Custard {
    /// セルビア語配列 (LJNJERTZ / QWERTZ-based Cyrillic)
    static let cyrillicSerbian = Custard(
        identifier: "cyrillic_serbian",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "セルビア語"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)),
            keys: [
                // Row 1: љ њ е р т з у и о п ш (小文字デフォルト)
                .gridFit(.init(x: 0, y: 0)): .custom(.input("љ")),
                .gridFit(.init(x: 1, y: 0)): .custom(.input("њ")),
                .gridFit(.init(x: 2, y: 0)): .custom(.input("е")),
                .gridFit(.init(x: 3, y: 0)): .custom(.input("р")),
                .gridFit(.init(x: 4, y: 0)): .custom(.input("т")),
                .gridFit(.init(x: 5, y: 0)): .custom(.input("з")),
                .gridFit(.init(x: 6, y: 0)): .custom(.input("у")),
                .gridFit(.init(x: 7, y: 0)): .custom(.input("и")),
                .gridFit(.init(x: 8, y: 0)): .custom(.input("о")),
                .gridFit(.init(x: 9, y: 0)): .custom(.input("п")),
                .gridFit(.init(x: 10, y: 0)): .custom(.input("ш")),

                // Row 2: а с д ф г х ј к л ч ћ (小文字デフォルト)
                .gridFit(.init(x: 0, y: 1)): .custom(.input("а")),
                .gridFit(.init(x: 1, y: 1)): .custom(.input("с")),
                .gridFit(.init(x: 2, y: 1)): .custom(.input("д")),
                .gridFit(.init(x: 3, y: 1)): .custom(.input("ф")),
                .gridFit(.init(x: 4, y: 1)): .custom(.input("г")),
                .gridFit(.init(x: 5, y: 1)): .custom(.input("х")),
                .gridFit(.init(x: 6, y: 1)): .custom(.input("ј")),
                .gridFit(.init(x: 7, y: 1)): .custom(.input("к")),
                .gridFit(.init(x: 8, y: 1)): .custom(.input("л")),
                .gridFit(.init(x: 9, y: 1)): .custom(.input("ч")),
                .gridFit(.init(x: 10, y: 1)): .custom(.input("ћ")),

                // Row 3: Shift џ ц в б н м đ ж , Del (小文字デフォルト)
                .gridFit(.init(x: 0, y: 2)): .custom(.shiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.input("џ")),
                .gridFit(.init(x: 2, y: 2)): .custom(.input("ц")),
                .gridFit(.init(x: 3, y: 2)): .custom(.input("в")),
                .gridFit(.init(x: 4, y: 2)): .custom(.input("б")),
                .gridFit(.init(x: 5, y: 2)): .custom(.input("н")),
                .gridFit(.init(x: 6, y: 2)): .custom(.input("м")),
                .gridFit(.init(x: 7, y: 2)): .custom(.input("đ")), // đ (Dje)
                .gridFit(.init(x: 8, y: 2)): .custom(.input("ж")), // ж (Zhe)
                .gridFit(.init(x: 9, y: 2)): .custom(.input(",")),
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
