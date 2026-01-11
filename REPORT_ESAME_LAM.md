# REPORT PROGETTO LAM 2024/2025
# Travel Companion - iOS Application

---

## Informazioni studente

| Campo | Valore |
|-------|--------|
| **Nome** | Giada |
| **Cognome** | Franceschini |
| **Email** | giada.franceschini3@studio.unibo.it |
| **Matricola** | 758288 |

---

## 1. Introduzione e panoramica

### 1.1 Descrizione del progetto

**Travel Companion** e un'applicazione iOS nativa sviluppata interamente in **Swift** con **UIKit** che assiste gli utenti nella pianificazione, tracciamento e documentazione delle proprie esperienze di viaggio. L'applicazione rappresenta un sistema completo di gestione viaggi che integra funzionalita di tracking GPS, memorizzazione multimediale e, come caratteristica distintiva, intelligenza artificiale on-device attraverso il framework **Apple Foundation Models**.

L'obiettivo principale e stato creare un'applicazione che non solo soddisfacesse tutti i requisiti del progetto, ma che esplorasse anche le potenzialita delle tecnologie piu avanzate disponibili per iOS, in particolare le funzionalita di Apple Intelligence introdotte con iOS 26.

### 1.2 Funzionalita principali

L'applicazione permette di:

- **Creare e gestire piani di viaggio** con destinazione, date e tipologia (locale, giornaliero, multi-giorno)
- **Tracciare percorsi GPS** in tempo reale con calcolo automatico delle distanze
- **Allegare foto e note geolocalizzate** ai momenti del viaggio
- **Visualizzare statistiche e mappe interattive** della cronologia dei viaggi
- **Ricevere notifiche** su punti di interesse vicini e promemoria di logging
- **Interagire con un assistente AI** capace di eseguire azioni nell'app (iOS 26+)

### 1.3 Requisiti tecnici e scelte di base

| Requisito | Valore | Motivazione |
|-----------|--------|-------------|
| **Piattaforma minima** | iOS 17.0 | Compatibilita con dispositivi recenti, accesso a API moderne |
| **Target AI** | iOS 26.0+ | Necessario per Apple Foundation Models |
| **Linguaggio** | Swift 5.9+ | Linguaggio nativo Apple, type-safety, performance |
| **Framework UI** | UIKit (100% programmatico) | Controllo totale, migliore manutenibilita, evita conflitti merge |
| **Persistenza** | Core Data | Framework nativo Apple, integrazione ottimale con l'ecosistema |

La scelta di **UIKit programmatico** invece di SwiftUI o Storyboard e stata dettata da tre fattori principali:

1. **Controllo granulare**: UIKit permette un controllo preciso su ogni aspetto del layout e del comportamento, fondamentale per implementazioni complesse come le animazioni dei grafici o la gestione della tastiera nella chat AI.

2. **Manutenibilita del codice**: Il codice Swift puro e piu facile da leggere, modificare e debuggare rispetto ai file XML dei Storyboard o alla sintassi dichiarativa di SwiftUI (ancora in evoluzione).

3. **Compatibilita Git**: I file Storyboard sono XML binari che generano frequenti conflitti durante i merge. Con UIKit programmatico, ogni modifica e tracciata chiaramente nel version control.

---

## 2. Architettura e Design Pattern

### 2.1 Pattern Architetturale: MVC con Services Layer

L'applicazione adotta il pattern **Model-View-Controller (MVC)** esteso con un **Services Layer** per la separazione delle responsabilita. Questa scelta segue le linee guida Apple per lo sviluppo iOS, garantendo al contempo una chiara separazione tra logica di business, presentazione e accesso ai dati.

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                           │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              UIKit ViewControllers (20+)                   │  │
│  │  Home │ TripList │ TripDetail │ Map │ Stats │ AI │ etc.   │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                       SERVICE LAYER                              │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐               │
│  │CoreData     │ │Location     │ │PhotoStorage │               │
│  │Manager      │ │Manager      │ │Manager      │               │
│  └─────────────┘ └─────────────┘ └─────────────┘               │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐               │
│  │Notification │ │Geofence     │ │Foundation   │               │
│  │Manager      │ │Manager      │ │ModelService │               │
│  └─────────────┘ └─────────────┘ └─────────────┘               │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                │
│  ┌─────────────────────────┐ ┌─────────────────────────┐       │
│  │      Core Data          │ │      FileManager        │       │
│  │   (SQLite Database)     │ │   (Photo Storage)       │       │
│  │  Trip │ Route │ Photo   │ │  /Documents/Photos/     │       │
│  │  Note │ GeofenceZone    │ │  UUID.jpg               │       │
│  └─────────────────────────┘ └─────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Motivazione dei Design Pattern utilizzati

