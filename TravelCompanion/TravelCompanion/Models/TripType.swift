import UIKit

/// Enum che rappresenta i tipi di viaggio supportati dall'applicazione
enum TripType: String, CaseIterable, Codable {
    case local = "local"
    case dayTrip = "dayTrip"
    case multiDay = "multiDay"

    // MARK: - Display Properties

    /// Nome visualizzato per il tipo di viaggio
    var displayName: String {
        switch self {
        case .local:
            return "Locale"
        case .dayTrip:
            return "Giornaliero"
        case .multiDay:
            return "Multi-giorno"
        }
    }

    /// Descrizione del tipo di viaggio
    var tripDescription: String {
        switch self {
        case .local:
            return "Viaggio in città, breve durata"
        case .dayTrip:
            return "Escursione giornaliera fuori città"
        case .multiDay:
            return "Vacanza di più giorni"
        }
    }

    /// Icona SF Symbol per il tipo di viaggio
    var iconName: String {
        switch self {
        case .local:
            return "building.2"
        case .dayTrip:
            return "car"
        case .multiDay:
            return "airplane"
        }
    }

    /// Colore associato al tipo di viaggio
    var color: UIColor {
        switch self {
        case .local:
            return UIColor.systemGreen
        case .dayTrip:
            return UIColor.systemOrange
        case .multiDay:
            return UIColor.systemBlue
        }
    }

    /// Emoji per il tipo di viaggio
    var emoji: String {
        switch self {
        case .local:
            return "🏠"
        case .dayTrip:
            return "🚗"
        case .multiDay:
            return "✈️"
        }
    }

    // MARK: - Initialization

    /// Inizializza dall'indice del segmented control
    init(segmentIndex: Int) {
        switch segmentIndex {
        case 0:
            self = .local
        case 1:
            self = .dayTrip
        case 2:
            self = .multiDay
        default:
            self = .local
        }
    }

    /// Indice per il segmented control
    var segmentIndex: Int {
        switch self {
        case .local:
            return 0
        case .dayTrip:
            return 1
        case .multiDay:
            return 2
        }
    }

    // MARK: - Utility Methods

    /// Indica se il tipo di viaggio supporta il calcolo della distanza totale
    var supportsDistanceCalculation: Bool {
        return self == .multiDay
    }

    /// Indica se il tipo di viaggio tipicamente richiede una data di fine
    var requiresEndDate: Bool {
        return self == .multiDay
    }
}
