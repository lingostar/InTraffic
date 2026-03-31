// Opening.swift
// InTraffic

import Foundation

class Opening: IMDFFeature<Opening.Properties> {
    struct Properties: Codable {
        let category: String
        let levelId: UUID
    }
}
