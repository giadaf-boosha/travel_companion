//
//  CLLocation+Extensions.swift
//  TravelCompanion
//
//  Created on 2025-12-07.
//

import Foundation
import CoreLocation

extension CLLocation {

    /// Returns a formatted string representation of the coordinates
    /// - Returns: A string like "40.7128° N, 74.0060° W"
    func formattedCoordinates() -> String {
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude

        let latDirection = latitude >= 0 ? "N" : "S"
        let lonDirection = longitude >= 0 ? "E" : "W"

        return String(format: "%.4f° %@, %.4f° %@",
                     abs(latitude), latDirection,
                     abs(longitude), lonDirection)
    }
}

extension CLLocationCoordinate2D {

    /// Returns a formatted string representation of the coordinates
    /// - Returns: A string like "40.7128° N, 74.0060° W"
    func formattedCoordinates() -> String {
        let latDirection = latitude >= 0 ? "N" : "S"
        let lonDirection = longitude >= 0 ? "E" : "W"

        return String(format: "%.4f° %@, %.4f° %@",
                     abs(latitude), latDirection,
                     abs(longitude), lonDirection)
    }

    /// Calculates the distance to another coordinate in meters
    /// - Parameter coordinate: The destination coordinate
    /// - Returns: The distance in meters
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let toLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return fromLocation.distance(from: toLocation)
    }

    /// Checks if the coordinate is valid
    var isValid: Bool {
        return CLLocationCoordinate2DIsValid(self)
    }
}

extension Array where Element == CLLocation {

    /// Calculates the total distance of a path through all locations in the array
    /// - Returns: The total distance in meters
    func totalDistance() -> CLLocationDistance {
        guard count > 1 else { return 0 }

        var total: CLLocationDistance = 0
        for i in 0..<(count - 1) {
            total += self[i].distance(from: self[i + 1])
        }
        return total
    }

    /// Returns the average coordinate of all locations
    var averageCoordinate: CLLocationCoordinate2D? {
        guard !isEmpty else { return nil }

        var totalLatitude: CLLocationDegrees = 0
        var totalLongitude: CLLocationDegrees = 0

        for location in self {
            totalLatitude += location.coordinate.latitude
            totalLongitude += location.coordinate.longitude
        }

        return CLLocationCoordinate2D(
            latitude: totalLatitude / Double(count),
            longitude: totalLongitude / Double(count)
        )
    }
}

extension CLLocationDistance {

    /// Returns a formatted string representation of the distance
    /// - Returns: A string like "1.5 km" or "250 m"
    func formattedDistance() -> String {
        if self >= 1000 {
            let kilometers = self / 1000
            return String(format: "%.1f km", kilometers)
        } else {
            return String(format: "%.0f m", self)
        }
    }
}
