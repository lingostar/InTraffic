// Venue.swift
// InTraffic

import Foundation
import MapKit

class Venue: IMDFFeature<Venue.Properties> {
    struct Properties: Codable {
        let category: String
        let name: LocalizedName?
        let hours: String?
        let phone: String?
        let website: String?
    }

    /// ordinal → [Level] 맵 (로드 후 채워짐)
    var levelsByOrdinal: [Int: [Level]] = [:]
}
