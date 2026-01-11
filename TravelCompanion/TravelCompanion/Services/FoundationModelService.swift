import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Servizio singleton per la gestione delle funzionalita AI con Apple Foundation Models
final class FoundationModelService {

    // MARK: - Singleton

    static let shared = FoundationModelService()

    // MARK: - Properties

    /// Session helper stored as Any to avoid availability issues at property declaration
    private var _sessionHelper: Any?

    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 0.5

    /// Indica se il modello sta generando una risposta
    var isGenerating: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return (sessionHelper as? SessionHelper)?.isResponding ?? false
        }
        #endif
        return false
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

    // MARK: - Session Helper (iOS 26+)

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private final class SessionHelper {
        var session: LanguageModelSession?
        let model = SystemLanguageModel.default

        var isResponding: Bool {
            return session?.isResponding ?? false
        }

        func ensureSession(systemPrompt: String) throws {
            guard model.availability == .available else {
                throw FoundationModelError.modelNotAvailable(reason: mapUnavailabilityReason())
            }

            if session == nil {
                session = LanguageModelSession {
                    systemPrompt
                }
            }
        }

        func mapUnavailabilityReason() -> UnavailabilityReason {
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

        func checkAvailability() -> ModelAvailabilityResult {
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
        }

        func prewarm() async {
            guard model.availability == .available else { return }

            // Initialize session without prewarm as API may vary
            session = LanguageModelSession()

            #if DEBUG
            print("FoundationModelService: Session initialized")
            #endif
        }

        func reset() {
            session = nil
        }
    }

    @available(iOS 26.0, *)
    private var sessionHelper: SessionHelper {
        if _sessionHelper == nil {
            _sessionHelper = SessionHelper()
        }
        return _sessionHelper as! SessionHelper
    }
    #endif

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
        if #available(iOS 26.0, *) {
            return sessionHelper.checkAvailability()
        }
        #endif
        return .unavailable(
            title: "Non Disponibile",
            message: "Le funzionalita AI richiedono iOS 26 o successivo.",
            action: nil
        )
    }

    /// Esegue il prewarm del modello se disponibile
    func prewarmIfAvailable() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            Task(priority: .utility) {
                await self.sessionHelper.prewarm()
            }
        }
        #endif
    }

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
    ) async throws -> TravelItineraryData {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard !isGenerating else {
                throw FoundationModelError.alreadyGenerating
            }

            try sessionHelper.ensureSession(systemPrompt: baseSystemPrompt)

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
                let response = try await self.sessionHelper.session!.respond(
                    to: prompt,
                    generating: TravelItinerary.self
                )

                #if DEBUG
                self.logResponse(response.content)
                #endif

                // Convert to Data structure for compatibility
                let itinerary = response.content
                return TravelItineraryData(
                    destination: itinerary.destination,
                    totalDays: itinerary.totalDays,
                    travelStyle: itinerary.travelStyle,
                    dailyPlans: itinerary.dailyPlans.map { plan in
                        DayPlanData(
                            dayNumber: plan.dayNumber,
                            theme: plan.theme,
                            morningActivity: plan.morningActivity,
                            lunchArea: plan.lunchArea,
                            afternoonActivity: plan.afternoonActivity,
                            dinnerArea: plan.dinnerArea,
                            eveningActivity: plan.eveningActivity,
                            transportNotes: plan.transportNotes
                        )
                    },
                    generalTips: itinerary.generalTips
                )
            }
        }
        #endif
        throw FoundationModelError.modelNotAvailable(reason: .unknown)
    }

    /// Genera una packing list
    func generatePackingList(
        destination: String,
        duration: Int,
        tripType: String,
        season: String
    ) async throws -> GeneratedPackingListData {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard !isGenerating else {
                throw FoundationModelError.alreadyGenerating
            }

            try sessionHelper.ensureSession(systemPrompt: baseSystemPrompt)

            let prompt = """
            Genera una lista di oggetti da mettere in valigia per:
            - Destinazione: \(destination)
            - Durata: \(duration) giorni
            - Tipo viaggio: \(tripType)
            - Stagione: \(season)

            Includi solo articoli essenziali e pertinenti.
            """

            return try await executeWithRetry {
                let response = try await self.sessionHelper.session!.respond(
                    to: prompt,
                    generating: GeneratedPackingList.self
                )

                #if DEBUG
                self.logResponse(response.content)
                #endif

                let packingList = response.content
                return GeneratedPackingListData(
                    documents: packingList.documents,
                    clothing: packingList.clothing,
                    toiletries: packingList.toiletries,
                    electronics: packingList.electronics,
                    specialItems: packingList.specialItems,
                    healthKit: packingList.healthKit
                )
            }
        }
        #endif
        throw FoundationModelError.modelNotAvailable(reason: .unknown)
    }

    /// Genera un briefing sulla destinazione
    func generateBriefing(destination: String) async throws -> TripBriefingData {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard !isGenerating else {
                throw FoundationModelError.alreadyGenerating
            }

            try sessionHelper.ensureSession(systemPrompt: baseSystemPrompt)

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
                let response = try await self.sessionHelper.session!.respond(
                    to: prompt,
                    generating: GeneratedTripBriefing.self
                )

                #if DEBUG
                self.logResponse(response.content)
                #endif

                let briefing = response.content
                return TripBriefingData(
                    destination: briefing.destination,
                    quickFacts: QuickFactsData(
                        language: briefing.quickFacts.language,
                        currency: briefing.quickFacts.currency,
                        timeZone: briefing.quickFacts.timeZone,
                        electricalOutlet: briefing.quickFacts.electricalOutlet
                    ),
                    culturalTips: briefing.culturalTips,
                    usefulPhrases: briefing.usefulPhrases.map {
                        LocalPhraseData(italian: $0.italian, local: $0.local, pronunciation: $0.pronunciation)
                    },
                    climateInfo: briefing.climateInfo,
                    foodCulture: briefing.foodCulture,
                    safetyNotes: briefing.safetyNotes
                )
            }
        }
        #endif
        throw FoundationModelError.modelNotAvailable(reason: .unknown)
    }

    /// Genera un'entry del diario di viaggio
    func generateJournalEntry(tripData: TripDayData) async throws -> JournalEntryData {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard !isGenerating else {
                throw FoundationModelError.alreadyGenerating
            }

            guard tripData.hasData else {
                throw FoundationModelError.validationFailed(reason: "Nessun dato disponibile per questa giornata")
            }

            try sessionHelper.ensureSession(systemPrompt: baseSystemPrompt)

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
                let response = try await self.sessionHelper.session!.respond(
                    to: prompt,
                    generating: JournalEntry.self
                )

                #if DEBUG
                self.logResponse(response.content)
                #endif

                let entry = response.content
                return JournalEntryData(
                    title: entry.title,
                    date: entry.date,
                    narrative: entry.narrative,
                    highlight: entry.highlight,
                    statsNarrative: entry.statsNarrative
                )
            }
        }
        #endif
        throw FoundationModelError.modelNotAvailable(reason: .unknown)
    }

    /// Struttura una nota da testo libero
    func structureNote(rawText: String) async throws -> StructuredNoteData {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard !isGenerating else {
                throw FoundationModelError.alreadyGenerating
            }

            let sanitizedText = sanitizeInput(rawText)
            guard !sanitizedText.isEmpty else {
                throw FoundationModelError.validationFailed(reason: "Testo vuoto")
            }

            try sessionHelper.ensureSession(systemPrompt: baseSystemPrompt)

            let prompt = """
            Analizza e struttura la seguente nota di viaggio:

            "\(sanitizedText)"

            Estrai: categoria, nome luogo (se presente), valutazione implicita (1-5), costo (se menzionato), riassunto pulito, tag pertinenti.
            """

            return try await executeWithRetry {
                let response = try await self.sessionHelper.session!.respond(
                    to: prompt,
                    generating: StructuredNote.self
                )

                #if DEBUG
                self.logResponse(response.content)
                #endif

                let note = response.content
                return StructuredNoteData(
                    category: note.category,
                    placeName: note.placeName,
                    rating: note.rating,
                    cost: note.cost,
                    summary: note.summary,
                    tags: note.tags
                )
            }
        }
        #endif
        throw FoundationModelError.modelNotAvailable(reason: .unknown)
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
    ) async throws -> TripSummaryData {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard !isGenerating else {
                throw FoundationModelError.alreadyGenerating
            }

            try sessionHelper.ensureSession(systemPrompt: baseSystemPrompt)

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
                let response = try await self.sessionHelper.session!.respond(
                    to: prompt,
                    generating: TripSummaryGenerated.self
                )

                #if DEBUG
                self.logResponse(response.content)
                #endif

                let summary = response.content
                return TripSummaryData(
                    title: summary.title,
                    tagline: summary.tagline,
                    narrative: summary.narrative,
                    highlights: summary.highlights,
                    statsNarrative: summary.statsNarrative,
                    nextTripSuggestion: summary.nextTripSuggestion
                )
            }
        }
        #endif
        throw FoundationModelError.modelNotAvailable(reason: .unknown)
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
        if #available(iOS 26.0, *) {
            // Errori specifici di LanguageModelSession
            // Note: Error types may vary between SDK versions, using generic handling
            if error is LanguageModelSession.GenerationError {
                return UserFacingError(
                    title: "Errore di Generazione",
                    message: "Si e verificato un problema con la generazione. Riprova.",
                    canRetry: true
                )
            }
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
        if #available(iOS 26.0, *) {
            sessionHelper.reset()
            #if DEBUG
            print("FoundationModelService: Session reset")
            #endif
        }
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
