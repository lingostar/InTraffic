// IMDFFeature.swift
// InTraffic
// ShowX의 Feature<T> 베이스 클래스를 InTraffic 용으로 정제

import Foundation
import MapKit

protocol IMDFDecodableFeature {
    init(feature: MKGeoJSONFeature) throws
}

enum IMDFError: Error, LocalizedError {
    case invalidType
    case invalidData
    case missingIdentifier
    case missingProperties

    var errorDescription: String? {
        switch self {
        case .invalidType:        "IMDF: 잘못된 feature 타입입니다."
        case .invalidData:        "IMDF: 데이터가 올바르지 않습니다."
        case .missingIdentifier:  "IMDF: identifier가 없습니다."
        case .missingProperties:  "IMDF: properties가 없습니다."
        }
    }
}

/// IMDF feature의 공통 베이스 클래스 (ShowX Feature<T> 동일 구조)
class IMDFFeature<Properties: Decodable>: NSObject, IMDFDecodableFeature {
    let identifier: UUID
    let properties: Properties
    let geometry: [MKShape & MKGeoJSONObject]

    required init(feature: MKGeoJSONFeature) throws {
        guard let uuidString = feature.identifier else {
            throw IMDFError.missingIdentifier
        }
        guard let id = UUID(uuidString: uuidString) else {
            throw IMDFError.invalidData
        }
        guard let propertiesData = feature.properties else {
            throw IMDFError.missingProperties
        }

        self.identifier = id
        self.geometry   = feature.geometry

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.properties = try decoder.decode(Properties.self, from: propertiesData)

        super.init()
    }
}
