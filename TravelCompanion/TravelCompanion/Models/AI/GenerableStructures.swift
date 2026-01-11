import Foundation

#if canImport(FoundationModels)
import FoundationModels

// MARK: - Itinerary Structures

/// Rappresenta un itinerario di viaggio generato dall'AI
@available(iOS 26.0, *)
@Generable
struct TravelItinerary: Codable, Sendable {
    @Guide(description: "Nome della destinazione")
    let destination: String

    @Guide(description: "Numero totale di giorni", .range(1...30))
    let totalDays: Int

    @Guide(description: "Stile del viaggio: culturale, relax, avventura, gastronomico")
    let travelStyle: String

    @Guide(description: "Piano per ogni giorno")
    let dailyPlans: [DayPlan]

    @Guide(description: "Consigli generali per il viaggio, massimo 5", .count(1...5))
    let generalTips: [String]
}

/// Rappresenta il piano per un singolo giorno
@available(iOS 26.0, *)
@Generable
struct DayPlan: Codable, Sendable {
    @Guide(description: "Numero del giorno", .range(1...30))
    let dayNumber: Int

    @Guide(description: "Tema della giornata")
    let theme: String

    @Guide(description: "Attivita della mattina")
    let morningActivity: String

    @Guide(description: "Zona consigliata per il pranzo")
    let lunchArea: String

    @Guide(description: "Attivita del pomeriggio")
    let afternoonActivity: String

    @Guide(description: "Zona consigliata per la cena")
    let dinnerArea: String

    @Guide(description: "Attivita serale opzionale")
    let eveningActivity: String?

    @Guide(description: "Note sui trasporti tra le attivita")
    let transportNotes: String
}

// MARK: - Packing List Structure

/// Lista degli oggetti da mettere in valigia generata dall'AI
@available(iOS 26.0, *)
@Generable
struct GeneratedPackingList: Codable, Sendable {
    @Guide(description: "Documenti e carte necessari", .count(2...5))
    let documents: [String]

    @Guide(description: "Abbigliamento consigliato", .count(5...10))
    let clothing: [String]

    @Guide(description: "Articoli per igiene personale", .count(3...8))
    let toiletries: [String]

    @Guide(description: "Elettronica e accessori", .count(2...5))
    let electronics: [String]

    @Guide(description: "Articoli specifici per il tipo di viaggio", .count(2...5))
    let specialItems: [String]

    @Guide(description: "Kit medico base", .count(3...6))
    let healthKit: [String]
}

// MARK: - Trip Briefing Structures

/// Briefing informativo sulla destinazione generato dall'AI
@available(iOS 26.0, *)
@Generable
struct GeneratedTripBriefing: Codable, Sendable {
    @Guide(description: "Destinazione")
    let destination: String

    @Guide(description: "Fatti rapidi: lingua, valuta, fuso orario")
    let quickFacts: QuickFacts

    @Guide(description: "Consigli culturali e comportamentali", .count(3...5))
    let culturalTips: [String]

    @Guide(description: "Frasi utili nella lingua locale con pronuncia", .count(5...8))
    let usefulPhrases: [LocalPhrase]

    @Guide(description: "Informazioni sul clima tipico")
    let climateInfo: String

    @Guide(description: "Consigli sulla cucina locale", .count(3...5))
    let foodCulture: [String]

    @Guide(description: "Note generali sulla sicurezza", .count(2...4))
    let safetyNotes: [String]
}

/// Informazioni rapide sulla destinazione
@available(iOS 26.0, *)
@Generable
struct QuickFacts: Codable, Sendable {
    @Guide(description: "Lingua principale parlata")
    let language: String

    @Guide(description: "Valuta locale")
    let currency: String

    @Guide(description: "Fuso orario rispetto all'Italia")
    let timeZone: String

    @Guide(description: "Tipo di presa elettrica")
    let electricalOutlet: String
}

/// Frase utile con traduzione e pronuncia
@available(iOS 26.0, *)
@Generable
struct LocalPhrase: Codable, Sendable {
    @Guide(description: "Frase in italiano")
    let italian: String

    @Guide(description: "Traduzione nella lingua locale")
    let local: String

