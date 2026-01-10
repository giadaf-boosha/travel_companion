//
//  DistanceCalculator.swift
//  TravelCompanion
//
//  Utility per calcoli di distanza, durata e velocita con formattazione localizzata.
//  Fornisce metodi statici per le metriche di viaggio.
//  Created on 2025-12-07.
//

import CoreLocation
import Foundation

// MARK: - Distance Calculator

/// Struttura di utilita per calcoli e formattazione di metriche di viaggio.
///
/// Fornisce metodi statici per:
/// - Calcolo distanza totale da una sequenza di posizioni GPS
/// - Calcolo durata temporale tra due istanti
/// - Calcolo velocita media
/// - Formattazione leggibile di tutte le metriche
///
/// - Note: Tutti i metodi sono statici per uso senza istanziazione
struct DistanceCalculator {

    // MARK: - Calcolo Distanza

    /// Calcola la distanza totale percorsa da un array di posizioni GPS
    ///
    /// Somma le distanze tra punti consecutivi usando il metodo geodetico di CLLocation.
    ///
    /// - Parameter locations: Array di posizioni GPS ordinate cronologicamente
    /// - Returns: Distanza totale in metri (0.0 se meno di 2 punti)
    ///
    /// - Example:
    ///   ```swift
    ///   let locations = [CLLocation(latitude: 41.9, longitude: 12.5),
    ///                    CLLocation(latitude: 42.0, longitude: 12.6)]
    ///   let distance = DistanceCalculator.calculateDistance(from: locations)
    ///   // Restituisce la distanza in metri tra i due punti
    ///   ```
    static func calculateDistance(from locations: [CLLocation]) -> CLLocationDistance {
        // Servono almeno 2 punti per calcolare una distanza
        guard locations.count >= 2 else {
            return 0.0
        }

        var totalDistance: CLLocationDistance = 0.0

        // Somma le distanze tra ogni coppia di punti consecutivi
        for i in 0..<(locations.count - 1) {
            let start = locations[i]
            let end = locations[i + 1]
            totalDistance += start.distance(from: end)
        }

        return totalDistance
    }

    /// Formatta una distanza in una stringa leggibile con unita di misura appropriate
    ///
    /// - Parameter meters: Distanza in metri
    /// - Returns: Stringa formattata:
    ///   - Metri senza decimali se < 1000m (es. "500 m")
    ///   - Chilometri con 1 decimale se >= 1000m (es. "2.5 km")
    static func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            // Sotto il km: mostra in metri
            return String(format: "%.0f m", meters)
        } else {
            // Sopra il km: converti in chilometri con un decimale
            let kilometers = meters / 1000.0
            return String(format: "%.1f km", kilometers)
        }
    }

    // MARK: - Calcolo Durata

    /// Calcola la durata in secondi tra due date
    ///
    /// - Parameters:
    ///   - start: Data/ora di inizio
    ///   - end: Data/ora di fine
    /// - Returns: Intervallo temporale in secondi (TimeInterval)
    ///
    /// - Note: Puo restituire valori negativi se end < start
    static func calculateDuration(from start: Date, to end: Date) -> TimeInterval {
        return end.timeIntervalSince(start)
    }

    /// Formatta una durata in una stringa leggibile con unita appropriate
    ///
    /// - Parameter seconds: Durata in secondi (viene usato il valore assoluto)
    /// - Returns: Stringa formattata in base alla grandezza:
    ///   - Solo secondi se < 60s (es. "45s")
    ///   - Minuti e secondi se < 1h (es. "5m 30s")
    ///   - Ore e minuti se >= 1h (es. "2h 15m")
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
            // 1 ora o piu: mostra ore e minuti (ignora i secondi per leggibilita)
            let hours = Int(absoluteSeconds / 3600)
            let remainingMinutes = Int((absoluteSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return String(format: "%dh %dm", hours, remainingMinutes)
        }
    }

    // MARK: - Calcolo Velocita

    /// Calcola la velocita media in km/h
    ///
    /// Formula: velocita = distanza / tempo
    ///
    /// - Parameters:
    ///   - distance: Distanza percorsa in metri
    ///   - duration: Tempo impiegato in secondi
    /// - Returns: Velocita media in km/h (0.0 se durata <= 0)
    ///
    /// - Note: Gestisce la divisione per zero restituendo 0.0
    static func calculateAverageSpeed(distance: CLLocationDistance, duration: TimeInterval) -> Double {
        // Previene divisione per zero
        guard duration > 0 else {
            return 0.0
        }

        // Conversione unita: metri -> km, secondi -> ore
        let distanceInKm = distance / 1000.0
        let durationInHours = duration / 3600.0

        return distanceInKm / durationInHours
    }

    /// Formatta una velocita in km/h in una stringa leggibile
    ///
    /// - Parameter kmh: Velocita in chilometri all'ora
    /// - Returns: Stringa formattata con 1 decimale (es. "25.5 km/h")
    static func formatSpeed(_ kmh: Double) -> String {
        return String(format: "%.1f km/h", kmh)
    }
}
