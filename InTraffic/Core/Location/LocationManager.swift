// LocationManager.swift
// InTraffic

import CoreLocation
import Foundation
import Observation

/// 위치 권한 관리 + significantLocationChange 기반 수집
/// 개인정보: 좌표는 ZoneResolver에서 즉시 Zone ID로 변환 후 파기
@Observable
@MainActor
final class LocationManager: NSObject {

    // MARK: - Observable State

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentCoordinate: CLLocationCoordinate2D? = nil
    var lastUpdated: Date? = nil

    // MARK: - Callbacks

    /// Zone 판정이 완료된 후 호출 (위치 이벤트 발생 시)
    var onLocationUpdate: ((CLLocationCoordinate2D) -> Void)?

    // MARK: - Private

    private let manager = CLLocationManager()

    // MARK: - Init

    override init() {
        super.init()
        manager.delegate          = self
        manager.desiredAccuracy   = kCLLocationAccuracyBest
        manager.distanceFilter    = 10      // 10m 이동 시 업데이트
        authorizationStatus       = manager.authorizationStatus
    }

    // MARK: - Public API

    func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    /// 포그라운드 위치 업데이트 시작 (앱 활성 시)
    func startForegroundUpdates() {
        guard authorizationStatus == .authorizedAlways ||
              authorizationStatus == .authorizedWhenInUse else { return }
        manager.startUpdatingLocation()
    }

    /// 백그라운드 significantLocationChange 시작
    func startSignificantLocationMonitoring() {
        guard authorizationStatus == .authorizedAlways else { return }
        manager.startMonitoringSignificantLocationChanges()
    }

    func stopForegroundUpdates() {
        manager.stopUpdatingLocation()
    }

    // MARK: - 권한 상태 레이블

    var authorizationLabel: String {
        switch authorizationStatus {
        case .authorizedAlways:           "항상 허용 ✅"
        case .authorizedWhenInUse:        "앱 사용 중 허용 ⚠️"
        case .denied, .restricted:        "거부됨 ❌"
        case .notDetermined:              "미설정"
        @unknown default:                 "알 수 없음"
        }
    }

    var isFullyAuthorized: Bool {
        authorizationStatus == .authorizedAlways
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedAlways {
                self.startSignificantLocationMonitoring()
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentCoordinate = location.coordinate
            self.lastUpdated       = Date()
            self.onLocationUpdate?(location.coordinate)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("[LocationManager] error: \(error.localizedDescription)")
    }
}
