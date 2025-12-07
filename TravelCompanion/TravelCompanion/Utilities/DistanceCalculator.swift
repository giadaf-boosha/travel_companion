//
//  DistanceCalculator.swift
//  TravelCompanion
//
//  Created on 2025-12-07.
//

import CoreLocation
import Foundation

struct DistanceCalculator {

    // MARK: - Distance Calculation

    /// Calcola la distanza totale da un array di CLLocation
    /// - Parameter locations: Array di posizioni GPS
    /// - Returns: Distanza totale in metri
    static func calculateDistance(from locations: [CLLocation]) -> CLLocationDistance {
        guard locations.count >= 2 else {
            return 0.0
        }

        var totalDistance: CLLocationDistance = 0.0

        for i in 0..<(locations.count - 1) {
            let start = locations[i]
            let end = locations[i + 1]
            totalDistance += start.distance(from: end)
        }

        return totalDistance
    }

    /// Formatta la distanza in modo leggibile
    /// - Parameter meters: Distanza in metri
    /// - Returns: Stringa formattata (es. "500 m" o "2.5 km")
    static func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            let kilometers = meters / 1000.0
            return String(format: "%.1f km", kilometers)
        }
    }

    // MARK: - Duration Calculation

    /// Calcola la durata in secondi tra due date
    /// - Parameters:
    ///   - start: Data di inizio
    ///   - end: Data di fine
    /// - Returns: Durata in secondi
    static func calculateDuration(from start: Date, to end: Date) -> TimeInterval {
        return end.timeIntervalSince(start)
    }

    /// Formatta la durata in modo leggibile
    /// - Parameter seconds: Durata in secondi
    /// - Returns: Stringa formattata (es. "5m 30s" o "2h 15m")
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let absoluteSeconds = abs(seconds)

        if absoluteSeconds < 60 {
            // Meno di 1 minuto: mostra solo i secondi
            return String(format: "%.0fs", absoluteSeconds)
        } else if absoluteSeconds < 3600 {
            // Meno di 1 ora: mostra minuti e secondi
            let minutes = Int(absoluteSeconds / 60)
            let remainingSeconds = Int(absoluteSeconds.truncatingRemainder(dividingBy: 60))
            return String(format: "%dm %ds", minutes, remainingSeconds)
        } else {
            // 1 ora o più: mostra ore e minuti
            let hours = Int(absoluteSeconds / 3600)
            let remainingMinutes = Int((absoluteSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return String(format: "%dh %dm", hours, remainingMinutes)
        }
    }

    // MARK: - Speed Calculation

    /// Calcola la velocità media in km/h
    /// - Parameters:
    ///   - distance: Distanza in metri
    ///   - duration: Durata in secondi
    /// - Returns: Velocità media in km/h (0.0 se la durata è 0)
    static func calculateAverageSpeed(distance: CLLocationDistance, duration: TimeInterval) -> Double {
        guard duration > 0 else {
            return 0.0
        }

        let distanceInKm = distance / 1000.0
        let durationInHours = duration / 3600.0

        return distanceInKm / durationInHours
    }

    /// Formatta la velocità in km/h
    /// - Parameter kmh: Velocità in km/h
    /// - Returns: Stringa formattata (es. "25.5 km/h")
    static func formatSpeed(_ kmh: Double) -> String {
        return String(format: "%.1f km/h", kmh)
    }
}
