import Foundation

/// Errori del servizio Chat
enum ChatServiceError: LocalizedError {
    case invalidURL
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case decodingError
    case rateLimitExceeded
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL non valido"
        case .invalidAPIKey:
            return "API key non valida. Configura la chiave in Config.swift"
        case .networkError(let error):
            return "Errore di rete: \(error.localizedDescription)"
        case .invalidResponse:
            return "Risposta non valida dal server"
        case .apiError(let message):
            return "Errore API: \(message)"
        case .decodingError:
            return "Errore nel parsing della risposta"
        case .rateLimitExceeded:
            return "Limite richieste superato. Riprova tra qualche minuto."
        case .serverError(let code):
            return "Errore server (codice \(code))"
        }
    }
}

/// Servizio per la comunicazione con l'API OpenAI
final class ChatService {

    // MARK: - Properties

    private let apiKey: String
    private let baseURL: String
    private let model: String
    private let session: URLSession

    /// Cronologia della conversazione
    private(set) var conversationHistory: [ChatMessage] = []

    /// Indica se una richiesta è in corso
    private(set) var isLoading: Bool = false

    // MARK: - Initialization

    init(
        apiKey: String = Config.openAIApiKey,
        baseURL: String = Config.openAIBaseURL,
        model: String = Config.openAIModel
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Config.apiTimeout
        config.timeoutIntervalForResource = Config.apiTimeout * 2
        self.session = URLSession(configuration: config)

        setupSystemPrompt()
    }

    // MARK: - System Prompt

    /// Configura il prompt di sistema per l'assistente
    private func setupSystemPrompt() {
        let systemPrompt = """
        Sei un assistente di viaggio esperto e amichevole chiamato Travel Companion.

        Il tuo compito è aiutare gli utenti a:
        - Pianificare viaggi e suggerire destinazioni interessanti
        - Creare itinerari giornalieri dettagliati
        - Fornire informazioni su attrazioni, ristoranti e trasporti
        - Dare consigli pratici su meteo, abbigliamento e documenti necessari

        Linee guida:
        - Rispondi sempre in italiano in modo conciso e utile
        - Sii entusiasta ma professionale
        - Fornisci informazioni pratiche e actionable
        - Se non conosci qualcosa, ammettilo onestamente
        - Quando suggerisci luoghi, includi dettagli utili come orari tipici di apertura
        - Per gli itinerari, organizza le attività in modo logico considerando distanze e tempi

        Non inventare informazioni specifiche come prezzi esatti o orari che potrebbero cambiare.
        Suggerisci sempre di verificare le informazioni prima del viaggio.
        """

        conversationHistory.append(ChatMessage.systemMessage(systemPrompt))
    }

    // MARK: - Public Methods