    @Guide(description: "Guida alla pronuncia")
    let pronunciation: String
}

// MARK: - Structured Note

/// Nota strutturata generata dall'AI a partire da testo o voce
@available(iOS 26.0, *)
@Generable
struct StructuredNote: Codable, Sendable {
    @Guide(description: "Categoria", .anyOf(["ristorante", "attrazione", "hotel", "trasporto", "shopping", "altro"]))
    let category: String

    @Guide(description: "Nome del luogo se menzionato")
    let placeName: String?

    @Guide(description: "Valutazione da 1 a 5 se deducibile dal tono", .range(1...5))
    let rating: Int?

    @Guide(description: "Costo menzionato")
    let cost: String?

    @Guide(description: "Riassunto pulito e strutturato della nota originale")
    let summary: String

    @Guide(description: "Tag estratti dal contenuto, massimo 5", .count(1...5))
    let tags: [String]
}

#endif

// MARK: - Fallback Structures for non-iOS 26

/// Struttura per rappresentare un itinerario di viaggio (fallback per iOS < 26)
struct TravelItineraryData: Codable {
    let destination: String
    let totalDays: Int
    let travelStyle: String
    let dailyPlans: [DayPlanData]
    let generalTips: [String]
}

/// Struttura per rappresentare un piano giornaliero (fallback per iOS < 26)
struct DayPlanData: Codable {
    let dayNumber: Int
    let theme: String
    let morningActivity: String
    let lunchArea: String
    let afternoonActivity: String
    let dinnerArea: String
    let eveningActivity: String?
    let transportNotes: String
}

/// Struttura per la packing list (fallback per iOS < 26)
struct GeneratedPackingListData: Codable {
    let documents: [String]
    let clothing: [String]
    let toiletries: [String]
    let electronics: [String]
    let specialItems: [String]
    let healthKit: [String]
}

/// Struttura per il briefing (fallback per iOS < 26)
struct TripBriefingData: Codable {
    let destination: String
    let quickFacts: QuickFactsData
    let culturalTips: [String]
    let usefulPhrases: [LocalPhraseData]
    let climateInfo: String
    let foodCulture: [String]
    let safetyNotes: [String]
}

struct QuickFactsData: Codable {
    let language: String
    let currency: String
    let timeZone: String
    let electricalOutlet: String
}

struct LocalPhraseData: Codable {
    let italian: String
    let local: String
    let pronunciation: String
}

/// Struttura per la nota strutturata (fallback per iOS < 26)
struct StructuredNoteData: Codable {
    let category: String
    let placeName: String?
    let rating: Int?
    let cost: String?
    let summary: String
    let tags: [String]
}

// MARK: - Note Category Enum

/// Categorie disponibili per le note strutturate
enum NoteCategory: String, CaseIterable, Codable {
    case restaurant = "ristorante"
    case attraction = "attrazione"
    case hotel = "hotel"
    case transport = "trasporto"
    case shopping = "shopping"
    case other = "altro"

    var displayName: String {
        switch self {
        case .restaurant: return "Ristorante"
        case .attraction: return "Attrazione"
        case .hotel: return "Hotel"
        case .transport: return "Trasporto"
        case .shopping: return "Shopping"
        case .other: return "Altro"
        }
    }

    var iconName: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .attraction: return "star.fill"
        case .hotel: return "bed.double.fill"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .other: return "note.text"
        }
    }
}

// MARK: - Travel Style Enum

/// Stili di viaggio per la generazione dell'itinerario
enum TravelStyle: String, CaseIterable {
    case cultural = "culturale"
    case relax = "relax"
    case adventure = "avventura"
    case gastronomic = "gastronomico"

    var displayName: String {
        switch self {
        case .cultural: return "Culturale"
        case .relax: return "Relax"
        case .adventure: return "Avventura"
        case .gastronomic: return "Gastronomico"
        }
    }

    var iconName: String {
        switch self {
        case .cultural: return "building.columns.fill"
        case .relax: return "sun.max.fill"
        case .adventure: return "figure.hiking"
        case .gastronomic: return "fork.knife.circle.fill"
        }
    }
}
