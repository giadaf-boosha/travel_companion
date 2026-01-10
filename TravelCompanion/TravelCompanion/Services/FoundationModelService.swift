import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Servizio singleton per la gestione delle funzionalita AI con Apple Foundation Models
@available(iOS 26.0, *)
final class FoundationModelService {

    // MARK: - Singleton

    static let shared = FoundationModelService()

    // MARK: - Properties

    #if canImport(FoundationModels)
    private var session: LanguageModelSession?
    private let model = SystemLanguageModel.default
    #endif

    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 0.5

    /// Indica se il modello sta generando una risposta
    var isGenerating: Bool {
        #if canImport(FoundationModels)
        return session?.isResponding ?? false
        #else
        return false
        #endif
    }

    // MARK: - System Prompts

    private let baseSystemPrompt = """
    Sei Travel Companion, un assistente di viaggio intelligente.

    REGOLE FONDAMENTALI:
    - Rispondi SEMPRE in italiano
    - Usa la TERZA PERSONA per narrativa e journal
    - Sii conciso ma informativo
    - Non inventare informazioni specifiche (prezzi, orari esatti)
    - Suggerisci sempre di verificare informazioni pratiche

    TONO:
    - Professionale ma amichevole
    - Bilanciato tra fatti ed emozioni
    - Mai eccessivamente entusiasta o freddo
    """

    // MARK: - Initialization

    private init() {
        #if DEBUG
        print("FoundationModelService: Initialized")
        #endif
    }

    // MARK: - Availability

    /// Verifica la disponibilita del modello
    func checkAvailability() -> ModelAvailabilityResult {
        #if canImport(FoundationModels)
        switch model.availability {
        case .available:
            return .available

        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable(
                title: "Apple Intelligence Disabilitata",
                message: "Attiva Apple Intelligence nelle Impostazioni per usare le funzioni AI.",
                action: .openSettings
            )

        case .unavailable(.deviceNotEligible):
            return .unavailable(
                title: "Dispositivo Non Supportato",
                message: "Questa funzione richiede iPhone con chip A17 Pro o successivo.",
                action: nil
            )

        case .unavailable(.modelNotReady):
            return .unavailable(
                title: "Modello in Preparazione",
                message: "Il modello AI e in fase di download. Riprova tra qualche minuto.",
                action: .retry
            )

        @unknown default:
            return .unavailable(
                title: "Funzione Non Disponibile",
                message: "Apple Intelligence non e attualmente disponibile.",
                action: nil
            )
        }
        #else
        return .unavailable(
            title: "Non Disponibile",
            message: "Le funzionalita AI richiedono iOS 26 o successivo.",
            action: nil
        )
        #endif
    }

    /// Esegue il prewarm del modello se disponibile
    func prewarmIfAvailable() {
        #if canImport(FoundationModels)
        guard model.availability == .available else { return }

        Task(priority: .utility) {
            do {
                self.session = LanguageModelSession()
                try await self.session?.prewarm(promptPrefix: "Sei Travel Companion")

                #if DEBUG
                print("FoundationModelService: Session prewarmed successfully")
                #endif
            } catch {
                #if DEBUG
                print("FoundationModelService: Prewarm failed - \(error.localizedDescription)")
                #endif
            }
        }
        #endif
    }

    // MARK: - Session Management

    /// Assicura che la sessione sia inizializzata
    private func ensureSession() throws {
        #if canImport(FoundationModels)
        guard model.availability == .available else {
            throw FoundationModelError.modelNotAvailable(reason: mapUnavailabilityReason())
        }

        if session == nil {
            session = LanguageModelSession {
                self.baseSystemPrompt
            }
        }
        #else
        throw FoundationModelError.modelNotAvailable(reason: .unknown)
        #endif
    }

    #if canImport(FoundationModels)
    private func mapUnavailabilityReason() -> UnavailabilityReason {
        switch model.availability {
        case .available:
            return .unknown
        case .unavailable(.appleIntelligenceNotEnabled):
            return .appleIntelligenceNotEnabled
        case .unavailable(.deviceNotEligible):
            return .deviceNotEligible
        case .unavailable(.modelNotReady):
            return .modelNotReady
        @unknown default:
            return .unknown
        }
    }
    #endif

    // MARK: - Retry Logic

