//
//  CustardManagerProtocol.swift
//  Keyboard
//
//  Created by ensan on 2021/02/21.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import CustardKit

public protocol CustardManagerProtocol {
    func custard(identifier: String) throws -> Custard
    func userCustard(identifier: String) throws -> UserMadeCustard
    func tabbar(identifier: Int) throws -> TabBarData
}

public extension CustardManagerProtocol {
    func custard(identifier: String) throws -> Custard {
        switch identifier {
        case "english_flick":
            return .flickEnglish
        case "japanese_flick":
            return .flickJapanese
        case "japanese_flick_number_symbols":
            return .flickNumberSymbols
        case "tenkey_number":
            return .numberPad
        case "cyrillic_standard":
            return .cyrillicStandard
        case "cyrillic_ukrainian":
            return .cyrillicUkrainian
        case "cyrillic_bulgarian":
            return .cyrillicBulgarian
        case "cyrillic_serbian":
            return .cyrillicSerbian
        default:
            // User-made custards should be loaded from storage by the CustardManager implementation
            throw CustardManagerError.identifierNotFound(identifier)
        }
    }
}

enum CustardManagerError: Error {
    case identifierNotFound(String)
}
