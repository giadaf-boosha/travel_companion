//
//  Constants.swift
//  TravelCompanion
//
//  Contiene tutte le costanti dell'applicazione organizzate per categoria.
//  Centralizza valori statici per evitare magic strings/numbers sparsi nel codice.
//

import Foundation
import CoreLocation

// MARK: - Constants Container

/// Struttura contenitore per tutte le costanti dell'applicazione.
/// Organizzata in sotto-strutture tematiche per una migliore manutenibilita.
struct Constants {

    // MARK: - Identificatori Segue (Storyboard)

    /// Identificatori per le transizioni tra view controller (Storyboard Segues)
    /// - Note: Usati in prepareForSegue e performSegue
    struct Segue {
        /// Transizione verso la creazione di un nuovo viaggio
        static let showNewTrip = "showNewTrip"
        /// Transizione verso il viaggio attivo con tracking GPS
        static let showActiveTrip = "showActiveTrip"
        /// Transizione verso i dettagli di un viaggio
        static let showTripDetail = "showTripDetail"
        /// Transizione verso la mappa del viaggio
        static let showTripMap = "showTripMap"
        /// Transizione verso le impostazioni
        static let showSettings = "showSettings"
        /// Transizione verso la gestione geofence
        static let showGeofence = "showGeofence"
        /// Transizione verso il dettaglio di una foto
        static let showPhotoDetail = "showPhotoDetail"
        /// Unwind segue per tornare alla Home
        static let unwindToHome = "unwindToHome"
        /// Unwind segue per tornare alla lista viaggi
        static let unwindToTripList = "unwindToTripList"
    }

    // MARK: - Identificatori Celle (TableView/CollectionView)

    /// Identificatori per il riuso delle celle nelle TableView e CollectionView
    struct Cell {
        /// Cella per visualizzare un viaggio nella lista
        static let tripCell = "TripCell"
        /// Cella per visualizzare una foto nella galleria
        static let photoCell = "PhotoCell"
        /// Cella per visualizzare una nota
        static let noteCell = "NoteCell"
        /// Cella per i messaggi utente nella chat
        static let chatUserCell = "ChatUserCell"
        /// Cella per i messaggi dell'assistente nella chat
        static let chatAssistantCell = "ChatAssistantCell"
        /// Cella per le zone geofence
        static let geofenceZoneCell = "GeofenceZoneCell"
        /// Cella generica per le impostazioni
        static let settingsCell = "SettingsCell"
    }

    // MARK: - Chiavi UserDefaults

    /// Chiavi per la persistenza delle preferenze utente in UserDefaults
    struct UserDefaultsKeys {
        /// Flag: notifiche abilitate globalmente
        static let notificationsEnabled = "notificationsEnabled"
        /// Flag: notifiche POI (punti di interesse) vicini
        static let poiNotificationsEnabled = "poiNotificationsEnabled"
        /// Flag: promemoria per registrare viaggi
        static let reminderNotificationsEnabled = "reminderNotificationsEnabled"
        /// Intervallo in giorni tra i promemoria
        static let reminderIntervalDays = "reminderIntervalDays"
        /// Data dell'ultimo viaggio registrato
        static let lastTripDate = "lastTripDate"
        /// Flag: onboarding completato
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        /// Tipo di mappa selezionato (standard, satellite, ibrida)
        static let selectedMapType = "selectedMapType"
    }

    // MARK: - Nomi Notifiche (NotificationCenter)

    /// Nomi delle notifiche per la comunicazione tra componenti tramite NotificationCenter
    struct NotificationName {
        // --- Eventi Viaggio ---
        /// Notifica: nuovo viaggio creato
        static let tripCreated = Notification.Name("tripCreated")
        /// Notifica: viaggio aggiornato
        static let tripUpdated = Notification.Name("tripUpdated")
        /// Notifica: viaggio eliminato
        static let tripDeleted = Notification.Name("tripDeleted")

