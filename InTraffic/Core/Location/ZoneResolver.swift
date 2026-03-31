// ZoneResolver.swift
// InTraffic
//
// 위치 좌표 → IMDF Unit(Zone) 판정
// Ray-casting Point-in-Polygon 알고리즘 사용

import CoreLocation
import Foundation
import MapKit

@MainActor
final class ZoneResolver {

    private let imdfStore: IMDFStore

    init(imdfStore: IMDFStore) {
        self.imdfStore = imdfStore
    }

    // MARK: - Public API

    /// 좌표가 속한 Unit을 반환
    func resolve(coordinate: CLLocationCoordinate2D, floorOrdinal: Int) -> Unit? {
        imdfStore.unit(containing: coordinate, ordinal: floorOrdinal)
    }

    /// 좌표가 건물 내부(어떤 층이든)에 있는지 확인
    /// 건물 외부 좌표는 서버로 전송하지 않음
    func isInsideVenue(coordinate: CLLocationCoordinate2D) -> Bool {
        guard let venue = imdfStore.venue else { return false }
        for (_, levels) in venue.levelsByOrdinal {
            for level in levels {
                for geo in level.geometry {
                    if let polygon = geo as? MKPolygon,
                       polygon.contains(coordinate) {
                        return true
                    }
                }
            }
        }
        return false
    }
}
