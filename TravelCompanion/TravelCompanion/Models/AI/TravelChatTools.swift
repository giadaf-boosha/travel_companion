//
//  TravelChatTools.swift
//  TravelCompanion
//
//  Tool definitions for AI Chat with Foundation Models Tool Calling.
//  These tools allow the AI to perform actions in the app.
//

import Foundation
import CoreLocation

#if canImport(FoundationModels)
import FoundationModels

// MARK: - Create Trip Tool

/// Tool per creare un nuovo viaggio dall'AI Chat
@available(iOS 26.0, *)
struct CreateTripTool: Tool {
    let name = "createTrip"
    let description = """
        Crea un nuovo viaggio per l'utente. Usa questo tool quando l'utente vuole iniziare un nuovo viaggio,
        pianificare una vacanza, o registrare una gita. Richiedi sempre destinazione e date.
        """

    @Generable
    struct Arguments {
        @Guide(description: "Nome della citta o luogo di destinazione")
        let destination: String

        @Guide(description: "Data di inizio viaggio nel formato yyyy-MM-dd")
        let startDate: String

        @Guide(description: "Data di fine viaggio nel formato yyyy-MM-dd, puo essere uguale a startDate per gite giornaliere")
        let endDate: String

        @Guide(description: "Tipo di viaggio", .anyOf(["locale", "giornaliero", "multi-giorno"]))
        let tripType: String
    }

    nonisolated func call(arguments: Arguments) async throws -> ToolOutput {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "it_IT")

        guard let startDate = dateFormatter.date(from: arguments.startDate) else {
            return ToolOutput("Errore: formato data inizio non valido. Usa yyyy-MM-dd.")
        }

        guard let endDate = dateFormatter.date(from: arguments.endDate) else {
            return ToolOutput("Errore: formato data fine non valido. Usa yyyy-MM-dd.")
        }

        guard endDate >= startDate else {
            return ToolOutput("Errore: la data di fine deve essere successiva o uguale alla data di inizio.")
        }

        // Map trip type
        let tripTypeValue: String
        switch arguments.tripType.lowercased() {
        case "locale": tripTypeValue = "local"
        case "giornaliero": tripTypeValue = "dayTrip"
        case "multi-giorno": tripTypeValue = "multiDay"
        default: tripTypeValue = "dayTrip"
        }

        // Create trip on main actor
        let result = await MainActor.run {
            let trip = CoreDataManager.shared.createTrip(
                destination: arguments.destination,
                startDate: startDate,
                endDate: endDate,
                type: tripTypeValue,
                isActive: false
            )
            return trip
        }

        if let trip = result {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "dd MMMM yyyy"
            displayFormatter.locale = Locale(identifier: "it_IT")

            let startStr = displayFormatter.string(from: startDate)
            let endStr = displayFormatter.string(from: endDate)

            return ToolOutput("""
                Viaggio creato con successo!
                - Destinazione: \(arguments.destination)
                - Date: \(startStr) - \(endStr)
                - Tipo: \(arguments.tripType)
                - ID: \(trip.id?.uuidString ?? "N/A")

                Il viaggio e stato salvato. Puoi attivarlo dalla lista viaggi per iniziare il tracking.
                """)
        } else {
            return ToolOutput("Errore nella creazione del viaggio. Riprova.")
        }
    }
}

// MARK: - Add Note Tool

/// Tool per aggiungere una nota al viaggio attivo
@available(iOS 26.0, *)
struct AddNoteTool: Tool {
    let name = "addNote"
    let description = """
        Aggiunge una nota al viaggio attualmente attivo. Usa questo tool quando l'utente vuole
        annotare qualcosa durante il viaggio, come un ristorante, un'attrazione, o un pensiero.
        Richiede un viaggio attivo.
        """

    @Generable
    struct Arguments {
        @Guide(description: "Contenuto della nota da salvare")
        let content: String

        @Guide(description: "Categoria della nota", .anyOf(["ristorante", "attrazione", "hotel", "trasporto", "shopping", "altro"]))
        let category: String?
    }

    nonisolated func call(arguments: Arguments) async throws -> ToolOutput {
        // Check for active trip and add note on main actor
        let result = await MainActor.run { () -> (success: Bool, message: String) in
            guard let activeTrip = CoreDataManager.shared.fetchActiveTrip() else {
                return (false, "Nessun viaggio attivo. Attiva un viaggio dalla lista viaggi prima di aggiungere note.")
            }

            // Get current location if available
            let location = LocationManager.shared.currentLocation

            let note = CoreDataManager.shared.createNote(
                for: activeTrip,
                text: arguments.content,
                latitude: location?.coordinate.latitude,
                longitude: location?.coordinate.longitude
            )

            if let note = note {
                // Update category if provided
                if let category = arguments.category {
                    note.category = category
                    note.isStructured = true
                    CoreDataManager.shared.saveContext()
                }

                let destination = activeTrip.destination ?? "viaggio"
                return (true, "Nota aggiunta al viaggio a \(destination):\n\"\(arguments.content)\"\n\nCategoria: \(arguments.category ?? "altro")")
            } else {
                return (false, "Errore nel salvare la nota. Riprova.")
            }
        }

        return ToolOutput(result.message)
    }
}

// MARK: - Get Trip Info Tool

