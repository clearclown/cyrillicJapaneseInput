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
                // Row 1: Љ Њ Е Р Т З У И О П Ш
                // (Standard Serbian: Љ Њ Е Р Т З У И О П Ш Đ)
                // 11 keys: Љ Њ Е Р Т З У И О П Ш
                .gridFit(.init(x: 0, y: 0)): .custom(.input("Љ")),
                .gridFit(.init(x: 1, y: 0)): .custom(.input("Њ")),
                .gridFit(.init(x: 2, y: 0)): .custom(.input("Е")),
                .gridFit(.init(x: 3, y: 0)): .custom(.input("Р")),
                .gridFit(.init(x: 4, y: 0)): .custom(.input("Т")),
                .gridFit(.init(x: 5, y: 0)): .custom(.input("З")),
                .gridFit(.init(x: 6, y: 0)): .custom(.input("У")),
                .gridFit(.init(x: 7, y: 0)): .custom(.input("И")),
                .gridFit(.init(x: 8, y: 0)): .custom(.input("О")),
                .gridFit(.init(x: 9, y: 0)): .custom(.input("П")),
                .gridFit(.init(x: 10, y: 0)): .custom(.input("Ш")),

                // Row 2: А С Д Ф Г Х Ј К Л Ч Ћ
                // (Standard: А С Д Ф Г Х Ј К Л Ч Ћ Ž)
                // 11 keys: А С Д Ф Г Х Ј К Л Ч Ћ
                .gridFit(.init(x: 0, y: 1)): .custom(.input("А")),
                .gridFit(.init(x: 1, y: 1)): .custom(.input("С")),
                .gridFit(.init(x: 2, y: 1)): .custom(.input("Д")),
                .gridFit(.init(x: 3, y: 1)): .custom(.input("Ф")),
                .gridFit(.init(x: 4, y: 1)): .custom(.input("Г")),
                .gridFit(.init(x: 5, y: 1)): .custom(.input("Х")),
                .gridFit(.init(x: 6, y: 1)): .custom(.input("Ј")),
                .gridFit(.init(x: 7, y: 1)): .custom(.input("К")),
                .gridFit(.init(x: 8, y: 1)): .custom(.input("Л")),
                .gridFit(.init(x: 9, y: 1)): .custom(.input("Ч")),
                .gridFit(.init(x: 10, y: 1)): .custom(.input("Ћ")),

                // Row 3: Shift Џ Ц В Б Н М , . Del
                // (Standard: Z X C V B N M ...)
                // Serbian is QWERTZ based.
                // Row 3: (Shift) < Z > Џ Ц В Б Н М ( ... )
                // Wait, Serbian QWERTZ has Z on top row (checked).
                // Bottom row starts with < > ? No, standard letters:
                // Џ, Ц, В, Б, Н, М, Đ, Ж?
                // Let's fit remaining chars: Џ, Ц, В, Б, Н, М, Đ, Ж.
                // 8 chars.

                .gridFit(.init(x: 0, y: 2)): .system(.upperLower),
                .gridFit(.init(x: 1, y: 2)): .custom(.input("Џ")),
                .gridFit(.init(x: 2, y: 2)): .custom(.input("Ц")),
                .gridFit(.init(x: 3, y: 2)): .custom(.input("В")),
                .gridFit(.init(x: 4, y: 2)): .custom(.input("Б")),
                .gridFit(.init(x: 5, y: 2)): .custom(.input("Н")),
                .gridFit(.init(x: 6, y: 2)): .custom(.input("М")),
                .gridFit(.init(x: 7, y: 2)): .custom(.input("Đ")), // Đ (Dje)
                .gridFit(.init(x: 8, y: 2)): .custom(.input("Ж")), // Ž (Zhe)
                .gridFit(.init(x: 9, y: 2)): .custom(.input(",")),
                .gridFit(.init(x: 10, y: 2)): .custom(.flickDelete()),

                // Row 4
                .gridFit(.init(x: 0, y: 3, width: 2, height: 1)): .custom(.numberTab()),
                .gridFit(.init(x: 2, y: 3)): .system(.changeKeyboard),
                .gridFit(.init(x: 3, y: 3, width: 5, height: 1)): .custom(.flickSpace()),
                .gridFit(.init(x: 8, y: 3)): .custom(.input("-")),
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

    /// QWERTY style number keyboard tab key
    static func numberTab() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .text("123"), color: .special),
            press_actions: [.moveTab(.system(.qwerty_numbers))],
            longpress_actions: .init(start: [.toggleTabBar], repeat: []),
            variations: []
        )
    }
}