    /// Esegue un'operazione con retry automatico
    private func executeWithRetry<T>(
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 1...maxRetryAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Non ritentare errori non recuperabili
                if let fmError = error as? FoundationModelError, !fmError.isRetryable {
                    throw error
                }

                #if DEBUG
                print("FoundationModelService: Attempt \(attempt) failed - \(error.localizedDescription)")
                #endif

                if attempt < maxRetryAttempts {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? FoundationModelError.generationFailed
    }

    // MARK: - Generation Methods

    /// Genera un itinerario di viaggio
    func generateItinerary(
        destination: String,
        days: Int,
        tripType: String,
        travelStyle: String? = nil
    ) async throws -> TravelItinerary {
        #if canImport(FoundationModels)
        guard !isGenerating else {
            throw FoundationModelError.alreadyGenerating
        }

        try ensureSession()

        let styleInfo = travelStyle.map { "Stile preferito: \($0)." } ?? ""
        let longTripNote = days > 7 ? "Genera un overview sintetico per aree/zone invece di dettagli giornalieri completi." : ""

        let prompt = """
        Genera un itinerario di viaggio per:
        - Destinazione: \(destination)
        - Durata: \(days) giorni
        - Tipo viaggio: \(tripType)
        \(styleInfo)
        \(longTripNote)

        Considera: logistica spostamenti, attivita appropriate per il tipo di viaggio.
        """

        return try await executeWithRetry {
            let response = try await self.session!.respond(
                to: prompt,
                generating: TravelItinerary.self
            )

            #if DEBUG
            self.logResponse(response.content)
            #endif

            return response.content
        }
        #else
        throw FoundationModelError.modelNotAvailable(reason: .unknown)
        #endif
    }

    /// Genera una packing list
    func generatePackingList(
        destination: String,
        duration: Int,
        tripType: String,
        season: String
    ) async throws -> GeneratedPackingList {
        #if canImport(FoundationModels)
        guard !isGenerating else {
            throw FoundationModelError.alreadyGenerating
        }

        try ensureSession()

        let prompt = """
        Genera una lista di oggetti da mettere in valigia per:
        - Destinazione: \(destination)
        - Durata: \(duration) giorni
        - Tipo viaggio: \(tripType)
        - Stagione: \(season)

        Includi solo articoli essenziali e pertinenti.
        """

        return try await executeWithRetry {
            let response = try await self.session!.respond(
                to: prompt,
                generating: GeneratedPackingList.self
            )

            #if DEBUG
            self.logResponse(response.content)
            #endif

            return response.content
        }
        #else
        throw FoundationModelError.modelNotAvailable(reason: .unknown)
        #endif
    }

    /// Genera un briefing sulla destinazione
    func generateBriefing(destination: String) async throws -> TripBriefing {
        #if canImport(FoundationModels)
        guard !isGenerating else {
            throw FoundationModelError.alreadyGenerating
        }

        try ensureSession()

        let prompt = """
        Genera un briefing informativo per un viaggio a: \(destination)

        INCLUDI SOLO informazioni stabili e generali:
        - Usi e costumi culturali
        - Frasi utili nella lingua locale
        - Clima tipico per stagione
        - Consigli generali di sicurezza
        - Usanze per le mance
        - Cucina tipica

        ESCLUDI informazioni che possono cambiare (visti, prezzi, restrizioni sanitarie).
        """

        return try await executeWithRetry {
            let response = try await self.session!.respond(
                to: prompt,
                generating: TripBriefing.self
            )

            #if DEBUG
            self.logResponse(response.content)
            #endif

            return response.content
        }
        #else
        throw FoundationModelError.modelNotAvailable(reason: .unknown)
        #endif
    }

    /// Genera un'entry del diario di viaggio
    func generateJournalEntry(tripData: TripDayData) async throws -> JournalEntry {
        #if canImport(FoundationModels)
        guard !isGenerating else {
            throw FoundationModelError.alreadyGenerating
        }

        guard tripData.hasData else {
            throw FoundationModelError.validationFailed(reason: "Nessun dato disponibile per questa giornata")
        }

        try ensureSession()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let dateString = dateFormatter.string(from: tripData.date)

        let notesContext = tripData.noteContents.isEmpty
            ? "Nessuna nota"
            : tripData.noteContents.joined(separator: "; ")

        let placesContext = tripData.placesVisited.isEmpty
            ? "Non specificati"
            : tripData.placesVisited.joined(separator: ", ")

        let distanceKm = tripData.totalDistance / 1000

        let prompt = """
        Genera un'entry di diario di viaggio per la giornata del \(dateString).

        DATI DELLA GIORNATA:
        - Foto scattate: \(tripData.photoCount)
        - Note registrate: \(notesContext)
        - Distanza percorsa: \(String(format: "%.1f", distanceKm)) km
        - Luoghi visitati: \(placesContext)

        STILE:
        - Scrivi in TERZA PERSONA
        - Tono bilanciato tra fatti ed emozioni
        - 150-250 parole per il racconto
        """

        return try await executeWithRetry {
            let response = try await self.session!.respond(
                to: prompt,
                generating: JournalEntry.self
            )

            #if DEBUG
            self.logResponse(response.content)
            #endif

            return response.content
        }
        #else
        throw FoundationModelError.modelNotAvailable(reason: .unknown)
        #endif
    }

    /// Struttura una nota da testo libero
    func structureNote(rawText: String) async throws -> StructuredNote {
        #if canImport(FoundationModels)
        guard !isGenerating else {
            throw FoundationModelError.alreadyGenerating
        }

        let sanitizedText = sanitizeInput(rawText)
        guard !sanitizedText.isEmpty else {
            throw FoundationModelError.validationFailed(reason: "Testo vuoto")
        }

        try ensureSession()

        let prompt = """
        Analizza e struttura la seguente nota di viaggio:

        "\(sanitizedText)"

        Estrai: categoria, nome luogo (se presente), valutazione implicita (1-5), costo (se menzionato), riassunto pulito, tag pertinenti.
        """

        return try await executeWithRetry {
            let response = try await self.session!.respond(
                to: prompt,
                generating: StructuredNote.self
            )

            #if DEBUG
            self.logResponse(response.content)
            #endif

            return response.content
        }
        #else
        throw FoundationModelError.modelNotAvailable(reason: .unknown)
        #endif
    }

    /// Genera un riassunto completo del viaggio
    func generateTripSummary(
        destination: String,
        duration: Int,
        photoCount: Int,
        noteCount: Int,
        totalDistance: Double,
        highlights: [String],
        variant: SummaryVariant = .standard
    ) async throws -> TripSummaryGenerated {
        #if canImport(FoundationModels)
        guard !isGenerating else {
            throw FoundationModelError.alreadyGenerating
        }

        try ensureSession()

        let distanceKm = totalDistance / 1000
        let highlightsText = highlights.isEmpty
            ? "Non specificati"
            : highlights.joined(separator: "; ")

        let variantModifier = variant.promptModifier

        let prompt = """
        Genera un riassunto narrativo completo per il viaggio completato.

        DATI DEL VIAGGIO:
        - Destinazione: \(destination)
        - Durata: \(duration) giorni
        - Foto scattate: \(photoCount)
        - Note registrate: \(noteCount)
        - Distanza totale: \(String(format: "%.1f", distanceKm)) km
        - Momenti salienti: \(highlightsText)

        STILE:
        - Scrivi in TERZA PERSONA
        - Tono evocativo ma non eccessivo
        \(variantModifier)
        """

        return try await executeWithRetry {
            let response = try await self.session!.respond(
                to: prompt,
                generating: TripSummaryGenerated.self
            )

            #if DEBUG
            self.logResponse(response.content)
            #endif

            return response.content
        }
        #else
        throw FoundationModelError.modelNotAvailable(reason: .unknown)
        #endif
    }

    // MARK: - Input Validation

    /// Sanifica l'input utente
    private func sanitizeInput(_ input: String) -> String {
        // Rimuovi caratteri di controllo
        let cleaned = input.components(separatedBy: .controlCharacters).joined()

        // Limita lunghezza
        let maxLength = 2000
        let truncated = String(cleaned.prefix(maxLength))

        return truncated.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Error Handling

    /// Gestisce un errore di generazione e restituisce un UserFacingError
    func handleGenerationError(_ error: Error) -> UserFacingError {
        #if canImport(FoundationModels)
        // Errori specifici di LanguageModelSession
        if let generationError = error as? LanguageModelSession.GenerationError {
            switch generationError {
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
            @unknown default:
                return UserFacingError(
                    title: "Errore di Generazione",
                    message: "Si e verificato un problema. Riprova.",
                    canRetry: true
                )
            }
        }

        // Errori di chiamata Tool
        if let toolError = error as? LanguageModelSession.ToolCallError {
            #if DEBUG
            print("Tool error: \(toolError.tool) - \(toolError.underlyingError)")
            #endif
            return UserFacingError(
                title: "Errore Recupero Dati",
                message: "Impossibile accedere ai dati del viaggio.",
                canRetry: true
            )
        }
        #endif

        // Errori FoundationModelError
        if let fmError = error as? FoundationModelError {
            return UserFacingError.from(fmError)
        }

        // Errore generico
        return UserFacingError(
            title: "Errore",
            message: "Si e verificato un problema. Riprova.",
            canRetry: true
        )
    }

    // MARK: - Debug Logging

    #if DEBUG
    private func logResponse<T>(_ response: T) {
        print("=== AI RESPONSE ===")
        print("\(response)")
        print("===================")
    }
    #endif

    // MARK: - Reset

    /// Resetta la sessione corrente
    func resetSession() {
        #if canImport(FoundationModels)
        session = nil
        #if DEBUG
        print("FoundationModelService: Session reset")
        #endif
        #endif
    }
}

// MARK: - Rate Limiter

/// Rate limiter per prevenire abusi
final class AIRateLimiter {
    private var requestTimestamps: [Date] = []
    private let maxRequestsPerMinute: Int
    private let lock = NSLock()

    init(maxRequestsPerMinute: Int = 10) {
        self.maxRequestsPerMinute = maxRequestsPerMinute
    }

    func canMakeRequest() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let oneMinuteAgo = Date().addingTimeInterval(-60)
        requestTimestamps = requestTimestamps.filter { $0 > oneMinuteAgo }
        return requestTimestamps.count < maxRequestsPerMinute
    }

    func recordRequest() {
        lock.lock()
        defer { lock.unlock() }

        requestTimestamps.append(Date())
    }
}
