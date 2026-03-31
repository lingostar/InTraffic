// Occupant.swift
// InTraffic

import Foundation
import MapKit

class Occupant: IMDFFeature<Occupant.Properties>, MKAnnotation {
    struct Properties: Codable {
        let category: String
        let name: LocalizedName
        let anchorId: UUID
    }

    var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    var title: String?
    var subtitle: String?
    weak var unit: Unit?
}
