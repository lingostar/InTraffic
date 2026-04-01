// DensityService.swift
// InTraffic
//
// Supabase에서 Zone별 혼잡도 데이터를 가져오는 서비스
// GET /rest/v1/zone_density
// GET /rest/v1/hourly_density

import Foundation

final class DensityService: Sendable {

    // MARK: - 현재 Zone 혼잡도 조회

    func fetchCurrentDensity() async throws -> [ZoneDensity] {
        var components    = URLComponents(url: SupabaseConfig.zoneDensityURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "select", value: "zone_id,floor_ordinal,current_count,updated_at"),
            URLQueryItem(name: "order",  value: "floor_ordinal.asc")
        ]

        var request = URLRequest(url: components.url!)
        SupabaseConfig.commonHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)

        let decoder = JSONDecoder()
        // CodingKeys가 snake_case 매핑을 이미 처리하므로 .convertFromSnakeCase 사용하지 않음
        decoder.dateDecodingStrategy = .custom(Self.supabaseDateDecoder)

        return try decoder.decode([ZoneDensity].self, from: data)
    }

    // MARK: - 오늘 시간대별 집계 조회

    func fetchHourlyDensity(date: Date = .now) async throws -> [HourlyDensity] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        var components = URLComponents(url: SupabaseConfig.hourlyDensityURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "select", value: "hour,count"),
            URLQueryItem(name: "date",   value: "eq.\(dateString)"),
            URLQueryItem(name: "order",  value: "hour.asc")
        ]

        var request = URLRequest(url: components.url!)
        SupabaseConfig.commonHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)

        let decoder = JSONDecoder()
        return try decoder.decode([HourlyDensity].self, from: data)
    }

    // MARK: - Private

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// Supabase TIMESTAMPTZ 파싱 (마이크로초 포함 ISO 8601 대응)
    private static func supabaseDateDecoder(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let string    = try container.decode(String.self)

        // ISO 8601 with fractional seconds
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }

        // Fallback: without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) { return date }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Cannot parse date: \(string)"
        )
    }
}
