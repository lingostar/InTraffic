// MapTabViewModel.swift
// InTraffic

import Foundation
import MapKit
import SwiftUI

@Observable
@MainActor
final class MapTabViewModel {

    // MARK: - State

    var selectedFloorIndex: Int = 0         // levels 배열 인덱스
    var zoneDensities: [String: ZoneDensity] = [:]   // zoneId → density
    var polygons: [ZonePolygon]  = []
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

        // 위치 업데이트 콜백
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
        var rawPolygons = imdfStore.polygons(for: currentOrdinal)
        // 혼잡도 오버레이 적용
        for i in rawPolygons.indices {
            rawPolygons[i].densityLevel = zoneDensities[rawPolygons[i].id.uuidString]?.densityLevel
        }
        polygons = rawPolygons
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
        guard UserDefaults.standard.bool(forKey: AppSettings.participationKey) else { return }

        let zoneResolver = ZoneResolver(imdfStore: imdfStore)
        guard let unit = zoneResolver.resolve(coordinate: coordinate, floorOrdinal: currentOrdinal) else {
            return
        }

        let event = DensityEvent(
            zoneId: unit.identifier.uuidString,
            floorOrdinal: currentOrdinal
        )
        Task { await eventUploader.upload(event) }

        // 위치 이벤트 트리거 즉시 폴링
        Task { await fetchDensity() }
    }
}
