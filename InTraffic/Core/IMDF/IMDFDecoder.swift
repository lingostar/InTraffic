// IMDFDecoder.swift
// InTraffic

import Foundation
import MapKit

/// IMDF GeoJSON 디렉터리를 디코딩해 Venue 객체 트리를 반환
final class IMDFDecoder {
    private let geoJSONDecoder = MKGeoJSONDecoder()

    func decode(_ directory: URL) throws -> Venue {
        let venues   = try decodeFeatures(Venue.self,   file: "venue",   in: directory)
        let levels   = try decodeFeatures(Level.self,   file: "level",   in: directory)
        let units    = try decodeFeatures(Unit.self,    file: "unit",    in: directory)
        let openings = (try? decodeFeatures(Opening.self, file: "opening", in: directory)) ?? []
        let amenities = (try? decodeFeatures(Amenity.self, file: "amenity", in: directory)) ?? []

        guard let venue = venues.first else { throw IMDFError.invalidData }

        // Level → ordinal 맵
        venue.levelsByOrdinal = Dictionary(grouping: levels, by: { $0.properties.ordinal })

        // Unit/Opening → Level
        let unitsByLevel    = Dictionary(grouping: units,    by: { $0.properties.levelId })
        let openingsByLevel = Dictionary(grouping: openings, by: { $0.properties.levelId })

        for level in levels {
            level.units    = unitsByLevel[level.identifier]    ?? []
            level.openings = openingsByLevel[level.identifier] ?? []
        }

        // Amenity 좌표 & Unit 연결
        let unitsById = units.reduce(into: [UUID: Unit]()) { $0[$1.identifier] = $1 }

        for amenity in amenities {
            guard let point = amenity.geometry.first as? MKPointAnnotation else { continue }
            amenity.coordinate = point.coordinate
            amenity.title    = amenity.properties.name?.bestLocalizedValue
                               ?? amenity.properties.category.capitalized
            amenity.subtitle = amenity.properties.category.capitalized

            for uid in amenity.properties.unitIds {
                unitsById[uid]?.amenities.append(amenity)
            }
        }

        // Occupant → Unit
        try? decodeOccupants(units: units, in: directory)

        return venue
    }

    // MARK: - Private

    private func decodeOccupants(units: [Unit], in directory: URL) throws {
        let occupants  = try decodeFeatures(Occupant.self, file: "occupant", in: directory)
        let anchors    = try decodeFeatures(Anchor.self,   file: "anchor",   in: directory)
        let unitsById  = units.reduce(into: [UUID: Unit]())     { $0[$1.identifier] = $1 }
        let anchorsById = anchors.reduce(into: [UUID: Anchor]()) { $0[$1.identifier] = $1 }

        for occupant in occupants {
            guard let anchor = anchorsById[occupant.properties.anchorId],
                  let point  = anchor.geometry.first as? MKPointAnnotation else { continue }
            occupant.coordinate = point.coordinate
            occupant.title      = occupant.properties.name.bestLocalizedValue
            occupant.subtitle   = occupant.properties.category.capitalized
            occupant.unit       = unitsById[anchor.properties.unitId]
        }
    }

    private func decodeFeatures<T: IMDFDecodableFeature>(
        _ type: T.Type,
        file: String,
        in directory: URL
    ) throws -> [T] {
        let url      = directory.appendingPathComponent("\(file).geojson")
        let data     = try Data(contentsOf: url)
        let objects  = try geoJSONDecoder.decode(data)
        guard let features = objects as? [MKGeoJSONFeature] else {
            throw IMDFError.invalidType
        }
        return try features.map { try T.init(feature: $0) }
    }
}
