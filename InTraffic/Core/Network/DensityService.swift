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
        decoder.keyDecodingStrategy  = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

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
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([HourlyDensity].self, from: data)
    }

    // MARK: - Private

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
