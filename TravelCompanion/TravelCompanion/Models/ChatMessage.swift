import Foundation

/// Struttura che rappresenta un messaggio nella chat con l'assistente AI
struct ChatMessage: Codable, Identifiable, Equatable {

    // MARK: - Properties

    /// Identificatore univoco del messaggio
    let id: UUID

    /// Ruolo del mittente del messaggio
    let role: Role

    /// Contenuto testuale del messaggio
    let content: String

    /// Timestamp di creazione del messaggio
    let timestamp: Date

    // MARK: - Role Enum

    /// Enum che rappresenta il ruolo del mittente
    enum Role: String, Codable {
        case system = "system"
        case user = "user"
        case assistant = "assistant"

        /// Indica se il messaggio è dell'utente
        var isUser: Bool {
            return self == .user
        }

        /// Indica se il messaggio è dell'assistente
        var isAssistant: Bool {
            return self == .assistant
        }

        /// Indica se il messaggio è di sistema (non visibile all'utente)
        var isSystem: Bool {
            return self == .system
        }
    }

    // MARK: - Initialization

    /// Inizializzatore principale
    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    /// Crea un messaggio utente
    static func userMessage(_ content: String) -> ChatMessage {
        return ChatMessage(role: .user, content: content)
    }

    /// Crea un messaggio dell'assistente
    static func assistantMessage(_ content: String) -> ChatMessage {
        return ChatMessage(role: .assistant, content: content)
    }

    /// Crea un messaggio di sistema
    static func systemMessage(_ content: String) -> ChatMessage {
        return ChatMessage(role: .system, content: content)
    }

    // MARK: - API Format

    /// Converte il messaggio nel formato richiesto dall'API OpenAI
    var apiFormat: [String: String] {
        return [
            "role": role.rawValue,
            "content": content
        ]
    }

    // MARK: - Equatable

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - ChatMessage Array Extension

extension Array where Element == ChatMessage {

    /// Converte l'array di messaggi nel formato richiesto dall'API OpenAI
    var apiFormat: [[String: String]] {
        return self.map { $0.apiFormat }
    }

    /// Filtra solo i messaggi visibili (esclude i messaggi di sistema)
    var visibleMessages: [ChatMessage] {
        return self.filter { !$0.role.isSystem }
    }

    /// Restituisce l'ultimo messaggio dell'utente
    var lastUserMessage: ChatMessage? {
        return self.last { $0.role.isUser }
    }

    /// Restituisce l'ultimo messaggio dell'assistente
    var lastAssistantMessage: ChatMessage? {
        return self.last { $0.role.isAssistant }
    }
}
