// IMDFStore.swift
// InTraffic

import Foundation
import MapKit
import SwiftUI

/// IMDF 데이터를 앱 전역에서 공유하는 Observable 스토어
@Observable
@MainActor
final class IMDFStore {
    // MARK: - State

    var venue: Venue?
    var levels: [Level] = []        // 표시 대상 층 (ordinal 오름차순)
    var isLoaded: Bool  = false
    var loadError: String?

    // MARK: - Private

    private let decoder = IMDFDecoder()

    // MARK: - Load

    func load() {
        guard !isLoaded else { return }
        guard let dir = Bundle.main.resourceURL?.appendingPathComponent("IMDF") else {
            loadError = "IMDF 디렉터리를 찾을 수 없습니다."
            return
        }

        do {
            let v = try decoder.decode(dir)
            venue = v

            // 모든 층 정렬 (ordinal 오름차순 = 낮은 층 먼저)
            let allLevels = v.levelsByOrdinal
                .sorted(by: { $0.key < $1.key })
                .compactMap { $0.value.first(where: { !$0.properties.outdoor }) ?? $0.value.first }

            levels   = allLevels
            isLoaded = true
        } catch {
            loadError = error.localizedDescription
        }
    }

    // MARK: - Polygon 생성 (Map 렌더링용)

    func polygons(for ordinal: Int) -> [ZonePolygon] {
        guard let levelList = venue?.levelsByOrdinal[ordinal] else { return [] }
        var result: [ZonePolygon] = []

        for level in levelList {
            // Level 외곽선
            for geo in level.geometry {
                if let polygon = geo as? MKPolygon {
                    result.append(ZonePolygon(
                        id: level.identifier,
                        coordinates: polygon.coordinates,
                        category: "level"
                    ))
                }
            }
            // Unit 폴리곤
            for unit in level.units {
                for polygon in unit.polygons {
                    result.append(ZonePolygon(
                        id: unit.identifier,
                        coordinates: polygon.coordinates,
                        category: unit.properties.category
                    ))
                }
            }
        }
        return result
    }

    // MARK: - Zone 조회

    /// 좌표가 속한 Unit을 반환 (ZoneResolver에서 사용)
    func unit(containing coordinate: CLLocationCoordinate2D, ordinal: Int) -> Unit? {
        guard let levelList = venue?.levelsByOrdinal[ordinal] else { return nil }
        for level in levelList {
            for unit in level.units {
                for polygon in unit.polygons {
                    if polygon.contains(coordinate) { return unit }
                }
            }
        }
        return nil
    }
}

// MARK: - ZonePolygon (렌더링 데이터)

struct ZonePolygon: Identifiable {
    let id: UUID
    let coordinates: [CLLocationCoordinate2D]
    let category: String

    /// 구조물 색상만 사용 (히트맵은 별도 HeatPoint로 렌더링)
    var fillColor: Color { baseColor }
    var strokeColor: Color { Color(UIColor.systemGray3) }
    var lineWidth: CGFloat  { category == "level" ? 2.0 : 1.0 }

    var centroid: CLLocationCoordinate2D {
        guard !coordinates.isEmpty else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        let lat = coordinates.map(\.latitude).reduce(0, +) / Double(coordinates.count)
        let lng = coordinates.map(\.longitude).reduce(0, +) / Double(coordinates.count)
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    /// Shoelace 공식으로 폴리곤 면적 (m²) 계산
    var areaInSquareMeters: Double {
        guard coordinates.count >= 3 else { return 9.0 }
        let center = centroid
        let mPerDegreeLat = 111_320.0
        let mPerDegreeLng = 111_320.0 * cos(center.latitude * .pi / 180.0)

        var area = 0.0
        let ref = coordinates[0]
        for i in 0..<coordinates.count {
            let j = (i + 1) % coordinates.count
            let xi = (coordinates[i].longitude - ref.longitude) * mPerDegreeLng
            let yi = (coordinates[i].latitude  - ref.latitude)  * mPerDegreeLat
            let xj = (coordinates[j].longitude - ref.longitude) * mPerDegreeLng
            let yj = (coordinates[j].latitude  - ref.latitude)  * mPerDegreeLat
            area += xi * yj - xj * yi
        }
        return max(abs(area) / 2.0, 9.0)  // 최소 9m² (단일 셀)
    }

    private var baseColor: Color {
        switch category {
        case "structure":
            return Color(UIColor(named: "StructureFill") ?? .systemGray5)
        case "walkway":
            return Color(UIColor(named: "WalkwayFill")   ?? .systemGray6)
        case "elevator", "stairs":
            return Color(UIColor(named: "ElevatorFill")  ?? .systemGray4)
        case "restroom", "restroom.male", "restroom.female", "restroom.unisex.wheelchair":
            return Color(UIColor(named: "RoomFill")      ?? .systemGray5)
        case "room", "auditorium", "conferenceroom":
            return Color(UIColor(named: "RoomFill")      ?? .systemGray5)
        case "lounge", "lobby", "kitchen":
            return Color(UIColor(named: "LoungeFill")    ?? .systemGray5)
        case "level":
            return .clear
        default:
            return Color(UIColor(named: "DefaultUnitFill") ?? .systemGray6)
        }
    }
}

// MARK: - MKPolygon coordinates helper

extension MKPolygon {
    var coordinates: [CLLocationCoordinate2D] {
        let pts = points()
        return (0..<pointCount).map { pts[$0].coordinate }
    }
}
