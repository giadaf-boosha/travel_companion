import Foundation

/// Enum che rappresenta i tipi di eventi geofence
enum GeofenceEventType: String, CaseIterable, Codable {
    case enter = "enter"
    case exit = "exit"

    // MARK: - Display Properties

    /// Nome visualizzato per il tipo di evento
    var displayName: String {
        switch self {
        case .enter:
            return "Ingresso"
        case .exit:
            return "Uscita"
        }
    }

    /// Descrizione del tipo di evento
    var description: String {
        switch self {
        case .enter:
            return "Sei entrato nella zona"
        case .exit:
            return "Sei uscito dalla zona"
        }
    }

    /// Icona SF Symbol per il tipo di evento
    var iconName: String {
        switch self {
        case .enter:
            return "arrow.down.right.circle"
        case .exit:
            return "arrow.up.left.circle"
        }
    }

    /// Emoji per notifiche
    var emoji: String {
        switch self {
        case .enter:
            return "📍"
        case .exit:
            return "👋"
        }
    }

    // MARK: - Initialization

    /// Inizializza dal valore raw string salvato in Core Data
    init?(rawValue: String) {
        switch rawValue {
        case "enter":
            self = .enter
        case "exit":
            self = .exit
        default:
            return nil
        }
    }
}
