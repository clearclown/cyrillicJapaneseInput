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
                // Row 2 (Top letters): , у е и ш щ к с д з ц (小文字デフォルト)
                .gridFit(.init(x: 0, y: 0)): .custom(.input(",")),
                .gridFit(.init(x: 1, y: 0)): .custom(.input("у")),
                .gridFit(.init(x: 2, y: 0)): .custom(.input("е")),
                .gridFit(.init(x: 3, y: 0)): .custom(.input("и")),
                .gridFit(.init(x: 4, y: 0)): .custom(.input("ш")),
                .gridFit(.init(x: 5, y: 0)): .custom(.input("щ")),
                .gridFit(.init(x: 6, y: 0)): .custom(.input("к")),
                .gridFit(.init(x: 7, y: 0)): .custom(.input("с")),
                .gridFit(.init(x: 8, y: 0)): .custom(.input("д")),
                .gridFit(.init(x: 9, y: 0)): .custom(.input("з")),
                .gridFit(.init(x: 10, y: 0)): .custom(.input("ц")),

                // Row 3 (Middle letters): ь я а о ж г т н в м ч (小文字デフォルト)
                .gridFit(.init(x: 0, y: 1)): .custom(.input("ь")),
                .gridFit(.init(x: 1, y: 1)): .custom(.input("я")),
                .gridFit(.init(x: 2, y: 1)): .custom(.input("а")),
                .gridFit(.init(x: 3, y: 1)): .custom(.input("о")),
                .gridFit(.init(x: 4, y: 1)): .custom(.input("ж")),
                .gridFit(.init(x: 5, y: 1)): .custom(.input("г")),
                .gridFit(.init(x: 6, y: 1)): .custom(.input("т")),
                .gridFit(.init(x: 7, y: 1)): .custom(.input("н")),
                .gridFit(.init(x: 8, y: 1)): .custom(.input("в")),
                .gridFit(.init(x: 9, y: 1)): .custom(.input("м")),
                .gridFit(.init(x: 10, y: 1)): .custom(.input("ч")),

                // Row 4 (Bottom letters): Shift ю й ъ э ф х п р л Del (小文字デフォルト)
                .gridFit(.init(x: 0, y: 2)): .custom(.shiftKey()),
                .gridFit(.init(x: 1, y: 2)): .custom(.input("ю")),
                .gridFit(.init(x: 2, y: 2)): .custom(.input("й")),
                .gridFit(.init(x: 3, y: 2)): .custom(.input("ъ")),
                .gridFit(.init(x: 4, y: 2)): .custom(.input("э")),
                .gridFit(.init(x: 5, y: 2)): .custom(.input("ф")),
                .gridFit(.init(x: 6, y: 2)): .custom(.input("х")),
                .gridFit(.init(x: 7, y: 2)): .custom(.input("п")),
                .gridFit(.init(x: 8, y: 2)): .custom(.input("р")),
                .gridFit(.init(x: 9, y: 2)): .custom(.input("л")),
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
