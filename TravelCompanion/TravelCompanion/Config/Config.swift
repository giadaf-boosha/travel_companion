import Foundation

struct Config {

    // MARK: - OpenAI API Configuration

    /// API key per OpenAI - Loaded from Secrets.xcconfig or Info.plist
    /// The key is stored securely and not committed to version control
    static var openAIApiKey: String {
        // First try to get from Info.plist (set via xcconfig)
        if let key = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String,
           !key.isEmpty,
           key != "YOUR_API_KEY_HERE",
           !key.contains("$(") {
            return key
        }

        // Fallback: try to get from environment variable (useful for CI/CD)
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
           !key.isEmpty {
            return key
        }

        // Return empty string if no key found - ChatService will handle the error
        print("⚠️ Warning: OpenAI API key not configured. Please set up Secrets.xcconfig")
        return ""
    }

    /// URL base per le API OpenAI
    static let openAIBaseURL = "https://api.openai.com/v1/chat/completions"

    /// Modello GPT da utilizzare
    static let openAIModel = "gpt-4.1-nano-2025-04-14"

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

    // MARK: - Apple Foundation Models Configuration

    /// Abilita le funzionalita AI con Apple Foundation Models (iOS 26+)
    static let enableFoundationModels = true

    /// Timeout per la generazione AI in secondi
    static let aiGenerationTimeout: TimeInterval = 30.0

    /// Numero massimo di tentativi per le richieste AI
    static let aiMaxRetryAttempts = 3

    /// Delay tra i retry in secondi
    static let aiRetryDelay: TimeInterval = 0.5
}
