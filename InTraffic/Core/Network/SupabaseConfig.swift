// SupabaseConfig.swift
// InTraffic
//
// ⚠️  실제 배포 전 아래 값을 Supabase 프로젝트 설정에서 교체하세요.
//     URL / anon key 는 public 정보이므로 git에 올려도 안전합니다.
//     service_role key 는 절대 클라이언트에 포함하지 마세요.

import Foundation

enum SupabaseConfig {
    // TODO: Supabase 프로젝트 생성 후 교체
    static let projectURL = URL(string: "https://YOUR_PROJECT_ID.supabase.co")!
    static let anonKey    = "YOUR_ANON_KEY"

    // MARK: - Endpoint URLs

    static var eventsURL: URL {
        projectURL.appendingPathComponent("rest/v1/density_events")
    }

    static var zoneDensityURL: URL {
        projectURL.appendingPathComponent("rest/v1/zone_density")
    }

    static var hourlyDensityURL: URL {
        projectURL.appendingPathComponent("rest/v1/hourly_density")
    }

    // MARK: - 공통 헤더

    static var commonHeaders: [String: String] {
        [
            "apikey":        anonKey,
            "Authorization": "Bearer \(anonKey)",
            "Content-Type":  "application/json",
            "Prefer":        "return=minimal"
        ]
    }
}