    /// Invia un messaggio e riceve una risposta
    func sendMessage(_ message: String, completion: @escaping (Result<String, ChatServiceError>) -> Void) {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.failure(.invalidResponse))
            return
        }

        guard apiKey != "YOUR_OPENAI_API_KEY" && !apiKey.isEmpty else {
            completion(.failure(.invalidAPIKey))
            return
        }

        guard let url = URL(string: baseURL) else {
            completion(.failure(.invalidURL))
            return
        }

        isLoading = true

        // Aggiungi il messaggio dell'utente alla cronologia
        let userMessage = ChatMessage.userMessage(message)
        conversationHistory.append(userMessage)

        // Prepara la richiesta
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": model,
            "messages": conversationHistory.apiFormat,
            "max_tokens": Constants.Defaults.chatMaxTokens,
            "temperature": Constants.Defaults.chatTemperature
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            isLoading = false
            // Rimuovi il messaggio utente se la richiesta fallisce
            conversationHistory.removeLast()
            completion(.failure(.networkError(error)))
            return
        }

        // Esegui la richiesta
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.handleResponse(data: data, response: response, error: error, completion: completion)
            }
        }

        task.resume()
    }

    /// Gestisce la risposta dell'API
    private func handleResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping (Result<String, ChatServiceError>) -> Void
    ) {
        // Gestisci errori di rete
        if let error = error {
            // Rimuovi l'ultimo messaggio utente in caso di errore
            if !conversationHistory.isEmpty && conversationHistory.last?.role == .user {
                conversationHistory.removeLast()
            }
            completion(.failure(.networkError(error)))
            return
        }

        // Verifica lo status code HTTP
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200...299:
                break // Successo
            case 429:
                if !conversationHistory.isEmpty && conversationHistory.last?.role == .user {
                    conversationHistory.removeLast()
                }
                completion(.failure(.rateLimitExceeded))
                return
            case 401:
                if !conversationHistory.isEmpty && conversationHistory.last?.role == .user {
                    conversationHistory.removeLast()
                }
                completion(.failure(.invalidAPIKey))
                return
            default:
                if !conversationHistory.isEmpty && conversationHistory.last?.role == .user {
                    conversationHistory.removeLast()
                }
                completion(.failure(.serverError(httpResponse.statusCode)))
                return
            }
        }

        // Verifica che ci siano dati
        guard let data = data else {
            if !conversationHistory.isEmpty && conversationHistory.last?.role == .user {
                conversationHistory.removeLast()
            }
            completion(.failure(.invalidResponse))
            return
        }

        // Parsing della risposta
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw ChatServiceError.decodingError
            }

            // Verifica errori nell'API
            if let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                if !conversationHistory.isEmpty && conversationHistory.last?.role == .user {
                    conversationHistory.removeLast()
                }
                completion(.failure(.apiError(message)))
                return
            }

            // Estrai il messaggio dalla risposta
            guard let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                if !conversationHistory.isEmpty && conversationHistory.last?.role == .user {
                    conversationHistory.removeLast()
                }
                completion(.failure(.decodingError))
                return
            }

            // Aggiungi la risposta alla cronologia
            let assistantMessage = ChatMessage.assistantMessage(content)
            conversationHistory.append(assistantMessage)

            if Config.verboseLogging {
                print("ChatService: Received response (\(content.count) chars)")
            }

            completion(.success(content))

        } catch {
            if !conversationHistory.isEmpty && conversationHistory.last?.role == .user {
                conversationHistory.removeLast()
            }
            completion(.failure(.decodingError))
        }
    }

    // MARK: - Conversation Management

    /// Pulisce la cronologia della conversazione
    func clearConversation() {
        conversationHistory.removeAll()
        setupSystemPrompt()

        if Config.verboseLogging {
            print("ChatService: Conversation cleared")
        }
    }

    /// Restituisce i messaggi visibili (esclusi i messaggi di sistema)
    func getVisibleMessages() -> [ChatMessage] {
        return conversationHistory.visibleMessages
    }

    /// Restituisce il numero di messaggi nella conversazione
    var messageCount: Int {
        return conversationHistory.visibleMessages.count
    }

    // MARK: - Convenience Methods

    /// Richiede suggerimenti per una destinazione
    func requestDestinationSuggestions(
        preferences: String? = nil,
        completion: @escaping (Result<String, ChatServiceError>) -> Void
    ) {
        var prompt = "Suggeriscimi alcune destinazioni di viaggio interessanti"
        if let preferences = preferences, !preferences.isEmpty {
            prompt += " considerando queste preferenze: \(preferences)"
        }
        prompt += ". Per ogni destinazione, includi il periodo migliore per visitarla e un'attrazione principale."

        sendMessage(prompt, completion: completion)
    }

    /// Richiede un itinerario per una destinazione
    func requestItinerary(
        destination: String,
        days: Int,
        completion: @escaping (Result<String, ChatServiceError>) -> Void
    ) {
        let prompt = """
        Crea un itinerario di \(days) giorn\(days == 1 ? "o" : "i") per visitare \(destination).
        Per ogni giorno, suggerisci:
        - Attività mattutine
        - Pranzo (zona consigliata)
        - Attività pomeridiane
        - Cena (tipo di cucina consigliata)
        Includi anche consigli su come spostarsi tra le varie attrazioni.
        """

        sendMessage(prompt, completion: completion)
    }

    /// Richiede informazioni pratiche su una destinazione
    func requestPracticalInfo(
        destination: String,
        completion: @escaping (Result<String, ChatServiceError>) -> Void
    ) {
        let prompt = """
        Fornisci informazioni pratiche per un viaggio a \(destination):
        - Documenti necessari
        - Valuta e metodi di pagamento comuni
        - Clima e abbigliamento consigliato
        - Trasporti locali
        - Cose da sapere (usanze locali, sicurezza, ecc.)
        """

        sendMessage(prompt, completion: completion)
    }
}
