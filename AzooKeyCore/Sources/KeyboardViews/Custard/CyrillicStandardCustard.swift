//
//  CyrillicStandardCustard.swift
//  AzooKeyCore
//
//  Created by Pismo on 2025/11/23.
//

import CustardKit

public extension Custard {
    /// ロシア語（標準）JCUKEN配列
    static let cyrillicStandard = Custard(
        identifier: "cyrillic_standard",
        language: .ja_JP, // 入力結果は日本語変換されるため ja_JP (または en_US で input_style で制御)
        input_style: .direct, // InputManagerでinterceptするのでdirectでOK
        metadata: .init(
            custard_version: .v1_2,
            display_name: "ロシア語(JCUKEN)"
        ),
        interface: CustardInterface(
            keyStyle: .pcStyle,
            keyLayout: .gridFit(.init(rowCount: 11, columnCount: 4)), // 11列×4行: JCUKENキーボード配列
            keys: [
                // Row 1: Й Ц У К Е Н Г Ш Щ З Х
                .gridFit(.init(x: 0, y: 0)): .custom(.input("Й")),
                .gridFit(.init(x: 1, y: 0)): .custom(.input("Ц")),
                .gridFit(.init(x: 2, y: 0)): .custom(.input("У")),
                .gridFit(.init(x: 3, y: 0)): .custom(.input("К")),
                .gridFit(.init(x: 4, y: 0)): .custom(.input("Е")),
                .gridFit(.init(x: 5, y: 0)): .custom(.input("Н")),
                .gridFit(.init(x: 6, y: 0)): .custom(.input("Г")),
                .gridFit(.init(x: 7, y: 0)): .custom(.input("Ш")),
                .gridFit(.init(x: 8, y: 0)): .custom(.input("Щ")),
                .gridFit(.init(x: 9, y: 0)): .custom(.input("З")),
                .gridFit(.init(x: 10, y: 0)): .custom(.input("Х")),
                // .gridFit(.init(x: 11, y: 0)): .custom(.input("Ъ")), // Ъは通常最上段右端だがスペースの都合で調整が必要かも

                // Row 2: Ф Ы В А П Р О Л Д Ж Э
                .gridFit(.init(x: 0, y: 1)): .custom(.input("Ф")),
                .gridFit(.init(x: 1, y: 1)): .custom(.input("Ы")),
                .gridFit(.init(x: 2, y: 1)): .custom(.input("В")),
                .gridFit(.init(x: 3, y: 1)): .custom(.input("А")),
                .gridFit(.init(x: 4, y: 1)): .custom(.input("П")),
                .gridFit(.init(x: 5, y: 1)): .custom(.input("Р")),
                .gridFit(.init(x: 6, y: 1)): .custom(.input("О")),
                .gridFit(.init(x: 7, y: 1)): .custom(.input("Л")),
                .gridFit(.init(x: 8, y: 1)): .custom(.input("Д")),
                .gridFit(.init(x: 9, y: 1)): .custom(.input("Ж")),
                .gridFit(.init(x: 10, y: 1)): .custom(.input("Э")),

                // Row 3: Shift Я Ч С М И Т Ь Б Ю Del
                .gridFit(.init(x: 0, y: 2)): .system(.upperLower), // Shift
                .gridFit(.init(x: 1, y: 2)): .custom(.input("Я")),
                .gridFit(.init(x: 2, y: 2)): .custom(.input("Ч")),
                .gridFit(.init(x: 3, y: 2)): .custom(.input("С")),
                .gridFit(.init(x: 4, y: 2)): .custom(.input("М")),
                .gridFit(.init(x: 5, y: 2)): .custom(.input("И")),
                .gridFit(.init(x: 6, y: 2)): .custom(.input("Т")),
                .gridFit(.init(x: 7, y: 2)): .custom(.input("Ь")),
                .gridFit(.init(x: 8, y: 2)): .custom(.input("Б")),
                .gridFit(.init(x: 9, y: 2)): .custom(.input("Ю")),
                .gridFit(.init(x: 10, y: 2)): .custom(.flickDelete()), // Backspace

                // Row 4: Shift Globe Space ー Enter
                .gridFit(.init(x: 0, y: 3)): .system(.upperLower), // Shift
                .gridFit(.init(x: 1, y: 3)): .system(.changeKeyboard), // Globe
                .gridFit(.init(x: 2, y: 3, width: 6, height: 1)): .custom(.flickSpace()), // Space (wider)
                .gridFit(.init(x: 8, y: 3)): .custom(.input("ー")), // 長音符 (伸ばし棒)
                .gridFit(.init(x: 9, y: 3, width: 2, height: 1)): .system(.enter), // Enter
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

}
