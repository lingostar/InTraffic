// ZoneDensity.swift
// InTraffic

import Foundation

/// 서버에서 수신하는 Zone별 혼잡도 집계 데이터
struct ZoneDensity: Codable, Identifiable, Sendable {
    let zoneId: String
    let floorOrdinal: Int
    let currentCount: Int
    let updatedAt: Date

    var id: String { zoneId }

    var densityLevel: DensityLevel {
        DensityLevel.from(count: currentCount)
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case zoneId       = "zone_id"
        case floorOrdinal = "floor_ordinal"
        case currentCount = "current_count"
        case updatedAt    = "updated_at"
    }
}

/// 서버 GET /zone-density 응답 래퍼
struct ZoneDensityResponse: Codable, Sendable {
    let zones: [ZoneDensity]
}

/// 시간대별 집계 데이터 (통계 탭용)
struct HourlyDensity: Codable, Identifiable, Sendable {
    let hour: Int       // 0~23
    let count: Int

    var id: Int { hour }

    enum CodingKeys: String, CodingKey {
        case hour
        case count
    }
}