/// Tool per recuperare informazioni sul viaggio attivo o recente
@available(iOS 26.0, *)
struct GetTripInfoTool: Tool {
    let name = "getTripInfo"
    let description = """
        Recupera informazioni dettagliate sul viaggio attivo o sui viaggi recenti dell'utente.
        Usa questo tool quando l'utente chiede informazioni sul suo viaggio corrente,
        statistiche, o storico viaggi.
        """

    @Generable
    struct Arguments {
        @Guide(description: "Tipo di informazione richiesta", .anyOf(["viaggio_attivo", "statistiche", "ultimi_viaggi"]))
        let infoType: String
    }

    nonisolated func call(arguments: Arguments) async throws -> ToolOutput {
        let result = await MainActor.run { () -> String in
            switch arguments.infoType {
            case "viaggio_attivo":
                return getActiveTripInfo()
            case "statistiche":
                return getStatistics()
            case "ultimi_viaggi":
                return getRecentTrips()
            default:
                return getActiveTripInfo()
            }
        }

        return ToolOutput(result)
    }

    private func getActiveTripInfo() -> String {
        guard let trip = CoreDataManager.shared.fetchActiveTrip() else {
            return "Nessun viaggio attivo al momento. Puoi crearne uno nuovo o attivare un viaggio esistente."
        }

        let photos = CoreDataManager.shared.fetchPhotos(for: trip)
        let notes = CoreDataManager.shared.fetchNotes(for: trip)

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.locale = Locale(identifier: "it_IT")

        let startStr = trip.startDate.map { formatter.string(from: $0) } ?? "N/D"
        let endStr = trip.endDate.map { formatter.string(from: $0) } ?? "N/D"
        let distance = String(format: "%.1f", trip.totalDistance / 1000)

        return """
            Viaggio attivo:
            - Destinazione: \(trip.destination ?? "Non specificata")
            - Date: \(startStr) - \(endStr)
            - Tipo: \(trip.tripTypeRaw ?? "N/D")
            - Distanza percorsa: \(distance) km
            - Foto scattate: \(photos.count)
            - Note registrate: \(notes.count)
            """
    }

    private func getStatistics() -> String {
        let totalTrips = CoreDataManager.shared.getTotalTripsCount()
        let totalPhotos = CoreDataManager.shared.getTotalPhotosCount()
        let totalNotes = CoreDataManager.shared.getTotalNotesCount()
        let totalDistance = CoreDataManager.shared.getTotalDistance()
        let distanceKm = String(format: "%.1f", totalDistance / 1000)

        return """
            Le tue statistiche di viaggio:
            - Viaggi totali: \(totalTrips)
            - Foto scattate: \(totalPhotos)
            - Note registrate: \(totalNotes)
            - Distanza totale: \(distanceKm) km
            """
    }

    private func getRecentTrips() -> String {
        let trips = CoreDataManager.shared.fetchAllTrips()

        if trips.isEmpty {
            return "Non hai ancora registrato nessun viaggio. Inizia creandone uno nuovo!"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "it_IT")

        var result = "I tuoi ultimi viaggi:\n"

        for trip in trips.prefix(5) {
            let destination = trip.destination ?? "Destinazione sconosciuta"
            let startStr = trip.startDate.map { formatter.string(from: $0) } ?? "N/D"
            let status = trip.isActive ? "(Attivo)" : ""
            result += "\n- \(destination) - \(startStr) \(status)"
        }

        return result
    }
}

#endif

// MARK: - Conversation Starters

/// Suggerimenti di conversazione per la chat AI
struct TravelChatStarters {

    /// Starter per funzionalità generali (travel expert)
    static let travelExpertStarters: [ChatStarterItem] = [
        ChatStarterItem(
            icon: "globe.europe.africa.fill",
            title: "Consiglia destinazione",
            prompt: "Suggeriscimi una destinazione perfetta per una vacanza di una settimana a marzo, preferisco il clima mite e la cultura locale"
        ),
        ChatStarterItem(
            icon: "fork.knife",
            title: "Cucina locale",
            prompt: "Quali sono i piatti tipici assolutamente da provare a Napoli?"
        ),
        ChatStarterItem(
            icon: "shield.checkered",
            title: "Consigli sicurezza",
            prompt: "Quali precauzioni di sicurezza dovrei prendere per un viaggio in Marocco?"
        ),
        ChatStarterItem(
            icon: "banknote",
            title: "Budget viaggio",
            prompt: "Aiutami a pianificare un budget per 5 giorni a Barcellona"
        ),
        ChatStarterItem(
            icon: "calendar.badge.clock",
            title: "Quando visitare",
            prompt: "Qual e il periodo migliore dell'anno per visitare il Giappone?"
        )
    ]

    /// Starter per azioni nell'app (tool calling)
    static let actionStarters: [ChatStarterItem] = [
        ChatStarterItem(
            icon: "plus.circle.fill",
            title: "Crea viaggio",
            prompt: "Voglio creare un nuovo viaggio per Roma dal 15 al 20 marzo 2026",
            isAction: true
        ),
        ChatStarterItem(
            icon: "note.text.badge.plus",
            title: "Aggiungi nota",
            prompt: "Aggiungi una nota: Ho trovato un ottimo ristorante di pesce vicino al porto, prezzi onesti",
            isAction: true
        ),
        ChatStarterItem(
            icon: "chart.bar.fill",
            title: "Le mie statistiche",
            prompt: "Mostrami le statistiche dei miei viaggi",
            isAction: true
        )
    ]
}

/// Elemento suggerimento conversazione
struct ChatStarterItem {
    let icon: String
    let title: String
    let prompt: String
    var isAction: Bool = false
}