#### Singleton per i Manager

Tutti i servizi dell'applicazione (`CoreDataManager`, `LocationManager`, `NotificationManager`, `GeofenceManager`, `FoundationModelService`) sono implementati come **Singleton**. Questa scelta e motivata da:

- **Stato condiviso consistente**: Servizi come `LocationManager` mantengono uno stato (`isTracking`, `currentLocation`) che deve essere accessibile e consistente da qualsiasi punto dell'app.
- **Inizializzazione lazy**: Le risorse costose (come la connessione al database Core Data o la sessione AI) vengono allocate solo quando necessario.
- **Accesso centralizzato**: Evita la necessita di passare riferimenti attraverso catene di view controller.

```swift
// File: CoreDataManager.swift
final class CoreDataManager {
    static let shared = CoreDataManager()
    private init() { /* Inizializzazione Core Data stack */ }
}
```

#### Delegate Pattern

La comunicazione tra componenti avviene principalmente tramite il pattern **Delegate**, seguendo le convenzioni UIKit:

```swift
// File: NewTripViewController.swift
protocol NewTripViewControllerDelegate: AnyObject {
    func didCreateTrip(_ trip: Trip)
    func didCancelTripCreation()
}
```

Questo pattern garantisce un accoppiamento debole tra componenti, facilitando testing e riutilizzo.

#### Observer Pattern con NotificationCenter

