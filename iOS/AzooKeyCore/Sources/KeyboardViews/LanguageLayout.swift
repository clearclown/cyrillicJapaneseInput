//
//  LanguageLayout.swift
//
//
//  Created by ensan on 2023/07/23.
//

import Foundation

public enum LanguageLayout: Codable, Hashable, Sendable {
    case flick
    case qwerty
    case custard(String)
    case cyrillicStandard
    case cyrillicUkrainian
    case cyrillicBulgarian
    case cyrillicSerbian
    case cyrillicBelarusian
    case cyrillicMacedonian
    case cyrillicKazakh
    case cyrillicKyrgyz
    case cyrillicMongolian
    case cyrillicTajik
    case cyrillicUzbek
}

public extension LanguageLayout {
    private enum CodingKeys: CodingKey {
        case flick
        case qwerty
        case custard
        case cyrillicStandard
        case cyrillicUkrainian
        case cyrillicBulgarian
        case cyrillicSerbian
        case cyrillicBelarusian
        case cyrillicMacedonian
        case cyrillicKazakh
        case cyrillicKyrgyz
        case cyrillicMongolian
        case cyrillicTajik
        case cyrillicUzbek
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .flick:
            try container.encode(true, forKey: .flick)
        case .qwerty:
            try container.encode(true, forKey: .qwerty)
        case let .custard(value):
            try container.encode(value, forKey: .custard)
        case .cyrillicStandard:
            try container.encode(true, forKey: .cyrillicStandard)
        case .cyrillicUkrainian:
            try container.encode(true, forKey: .cyrillicUkrainian)
        case .cyrillicBulgarian:
            try container.encode(true, forKey: .cyrillicBulgarian)
        case .cyrillicSerbian:
            try container.encode(true, forKey: .cyrillicSerbian)
        case .cyrillicBelarusian:
            try container.encode(true, forKey: .cyrillicBelarusian)
        case .cyrillicMacedonian:
            try container.encode(true, forKey: .cyrillicMacedonian)
        case .cyrillicKazakh:
            try container.encode(true, forKey: .cyrillicKazakh)
        case .cyrillicKyrgyz:
            try container.encode(true, forKey: .cyrillicKyrgyz)
        case .cyrillicMongolian:
            try container.encode(true, forKey: .cyrillicMongolian)
        case .cyrillicTajik:
            try container.encode(true, forKey: .cyrillicTajik)
        case .cyrillicUzbek:
            try container.encode(true, forKey: .cyrillicUzbek)
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let key = container.allKeys.first else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unabled to decode LanguageLayout."
                )
            )
        }
        switch key {
        case .flick:
            self = .flick
        case .qwerty:
            self = .qwerty
        case .custard:
            let value = try container.decode(
                String.self,
                forKey: .custard
            )
            self = .custard(value)
        case .cyrillicStandard:
            self = .cyrillicStandard
        case .cyrillicUkrainian:
            self = .cyrillicUkrainian
        case .cyrillicBulgarian:
            self = .cyrillicBulgarian
        case .cyrillicSerbian:
            self = .cyrillicSerbian
        case .cyrillicBelarusian:
            self = .cyrillicBelarusian
        case .cyrillicMacedonian:
            self = .cyrillicMacedonian
        case .cyrillicKazakh:
            self = .cyrillicKazakh
        case .cyrillicKyrgyz:
            self = .cyrillicKyrgyz
        case .cyrillicMongolian:
            self = .cyrillicMongolian
        case .cyrillicTajik:
            self = .cyrillicTajik
        case .cyrillicUzbek:
            self = .cyrillicUzbek
        }
    }
}