        // --- Eventi Localizzazione ---
        /// Notifica: posizione GPS aggiornata
        static let locationUpdated = Notification.Name("locationUpdated")
        /// Notifica: tracking GPS avviato
        static let trackingStarted = Notification.Name("trackingStarted")
        /// Notifica: tracking GPS fermato
        static let trackingStopped = Notification.Name("trackingStopped")

        // --- Eventi Geofence ---
        /// Notifica: utente entrato in zona geofence
        static let geofenceEntered = Notification.Name("geofenceEntered")
        /// Notifica: utente uscito da zona geofence
        static let geofenceExited = Notification.Name("geofenceExited")

        // --- Eventi Media ---
        /// Notifica: nuova foto aggiunta al viaggio
        static let photoAdded = Notification.Name("photoAdded")
        /// Notifica: nuova nota aggiunta al viaggio
        static let noteAdded = Notification.Name("noteAdded")

        // --- Eventi Funzionalita AI ---
        /// Notifica: itinerario AI generato
        static let itineraryGenerated = Notification.Name("itineraryGenerated")
        /// Notifica: packing list AI generata
        static let packingListGenerated = Notification.Name("packingListGenerated")
        /// Notifica: briefing destinazione AI generato
        static let briefingGenerated = Notification.Name("briefingGenerated")
    }

    // MARK: - Identificatori Notifiche Locali

    /// Identificatori per le notifiche locali (UNUserNotification)
    /// - Note: Usati per programmare e cancellare notifiche specifiche
    struct LocalNotification {
        /// Prefisso per notifiche POI vicini (seguito da UUID)
        static let poiNearbyPrefix = "poi_nearby_"
        /// Identificatore per il promemoria di logging viaggio
        static let loggingReminder = "logging_reminder"
        /// Prefisso per notifiche entrata geofence
        static let geofenceEnter = "geofence_enter_"
        /// Prefisso per notifiche uscita geofence
        static let geofenceExit = "geofence_exit_"
    }

    // MARK: - Valori di Default

    /// Valori predefiniti per le impostazioni e comportamenti dell'app
    struct Defaults {
        // --- Geofencing ---
        /// Raggio minimo geofence in metri
        static let geofenceRadiusMin: Double = 50.0
        /// Raggio massimo geofence in metri
        static let geofenceRadiusMax: Double = 500.0
        /// Raggio predefinito geofence in metri
        static let geofenceRadiusDefault: Double = 100.0
        /// Intervallo predefinito tra promemoria (giorni)
        static let reminderIntervalDays: Int = 7
        /// Numero massimo di zone geofence monitorabili (limite iOS: 20)
        static let maxGeofenceZones: Int = 20

        // --- Localizzazione ---
        /// Intervallo aggiornamento posizione in secondi
        static let locationUpdateInterval: TimeInterval = 5.0
        /// Filtro distanza per aggiornamenti GPS (metri)
        static let locationDistanceFilter: CLLocationDistance = 10.0
        /// Raggio di ricerca per POI vicini (metri)
        static let poiSearchRadius: CLLocationDistance = 500.0

        // --- Media ---
        /// Qualita compressione JPEG (0.0 - 1.0)
        static let photoCompressionQuality: CGFloat = 0.7
        /// Dimensione thumbnail in pixel
        static let thumbnailSize: CGSize = CGSize(width: 150, height: 150)

        // --- Chat/AI ---
        /// Token massimi per risposta chat
        static let chatMaxTokens: Int = 500
        /// Temperatura creativita LLM (0.0 = deterministico, 1.0 = creativo)
        static let chatTemperature: Double = 0.7
    }

    // MARK: - Formati Data

