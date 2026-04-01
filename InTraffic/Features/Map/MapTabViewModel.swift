// MapTabViewModel.swift
// InTraffic

import Foundation
import MapKit
import SwiftUI

// MARK: - HeatPoint

struct HeatPoint: Identifiable {
    let id: Int          // 안정적 ID (애니메이션용)
    let coordinate: CLLocationCoordinate2D
    let densityLevel: DensityLevel
    let radius: CLLocationDistance   // 미터
    let opacity: Double
}

// MARK: - Seeded RNG (동일 Zone → 동일 포인트 위치)

private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed))
        // warm up
        for _ in 0..<4 { _ = next() }
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class MapTabViewModel {

    // MARK: - State

    var selectedFloorIndex: Int = 0
    var zoneDensities: [String: ZoneDensity] = [:]
    var polygons: [ZonePolygon]  = []
    var heatPoints: [HeatPoint]  = []
    var lastUpdated: Date?       = nil
    var isLoading: Bool          = false
    var errorMessage: String?    = nil
    var selectedZone: (zone: ZonePolygon, density: ZoneDensity?)? = nil
    var refreshCountdown: Int    = 30

    // MARK: - Dependencies

    private let imdfStore: IMDFStore
    private let densityService: DensityService
    private let eventUploader: EventUploader
    private let locationManager: LocationManager

    private var pollingTask:   Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?

    // MARK: - Computed

    var currentOrdinal: Int {
        guard imdfStore.levels.indices.contains(selectedFloorIndex) else { return 0 }
        return imdfStore.levels[selectedFloorIndex].properties.ordinal
    }

    var currentFloorLabel: String {
        guard imdfStore.levels.indices.contains(selectedFloorIndex) else { return "-" }
        return imdfStore.levels[selectedFloorIndex].displayName
    }

    var allFloorLabels: [String] {
        imdfStore.levels.map { $0.displayName }
    }

    // MARK: - Init

    init(
        imdfStore: IMDFStore,
        densityService: DensityService,
        eventUploader: EventUploader,
        locationManager: LocationManager
    ) {
        self.imdfStore       = imdfStore
        self.densityService  = densityService
        self.eventUploader   = eventUploader
        self.locationManager = locationManager
    }

    // MARK: - Lifecycle

    func onAppear() {
        loadPolygons()
        startPolling()
        startCountdown()

        locationManager.onLocationUpdate = { [weak self] coordinate in
            Task { @MainActor [weak self] in
                self?.handleLocationUpdate(coordinate)
            }
        }
        locationManager.startForegroundUpdates()
    }

    func onDisappear() {
        stopPolling()
        locationManager.stopForegroundUpdates()
    }

    // MARK: - Floor Selection

    func selectFloor(index: Int) {
        guard imdfStore.levels.indices.contains(index) else { return }
        selectedFloorIndex = index
        loadPolygons()
    }

    // MARK: - Zone Selection

    func selectZone(_ polygon: ZonePolygon) {
        let density = zoneDensities[polygon.id.uuidString]
        selectedZone = (polygon, density)
    }

    func clearSelection() { selectedZone = nil }

    // MARK: - Private: 폴리곤 로드

    private func loadPolygons() {
        polygons = imdfStore.polygons(for: currentOrdinal)
        generateHeatPoints()
    }

    // MARK: - Heat Point 생성

    private func generateHeatPoints() {
        var points: [HeatPoint] = []
        var globalIndex = 0

        for polygon in polygons {
            guard polygon.category != "level" else { continue }

            let zoneId = polygon.id.uuidString
            guard let density = zoneDensities[zoneId] else { continue }

            let count = density.currentCount
            guard count > 0 else { continue }

            // 3x3m (9m²) 셀 기준 밀도 환산
            let areaM2 = polygon.areaInSquareMeters
            let countPerCell = Double(count) * 9.0 / areaM2
            let level = DensityLevel.from(countPerCell: countPerCell)

            let centroid = polygon.centroid

            // 점 개수: 사람 수에 비례 (최소 2, 최대 30)
            let dotCount = min(max(count * 2, 2), 30)

            // 폴리곤 경계 크기에 비례한 분산 범위
            let (latSpread, lngSpread) = polygonSpread(polygon.coordinates)

            var rng = SeededRNG(seed: polygon.id.hashValue &+ count)

            for _ in 0..<dotCount {
                let latOffset = Double.random(in: -latSpread...latSpread, using: &rng)
                let lngOffset = Double.random(in: -lngSpread...lngSpread, using: &rng)

                let coord = CLLocationCoordinate2D(
                    latitude: centroid.latitude + latOffset,
                    longitude: centroid.longitude + lngOffset
                )

                // 외곽 글로우 (큰 반경, 낮은 투명도)
                points.append(HeatPoint(
                    id: globalIndex,
                    coordinate: coord,
                    densityLevel: level,
                    radius: 6,
                    opacity: 0.12
                ))
                globalIndex += 1

                // 내부 코어 (작은 반경, 높은 투명도)
                points.append(HeatPoint(
                    id: globalIndex,
                    coordinate: coord,
                    densityLevel: level,
                    radius: 3,
                    opacity: 0.30
                ))
                globalIndex += 1
            }
        }

        heatPoints = points
    }

    /// 폴리곤 좌표의 위도/경도 분산 범위 (약 폴리곤 크기의 30%)
    private func polygonSpread(_ coords: [CLLocationCoordinate2D]) -> (Double, Double) {
        guard coords.count >= 3 else { return (0.00003, 0.00003) }
        let lats = coords.map(\.latitude)
        let lngs = coords.map(\.longitude)
        let latRange = (lats.max()! - lats.min()!) * 0.3
        let lngRange = (lngs.max()! - lngs.min()!) * 0.3
        return (max(latRange, 0.00001), max(lngRange, 0.00001))
    }

    // MARK: - Private: 폴링

    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                await fetchDensity()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        countdownTask?.cancel()
        countdownTask = nil
    }

    func manualRefresh() {
        refreshCountdown = 30
        Task { await fetchDensity() }
    }

    private func startCountdown() {
        countdownTask?.cancel()
        countdownTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if refreshCountdown > 0 {
                    refreshCountdown -= 1
                } else {
                    refreshCountdown = 30
                }
            }
        }
    }

    private func fetchDensity() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let zones = try await densityService.fetchCurrentDensity()
            zoneDensities = Dictionary(uniqueKeysWithValues: zones.map { ($0.zoneId, $0) })
            lastUpdated   = Date()
            loadPolygons()
            refreshCountdown = 30
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private: 위치 이벤트

    private func handleLocationUpdate(_ coordinate: CLLocationCoordinate2D) {
        guard AppSettings.participatesInDataCollection else { return }

        let zoneResolver = ZoneResolver(imdfStore: imdfStore)
        guard let unit = zoneResolver.resolve(coordinate: coordinate, floorOrdinal: currentOrdinal) else {
            return
        }

        let event = DensityEvent(
            zoneId: unit.identifier.uuidString,
            floorOrdinal: currentOrdinal
        )
        Task { await eventUploader.upload(event) }
        Task { await fetchDensity() }
    }
}
