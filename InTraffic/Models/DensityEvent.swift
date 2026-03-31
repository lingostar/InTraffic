// DensityEvent.swift
// InTraffic

import Foundation

/// 서버로 전송하는 익명 위치 이벤트
/// 개인 식별 정보 없음 — anonymousId는 앱 최초 실행 시 기기에서 생성된 UUID
struct DensityEvent: Codable, Sendable {
    let anonymousId: String
    let zoneId: String
    let floorOrdinal: Int
    let timestamp: Date
    let appVersion: String

    init(zoneId: String, floorOrdinal: Int) {
        self.anonymousId  = AnonymousID.shared.value
        self.zoneId       = zoneId
        self.floorOrdinal = floorOrdinal
        self.timestamp    = Date()
        self.appVersion   = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    enum CodingKeys: String, CodingKey {
        case anonymousId  = "anonymous_id"
        case zoneId       = "zone_id"
        case floorOrdinal = "floor_ordinal"
        case timestamp
        case appVersion   = "app_version"
    }
}

// MARK: - Anonymous ID 관리

/// 앱 최초 실행 시 UUID를 생성하고 UserDefaults에 영속 저장
final class AnonymousID: @unchecked Sendable {
    static let shared = AnonymousID()
    private init() {}

    private let key = "com.intrafficapp.anonymousId"

    var value: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }
}
