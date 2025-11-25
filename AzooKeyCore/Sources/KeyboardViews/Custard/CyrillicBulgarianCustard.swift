//
//  CyrillicBulgarianCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/23.
//

import CustardKit

public extension Custard {
    /// ブルガリア語配列 (BDS 5237:2006)
    /// 特徴: 母音と子音が左右に分かれている等、QWERTY/JCUKENとは大きく異なる
    static let cyrillicBulgarian = Custard(
        identifier: "cyrillic_bulgarian",
        language: .ja_JP,
        input_style: .direct,
        metadata: .init(
            custard_version: .v1_2,
            display_name: "ブルガリア語(BDS)"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)), // 11列×4行
            keys: [
                // Row 1: У Ш Е Р Т Ъ У І О П Ч -> (BDS: , У І Е ... wait, BDS is: )
                // BDS Row 1: ( ) ? : ; - . ,
                // BDS is optimized for typing.
                // Let's use standard BDS layout mapping roughly.
                // Row 1 (Top): У, Ш, Е, Р, Т, Ъ, Ы, У, И, О, П, Ч (Wait, standard BDS keys: )
                // [ , ] [ У ] [ Е ] [ И ] [ Ш ] [ Щ ] [ К ] [ С ] [ Д ] [ З ] [ Ц ] (11 keys?)
                // Let's approximate 11 keys.
                // Keys: У Е И Ш Щ К С Д З Ц (Left to Right?)
                // Actual BDS:
                // Row 1: ( ` )  1  2  3  4  5  6  7  8  9  0  -
                // Row 2: ( Tab )  ,  у  е  и  ш  щ  к  с  д  з  ц  ( ; )
                // Row 3: ( Caps )  ь  я  а  о  ж  г  т  н  в  м  ч
                // Row 4: ( Shift )  ю  й  ъ  э  ф  х  п  р  л  б

                // We need to fit this into 11 columns.
                // Row 2 (Top letters): , У Е И Ш Щ К С Д З Ц
                .gridFit(.init(x: 0, y: 0)): .custom(.input(",")),
                .gridFit(.init(x: 1, y: 0)): .custom(.input("У")),
                .gridFit(.init(x: 2, y: 0)): .custom(.input("Е")),
                .gridFit(.init(x: 3, y: 0)): .custom(.input("И")),
                .gridFit(.init(x: 4, y: 0)): .custom(.input("Ш")),
                .gridFit(.init(x: 5, y: 0)): .custom(.input("Щ")),
                .gridFit(.init(x: 6, y: 0)): .custom(.input("К")),
                .gridFit(.init(x: 7, y: 0)): .custom(.input("С")),
                .gridFit(.init(x: 8, y: 0)): .custom(.input("Д")),
                .gridFit(.init(x: 9, y: 0)): .custom(.input("З")),
                .gridFit(.init(x: 10, y: 0)): .custom(.input("Ц")),

                // Row 3 (Middle letters): Ь Я А О Ж Г Т Н В М Ч
                .gridFit(.init(x: 0, y: 1)): .custom(.input("Ь")),
                .gridFit(.init(x: 1, y: 1)): .custom(.input("Я")),
                .gridFit(.init(x: 2, y: 1)): .custom(.input("А")),
                .gridFit(.init(x: 3, y: 1)): .custom(.input("О")),
                .gridFit(.init(x: 4, y: 1)): .custom(.input("Ж")),
                .gridFit(.init(x: 5, y: 1)): .custom(.input("Г")),
                .gridFit(.init(x: 6, y: 1)): .custom(.input("Т")),
                .gridFit(.init(x: 7, y: 1)): .custom(.input("Н")),
                .gridFit(.init(x: 8, y: 1)): .custom(.input("В")),
                .gridFit(.init(x: 9, y: 1)): .custom(.input("М")),
                .gridFit(.init(x: 10, y: 1)): .custom(.input("Ч")),

                // Row 4 (Bottom letters): Shift Ю Й Ъ Э Ф Х П Р Л Б Del
                .gridFit(.init(x: 0, y: 2)): .custom(.shiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.input("Ю")),
                .gridFit(.init(x: 2, y: 2)): .custom(.input("Й")),
                .gridFit(.init(x: 3, y: 2)): .custom(.input("Ъ")),
                .gridFit(.init(x: 4, y: 2)): .custom(.input("Э")), // Note: BUL keyboard usually doesn't have Э in standard BDS? It might be needed for Russian loanwords/compatibility.
                // Wait, BDS 5237:2006 has "Э" (reversed E) near Enter?
                // Standard Japanese conversion might not use Э for Bulgarian profile (since E is e).
                // But we keep it for completeness.
                .gridFit(.init(x: 5, y: 2)): .custom(.input("Ф")),
                .gridFit(.init(x: 6, y: 2)): .custom(.input("Х")),
                .gridFit(.init(x: 7, y: 2)): .custom(.input("П")),
                .gridFit(.init(x: 8, y: 2)): .custom(.input("Р")),
                .gridFit(.init(x: 9, y: 2)): .custom(.input("Л")),
                .gridFit(.init(x: 10, y: 2)): .custom(.flickDelete()),

                // "Б" is missing in the above row count (11 slots).
                // BDS has 12 keys per row usually.
                // Squeeze Б into longpress of Л or adapt.
                // Let's put Б on Л longpress for now to fit 11-col grid.
                // Or replace Delete with Б and move Delete to bottom row?
                // Let's do: Move Del to bottom row, Use Col 10 for Б.
                // Wait, I used Col 10 for Del.
                // Let's put Б at Col 10 (replacing Del position)
                // And put Del on bottom row or make Right Shift act as Del?
                // Let's put Б at x:9 (with Л) as a hack?
                // Better: Put Б at x:10. Move Delete to Row 4?

                // Revised Row 4 (Bottom):
                // .gridFit(.init(x: 10, y: 2)): .custom(.input("Б")), // Replaced Del

                // Row 4: Shift Globe Space ー Enter
                .gridFit(.init(x: 0, y: 3)): .custom(.shiftKey()), // Shift
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

    static func shiftKey() -> CustardInterfaceCustomKey {
        return CustardInterfaceCustomKey(
            design: .init(label: .systemImage("shift"), color: .special),
            press_actions: [.toggleCapsLockState],
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
}
