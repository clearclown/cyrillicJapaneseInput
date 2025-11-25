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
        }
    }
}