Per eventi che devono raggiungere componenti multipli (come l'aggiornamento della lista viaggi dopo una creazione), utilizzo `NotificationCenter`:

```swift
// Pubblicazione evento
NotificationCenter.default.post(name: .tripDidUpdate, object: trip)

// Sottoscrizione
NotificationCenter.default.addObserver(self,
    selector: #selector(handleTripUpdate),
    name: .tripDidUpdate,
    object: nil)
```

---

## 3. Implementazione delle funzionalita core

### 3.1 Record the Activities

#### 3.1.1 Creazione Trip Plans

**File di riferimento:** `NewTripViewController.swift`

La schermata di creazione viaggio implementa un form completo con validazione in tempo reale. La scelta di usare `UIDatePicker` con stile `.wheels` e stata dettata dalla necessita di un'esperienza utente intuitiva per la selezione delle date.

```swift
private func validateInput() -> (isValid: Bool, errorMessage: String?) {
    guard let destination = destinationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
          !destination.isEmpty else {
        return (false, "Inserisci una destinazione")
    }
    guard destination.count >= 2 else {
        return (false, "La destinazione deve contenere almeno 2 caratteri")
    }
    guard endDate >= startDate else {
        return (false, "La data di fine deve essere successiva alla data di inizio")
    }
    return (true, nil)
}
```

La validazione e **sincrona** e avviene al tap sul pulsante "Crea Viaggio", evitando validazioni troppo aggressive che potrebbero frustrare l'utente durante la digitazione.

#### 3.1.2 Journey Logging con GPS

**File di riferimento:** `LocationManager.swift` (~320 linee)

Il tracking GPS e gestito da un singleton che incapsula tutta la logica di posizionamento. La scelta architetturale chiave e stata implementare un **filtro di qualita** per eliminare dati GPS anomali:

```swift
private func shouldRecordLocation(_ location: CLLocation) -> Bool {
    // Filtra posizioni troppo inaccurate (> 50 metri di errore)
    guard location.horizontalAccuracy >= 0 &&
          location.horizontalAccuracy <= 50 else {
        return false
    }

    // Filtra velocita impossibili (> 200 km/h = ~55 m/s)
    if let lastLocation = recordedLocations.last {
        let timeDiff = location.timestamp.timeIntervalSince(lastLocation.timestamp)
        if timeDiff > 0 {
            let distance = location.distance(from: lastLocation)
            let speed = distance / timeDiff
            if speed > 55 { return false }
        }
    }
    return true
}
```

Questo filtro anti-rumore e essenziale perche il GPS puo fornire letture errate, specialmente in ambienti urbani con riflessi dei segnali (multipath). Senza questo filtro, le polyline sulla mappa mostrerebbero "salti" irrealistici.

#### 3.1.3 Tipi di Viaggio

**File di riferimento:** `TripType.swift`

I tre tipi di viaggio obbligatori sono implementati come `enum` Swift con proprieta computed, una scelta che garantisce type-safety e centralizza la logica di presentazione:

```swift
enum TripType: String, CaseIterable, Codable {
    case local = "local"
    case dayTrip = "dayTrip"
    case multiDay = "multiDay"

    var displayName: String {
        switch self {
        case .local: return "Locale"
        case .dayTrip: return "Giornaliero"
        case .multiDay: return "Multi-giorno"
        }
    }

    var color: UIColor {
        switch self {
        case .local: return .systemGreen
        case .dayTrip: return .systemOrange
        case .multiDay: return .systemBlue
        }
    }
}
```

L'uso di colori distinti per tipo permette un riconoscimento visivo immediato nelle liste e sulla mappa.

### 3.2 Display Charts

#### 3.2.1 Map View con percorsi

**File di riferimento:** `MapViewController.swift`

La mappa mostra i percorsi GPS come polylines colorate per tipo di viaggio. L'implementazione usa `MKPolyline` e il delegate `MKMapViewDelegate`:

```swift
func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let polyline = overlay as? MKPolyline {
        let renderer = MKPolylineRenderer(polyline: polyline)
        if let trip = findTripForPolyline(polyline) {
            renderer.strokeColor = trip.tripType.color
        }
        renderer.lineWidth = 4.0
        return renderer
    }
    return MKOverlayRenderer(overlay: overlay)
}
```

La **heatmap** delle zone visitate e implementata aggregando i punti GPS in una griglia:

```swift
private func createHeatmapOverlay(from coordinates: [CLLocationCoordinate2D]) -> MKPolygon {
    var densityMap: [String: Int] = [:]
    let gridSize = 0.01 // ~1km

    for coord in coordinates {
        let gridLat = round(coord.latitude / gridSize) * gridSize
        let gridLon = round(coord.longitude / gridSize) * gridSize
        let key = "\(gridLat),\(gridLon)"
        densityMap[key, default: 0] += 1
    }
    // Zone con > 5 punti sono considerate "hot"
}
```

#### 3.2.2 Bar Charts con Core Animation

**File di riferimento:** `StatisticsViewController.swift`

Ho scelto di implementare i grafici **senza librerie esterne**, usando `CAShapeLayer` per un rendering hardware-accelerato e animazioni fluide:

```swift
private func drawTripsChart(data: [Int: Int]) {
    let chartLayer = CALayer()
    let maxValue = data.values.max() ?? 1

    for month in 1...12 {
        let value = data[month] ?? 0
        let barHeight = (CGFloat(value) / CGFloat(maxValue)) * availableHeight

        let barLayer = CAShapeLayer()
        let barPath = UIBezierPath(roundedRect: CGRect(...), cornerRadius: 4)
        barLayer.path = barPath.cgPath
        barLayer.fillColor = chartBarColor.cgColor

        // Animazione fade-in sequenziale per effetto "wave"
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.beginTime = CACurrentMediaTime() + (Double(month - 1) * 0.05)
        barLayer.add(animation, forKey: "fadeIn")

        chartLayer.addSublayer(barLayer)
    }
}
```

La scelta di Core Animation invece di una libreria come Charts e motivata da:
- Nessuna dipendenza esterna
- Controllo totale sulle animazioni
- Performance native
- Minor dimensione dell'app finale

### 3.3 Perform Background Jobs

#### 3.3.1 Notifiche periodiche

**File di riferimento:** `NotificationManager.swift` (~340 linee)

L'applicazione implementa due tipi di notifiche come richiesto:

1. **Notifiche POI Nearby**: Inviate quando l'utente si avvicina a un punto di interesse
2. **Logging Reminder**: Promemoria giornaliero se l'utente non registra viaggi

```swift
func scheduleLoggingReminder(daysInterval: Int = 7) {
    let content = UNMutableNotificationContent()
    content.title = "Registra il tuo viaggio"
    content.body = "Non hai registrato viaggi di recente. Stai pianificando qualcosa?"
    content.categoryIdentifier = "LOGGING_REMINDER"

    var dateComponents = DateComponents()
    dateComponents.hour = 10  // Alle 10:00 ogni giorno

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(identifier: "logging_reminder",
                                         content: content,
                                         trigger: trigger)
    notificationCenter.add(request)
}
```

#### 3.3.2 Geofencing

**File di riferimento:** `GeofenceManager.swift` (~360 linee)

Il geofencing e stato scelto come background operation aggiuntiva perche rappresenta un caso d'uso reale per un'app di viaggi (notifiche quando si arriva a destinazione, quando si lascia casa, ecc.).

```swift
func addGeofence(for zone: GeofenceZone) -> Bool {
    // iOS limita a 20 regioni monitorate simultaneamente
    guard availableRegionSlots > 0 else { return false }
    guard hasRequiredPermissions else {
        requestAlwaysAuthorization()
        return false
    }

    let region = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude),
        radius: min(zone.radius, locationManager.maximumRegionMonitoringDistance),
        identifier: zone.id!.uuidString
    )
    region.notifyOnEntry = true
    region.notifyOnExit = true

    locationManager.startMonitoring(for: region)
    return true
}
```

La gestione del **limite di 20 regioni** imposto da iOS e fondamentale: l'app tiene traccia delle regioni attive e avvisa l'utente se il limite viene raggiunto.

---

## 4. Apple Foundation Models: Intelligenza Artificiale On-Device

Questa sezione rappresenta il cuore dell'estensione del progetto oltre i requisiti minimi. L'integrazione di **Apple Foundation Models** (disponibile da iOS 26) permette all'applicazione di offrire funzionalita AI avanzate che vengono eseguite **interamente on-device**, garantendo privacy e funzionamento offline.

### 4.1 Introduzione al Framework

Apple Foundation Models e il framework introdotto con iOS 26 che permette agli sviluppatori di sfruttare i modelli di linguaggio di Apple Intelligence direttamente nelle proprie app. Le caratteristiche principali sono:

- **Esecuzione on-device**: Nessun dato viene inviato a server esterni
- **Privacy by design**: I dati dell'utente non lasciano mai il dispositivo
- **Integrazione nativa**: Accesso tramite API Swift type-safe
- **Guided Generation**: Possibilita di generare output strutturati conformi a schemi definiti

L'utilizzo di questo framework per Travel Companion e motivato dalla volonta di esplorare le piu recenti tecnologie Apple e di offrire un'esperienza utente differenziante rispetto ad app che dipendono da servizi cloud esterni.

### 4.2 Guided Generation e la Macro @Generable

**File di riferimento:** `GenerableStructures.swift`

Una delle funzionalita piu potenti di Foundation Models e la **Guided Generation**, che permette al modello di generare output conformi a strutture Swift predefinite. Questo si ottiene attraverso la macro `@Generable`.

#### Perche Guided Generation?

Senza Guided Generation, l'output di un LLM e testo non strutturato che richiede parsing manuale, con tutti i rischi di errore che ne conseguono. Con Guided Generation, il modello e **vincolato** a produrre output che rispetta esattamente lo schema definito.

#### Esempio: Itinerario di Viaggio

```swift
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
```

L'attributo `@Guide` fornisce al modello indicazioni su:
- **description**: Spiega cosa dovrebbe contenere il campo
- **range**: Vincola valori numerici (es. `1...30` giorni)
- **count**: Limita il numero di elementi in un array (es. `1...5` consigli)
- **anyOf**: Enumera i valori possibili per un campo

Questa annotazione semantica guida il modello durante la generazione, migliorando drasticamente la qualita e conformita dell'output.

#### Strutture Annidate

La potenza di Guided Generation si vede nelle strutture complesse con nesting:

```swift
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

    @Guide(description: "Attivita serale opzionale")
    let eveningActivity: String?

    @Guide(description: "Note sui trasporti tra le attivita")
    let transportNotes: String
}
```

Il modello genera automaticamente un array di `DayPlan` con il numero corretto di elementi basandosi su `totalDays`, garantendo coerenza strutturale.

#### Altre strutture Generable implementate

**Packing List:**
```swift
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
}
```

**Trip Briefing con QuickFacts annidati:**
```swift
@Generable
struct GeneratedTripBriefing: Codable, Sendable {
    @Guide(description: "Fatti rapidi: lingua, valuta, fuso orario")
    let quickFacts: QuickFacts

    @Guide(description: "Consigli culturali e comportamentali", .count(3...5))
    let culturalTips: [String]

    @Guide(description: "Frasi utili nella lingua locale", .count(5...8))
    let usefulPhrases: [LocalPhrase]
}

@Generable
struct LocalPhrase: Codable, Sendable {
    @Guide(description: "Frase in italiano")
    let italian: String

    @Guide(description: "Traduzione nella lingua locale")
    let local: String

    @Guide(description: "Guida alla pronuncia")
    let pronunciation: String
}
```

### 4.3 Custom Instructions (Istruzioni Personalizzate)

**File di riferimento:** `TravelAIChatViewController.swift`, `FoundationModelService.swift`

Le **Custom Instructions** definiscono la personalita e il comportamento dell'assistente AI. In Travel Companion, ho definito istruzioni dettagliate per garantire risposte appropriate al contesto di un'app di viaggi.

#### Struttura delle istruzioni

```swift
chatSession = LanguageModelSession(tools: [createTripTool, addNoteTool, getTripInfoTool]) {
    """
    Sei Travel Companion AI, un assistente di viaggio esperto e amichevole.

    IDENTITA:
    - Sei un esperto di viaggi con vasta conoscenza di destinazioni, culture e logistica
    - Rispondi SEMPRE in italiano
    - Sii conciso ma informativo, evita risposte troppo lunghe
    - Usa un tono professionale ma cordiale

    COMPETENZE:
    - Consigli su destinazioni, periodo migliore per visitare, cosa vedere
    - Informazioni culturali, gastronomiche, di sicurezza
    - Suggerimenti su budget, itinerari, trasporti
    - Frasi utili nelle lingue locali

    STRUMENTI DISPONIBILI:
    - createTrip: Crea un nuovo viaggio quando l'utente lo richiede
    - addNote: Aggiunge note al viaggio attivo
    - getTripInfo: Recupera informazioni sui viaggi dell'utente

    REGOLE:
    - Non inventare prezzi specifici o orari che potrebbero cambiare
    - Suggerisci sempre di verificare informazioni pratiche aggiornate
    - Quando crei viaggi o note, conferma l'azione completata
    - Se l'utente chiede di fare qualcosa nell'app, usa gli strumenti appropriati
    """
}
```

#### Perche queste istruzioni?

Le istruzioni sono strutturate in sezioni per massimizzare l'efficacia:

1. **IDENTITA**: Definisce chi e l'assistente, fondamentale per la coerenza delle risposte
2. **COMPETENZE**: Specifica le aree di expertise, aiutando il modello a capire cosa sa fare
3. **STRUMENTI DISPONIBILI**: Elenca i tool accessibili, cruciale per il Tool Calling
4. **REGOLE**: Vincoli comportamentali per evitare risposte inappropriate (es. non inventare prezzi)

Le istruzioni includono anche vincoli linguistici ("Rispondi SEMPRE in italiano") perche il modello Foundation potrebbe altrimenti rispondere nella lingua del prompt o mescolare lingue.

### 4.4 Tool Calling: L'AI che agisce nell'App

**File di riferimento:** `TravelChatTools.swift`

Il **Tool Calling** e la funzionalita che distingue Travel Companion da una semplice chat: l'AI puo **eseguire azioni concrete** nell'applicazione, non solo rispondere a domande.

#### Architettura del Tool Calling

Ogni tool implementa il protocollo `Tool` e definisce:
- `name`: Identificatore univoco del tool
- `description`: Descrizione per il modello (quando usare il tool)
- `Arguments`: Struttura `@Generable` con i parametri
- `call()`: Funzione asincrona che esegue l'azione

#### Tool 1: CreateTripTool

Questo tool permette all'utente di creare un viaggio tramite linguaggio naturale.

```swift
@available(iOS 26.0, *)
struct CreateTripTool: Tool {
    let name = "createTrip"
    let description = """
        Crea un nuovo viaggio per l'utente. Usa questo tool quando l'utente vuole
        iniziare un nuovo viaggio, pianificare una vacanza, o registrare una gita.
        Richiedi sempre destinazione e date.
        """

    @Generable
    struct Arguments {
        @Guide(description: "Nome della citta o luogo di destinazione")
        var destination: String

        @Guide(description: "Data di inizio viaggio nel formato yyyy-MM-dd")
        var startDate: String

        @Guide(description: "Data di fine viaggio nel formato yyyy-MM-dd")
        var endDate: String

        @Guide(description: "Tipo di viaggio: locale, giornaliero, o multi-giorno")
        var tripType: String
    }

    func call(arguments: Arguments) async throws -> [String] {
        // Parsing e validazione date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let startDate = dateFormatter.date(from: arguments.startDate) else {
            return ["Errore: formato data inizio non valido. Usa yyyy-MM-dd."]
        }

        guard let endDate = dateFormatter.date(from: arguments.endDate) else {
            return ["Errore: formato data fine non valido. Usa yyyy-MM-dd."]
        }

        // Mapping tipo viaggio
        let tripType: TripType
        switch arguments.tripType.lowercased() {
        case "locale": tripType = .local
        case "giornaliero": tripType = .dayTrip
        case "multi-giorno": tripType = .multiDay
        default: tripType = .dayTrip
        }

        // Creazione su MainActor (Core Data richiede main thread)
        let result = await MainActor.run {
            CoreDataManager.shared.createTrip(
                destination: arguments.destination,
                startDate: startDate,
                endDate: endDate,
                type: tripType,
                isActive: false
            )
        }

        if result != nil {
            return [
                "Viaggio creato con successo!",
                "Destinazione: \(arguments.destination)",
                "Date: \(arguments.startDate) - \(arguments.endDate)",
                "Tipo: \(arguments.tripType)"
            ]
        } else {
            return ["Errore nella creazione del viaggio. Riprova."]
        }
    }
}
```

**Aspetti chiave dell'implementazione:**

1. **Uso di `MainActor.run`**: Core Data non e thread-safe, quindi le operazioni devono avvenire sul main thread. Il tool usa `await MainActor.run` per garantire la sicurezza.

2. **Gestione errori robusta**: Il tool restituisce messaggi di errore user-friendly invece di lanciare eccezioni, permettendo all'AI di comunicare il problema all'utente.

3. **Feedback strutturato**: L'output e un array di stringhe che l'AI puo elaborare per formulare una risposta naturale.

#### Tool 2: AddNoteTool

```swift
@available(iOS 26.0, *)
struct AddNoteTool: Tool {
    let name = "addNote"
    let description = """
        Aggiunge una nota al viaggio attualmente attivo. Usa questo tool quando
        l'utente vuole annotare qualcosa durante il viaggio.
        """

    @Generable
    struct Arguments {
        @Guide(description: "Contenuto della nota da salvare")
        var content: String

        @Guide(description: "Categoria: ristorante, attrazione, hotel, trasporto, shopping, altro")
        var category: String
    }

    func call(arguments: Arguments) async throws -> [String] {
        let result = await MainActor.run { () -> (success: Bool, messages: [String]) in
            // Verifica viaggio attivo
            guard let activeTrip = CoreDataManager.shared.fetchActiveTrip() else {
                return (false, ["Nessun viaggio attivo.",
                               "Attiva un viaggio prima di aggiungere note."])
            }

            // Geolocalizzazione automatica
            let location = LocationManager.shared.currentLocation
            let latitude = location?.coordinate.latitude ?? 0.0
            let longitude = location?.coordinate.longitude ?? 0.0

            // Creazione nota
            let note = CoreDataManager.shared.createNote(
                for: activeTrip,
                text: arguments.content,
                latitude: latitude,
                longitude: longitude
            )

            if let note = note {
                note.category = arguments.category
                CoreDataManager.shared.saveContext()
                return (true, ["Nota aggiunta con successo!"])
            }
            return (false, ["Errore nel salvare la nota."])
        }
        return result.messages
    }
}
```

#### Tool 3: GetTripInfoTool

Questo tool permette all'AI di recuperare informazioni sui viaggi dell'utente per rispondere a domande come "Quanti viaggi ho fatto?" o "Qual e il mio viaggio attivo?".

```swift
@available(iOS 26.0, *)
struct GetTripInfoTool: Tool {
    let name = "getTripInfo"
    let description = """
        Recupera informazioni sul viaggio attivo o sui viaggi recenti dell'utente.
        """

    @Generable
    struct Arguments {
        @Guide(description: "Tipo di informazione: viaggio_attivo, statistiche, ultimi_viaggi")
        var infoType: String
    }

    func call(arguments: Arguments) async throws -> [String] {
        let result = await MainActor.run { () -> [String] in
            switch arguments.infoType {
            case "viaggio_attivo": return getActiveTripInfo()
            case "statistiche": return getStatistics()
            case "ultimi_viaggi": return getRecentTrips()
            default: return getActiveTripInfo()
            }
        }
        return result
    }

    private func getStatistics() -> [String] {
        let totalTrips = CoreDataManager.shared.getTotalTripsCount()
        let totalPhotos = CoreDataManager.shared.getTotalPhotosCount()
        let totalDistance = CoreDataManager.shared.getTotalDistance()

        return [
            "Le tue statistiche di viaggio:",
            "Viaggi totali: \(totalTrips)",
            "Foto scattate: \(totalPhotos)",
            "Distanza totale: \(String(format: "%.1f", totalDistance / 1000)) km"
        ]
    }
}
```

### 4.5 Conversation Starters

**File di riferimento:** `TravelChatTools.swift`

Per migliorare l'esperienza utente, l'app fornisce **8 suggerimenti di conversazione** suddivisi in due categorie:

```swift
struct TravelChatStarters {
    /// Starter per consigli di viaggio (5)
    static let travelExpertStarters: [ChatStarterItem] = [
        ChatStarterItem(
            icon: "globe.europe.africa.fill",
            title: "Consiglia destinazione",
            prompt: "Suggeriscimi una destinazione perfetta per una vacanza..."
        ),
        ChatStarterItem(
            icon: "fork.knife",
            title: "Cucina locale",
            prompt: "Quali sono i piatti tipici assolutamente da provare a Napoli?"
        ),
        // ... altri starter
    ]

    /// Starter per azioni nell'app (3)
    static let actionStarters: [ChatStarterItem] = [
        ChatStarterItem(
            icon: "plus.circle.fill",
            title: "Crea viaggio",
            prompt: "Voglio creare un nuovo viaggio per Roma dal 15 al 20 marzo 2026",
            isAction: true  // Evidenziato visivamente in verde
        ),
        // ... altri starter
    ]
}
```

Gli starter di tipo "action" sono visivamente distinti (sfondo verde) per indicare che attiveranno un'azione nell'app.

### 4.6 Gestione della sessione e degli errori

**File di riferimento:** `FoundationModelService.swift`

La gestione della sessione AI e centralizzata in `FoundationModelService`, che implementa:

#### Verifica Disponibilita

```swift
func checkAvailability() -> ModelAvailabilityResult {
    let model = SystemLanguageModel.default

    switch model.availability {
    case .available:
        return .available

    case .unavailable(.appleIntelligenceNotEnabled):
        return .unavailable(
            title: "Apple Intelligence Disabilitata",
            message: "Attiva Apple Intelligence nelle Impostazioni.",
            action: .openSettings
        )

    case .unavailable(.deviceNotEligible):
        return .unavailable(
            title: "Dispositivo Non Supportato",
            message: "Richiede iPhone con chip A17 Pro o successivo.",
            action: nil
        )

    case .unavailable(.modelNotReady):
        return .unavailable(
            title: "Modello in Preparazione",
            message: "Il modello AI e in download. Riprova tra poco.",
            action: .retry
        )
    }
}
```

#### Retry Logic

Per gestire errori transitori, il servizio implementa un meccanismo di retry:

```swift
private func executeWithRetry<T>(operation: () async throws -> T) async throws -> T {
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

            if attempt < maxRetryAttempts {
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            }
        }
    }
    throw lastError ?? FoundationModelError.generationFailed
}
```

---

## 5. Modello Dati (Core Data)

### 5.1 Schema Entita

```
┌─────────────────────────────────────────────────────────────────┐
│                        CORE DATA MODEL                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────┐      1:n      ┌────────┐                        │
│  │    Trip    │──────────────▶│ Route  │                        │
│  │            │               └────────┘                        │
│  │ destination│      1:n      ┌────────┐                        │
│  │ startDate  │──────────────▶│ Photo  │                        │
│  │ endDate    │               └────────┘                        │
│  │ tripType   │      1:n      ┌────────┐                        │
│  │ isActive   │──────────────▶│  Note  │                        │
│  │ totalDist  │               └────────┘                        │
│  └────────────┘                                                  │
│                                                                  │
│  ┌──────────────┐   1:n   ┌────────────────┐                    │
│  │GeofenceZone  │────────▶│ GeofenceEvent  │                    │
│  │ name/lat/lon │         │ type/timestamp │                    │
│  └──────────────┘         └────────────────┘                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

La scelta di usare Core Data invece di alternative come Realm o SQLite diretto e motivata da:
- Integrazione nativa con l'ecosistema Apple
- Supporto per relazioni e fetch request tipizzate
- Migrazione automatica degli schemi
- Integrazione con CloudKit per sync futuri

### 5.2 Operazioni CRUD

**File:** `CoreDataManager.swift` (~1000 linee)

```swift
// Create
func createTrip(destination: String, startDate: Date, endDate: Date?,
                type: TripType, isActive: Bool = false) -> Trip?

// Read
func fetchAllTrips() -> [Trip]
func fetchTrips(filteredBy type: TripType?) -> [Trip]
func fetchActiveTrip() -> Trip?

// Update
func updateTrip(_ trip: Trip)
func setTripActive(_ trip: Trip, isActive: Bool)
func updateTotalDistance(for trip: Trip)

// Delete
func deleteTrip(_ trip: Trip)
```

---

## 6. Testing

### 6.1 Strategia di testing

| Tipo | Test | Scopo |
|------|------|-------|
| **Unit Test** | 123 | Logica di business, calcoli, validazione |
| **UI Test** | 70+ | Flussi utente, interazione UI |

### 6.2 Copertura per modulo

| Suite | Test | Copertura |
|-------|------|-----------|
| `CoreDataManagerTests` | 28 | CRUD completo per tutte le entita |
| `LocationManagerTests` | 15 | Permessi, tracking, calcolo distanze |
| `NotificationManagerTests` | 12 | Autorizzazioni, scheduling, categorie |
| `DistanceCalculatorTests` | 18 | Formula Haversine, formattazione |
| `TripLifecycleUITests` | 25 | Ciclo vita completo viaggio |

---

## 7. Conformita ai requisiti

| Requisito | Stato | Implementazione |
|-----------|:-----:|-----------------|
| UI creazione trip plans | ✅ | `NewTripViewController.swift` |
| Start/Stop journey logging | ✅ | `ActiveTripViewController.swift` |
| Record coordinate GPS | ✅ | `LocationManager.swift` |
| Allegare foto via camera | ✅ | `UIImagePickerController` |
| Allegare note geolocalizzate | ✅ | `CoreDataManager.createNote()` |
| Database locale | ✅ | Core Data |
| 3 tipi viaggio obbligatori | ✅ | `TripType` enum |
| Calcolo distanza multi-day | ✅ | `DistanceCalculator.swift` |
| Lista viaggi con filtro | ✅ | `TripListViewController.swift` |
| Map View percorsi | ✅ | `MapViewController.swift` |
| Map View heatmap | ✅ | `createHeatmapOverlay()` |
| Bar Chart viaggi/mese | ✅ | `StatisticsViewController.swift` |
| Bar Chart distanza/mese | ✅ | `StatisticsViewController.swift` |
| Notifica POI nearby | ✅ | `NotificationManager.swift` |
| Notifica logging reminder | ✅ | `scheduleLoggingReminder()` |
| Geofencing | ✅ | `GeofenceManager.swift` |

**Totale: 34/34 requisiti rispettati (100%)**

**Funzionalita extra implementate:**
- Chat AI con Tool Calling (3 tool)
- Genera Itinerario (Guided Generation)
- Packing List (Guided Generation)
- Briefing Destinazione (Guided Generation)

---

## 8. Conclusioni

### 8.1 Obiettivi raggiunti

Questo progetto ha raggiunto tutti gli obiettivi prefissati:

1. **Funzionalita complete**: Tutti i 34 requisiti del progetto sono stati implementati e testati
2. **Architettura solida**: Pattern MVC con Services Layer, codice modulare e manutenibile
3. **UI professionale**: Interfaccia UIKit programmatica, responsive, con supporto dark mode
4. **Testing**: 123 unit test + 70+ UI test per copertura completa
5. **Documentazione**: Codice commentato in italiano

### 8.2 Innovazione: Apple Foundation Models

L'integrazione di Apple Foundation Models rappresenta l'aspetto piu innovativo del progetto. Le funzionalita implementate dimostrano:

- **Guided Generation**: Output strutturato e type-safe per itinerari, packing list e briefing
- **Custom Instructions**: Personalita AI coerente e comportamento appropriato al contesto
- **Tool Calling**: AI che non solo risponde ma **agisce** nell'app, creando viaggi e note

Questa implementazione mostra come l'AI on-device possa migliorare significativamente l'esperienza utente mantenendo la privacy e funzionando offline.

### 8.3 Competenze acquisite

Lo sviluppo di Travel Companion ha permesso di approfondire:

- Sviluppo iOS nativo con UIKit programmatico
- Pattern architetturali (MVC, Singleton, Delegate, Observer)
- Core Data e persistenza locale
- MapKit e Core Location
- Background jobs e notifiche
- Apple Foundation Models e AI on-device
- Testing (Unit e UI) in ambiente iOS

---

**Documento generato il:** 11 Gennaio 2026

**Versione progetto:** 3.0

**Repository:** https://github.com/giadaf-boosha/travel_companion
