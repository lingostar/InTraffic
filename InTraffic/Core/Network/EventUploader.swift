// EventUploader.swift
// InTraffic
//
// 익명 위치 이벤트를 Supabase REST API로 전송
// POST /rest/v1/density_events

import Foundation

actor EventUploader {

    // MARK: - Deduplication (5분 이내 동일 Zone 재전송 방지)
    // actor 격리로 NSLock 없이 스레드 안전

    private let deduplicationWindow: TimeInterval = 300   // 5분
    private var lastUploadByZone: [String: Date]  = [:]

    // MARK: - Public API

    func upload(_ event: DensityEvent) async {
        let now = Date()

        // 중복 전송 억제
        if let last = lastUploadByZone[event.zoneId],
           now.timeIntervalSince(last) < deduplicationWindow {
            return
        }
        lastUploadByZone[event.zoneId] = now

        do {
            var request = URLRequest(url: SupabaseConfig.eventsURL)
            request.httpMethod = "POST"
            SupabaseConfig.commonHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(event)

            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                print("[EventUploader] 전송 실패: \(response)")
                return
            }
            print("[EventUploader] ✅ 전송 완료 zone=\(event.zoneId)")
        } catch {
            print("[EventUploader] ❌ 오류: \(error.localizedDescription)")
        }
    }
}
