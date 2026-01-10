import Foundation

// MARK: - Foundation Model Error

/// Errori specifici per le operazioni con Apple Foundation Models
enum FoundationModelError: LocalizedError {

    /// Il modello non e disponibile
    case modelNotAvailable(reason: UnavailabilityReason)

    /// Una generazione e gia in corso
    case alreadyGenerating

    /// Il contesto ha superato il limite di 4096 token
    case contextLimitExceeded

    /// Lingua non supportata
    case unsupportedLanguage

    /// Contenuto bloccato dai guardrail
    case guardrailViolation

    /// La generazione e fallita
    case generationFailed

    /// Errore nella chiamata di un Tool
    case toolCallFailed(toolName: String, underlyingError: String)

    /// Validazione dell'output fallita
    case validationFailed(reason: String)

    /// Timeout durante la generazione
    case timeout

    /// Sessione non inizializzata
    case sessionNotInitialized

    /// Errore generico
    case unknown(Error)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .modelNotAvailable(let reason):
            return reason.localizedDescription
        case .alreadyGenerating:
            return "Una generazione e gia in corso"
        case .contextLimitExceeded:
            return "La richiesta e troppo lunga"
        case .unsupportedLanguage:
            return "Lingua non supportata"
        case .guardrailViolation:
            return "Richiesta non elaborabile"
        case .generationFailed:
            return "Errore durante la generazione"
        case .toolCallFailed(let toolName, _):
            return "Errore nel recupero dati: \(toolName)"
        case .validationFailed(let reason):
            return "Validazione fallita: \(reason)"
        case .timeout:
            return "Tempo scaduto"
        case .sessionNotInitialized:
            return "Sessione AI non inizializzata"
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    /// Indica se l'errore e recuperabile con un retry
    var isRetryable: Bool {
        switch self {
        case .modelNotAvailable(let reason):
            return reason == .modelNotReady
        case .generationFailed, .toolCallFailed, .timeout, .unknown:
            return true
        case .alreadyGenerating, .contextLimitExceeded, .unsupportedLanguage,
             .guardrailViolation, .validationFailed, .sessionNotInitialized:
            return false
        }
    }
}

// MARK: - Unavailability Reason

/// Motivi per cui il modello non e disponibile
enum UnavailabilityReason: Equatable {
    /// Apple Intelligence non e abilitata nelle impostazioni
    case appleIntelligenceNotEnabled

    /// Il dispositivo non e compatibile (richiede A17 Pro o superiore)
    case deviceNotEligible

    /// Il modello sta ancora scaricando/preparandosi
    case modelNotReady

    /// Motivo sconosciuto
    case unknown

    var localizedDescription: String {
        switch self {
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence e disabilitata"
        case .deviceNotEligible:
            return "Dispositivo non compatibile"
        case .modelNotReady:
            return "Modello in preparazione"
        case .unknown:
            return "Funzione non disponibile"
        }
    }
}

// MARK: - Model Availability Result

/// Risultato della verifica di disponibilita del modello
enum ModelAvailabilityResult {
    /// Il modello e disponibile e pronto all'uso
    case available

    /// Il modello non e disponibile
    case unavailable(title: String, message: String, action: AvailabilityAction?)

    var isAvailable: Bool {
        if case .available = self {
            return true
        }
        return false
    }
}

/// Azione suggerita in caso di indisponibilita
enum AvailabilityAction {
    /// Apri le impostazioni di sistema
    case openSettings

    /// Riprova piu tardi
    case retry
}

// MARK: - User Facing Error

/// Errore formattato per la visualizzazione all'utente
struct UserFacingError {
    /// Titolo dell'errore
    let title: String

    /// Messaggio descrittivo
    let message: String

    /// Indica se l'utente puo riprovare
    let canRetry: Bool

    /// Azione suggerita (opzionale)
    let action: AvailabilityAction?

    init(title: String, message: String, canRetry: Bool, action: AvailabilityAction? = nil) {
        self.title = title
        self.message = message
        self.canRetry = canRetry
        self.action = action
    }

    /// Crea un UserFacingError da un FoundationModelError
    static func from(_ error: FoundationModelError) -> UserFacingError {
        switch error {
        case .modelNotAvailable(let reason):
            return UserFacingError(
                title: reason.localizedDescription,
                message: messageForUnavailability(reason),
                canRetry: reason == .modelNotReady,
                action: reason == .appleIntelligenceNotEnabled ? .openSettings : (reason == .modelNotReady ? .retry : nil)
            )

        case .alreadyGenerating:
            return UserFacingError(
                title: "Generazione in Corso",
                message: "Attendi il completamento della richiesta precedente.",
                canRetry: false
            )

        case .contextLimitExceeded:
            return UserFacingError(
                title: "Richiesta Troppo Lunga",
                message: "Prova con una richiesta piu breve.",
                canRetry: false
            )

        case .unsupportedLanguage:
            return UserFacingError(
                title: "Lingua Non Supportata",
                message: "L'assistente funziona meglio in italiano o inglese.",
                canRetry: false
            )

        case .guardrailViolation:
            return UserFacingError(
                title: "Richiesta Non Elaborabile",
                message: "Prova a riformulare la richiesta.",
                canRetry: false
            )

        case .generationFailed:
            return UserFacingError(
                title: "Errore di Generazione",
                message: "Si e verificato un problema. Riprova.",
                canRetry: true
            )

        case .toolCallFailed:
            return UserFacingError(
                title: "Errore Recupero Dati",
                message: "Impossibile accedere ai dati del viaggio.",
                canRetry: true
            )

        case .validationFailed:
            return UserFacingError(
                title: "Contenuto Non Valido",
                message: "Il contenuto generato non e valido. Riprova.",
                canRetry: true
            )

        case .timeout:
            return UserFacingError(
                title: "Tempo Scaduto",
                message: "La generazione ha impiegato troppo tempo. Riprova.",
                canRetry: true
            )

        case .sessionNotInitialized:
            return UserFacingError(
                title: "Servizio Non Pronto",
                message: "Il servizio AI non e ancora pronto. Riprova tra poco.",
                canRetry: true,
                action: .retry
            )

        case .unknown:
            return UserFacingError(
                title: "Errore",
                message: "Si e verificato un problema. Riprova.",
                canRetry: true
            )
        }
    }

    private static func messageForUnavailability(_ reason: UnavailabilityReason) -> String {
        switch reason {
        case .appleIntelligenceNotEnabled:
            return "Attiva Apple Intelligence nelle Impostazioni per usare le funzioni AI."
        case .deviceNotEligible:
            return "Questa funzione richiede iPhone con chip A17 Pro o successivo."
        case .modelNotReady:
            return "Il modello AI e in fase di download. Riprova tra qualche minuto."
        case .unknown:
            return "Apple Intelligence non e attualmente disponibile."
        }
    }
}

// MARK: - Trip Day Data

/// Dati di un giorno del viaggio per la generazione del journal
struct TripDayData {
    let tripId: UUID
    let date: Date
    let photoCount: Int
    let noteContents: [String]
    let totalDistance: Double
    let placesVisited: [String]

    var hasData: Bool {
        return photoCount > 0 || !noteContents.isEmpty || totalDistance > 0 || !placesVisited.isEmpty
    }
}
