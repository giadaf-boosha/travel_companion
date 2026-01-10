import Foundation
import CoreLocation

#if canImport(FoundationModels)
import FoundationModels

// MARK: - Get Trip Data Tool

/// Tool per recuperare i dati di un viaggio specifico
@available(iOS 26.0, *)
struct GetTripDataTool: Tool {
    let name = "getTripData"
    let description = "Recupera i dati completi di un viaggio: foto, note e percorsi"

    struct Arguments: Decodable {
        let tripId: String
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        guard let tripUUID = UUID(uuidString: arguments.tripId) else {
            return ToolOutput(content: "ID viaggio non valido")
        }

        // Recupera i dati dal CoreDataManager
        let trips = CoreDataManager.shared.fetchAllTrips()
        guard let trip = trips.first(where: { $0.id == tripUUID }) else {
            return ToolOutput(content: "Viaggio non trovato")
        }

        let photos = CoreDataManager.shared.fetchPhotos(for: trip)
        let notes = CoreDataManager.shared.fetchNotes(for: trip)
        let routes = CoreDataManager.shared.fetchRoute(for: trip)

        var result = """
        Viaggio: \(trip.destination ?? "Sconosciuto")
        Date: \(formatDate(trip.startDate)) - \(formatDate(trip.endDate))
        Tipo: \(trip.tripTypeRaw ?? "Non specificato")
        Distanza totale: \(String(format: "%.1f", trip.totalDistance / 1000)) km

        Foto: \(photos.count)
        Note: \(notes.count)
        Punti percorso: \(routes.count)
        """

        if !notes.isEmpty {
            result += "\n\nNote registrate:\n"
            for note in notes.prefix(5) {
                if let content = note.content {
                    result += "- \(content.prefix(100))...\n"
                }
            }
        }

        return ToolOutput(content: result)
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/D" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Get Trip Statistics Tool

/// Tool per recuperare le statistiche di un viaggio
@available(iOS 26.0, *)
struct GetTripStatisticsTool: Tool {
    let name = "getTripStatistics"
    let description = "Recupera le statistiche di un viaggio: distanza, numero foto, numero note"

    struct Arguments: Decodable {
        let tripId: String
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        guard let tripUUID = UUID(uuidString: arguments.tripId) else {
            return ToolOutput(content: "ID viaggio non valido")
        }

        let trips = CoreDataManager.shared.fetchAllTrips()
        guard let trip = trips.first(where: { $0.id == tripUUID }) else {
            return ToolOutput(content: "Viaggio non trovato")
        }

        let photos = CoreDataManager.shared.fetchPhotos(for: trip)
        let notes = CoreDataManager.shared.fetchNotes(for: trip)

        // Calcola durata
        var durationDays = 0
        if let startDate = trip.startDate {
            let endDate = trip.endDate ?? Date()
            durationDays = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        }

        let result = """
        Statistiche viaggio:
        - Destinazione: \(trip.destination ?? "Non specificata")
        - Durata: \(durationDays) giorni
        - Distanza totale: \(String(format: "%.1f", trip.totalDistance / 1000)) km
        - Foto scattate: \(photos.count)
        - Note registrate: \(notes.count)
        - Stato: \(trip.isActive ? "In corso" : "Completato")
        """

        return ToolOutput(content: result)
    }
}

// MARK: - Get Today Activity Tool

/// Tool per recuperare le attivita di oggi per il viaggio attivo
@available(iOS 26.0, *)
struct GetTodayActivityTool: Tool {
    let name = "getTodayActivity"
    let description = "Recupera le attivita registrate oggi per il viaggio attivo"

    struct Arguments: Decodable {
        // Nessun argomento richiesto
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        guard let activeTrip = CoreDataManager.shared.fetchActiveTrip() else {
            return ToolOutput(content: "Nessun viaggio attivo")
        }

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        // Recupera foto di oggi
        let allPhotos = CoreDataManager.shared.fetchPhotos(for: activeTrip)
        let todayPhotos = allPhotos.filter { photo in
            guard let timestamp = photo.timestamp else { return false }
            return timestamp >= today && timestamp < tomorrow
        }

        // Recupera note di oggi
        let allNotes = CoreDataManager.shared.fetchNotes(for: activeTrip)
        let todayNotes = allNotes.filter { note in
            guard let timestamp = note.timestamp else { return false }
            return timestamp >= today && timestamp < tomorrow
        }

        // Recupera percorso di oggi
        let allRoutes = CoreDataManager.shared.fetchRoute(for: activeTrip)
        let todayRoutes = allRoutes.filter { route in
            guard let timestamp = route.timestamp else { return false }
            return timestamp >= today && timestamp < tomorrow
        }

        // Calcola distanza di oggi
        var todayDistance: Double = 0
        if todayRoutes.count >= 2 {
            for i in 1..<todayRoutes.count {
                let prev = CLLocation(latitude: todayRoutes[i-1].latitude, longitude: todayRoutes[i-1].longitude)
                let curr = CLLocation(latitude: todayRoutes[i].latitude, longitude: todayRoutes[i].longitude)
                todayDistance += curr.distance(from: prev)
            }
        }

