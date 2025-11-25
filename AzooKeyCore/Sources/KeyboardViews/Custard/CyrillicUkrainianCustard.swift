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

                .gridFit(.init(x: 0, y: 0)): .custom(.input("Й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.input("Ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.input("У")),
                .gridFit(.init(x: 3, y: 0)): .custom(.input("К")),
                .gridFit(.init(x: 4, y: 0)): .custom(.input("Е")),
                .gridFit(.init(x: 5, y: 0)): .custom(.input("Н")),
                .gridFit(.init(x: 6, y: 0)): .custom(.input("Г").withLongPress("Ґ")), // Г with Ґ
                .gridFit(.init(x: 7, y: 0)): .custom(.input("Ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.input("Щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.input("З")),
                .gridFit(.init(x: 10, y: 0)): .custom(.input("Х")),

                // Row 2: Ф І В А П Р О Л Д Ж Є
                // RUS: Ф Ы В А П Р О Л Д Ж Э
                // UKR replaces Ы with І, and Э with Є.
                .gridFit(.init(x: 0, y: 1)): .custom(.input("Ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.input("І")), // І instead of Ы
                .gridFit(.init(x: 2, y: 1)): .custom(.input("В")),
                .gridFit(.init(x: 3, y: 1)): .custom(.input("А")),
                .gridFit(.init(x: 4, y: 1)): .custom(.input("П")),
                .gridFit(.init(x: 5, y: 1)): .custom(.input("Р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.input("О")),
                .gridFit(.init(x: 7, y: 1)): .custom(.input("Л")),
                .gridFit(.init(x: 8, y: 1)): .custom(.input("Д")),
                .gridFit(.init(x: 9, y: 1)): .custom(.input("Ж")),
                .gridFit(.init(x: 10, y: 1)): .custom(.input("Є")), // Є instead of Э

                // Row 3: Shift Я Ч С М И Т Ь Б Ю Del
                // UKR: Shift Я Ч С М И Т Ь Б Ю .
                // UKR "И" corresponds to RUS "Ы" sound-wise but key position is same as RUS "И".
                // Wait, Standard UKR: ... М И Т Ь Б Ю .
                // RUS: ... М И Т Ь Б Ю .
                // Positions are mostly same.
                // Where is Ї? Usually right of Х (Row 1).
                // Since we only have 11 cols, let's put Ї on longpress of І or somewhere?
                // Better: Put Ї on Row 1 Col 10 (replace X? No).
                // Let's put Ї as a variation of І or separate key if we expand layout.
                // For now: Longpress of І -> Ї.

                .gridFit(.init(x: 0, y: 2)): .custom(.shiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.input("Я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.input("Ч")),
                .gridFit(.init(x: 3, y: 2)): .custom(.input("С")),
                .gridFit(.init(x: 4, y: 2)): .custom(.input("М")),
                .gridFit(.init(x: 5, y: 2)): .custom(.input("И").withLongPress("Ї")), // И, Ї on longpress for access
                .gridFit(.init(x: 6, y: 2)): .custom(.input("Т")),
                .gridFit(.init(x: 7, y: 2)): .custom(.input("Ь")),
                .gridFit(.init(x: 8, y: 2)): .custom(.input("Б")),
                .gridFit(.init(x: 9, y: 2)): .custom(.input("Ю")),
                .gridFit(.init(x: 10, y: 2)): .custom(.flickDelete()),

                // Row 4: ☆123 Globe Space ー Enter
                .gridFit(.init(x: 0, y: 3)): .custom(.symbolsTabKey()), // Numbers/Symbols
                .gridFit(.init(x: 1, y: 3)): .system(.changeKeyboard), // Globe
                .gridFit(.init(x: 2, y: 3, width: 6, height: 1)): .custom(.flickSpace()), // Space (wider)
                .gridFit(.init(x: 8, y: 3)): .custom(.input("ー")), // 長音符 (伸ばし棒)
                .gridFit(.init(x: 9, y: 3, width: 2, height: 1)): .custom(.enterKey()), // Enter
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
            press_actions: [.replaceDefault(.default)],
            longpress_actions: .init(start: [], repeat: []),
            variations: []
        )
    }

    static func enterKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .systemImage("return"), color: .special),
            press_actions: [.complete],
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
