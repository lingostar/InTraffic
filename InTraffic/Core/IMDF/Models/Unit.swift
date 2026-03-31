// Unit.swift
// InTraffic

import Foundation
import MapKit

class Unit: IMDFFeature<Unit.Properties> {
    struct Properties: Codable {
        let category: String
        let levelId: UUID
        let name: LocalizedName?
        let displayPoint: DisplayPoint?

        struct DisplayPoint: Codable {
            let coordinates: [Double]   // [longitude, latitude]
        }
    }

    var amenities: [Amenity] = []

    /// 유닛 중심 좌표 (display_point 우선, 없으면 polygon centroid)
    var centerCoordinate: CLLocationCoordinate2D {
        if let dp = properties.displayPoint,
           dp.coordinates.count >= 2 {
            return CLLocationCoordinate2D(
                latitude:  dp.coordinates[1],
                longitude: dp.coordinates[0]
            )
        }
        // polygon centroid 계산
        guard let polygon = geometry.first as? MKPolygon else {
            return kCLLocationCoordinate2DInvalid
        }
        return polygon.centroid
    }

    /// Polygon 배열 (multi-polygon 포함)
    var polygons: [MKPolygon] {
        geometry.compactMap { shape -> [MKPolygon]? in
            if let p = shape as? MKPolygon           { return [p] }
            if let mp = shape as? MKMultiPolygon     { return mp.polygons }
            return nil
        }.flatMap { $0 }
    }
}

// MARK: - MKPolygon centroid helper

extension MKPolygon {
    var centroid: CLLocationCoordinate2D {
        let pts = points()
        guard pointCount > 0 else { return kCLLocationCoordinate2DInvalid }
        var x = 0.0, y = 0.0
        for i in 0..<pointCount {
            x += pts[i].x; y += pts[i].y
        }
        return MKMapPoint(x: x / Double(pointCount),
                          y: y / Double(pointCount)).coordinate
    }

    /// Ray-casting point-in-polygon
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let testPoint = MKMapPoint(coordinate)
        let pts       = points()
        var inside    = false
        var j         = pointCount - 1
        for i in 0..<pointCount {
            let pi = pts[i], pj = pts[j]
            if (pi.y > testPoint.y) != (pj.y > testPoint.y),
               testPoint.x < (pj.x - pi.x) * (testPoint.y - pi.y) / (pj.y - pi.y) + pi.x {
                inside.toggle()
            }
            j = i
        }
        return inside
    }
}