    /// Stringhe di formato per DateFormatter
    /// - Note: Compatibili con il locale italiano
    struct DateFormat {
        /// Formato visualizzazione standard: "07 dic 2025"
        static let display = "dd MMM yyyy"
        /// Formato con ora: "07 dic 2025 14:30"
        static let displayWithTime = "dd MMM yyyy HH:mm"
        /// Solo ora: "14:30"
        static let time = "HH:mm"
        /// Mese e anno: "dicembre 2025"
        static let monthYear = "MMMM yyyy"
        /// Giorno e mese: "07 dic"
        static let dayMonth = "dd MMM"
        /// Formato ISO 8601 per API/storage
        static let iso8601 = "yyyy-MM-dd'T'HH:mm:ssZ"
    }

    // MARK: - Configurazione Mappa

    /// Costanti per la configurazione di MapKit
    struct Map {
        /// Span predefinito per la regione mappa (gradi lat/lon)
        static let defaultSpan: Double = 0.01
        /// Spessore linea del percorso in punti
        static let routeLineWidth: CGFloat = 4.0
        /// Raggio per effetto heatmap
        static let heatmapRadius: CGFloat = 40.0
    }

    // MARK: - Nomi Colori (Asset Catalog)

    /// Nomi dei colori definiti nell'Asset Catalog
    /// - Note: Usare con UIColor(named:) per supporto dark mode
    struct ColorName {
        /// Colore primario del brand
        static let primary = "PrimaryColor"
        /// Colore secondario
        static let secondary = "SecondaryColor"
        /// Colore di accento
        static let accent = "AccentColor"
        /// Colore per viaggi locali
        static let localTrip = "LocalTripColor"
        /// Colore per gite giornaliere
        static let dayTrip = "DayTripColor"
        /// Colore per viaggi multi-giorno
        static let multiDayTrip = "MultiDayTripColor"
        /// Sfondo messaggi utente nella chat
        static let userMessage = "UserMessageColor"
        /// Sfondo messaggi assistente nella chat
        static let assistantMessage = "AssistantMessageColor"
    }

    // MARK: - Durate Animazioni

    /// Durate standard per le animazioni UIKit
    struct Animation {
        /// Animazione breve (es. feedback tap): 0.2s
        static let shortDuration: TimeInterval = 0.2
        /// Animazione standard (es. transizioni): 0.3s
        static let standardDuration: TimeInterval = 0.3
        /// Animazione lunga (es. modali): 0.5s
        static let longDuration: TimeInterval = 0.5
    }

    // MARK: - Validazione Input

    /// Limiti per la validazione degli input utente
    struct Validation {
        /// Lunghezza minima nome destinazione
        static let minDestinationLength = 2
        /// Lunghezza massima nome destinazione
        static let maxDestinationLength = 100
        /// Lunghezza massima contenuto nota
        static let maxNoteLength = 1000
        /// Lunghezza massima messaggio chat
        static let maxChatMessageLength = 500
    }

    // MARK: - Configurazione AI Assistant

    /// Costanti per le funzionalita AI (Apple Foundation Models)
    struct AIAssistant {
        /// Numero massimo di tentativi in caso di errore recuperabile
        static let maxRetryAttempts = 3
        /// Delay tra tentativi (secondi)
        static let retryDelay: TimeInterval = 0.5
        /// Timeout per generazione AI (secondi)
        static let generationTimeout: TimeInterval = 30.0
        /// Lunghezza massima input utente (caratteri)
        static let maxInputLength = 2000
        /// Limite token contesto LLM
        static let tokenLimit = 4096

        // --- Categorie Packing List ---

        /// Identificatori delle categorie per la packing list
        static let packingCategories = [
            "documents",
            "clothing",
            "toiletries",
            "electronics",
            "specialItems",
            "healthKit"
        ]

        /// Nomi visualizzazione categorie packing (italiano)
        static let packingCategoryDisplayNames: [String: String] = [
            "documents": "Documenti",
            "clothing": "Abbigliamento",
            "toiletries": "Igiene Personale",
            "electronics": "Elettronica",
            "specialItems": "Articoli Speciali",
            "healthKit": "Kit Medico"
        ]
    }
}
