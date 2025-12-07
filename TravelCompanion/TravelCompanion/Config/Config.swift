import Foundation

struct Config {

    // MARK: - OpenAI API Configuration

    /// API key per OpenAI - IMPORTANTE: sostituire con la propria chiave
    /// Non committare mai questo file con la chiave reale nel repository
    static let openAIApiKey = "YOUR_OPENAI_API_KEY"

    /// URL base per le API OpenAI
    static let openAIBaseURL = "https://api.openai.com/v1/chat/completions"

    /// Modello GPT da utilizzare
    static let openAIModel = "gpt-5-nano-2025-08-07"

    /// Timeout per le richieste API in secondi
    static let apiTimeout: TimeInterval = 30.0

    // MARK: - App Configuration

    /// Nome dell'app
    static let appName = "Travel Companion"

    /// Versione minima iOS supportata
    static let minimumIOSVersion = "17.0"

    /// Bundle identifier
    static let bundleIdentifier = "com.unibo.lam.TravelCompanion"

    // MARK: - Core Data Configuration

    /// Nome del modello Core Data
    static let coreDataModelName = "TravelCompanion"

    // MARK: - Location Configuration

    /// Precisione GPS desiderata
    static let desiredLocationAccuracy: Double = 10.0 // metri

    /// Filtro distanza per aggiornamenti location
    static let locationDistanceFilter: Double = 10.0 // metri

    // MARK: - Debug Configuration

    #if DEBUG
    static let isDebugMode = true
    #else
    static let isDebugMode = false
    #endif

    /// Abilita log dettagliati
    static let verboseLogging = isDebugMode

    // MARK: - Feature Flags

    /// Abilita funzionalità chatbot AI
    static let enableAIChatbot = true

    /// Abilita geofencing
    static let enableGeofencing = true

    /// Abilita notifiche POI
    static let enablePOINotifications = true
}
