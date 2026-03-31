// Amenity.swift
// InTraffic

import Foundation
import MapKit

class Amenity: IMDFFeature<Amenity.Properties>, MKAnnotation {
    struct Properties: Codable {
        let category: String
        let name: LocalizedName?
        let unitIds: [UUID]
    }

    var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    var title: String?
    var subtitle: String?
}
