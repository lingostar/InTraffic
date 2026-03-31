// Anchor.swift
// InTraffic

import Foundation

class Anchor: IMDFFeature<Anchor.Properties> {
    struct Properties: Codable {
        let unitId: UUID
        let addressId: UUID?
    }
}