        var result = """
        Attivita di oggi (\(formatDate(today))):
        - Viaggio: \(activeTrip.destination ?? "Non specificato")
        - Foto scattate: \(todayPhotos.count)
        - Note registrate: \(todayNotes.count)
        - Distanza percorsa: \(String(format: "%.1f", todayDistance / 1000)) km
        """

        if !todayNotes.isEmpty {
            result += "\n\nNote di oggi:\n"
            for note in todayNotes {
                if let content = note.content {
                    result += "- \(content.prefix(100))\n"
                }
            }
        }

        return ToolOutput(content: result)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Get User Trips Tool

/// Tool per recuperare la lista dei viaggi dell'utente
@available(iOS 26.0, *)
struct GetUserTripsTool: Tool {
    let name = "getUserTrips"
    let description = "Recupera la lista dei viaggi dell'utente"

    struct Arguments: Decodable {
        let limit: Int?
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        let allTrips = CoreDataManager.shared.fetchAllTrips()
        let limit = arguments.limit ?? 10
        let trips = Array(allTrips.prefix(limit))

        if trips.isEmpty {
            return ToolOutput(content: "Nessun viaggio registrato")
        }

        var result = "Viaggi recenti (\(trips.count)):\n"

        for trip in trips {
            let status = trip.isActive ? "In corso" : "Completato"
            let distance = String(format: "%.1f", trip.totalDistance / 1000)

            result += """

            - \(trip.destination ?? "Non specificato")
              Date: \(formatDate(trip.startDate)) - \(formatDate(trip.endDate))
              Tipo: \(trip.tripTypeRaw ?? "N/D")
              Distanza: \(distance) km
              Stato: \(status)
            """
        }

        return ToolOutput(content: result)
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/D" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Get Current Location Tool

/// Tool per recuperare la posizione corrente
@available(iOS 26.0, *)
struct GetCurrentLocationTool: Tool {
    let name = "getCurrentLocation"
    let description = "Recupera la posizione GPS corrente dell'utente"

    struct Arguments: Decodable {
        // Nessun argomento richiesto
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        guard let location = LocationManager.shared.currentLocation else {
            return ToolOutput(content: "Posizione non disponibile")
        }

        let result = """
        Posizione corrente:
        - Latitudine: \(location.coordinate.latitude)
        - Longitudine: \(location.coordinate.longitude)
        - Altitudine: \(String(format: "%.0f", location.altitude)) m
        - Precisione: \(String(format: "%.0f", location.horizontalAccuracy)) m
        - Timestamp: \(formatDate(location.timestamp))
        """

        return ToolOutput(content: result)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Get Photos For Day Tool

/// Tool per recuperare le foto di un giorno specifico
@available(iOS 26.0, *)
struct GetPhotosForDayTool: Tool {
    let name = "getPhotosForDay"
    let description = "Recupera le foto scattate in un giorno specifico del viaggio"

    struct Arguments: Decodable {
        let tripId: String
        let date: String // formato: yyyy-MM-dd
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        guard let tripUUID = UUID(uuidString: arguments.tripId) else {
            return ToolOutput(content: "ID viaggio non valido")
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let targetDate = dateFormatter.date(from: arguments.date) else {
            return ToolOutput(content: "Formato data non valido. Usa yyyy-MM-dd")
        }

        let trips = CoreDataManager.shared.fetchAllTrips()
        guard let trip = trips.first(where: { $0.id == tripUUID }) else {
            return ToolOutput(content: "Viaggio non trovato")
        }

        let startOfDay = Calendar.current.startOfDay(for: targetDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let allPhotos = CoreDataManager.shared.fetchPhotos(for: trip)
        let dayPhotos = allPhotos.filter { photo in
            guard let timestamp = photo.timestamp else { return false }
            return timestamp >= startOfDay && timestamp < endOfDay
        }

        if dayPhotos.isEmpty {
            return ToolOutput(content: "Nessuna foto trovata per il \(arguments.date)")
        }

        var result = "Foto del \(arguments.date): \(dayPhotos.count)\n"

        for (index, photo) in dayPhotos.enumerated() {
            let time = formatTime(photo.timestamp)
            let caption = photo.caption ?? "Senza didascalia"
            result += "\n\(index + 1). Ore \(time) - \(caption)"

            if photo.latitude != 0 && photo.longitude != 0 {
                result += " (GPS: \(photo.latitude), \(photo.longitude))"
            }
        }

        return ToolOutput(content: result)
    }

    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "N/D" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#endif

// MARK: - Tool Output Helper (Fallback for non-iOS 26)

/// Struttura per l'output dei tool (fallback)
struct AIToolOutput {
    let content: String

    init(content: String) {
        self.content = content
    }
}
