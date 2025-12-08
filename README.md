# Travel Companion

Applicazione mobile iOS per pianificare, tracciare e documentare esperienze di viaggio.

**Corso:** Laboratorio di applicazioni mobili (LAM)
**Università:** Alma Mater Studiorum - Università di Bologna
**Anno accademico:** 2024/2025
**Docenti:** Federico Montori, Lorenzo Gigli

---

## Indice

1. [Panoramica](#panoramica)
2. [Requisiti funzionali](#requisiti-funzionali)
3. [Architettura](#architettura)
4. [Componenti iOS](#componenti-ios)
5. [Database locale](#database-locale)
6. [Funzionalità aggiuntiva: AI travel assistant](#funzionalità-aggiuntiva-ai-travel-assistant)
7. [Struttura del progetto](#struttura-del-progetto)
8. [Requisiti di sistema](#requisiti-di-sistema)
9. [Installazione e configurazione](#installazione-e-configurazione)
10. [Testing](#testing)

---

## Panoramica

Travel Companion è un'applicazione iOS nativa sviluppata in Swift con UIKit e storyboard che permette agli utenti di:

- Creare piani di viaggio con destinazione e date
- Tracciare percorsi tramite GPS durante i viaggi
- Allegare foto e note a momenti specifici del viaggio
- Visualizzare lo storico dei viaggi attraverso mappe e statistiche
- Ricevere notifiche su punti di interesse nelle vicinanze
- Pianificare viaggi con l'assistenza di un chatbot AI

L'applicazione segue il pattern architetturale **Model-View-Controller (MVC)** come richiesto dallo sviluppo iOS con UIKit.

---

## Requisiti funzionali

### 1. Registrazione delle attività

#### 1.1 Creazione piano di viaggio
- Interfaccia per inserire destinazione e date di viaggio
- Selezione del tipo di viaggio
- Salvataggio del piano nel database locale

#### 1.2 Tipi di viaggio supportati
L'applicazione supporta i seguenti tipi di viaggio obbligatori:

| Tipo | Descrizione | Caratteristiche |
|------|-------------|-----------------|
| **Local trip** | Viaggio in città | Breve durata, stesso giorno |
| **Day trip** | Escursione giornaliera | Fuori città, ritorno in giornata |
| **Multi-day trip** | Vacanza | Più giorni, calcolo distanza totale |

#### 1.3 Logging del percorso GPS
- Pulsante start/stop per avviare e terminare il tracciamento
- Registrazione delle coordinate GPS lungo il percorso
- Calcolo del tempo di viaggio
- Per i viaggi multi-day: calcolo e visualizzazione della distanza totale percorsa

#### 1.4 Allegati multimediali
- Scatto foto tramite fotocamera del dispositivo durante il viaggio
- Aggiunta di note testuali a momenti specifici
- Associazione automatica della posizione GPS agli allegati
- Salvataggio di foto e note nel database locale

#### 1.5 Persistenza dati
Tutti i dati relativi ai viaggi vengono salvati in un database locale:
- Piani di viaggio
- Percorsi GPS (lista di coordinate con timestamp)
- Foto (riferimento al file locale)
- Note testuali

### 2. Visualizzazione dei viaggi

#### 2.1 Lista viaggi
- Elenco di tutti i viaggi passati con UITableView
- Filtro per:
  - Data
  - Destinazione
  - Tipo di viaggio

#### 2.2 Mappa viaggi
- Visualizzazione dei percorsi registrati su mappa (MapKit)
- Possibilità di selezionare un viaggio specifico per visualizzarne il dettaglio

### 3. Visualizzazioni statistiche

L'applicazione include almeno due visualizzazioni interattive dei dati di viaggio:

#### 3.1 Map view
- Visualizzazione dei percorsi registrati sulla mappa
- Heatmap delle località visitate in un periodo selezionato (es. ultimo mese)
- Marker interattivi per foto e note

#### 3.2 Bar chart / timeline
- Numero di viaggi effettuati per mese
- Distanza totale percorsa per mese
- Grafici interattivi con possibilità di selezione del periodo

### 4. Operazioni in background

#### 4.1 Notifiche periodiche
Implementazione di almeno un tipo di notifica ricorrente:

- **Punti di interesse nelle vicinanze**: alert basati sulla posizione GPS corrente dell'utente che segnalano landmark o attrazioni nelle vicinanze
- **Promemoria di logging**: notifica se l'utente non ha registrato viaggi di recente

#### 4.2 Operazione background aggiuntiva
Implementazione di una delle seguenti funzionalità:

**Opzione A - Automatic journey tracking:**
- Utilizzo dell'Activity Recognition per rilevare quando l'utente è in movimento (camminata, guida)
- Prompt per avviare il logging del viaggio o avvio automatico della registrazione
- Richiesta occasionale di conferma del tipo di viaggio

**Opzione B - Geofencing:**
- Definizione di aree di interesse da parte dell'utente (casa, destinazioni frequenti)
- Registrazione degli eventi di ingresso/uscita dalle zone tramite Geofencing API
- Salvataggio degli eventi separatamente dai log di viaggio (timestamp, tipo evento)

### 5. Gestione periodi senza viaggi attivi

L'applicazione gestisce i periodi senza viaggi attivi attraverso un approccio basato su **Empty State UI**, una pratica standard nelle applicazioni mobile moderne conforme alle [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/).

#### Implementazione

| Componente | Funzionalità |
|------------|--------------|
| **Empty State View** | Quando non ci sono viaggi registrati, l'utente visualizza un messaggio contestuale che varia in base allo stato dell'applicazione |
| **Flag `isActive`** | Proprietà booleana nell'entità `Trip` che distingue i viaggi in corso da quelli completati |
| **Messaggi dinamici** | Il testo dell'empty state cambia in base al contesto (filtri attivi, ricerca in corso, o assenza totale di dati) |

#### Comportamento dell'Empty State

| Contesto | Messaggio visualizzato |
|----------|------------------------|
| Nessun viaggio | "Nessun viaggio ancora. Tocca + per crearne uno!" |
| Filtro attivo senza risultati | "Nessun viaggio in questa categoria" |
| Ricerca senza risultati | "Nessun viaggio trovato per '[termine]'" |

#### Motivazione della scelta progettuale

Questo approccio è stato preferito rispetto a una marcatura esplicita "no travel" nella timeline per i seguenti motivi:

1. **Usabilità**: L'empty state è più intuitivo per l'utente e comunica immediatamente lo stato dell'applicazione
2. **Conformità UX**: Segue le best practice di design iOS e le Human Interface Guidelines di Apple
3. **Semplicità**: Evita complessità aggiuntiva nel modello dati senza sacrificare la chiarezza dell'interfaccia
4. **Distinzione visiva**: Il flag `isActive` permette comunque di identificare immediatamente lo stato di ogni viaggio nella lista (badge "In corso" per viaggi attivi)

---

## Architettura

### Pattern MVC (Model-View-Controller)

L'applicazione segue rigorosamente il pattern MVC come richiesto per lo sviluppo iOS con UIKit:

```
┌─────────────────────────────────────────────────────────────┐
│                      CONTROLLER                              │
│                   (ViewController)                           │
│                                                              │
│  ┌─────────────┐                      ┌─────────────┐       │
│  │   Target    │◄────────────────────►│   Outlet    │       │
│  └─────────────┘                      └─────────────┘       │
│         ▲                                    │               │
│         │ Action                             │               │
│         │                                    ▼               │
└─────────┼────────────────────────────────────┼───────────────┘
          │                                    │
          │                                    │
┌─────────┴─────────┐              ┌───────────┴───────────┐
│       VIEW        │              │        MODEL          │
│   (Storyboard)    │              │   (Data structures)   │
│                   │              │                       │
│ - UITableView     │              │ - Trip                │
│ - UIButton        │              │ - Route               │
│ - UILabel         │              │ - Photo               │
│ - MKMapView       │              │ - Note                │
│ - UIImageView     │              │ - Location            │
└───────────────────┘              └───────────────────────┘
```

### Comunicazione tra componenti

| Da | A | Meccanismo |
|----|---|------------|
| Controller | View | Outlet (`@IBOutlet`) |
| View | Controller | Action (`@IBAction`) con target |
| Controller | Model | Accesso diretto |
| Model | Controller | Notifications / KVO |
| View | Model | **Mai** (comunicazione vietata) |

---

## Componenti iOS

### UIKit e storyboard

L'applicazione utilizza UIKit con storyboard come interfaccia grafica, seguendo l'approccio tradizionale iOS:

#### ViewController e scene
- Ogni schermata corrisponde a una scene nello storyboard
- Ogni scene è associata a un ViewController dedicato
- Utilizzo di `@IBOutlet` per collegare elementi UI al codice
- Utilizzo di `@IBAction` per gestire eventi utente

#### Elementi UI utilizzati

| Componente | Utilizzo |
|------------|----------|
| `UIViewController` | Controller base per ogni schermata |
| `UINavigationController` | Navigazione tra schermate con stack |
| `UITableView` | Lista viaggi, lista note |
| `UITableViewCell` | Celle personalizzate per i viaggi |
| `UIButton` | Azioni (start/stop tracking, scatta foto) |
| `UILabel` | Testi e informazioni |
| `UITextField` | Input destinazione |
| `UIDatePicker` | Selezione date viaggio |
| `UISegmentedControl` | Selezione tipo viaggio |
| `UIImageView` | Visualizzazione foto |
| `UITextView` | Input/visualizzazione note |
| `UISwitch` | Toggle impostazioni |
| `UIStackView` | Organizzazione layout |

### AutoLayout

Utilizzo di AutoLayout per garantire responsività su diversi dispositivi iOS:

- Constraint basati su Safe Area
- Supporto per variazioni di size class (compact/regular)
- Utilizzo di `UIStackView` per layout flessibili
- Constraint con priorità per gestire conflitti

### Navigazione

```
┌──────────────────┐
│ Navigation       │
│ Controller       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     Segue      ┌──────────────────┐
│   Home View      │───────────────►│  Trip Detail     │
│   Controller     │                │  ViewController  │
└────────┬─────────┘                └──────────────────┘
         │
         │ Segue
         ▼
┌──────────────────┐     Segue      ┌──────────────────┐
│   Trip List      │───────────────►│  Map View        │
│   ViewController │                │  Controller      │
└──────────────────┘                └──────────────────┘
```

- Utilizzo di segue per transizioni tra schermate
- Passaggio parametri tramite `prepare(for:sender:)`
- Back button automatico gestito dal Navigation Controller
- Identificatori stringa per ogni segue

### UITableView e prototype cell

Implementazione della lista viaggi con UITableView:

```swift
// Classe per la cella personalizzata
class TripCell: UITableViewCell {
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var tripTypeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
}

// ViewController come delegate e dataSource
extension TripListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return trips.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "TripCell"
        ) as! TripCell
        // Configurazione cella
        return cell
    }
}

extension TripListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        // Navigazione al dettaglio
    }
}
```

### Lifecycle del ViewController

Gestione del ciclo di vita delle schermate:

| Metodo | Utilizzo |
|--------|----------|
| `viewDidLoad()` | Inizializzazione una tantum (simile a `onCreate`) |
| `viewWillAppear(_:)` | Preparazione prima della visualizzazione |
| `viewDidAppear(_:)` | Schermata completamente visibile |
| `viewWillDisappear(_:)` | Preparazione prima della scomparsa |
| `viewDidDisappear(_:)` | Schermata non più visibile |
| `traitCollectionDidChange(_:)` | Gestione rotazione schermo |

### MapKit

Integrazione mappe native iOS:

```swift
import MapKit

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showsUserLocation = true
    }

    func displayRoute(_ coordinates: [CLLocationCoordinate2D]) {
        let polyline = MKPolyline(coordinates: coordinates,
                                   count: coordinates.count)
        mapView.addOverlay(polyline)
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
```

### Core Location

Gestione GPS e geolocalizzazione:

```swift
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    var onLocationUpdate: ((CLLocation) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationUpdate?(location)
    }
}
```

### Camera e foto

Integrazione fotocamera per scattare foto durante il viaggio:

```swift
import UIKit

class PhotoCaptureViewController: UIViewController,
                                   UIImagePickerControllerDelegate,
                                   UINavigationControllerDelegate {

    func capturePhoto() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            // Salva foto con coordinate GPS correnti
        }
        dismiss(animated: true)
    }
}
```

### Notifiche locali

Implementazione notifiche periodiche:

```swift
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            // Gestione risposta
        }
    }

    func scheduleNearbyPOINotification(poiName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Punto di interesse nelle vicinanze"
        content.body = "Sei vicino a \(poiName). Vuoi aggiungerlo al tuo viaggio?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleReminderNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Registra il tuo viaggio"
        content.body = "Non hai registrato viaggi di recente. Stai pianificando qualcosa?"
        content.sound = .default

        // Notifica periodica ogni 3 giorni
        var dateComponents = DateComponents()
        dateComponents.hour = 10

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
```

### Background processing

#### Geofencing (opzione implementata)

```swift
import CoreLocation

class GeofenceManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    func setupGeofence(center: CLLocationCoordinate2D,
                       radius: CLLocationDistance,
                       identifier: String) {
        let region = CLCircularRegion(
            center: center,
            radius: radius,
            identifier: identifier
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true

        locationManager.startMonitoring(for: region)
    }

    func locationManager(_ manager: CLLocationManager,
                         didEnterRegion region: CLRegion) {
        // Salva evento ingresso nel database
        saveGeofenceEvent(regionId: region.identifier, eventType: .enter)
    }

    func locationManager(_ manager: CLLocationManager,
                         didExitRegion region: CLRegion) {
        // Salva evento uscita nel database
        saveGeofenceEvent(regionId: region.identifier, eventType: .exit)
    }
}
```

---

## Database locale

### Core Data

Utilizzo di Core Data per la persistenza dei dati:

#### Modello dati

```
┌─────────────────┐       ┌─────────────────┐
│      Trip       │       │     Route       │
├─────────────────┤       ├─────────────────┤
│ id: UUID        │       │ id: UUID        │
│ destination     │1     *│ tripId: UUID    │
│ startDate       │───────│ timestamp       │
│ endDate         │       │ latitude        │
│ tripType        │       │ longitude       │
│ totalDistance   │       └─────────────────┘
└────────┬────────┘
         │
         │ 1
         │
         │ *
┌────────┴────────┐       ┌─────────────────┐
│     Photo       │       │      Note       │
├─────────────────┤       ├─────────────────┤
│ id: UUID        │       │ id: UUID        │
│ tripId: UUID    │       │ tripId: UUID    │
│ imagePath       │       │ content         │
│ latitude        │       │ latitude        │
│ longitude       │       │ longitude       │
│ timestamp       │       │ timestamp       │
└─────────────────┘       └─────────────────┘

┌─────────────────┐       ┌─────────────────┐
│  GeofenceZone   │       │ GeofenceEvent   │
├─────────────────┤       ├─────────────────┤
│ id: UUID        │1     *│ id: UUID        │
│ name            │───────│ zoneId: UUID    │
│ latitude        │       │ eventType       │
│ longitude       │       │ timestamp       │
│ radius          │       └─────────────────┘
└─────────────────┘
```

#### Enum per tipi di viaggio

```swift
enum TripType: String, CaseIterable {
    case local = "Local trip"
    case dayTrip = "Day trip"
    case multiDay = "Multi-day trip"
}
```

---

## Funzionalità aggiuntiva: AI travel assistant

### Descrizione

L'applicazione include un chatbot integrato basato su **GPT-5.1-mini** di OpenAI che assiste l'utente nella pianificazione dei viaggi.

### Funzionalità del chatbot

| Funzionalità | Descrizione |
|--------------|-------------|
| Suggerimenti destinazioni | Propone destinazioni basate sulle preferenze dell'utente |
| Pianificazione itinerari | Crea itinerari giornalieri per le destinazioni scelte |
| Informazioni locali | Fornisce info su attrazioni, ristoranti, trasporti |
| Consigli pratici | Suggerimenti su meteo, abbigliamento, documenti necessari |

### Architettura del chatbot

```
┌─────────────────────────────────────────────────────────────┐
│                    ChatViewController                        │
│                                                              │
│  ┌─────────────────┐         ┌─────────────────────────┐   │
│  │  UITableView    │         │    UITextField          │   │
│  │  (messaggi)     │         │    (input utente)       │   │
│  └─────────────────┘         └─────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    ChatService                               │
│                                                              │
│  - Gestione conversazione                                   │
│  - Chiamata API OpenAI                                      │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    OpenAI API                                │
│                    (GPT-5.1-mini)                            │
└──────────────────────────────────────────────────────────────┘
```

### Implementazione

```swift
import Foundation

class ChatService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private var conversationHistory: [Message] = []

    struct Message: Codable {
        let role: String
        let content: String
    }

    init(apiKey: String) {
        self.apiKey = apiKey
        setupSystemPrompt()
    }

    private func setupSystemPrompt() {
        let systemPrompt = """
        Sei un assistente di viaggio esperto e amichevole.
        Aiuti gli utenti a pianificare viaggi, suggerire destinazioni,
        creare itinerari e fornire consigli pratici.
        Rispondi sempre in italiano in modo conciso e utile.
        """
        conversationHistory.append(Message(role: "system", content: systemPrompt))
    }

    func sendMessage(_ userMessage: String,
                     completion: @escaping (Result<String, Error>) -> Void) {

        conversationHistory.append(Message(role: "user", content: userMessage))

        // Prepara richiesta API
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": "gpt-5.1-mini",
            "messages": conversationHistory.map { ["role": $0.role, "content": $0.content] },
            "max_tokens": 500,
            "temperature": 0.7
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                completion(.failure(NSError(domain: "", code: -1)))
                return
            }

            self?.conversationHistory.append(Message(role: "assistant", content: content))
            completion(.success(content))
        }.resume()
    }

    func clearHistory() {
        conversationHistory.removeAll()
        setupSystemPrompt()
    }
}
```

### Interfaccia utente del chatbot

```swift
class ChatViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!

    private var messages: [(role: String, content: String)] = []
    private let chatService = ChatService(apiKey: Config.openAIApiKey)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupKeyboardHandling()
    }

    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard let text = messageTextField.text, !text.isEmpty else { return }

        // Aggiungi messaggio utente
        messages.append((role: "user", content: text))
        tableView.reloadData()
        messageTextField.text = ""

        // Invia al servizio
        chatService.sendMessage(text) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.messages.append((role: "assistant", content: response))
                case .failure:
                    self?.messages.append((role: "assistant",
                                           content: "Mi dispiace, si è verificato un errore. Riprova."))
                }
                self?.tableView.reloadData()
                self?.scrollToBottom()
            }
        }
    }
}
```

---

## Struttura del progetto

```
TravelCompanion/
├── TravelCompanion.xcodeproj
├── TravelCompanion/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── Info.plist
│   │
│   ├── Models/
│   │   ├── Trip.swift
│   │   ├── Route.swift
│   │   ├── Photo.swift
│   │   ├── Note.swift
│   │   ├── GeofenceZone.swift
│   │   ├── GeofenceEvent.swift
│   │   └── TripType.swift
│   │
│   ├── Views/
│   │   ├── Main.storyboard
│   │   ├── LaunchScreen.storyboard
│   │   └── Cells/
│   │       ├── TripCell.swift
│   │       ├── PhotoCell.swift
│   │       ├── NoteCell.swift
│   │       └── ChatMessageCell.swift
│   │
│   ├── Controllers/
│   │   ├── HomeViewController.swift
│   │   ├── TripListViewController.swift
│   │   ├── TripDetailViewController.swift
│   │   ├── NewTripViewController.swift
│   │   ├── ActiveTripViewController.swift
│   │   ├── MapViewController.swift
│   │   ├── StatisticsViewController.swift
│   │   ├── ChatViewController.swift
│   │   ├── SettingsViewController.swift
│   │   └── GeofenceViewController.swift
│   │
│   ├── Services/
│   │   ├── LocationManager.swift
│   │   ├── GeofenceManager.swift
│   │   ├── NotificationManager.swift
│   │   ├── ChatService.swift
│   │   └── CoreDataManager.swift
│   │
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   ├── CLLocation+Extensions.swift
│   │   └── UIViewController+Extensions.swift
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   └── TravelCompanion.xcdatamodeld
│   │
│   └── Config/
│       └── Config.swift
│
└── TravelCompanionTests/
    └── TravelCompanionTests.swift
```

---

## Requisiti di sistema

### Sviluppo
- macOS Sonoma 14.5 o successivo
- Xcode 16.0 o successivo
- Swift 5.9 o successivo

### Esecuzione
- iOS 17.0 o successivo
- Dispositivo con GPS (per funzionalità di tracking)
- Fotocamera (per scattare foto durante i viaggi)
- Connessione internet (per il chatbot AI)

### Permessi richiesti

I seguenti permessi devono essere dichiarati in `Info.plist`:

| Chiave | Descrizione |
|--------|-------------|
| `NSLocationWhenInUseUsageDescription` | Accesso GPS durante l'uso |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Accesso GPS in background (geofencing) |
| `NSCameraUsageDescription` | Accesso alla fotocamera |
| `NSPhotoLibraryUsageDescription` | Accesso alla libreria foto |

---

## Installazione e configurazione

### 1. Clonare il repository

```bash
git clone https://github.com/giadaf-boosha/travel_companion.git
cd travel_companion
```

### 2. Aprire il progetto in Xcode

```bash
open TravelCompanion/TravelCompanion.xcodeproj
```

### 3. Configurare l'API key di OpenAI (IMPORTANTE)

L'API key di OpenAI **non è inclusa nel repository** per motivi di sicurezza. Per configurarla:

1. Copia il file di esempio:
   ```bash
   cp TravelCompanion/TravelCompanion/Config/Secrets.xcconfig.example \
      TravelCompanion/TravelCompanion/Config/Secrets.xcconfig
   ```

2. Modifica `Secrets.xcconfig` con la tua API key:
   ```
   OPENAI_API_KEY = sk-proj-YOUR_ACTUAL_API_KEY_HERE
   ```

3. In Xcode, vai su **Project Settings > Info** e aggiungi una nuova riga:
   - Key: `OPENAI_API_KEY`
   - Value: `$(OPENAI_API_KEY)`

4. Assicurati che `Secrets.xcconfig` sia nel tuo `.gitignore` (già configurato)

> **Nota:** Il file `Secrets.xcconfig` contiene dati sensibili e **non deve mai essere committato** nel repository. Solo il file `.example` è tracciato da git.

#### Alternativa: Variabile d'ambiente

Puoi anche configurare l'API key come variabile d'ambiente:
```bash
export OPENAI_API_KEY="sk-proj-YOUR_ACTUAL_API_KEY_HERE"
```

Questa opzione è utile per CI/CD e ambienti di sviluppo condivisi.

### 4. Build e run

- Selezionare un simulatore o dispositivo fisico
- Premere `Cmd + R` per compilare e avviare l'applicazione

---

## Testing

### Test su simulatore

L'applicazione può essere testata sul simulatore iOS incluso in Xcode. Alcune funzionalità richiedono configurazione aggiuntiva:

- **GPS**: Usare `Debug > Location > Custom Location` per simulare posizioni
- **Fotocamera**: Non disponibile su simulatore, usare libreria foto

### Test su dispositivo fisico

Per testare su dispositivo fisico è necessario:
1. Account Apple Developer (gratuito per sviluppo)
2. Certificato di sviluppo configurato in Xcode
3. Dispositivo registrato nel proprio team

---

## Riferimenti

- [Documentazione UIKit](https://developer.apple.com/documentation/uikit)
- [Documentazione Core Location](https://developer.apple.com/documentation/corelocation)
- [Documentazione MapKit](https://developer.apple.com/documentation/mapkit)
- [Documentazione Core Data](https://developer.apple.com/documentation/coredata)
- [OpenAI API](https://platform.openai.com/docs)
- [Swift Language Guide](https://www.swift.org/documentation/)

---

## Licenza

Progetto sviluppato per il corso di Laboratorio di applicazioni mobili, Università di Bologna.
