// Level.swift
// InTraffic

import Foundation

class Level: IMDFFeature<Level.Properties> {
    struct Properties: Codable {
        let ordinal: Int
        let category: String
        let shortName: LocalizedName?
        let outdoor: Bool
        let buildingIds: [String]?
    }

    var units: [Unit]    = []
    var openings: [Opening] = []

    /// 층 표시용 레이블 (예: "5층", "L5")
    var displayName: String {
        properties.shortName?.bestLocalizedValue
            ?? "\(properties.ordinal + 1)층"
    }
}
