//
//  CLLocation+Extensions.swift
//  TravelCompanion
//
//  Estensioni per CoreLocation con utility di formattazione coordinate e calcolo distanze.
//  Created on 2025-12-07.
//

import Foundation
import CoreLocation

// MARK: - CLLocation Extensions

/// Estensione di CLLocation con metodi di formattazione coordinate
extension CLLocation {

    /// Restituisce una rappresentazione stringa formattata delle coordinate
    /// - Returns: Stringa nel formato "40.7128° N, 74.0060° E"
    /// - Note: Usa 4 decimali e indica direzione cardinale (N/S per latitudine, E/W per longitudine)
    func formattedCoordinates() -> String {
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude

        // Determina la direzione cardinale in base al segno
        let latDirection = latitude >= 0 ? "N" : "S"
        let lonDirection = longitude >= 0 ? "E" : "W"

        return String(format: "%.4f° %@, %.4f° %@",
                     abs(latitude), latDirection,
                     abs(longitude), lonDirection)
    }
}

// MARK: - CLLocationCoordinate2D Extensions

/// Estensione di CLLocationCoordinate2D con utility di formattazione e calcolo distanze
extension CLLocationCoordinate2D {

    /// Restituisce una rappresentazione stringa formattata delle coordinate
    /// - Returns: Stringa nel formato "40.7128° N, 74.0060° E"
    /// - Example: Coordinate di Roma -> "41.9028° N, 12.4964° E"
    func formattedCoordinates() -> String {
        let latDirection = latitude >= 0 ? "N" : "S"
        let lonDirection = longitude >= 0 ? "E" : "W"

        return String(format: "%.4f° %@, %.4f° %@",
                     abs(latitude), latDirection,
                     abs(longitude), lonDirection)
    }

    /// Calcola la distanza verso un'altra coordinata in metri
    /// - Parameter coordinate: La coordinata di destinazione
    /// - Returns: La distanza in metri (CLLocationDistance)
    /// - Note: Usa il metodo distance(from:) di CLLocation per calcolo geodetico preciso
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let toLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return fromLocation.distance(from: toLocation)
    }

    /// Verifica se la coordinata e valida
    /// - Returns: `true` se latitudine e tra -90 e 90, longitudine tra -180 e 180
    var isValid: Bool {
        return CLLocationCoordinate2DIsValid(self)
    }
}

// MARK: - Array<CLLocation> Extensions

/// Estensione per array di CLLocation con calcolo distanza totale e coordinate medie
extension Array where Element == CLLocation {

    /// Calcola la distanza totale di un percorso attraverso tutte le location nell'array
    /// - Returns: La distanza totale in metri
    /// - Note: Richiede almeno 2 punti per calcolare una distanza
    func totalDistance() -> CLLocationDistance {
        guard count > 1 else { return 0 }

        var total: CLLocationDistance = 0
        // Somma le distanze tra punti consecutivi
        for i in 0..<(count - 1) {
            total += self[i].distance(from: self[i + 1])
        }
        return total
    }

    /// Restituisce la coordinata media (centro geometrico) di tutte le location
    /// - Returns: Coordinata media, o `nil` se l'array e vuoto
    /// - Note: Utile per centrare la mappa su un percorso
    var averageCoordinate: CLLocationCoordinate2D? {
        guard !isEmpty else { return nil }

        var totalLatitude: CLLocationDegrees = 0
        var totalLongitude: CLLocationDegrees = 0

        // Somma tutte le coordinate
        for location in self {
            totalLatitude += location.coordinate.latitude
            totalLongitude += location.coordinate.longitude
        }

        // Calcola la media
        return CLLocationCoordinate2D(
            latitude: totalLatitude / Double(count),
            longitude: totalLongitude / Double(count)
        )
    }
}

// MARK: - CLLocationDistance Extensions

/// Estensione di CLLocationDistance per formattazione leggibile
extension CLLocationDistance {

    /// Restituisce una rappresentazione stringa formattata della distanza
    /// - Returns: Stringa come "1.5 km" o "250 m"
    /// - Note: Usa km per distanze >= 1000m, altrimenti metri
    func formattedDistance() -> String {
        if self >= 1000 {
            // Converte in chilometri con un decimale
            let kilometers = self / 1000
            return String(format: "%.1f km", kilometers)
        } else {
            // Mostra in metri senza decimali
            return String(format: "%.0f m", self)
        }
    }
}
