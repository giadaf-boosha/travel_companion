# Piano di implementazione - Travel Companion iOS

## Panoramica

Questo documento descrive il piano completo per implementare l'applicazione Travel Companion iOS, un'app nativa sviluppata in Swift con UIKit e storyboard per il corso LAM dell'Università di Bologna.

---

## Fase 1: Setup progetto Xcode

### 1.1 Creazione progetto

**Obiettivo:** Creare il progetto Xcode con la configurazione corretta.

**Azioni:**
1. Creare nuovo progetto Xcode:
   - Template: App
   - Interface: Storyboard
   - Language: Swift
   - Use Core Data: Yes
   - Product Name: TravelCompanion
   - Organization Identifier: com.unibo.lam
   - Deployment Target: iOS 17.0

2. Configurare la struttura delle cartelle:
```
TravelCompanion/
├── Application/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Models/
├── Views/
│   ├── Storyboards/
│   └── Cells/
├── Controllers/
├── Services/
├── Extensions/
├── Utilities/
├── Resources/
└── Config/
```

### 1.2 Configurazione Info.plist

**File:** `Info.plist`

**Permessi da aggiungere:**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Travel Companion usa la tua posizione per tracciare i percorsi dei tuoi viaggi.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Travel Companion usa la tua posizione in background per il geofencing.</string>

<key>NSCameraUsageDescription</key>
<string>Travel Companion usa la fotocamera per scattare foto durante i viaggi.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Travel Companion accede alla libreria foto per salvare le foto dei viaggi.</string>

<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

### 1.3 File Constants.swift

**File:** `Utilities/Constants.swift`

**Contenuto:**
- Identificatori segue
- Identificatori celle
- Chiavi UserDefaults
- Nomi notifiche
- Costanti numeriche (raggio geofence default, intervallo notifiche, etc.)

### 1.4 File Config.swift

**File:** `Config/Config.swift`

**Contenuto:**
- API key OpenAI (placeholder, da sostituire)
- URL base API
- Configurazioni timeout

---

## Fase 2: Modello dati Core Data

### 2.1 Schema Core Data

**File:** `TravelCompanion.xcdatamodeld`

**Entità da creare:**

#### Trip
| Attributo | Tipo | Obbligatorio | Default |
|-----------|------|--------------|---------|
| id | UUID | Si | - |
| destination | String | Si | - |
| startDate | Date | Si | - |
| endDate | Date | No | - |
| tripType | String | Si | - |
| totalDistance | Double | Si | 0 |
| isActive | Boolean | Si | false |
| createdAt | Date | Si | - |

#### Route
| Attributo | Tipo | Obbligatorio |
|-----------|------|--------------|
| id | UUID | Si |
| latitude | Double | Si |
| longitude | Double | Si |
| altitude | Double | No |
| timestamp | Date | Si |
| speed | Double | No |

#### Photo
| Attributo | Tipo | Obbligatorio |
|-----------|------|--------------|
| id | UUID | Si |
| imagePath | String | Si |
| latitude | Double | Si |
| longitude | Double | Si |
| timestamp | Date | Si |
| caption | String | No |

#### Note
| Attributo | Tipo | Obbligatorio |
|-----------|------|--------------|
| id | UUID | Si |
| content | String | Si |
| latitude | Double | No |
| longitude | Double | No |
| timestamp | Date | Si |

#### GeofenceZone
| Attributo | Tipo | Obbligatorio |
|-----------|------|--------------|
| id | UUID | Si |
| name | String | Si |
| latitude | Double | Si |
| longitude | Double | Si |
| radius | Double | Si |
| isActive | Boolean | Si |
| createdAt | Date | Si |

#### GeofenceEvent
| Attributo | Tipo | Obbligatorio |
|-----------|------|--------------|
| id | UUID | Si |
| eventType | String | Si |
| timestamp | Date | Si |

**Relazioni:**
- Trip → Route: uno-a-molti, cascade delete
- Trip → Photo: uno-a-molti, cascade delete
- Trip → Note: uno-a-molti, cascade delete
- GeofenceZone → GeofenceEvent: uno-a-molti, cascade delete

### 2.2 Model Swift files

**File da creare:**

1. `Models/TripType.swift` - Enum per tipi viaggio
2. `Models/GeofenceEventType.swift` - Enum per eventi geofence
3. `Models/ChatMessage.swift` - Struttura per messaggi chat

---

## Fase 3: Servizi

### 3.1 CoreDataManager

**File:** `Services/CoreDataManager.swift`

**Responsabilità:**
- Gestione NSPersistentContainer
- CRUD per Trip
- CRUD per Route
- CRUD per Photo
- CRUD per Note
- CRUD per GeofenceZone e GeofenceEvent
- Query per statistiche (viaggi per mese, distanza per mese)
- Filtri (per data, destinazione, tipo)

**Metodi principali:**
```swift
// Trip
func createTrip(destination:startDate:endDate:tripType:) -> Trip
func fetchAllTrips() -> [Trip]
func fetchTrips(filteredBy type: TripType?) -> [Trip]
func fetchTrips(from startDate: Date, to endDate: Date) -> [Trip]
func fetchTrips(destination: String) -> [Trip]
func updateTrip(_:)
func deleteTrip(_:)
func setTripActive(_:isActive:)

// Route
func addRoutePoint(to trip: Trip, location: CLLocation)
func fetchRoute(for trip: Trip) -> [Route]
func calculateTotalDistance(for trip: Trip) -> Double

// Photo
func addPhoto(to trip: Trip, imagePath: String, location: CLLocation) -> Photo
func fetchPhotos(for trip: Trip) -> [Photo]
func deletePhoto(_:)

// Note
func addNote(to trip: Trip, content: String, location: CLLocation?) -> Note
func fetchNotes(for trip: Trip) -> [Note]
func updateNote(_:content:)
func deleteNote(_:)

// GeofenceZone
func createGeofenceZone(name:center:radius:) -> GeofenceZone
func fetchAllGeofenceZones() -> [GeofenceZone]
func deleteGeofenceZone(_:)

// GeofenceEvent
func saveGeofenceEvent(zone:eventType:)
func fetchEvents(for zone: GeofenceZone) -> [GeofenceEvent]

// Statistics
func getTripsCountByMonth(year: Int) -> [Int: Int]
func getDistanceByMonth(year: Int) -> [Int: Double]
func getTotalTripsCount() -> Int
func getTotalDistance() -> Double
```

### 3.2 LocationManager

**File:** `Services/LocationManager.swift`

**Responsabilità:**
- Gestione CLLocationManager
- Richiesta autorizzazioni
- Tracking posizione
- Registrazione percorso
- Calcolo distanza

**Proprietà:**
```swift
static let shared: LocationManager
weak var delegate: LocationManagerDelegate?
private(set) var currentLocation: CLLocation?
private(set) var isTracking: Bool
private(set) var recordedLocations: [CLLocation]
```

**Metodi:**
```swift
func requestAuthorization()
func startTracking()
func stopTracking()
func getRecordedRoute() -> [CLLocationCoordinate2D]
func calculateTotalDistance() -> CLLocationDistance
func clearRecordedLocations()
```

**Delegate protocol:**
```swift
protocol LocationManagerDelegate: AnyObject {
    func locationManager(_ manager: LocationManager, didUpdateLocation location: CLLocation)
    func locationManager(_ manager: LocationManager, didFailWithError error: Error)
    func locationManager(_ manager: LocationManager, didChangeAuthorization status: CLAuthorizationStatus)
}
```

### 3.3 GeofenceManager

**File:** `Services/GeofenceManager.swift`

**Responsabilità:**
- Setup regioni geofence
- Monitoring ingresso/uscita
- Gestione limite 20 regioni iOS
- Salvataggio eventi nel database

**Metodi:**
```swift
func addGeofence(for zone: GeofenceZone) -> Bool
func removeGeofence(identifier: String)
func removeAllGeofences()
func getMonitoredRegions() -> Set<CLRegion>
```

**Delegate protocol:**
```swift
protocol GeofenceManagerDelegate: AnyObject {
    func geofenceManager(_ manager: GeofenceManager, didEnterRegion region: CLRegion)
    func geofenceManager(_ manager: GeofenceManager, didExitRegion region: CLRegion)
}
```

### 3.4 NotificationManager

**File:** `Services/NotificationManager.swift`

**Responsabilità:**
- Richiesta autorizzazione notifiche
- Notifiche POI nelle vicinanze
- Promemoria logging viaggio
- Gestione badge e suoni

**Metodi:**
```swift
func requestAuthorization(completion: @escaping (Bool) -> Void)
func scheduleNearbyPOINotification(poiName: String, distance: Double)
func scheduleLoggingReminder(daysInterval: Int)
func cancelLoggingReminder()
func cancelAllPendingNotifications()
```

### 3.5 PhotoStorageManager

**File:** `Services/PhotoStorageManager.swift`

**Responsabilità:**
- Salvataggio foto su filesystem
- Generazione path univoci
- Caricamento foto
- Eliminazione foto
- Generazione thumbnail

**Metodi:**
```swift
func savePhoto(_ image: UIImage, for tripId: UUID) -> String?
func loadPhoto(at path: String) -> UIImage?
func deletePhoto(at path: String) -> Bool
func generateThumbnail(for image: UIImage, size: CGSize) -> UIImage?
func deleteAllPhotos(for tripId: UUID)
```

### 3.6 ChatService

**File:** `Services/ChatService.swift`

**Responsabilità:**
- Comunicazione con OpenAI API
- Gestione cronologia conversazione
- System prompt per assistente viaggio
- Parsing risposte

**Proprietà:**
```swift
private let apiKey: String
private let baseURL = "https://api.openai.com/v1/chat/completions"
private var conversationHistory: [ChatMessage]
```

**Metodi:**
```swift
func sendMessage(_ message: String, completion: @escaping (Result<String, Error>) -> Void)
func clearConversation()
func getConversationHistory() -> [ChatMessage]
```

**System prompt:**
```
Sei un assistente di viaggio esperto e amichevole.
Aiuti gli utenti a pianificare viaggi, suggerire destinazioni,
creare itinerari e fornire consigli pratici.
Rispondi sempre in italiano in modo conciso e utile.
```

---

## Fase 4: Extensions

### 4.1 Date+Extensions.swift

**File:** `Extensions/Date+Extensions.swift`

**Funzionalità:**
```swift
extension Date {
    func formatted(style: DateFormatter.Style) -> String
    func timeAgo() -> String
    var startOfDay: Date
    var endOfDay: Date
    var startOfMonth: Date
    var endOfMonth: Date
    func isSameDay(as date: Date) -> Bool
    func daysBetween(_ date: Date) -> Int
}
```

### 4.2 CLLocation+Extensions.swift

**File:** `Extensions/CLLocation+Extensions.swift`

**Funzionalità:**
```swift
extension CLLocation {
    var coordinate2D: CLLocationCoordinate2D
    func formattedCoordinates() -> String
}

extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance
}

extension Array where Element == CLLocation {
    func totalDistance() -> CLLocationDistance
}
```

### 4.3 UIViewController+Extensions.swift

**File:** `Extensions/UIViewController+Extensions.swift`

**Funzionalità:**
```swift
extension UIViewController {
    func showAlert(title: String, message: String, completion: (() -> Void)?)
    func showConfirmationAlert(title: String, message: String, confirmAction: @escaping () -> Void)
    func showErrorAlert(_ error: Error)
    func hideKeyboardWhenTappedAround()
}
```

### 4.4 UIColor+Extensions.swift

**File:** `Extensions/UIColor+Extensions.swift`

**Funzionalità:**
```swift
extension UIColor {
    static let primaryColor: UIColor
    static let secondaryColor: UIColor
    static let accentColor: UIColor
    static let localTripColor: UIColor
    static let dayTripColor: UIColor
    static let multiDayTripColor: UIColor
}
```

### 4.5 String+Extensions.swift

**File:** `Extensions/String+Extensions.swift`

**Funzionalità:**
```swift
extension String {
    var trimmed: String
    var isNotEmpty: Bool
    func localized() -> String
}
```

---

## Fase 5: Storyboard e navigazione

### 5.1 Struttura Main.storyboard

**Gerarchia:**
```
UITabBarController (Initial View Controller)
│
├── Tab 1: "Home"
│   └── UINavigationController
│       └── HomeViewController
│           ├── Segue → NewTripViewController (modal)
│           └── Segue → ActiveTripViewController (push)
│
├── Tab 2: "Viaggi"
│   └── UINavigationController
│       └── TripListViewController
│           └── Segue → TripDetailViewController (push)
│               └── Segue → MapViewController (push, single trip)
│
├── Tab 3: "Mappa"
│   └── UINavigationController
│       └── MapViewController (all trips)
│
├── Tab 4: "Statistiche"
│   └── UINavigationController
│       └── StatisticsViewController
│
└── Tab 5: "Assistente"
    └── UINavigationController
        └── ChatViewController
```

**Accesso Settings:**
- Bar button item su ogni NavigationController
- Segue → SettingsViewController (modal)
  - Segue → GeofenceViewController (push)

### 5.2 Identificatori segue

```swift
struct SegueIdentifiers {
    static let showNewTrip = "showNewTrip"
    static let showActiveTrip = "showActiveTrip"
    static let showTripDetail = "showTripDetail"
    static let showTripMap = "showTripMap"
    static let showSettings = "showSettings"
    static let showGeofence = "showGeofence"
}
```

### 5.3 Identificatori celle

```swift
struct CellIdentifiers {
    static let tripCell = "TripCell"
    static let photoCell = "PhotoCell"
    static let noteCell = "NoteCell"
    static let chatUserCell = "ChatUserCell"
    static let chatAssistantCell = "ChatAssistantCell"
}
```

---

## Fase 6: ViewControllers

### 6.1 HomeViewController

**File:** `Controllers/HomeViewController.swift`

**UI Elements:**
- Logo/titolo app
- Pulsante "Nuovo viaggio" (grande, prominente)
- Pulsante "Continua viaggio" (se viaggio attivo)
- Card riepilogo ultimo viaggio
- Card statistiche rapide (totale viaggi, km totali)

**Funzionalità:**
- Verifica se esiste viaggio attivo all'avvio
- Navigazione a NewTripViewController
- Navigazione a ActiveTripViewController (se viaggio attivo)
- Mostra statistiche rapide dal database

**Outlets:**
```swift
@IBOutlet weak var newTripButton: UIButton!
@IBOutlet weak var continueTripButton: UIButton!
@IBOutlet weak var lastTripCard: UIView!
@IBOutlet weak var statsCard: UIView!
@IBOutlet weak var totalTripsLabel: UILabel!
@IBOutlet weak var totalDistanceLabel: UILabel!
```

### 6.2 TripListViewController

**File:** `Controllers/TripListViewController.swift`

**UI Elements:**
- UISearchBar per filtro destinazione
- UISegmentedControl per filtro tipo viaggio
- UITableView con TripCell
- Empty state view

**Funzionalità:**
- Caricamento lista viaggi da Core Data
- Filtro per tipo viaggio
- Filtro per destinazione (ricerca)
- Ordinamento per data (più recente prima)
- Pull to refresh
- Swipe to delete

**Protocols:**
- UITableViewDataSource
- UITableViewDelegate
- UISearchBarDelegate

**Outlets:**
```swift
@IBOutlet weak var searchBar: UISearchBar!
@IBOutlet weak var filterSegment: UISegmentedControl!
@IBOutlet weak var tableView: UITableView!
@IBOutlet weak var emptyStateView: UIView!
```

### 6.3 TripDetailViewController

**File:** `Controllers/TripDetailViewController.swift`

**UI Elements:**
- Header con destinazione e date
- Label tipo viaggio (con colore)
- Label distanza totale (per multi-day)
- UICollectionView foto (griglia)
- UITableView note
- Pulsante "Vedi su mappa"

**Funzionalità:**
- Visualizzazione dettagli viaggio
- Griglia foto con tap per ingrandire
- Lista note con possibilità di aggiunta
- Navigazione a mappa singolo viaggio
- Eliminazione viaggio

**Proprietà:**
```swift
var trip: Trip!
private var photos: [Photo] = []
private var notes: [Note] = []
```

### 6.4 NewTripViewController

**File:** `Controllers/NewTripViewController.swift`

**UI Elements:**
- UITextField destinazione
- UIDatePicker data inizio
- UIDatePicker data fine (opzionale)
- UISegmentedControl tipo viaggio
- Pulsante "Crea e inizia tracking"
- Pulsante "Salva senza tracking"

**Funzionalità:**
- Validazione input
- Creazione Trip nel database
- Opzione per iniziare tracking immediato
- Dismissal con callback

**Outlets:**
```swift
@IBOutlet weak var destinationTextField: UITextField!
@IBOutlet weak var startDatePicker: UIDatePicker!
@IBOutlet weak var endDatePicker: UIDatePicker!
@IBOutlet weak var tripTypeSegment: UISegmentedControl!
@IBOutlet weak var createButton: UIButton!
@IBOutlet weak var saveOnlyButton: UIButton!
```

### 6.5 ActiveTripViewController

**File:** `Controllers/ActiveTripViewController.swift`

**UI Elements:**
- MKMapView con posizione corrente
- Label destinazione
- Label tempo trascorso (timer)
- Label distanza percorsa
- Pulsante Start/Stop tracking (grande)
- Pulsante "Scatta foto"
- Pulsante "Aggiungi nota"
- Indicator stato GPS

**Funzionalità:**
- Tracking GPS in tempo reale
- Aggiornamento mappa con posizione
- Timer tempo trascorso
- Calcolo distanza in tempo reale
- Scatto foto con UIImagePickerController
- Aggiunta note con alert
- Salvataggio percorso nel database
- Gestione start/stop tracking

**Outlets:**
```swift
@IBOutlet weak var mapView: MKMapView!
@IBOutlet weak var destinationLabel: UILabel!
@IBOutlet weak var timerLabel: UILabel!
@IBOutlet weak var distanceLabel: UILabel!
@IBOutlet weak var trackingButton: UIButton!
@IBOutlet weak var photoButton: UIButton!
@IBOutlet weak var noteButton: UIButton!
@IBOutlet weak var gpsIndicator: UIView!
```

**Proprietà:**
```swift
var trip: Trip!
private var isTracking = false
private var timer: Timer?
private var startTime: Date?
private var routeCoordinates: [CLLocationCoordinate2D] = []
```

### 6.6 MapViewController

**File:** `Controllers/MapViewController.swift`

**UI Elements:**
- MKMapView a schermo intero
- UISegmentedControl per tipo visualizzazione (percorsi/heatmap)
- Toolbar con filtri
- Annotation per foto e note

**Funzionalità:**
- Visualizzazione tutti i percorsi (se nessun trip specifico)
- Visualizzazione singolo percorso (se trip specifico)
- Heatmap località visitate
- Marker foto cliccabili
- Marker note cliccabili
- Zoom su percorso selezionato

**Proprietà:**
```swift
var trip: Trip? // nil = mostra tutti
private var allTrips: [Trip] = []
private var overlays: [MKOverlay] = []
private var annotations: [MKAnnotation] = []
```

**Protocols:**
- MKMapViewDelegate

### 6.7 StatisticsViewController

**File:** `Controllers/StatisticsViewController.swift`

**UI Elements:**
- UISegmentedControl per selezione anno
- UIView per grafico viaggi per mese
- UIView per grafico distanza per mese
- Card totali (viaggi, km, foto, note)

**Funzionalità:**
- Grafico a barre viaggi per mese
- Grafico a barre distanza per mese
- Selezione anno
- Totali complessivi
- Animazione grafici

**Implementazione grafici:**
- Utilizzo di UIView custom con CAShapeLayer
- Oppure libreria Charts (da valutare)

### 6.8 ChatViewController

**File:** `Controllers/ChatViewController.swift`

**UI Elements:**
- UITableView messaggi
- UITextField input
- UIButton invio
- UIActivityIndicatorView loading
- Empty state con suggerimenti

**Funzionalità:**
- Visualizzazione cronologia chat
- Invio messaggi
- Ricezione risposte AI
- Auto-scroll a ultimo messaggio
- Gestione tastiera
- Gestione errori rete
- Suggerimenti iniziali cliccabili

**Outlets:**
```swift
@IBOutlet weak var tableView: UITableView!
@IBOutlet weak var inputTextField: UITextField!
@IBOutlet weak var sendButton: UIButton!
@IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
@IBOutlet weak var inputContainerBottomConstraint: NSLayoutConstraint!
```

**Proprietà:**
```swift
private let chatService = ChatService()
private var messages: [ChatMessage] = []
```

### 6.9 SettingsViewController

**File:** `Controllers/SettingsViewController.swift`

**UI Elements:**
- UITableView con sezioni statiche
- Toggle notifiche POI
- Toggle notifiche reminder
- Slider intervallo reminder (giorni)
- Cella "Gestisci zone geofence"
- Cella "Privacy e permessi"
- Cella "Informazioni app"

**Funzionalità:**
- Salvataggio preferenze in UserDefaults
- Navigazione a GeofenceViewController
- Apertura impostazioni sistema per permessi
- Visualizzazione versione app

### 6.10 GeofenceViewController

**File:** `Controllers/GeofenceViewController.swift`

**UI Elements:**
- MKMapView per selezione posizione
- UITextField nome zona
- UISlider raggio (50m - 500m)
- UITableView zone esistenti
- Pulsante "Aggiungi zona"

**Funzionalità:**
- Creazione nuova zona geofence
- Selezione posizione su mappa
- Impostazione raggio
- Lista zone esistenti
- Eliminazione zona
- Toggle attivazione zona

---

## Fase 7: Celle personalizzate

### 7.1 TripCell

**File:** `Views/Cells/TripCell.swift`

**UI Elements:**
```swift
@IBOutlet weak var destinationLabel: UILabel!
@IBOutlet weak var dateLabel: UILabel!
@IBOutlet weak var tripTypeLabel: UILabel!
@IBOutlet weak var tripTypeIndicator: UIView!
@IBOutlet weak var distanceLabel: UILabel!
@IBOutlet weak var photoCountLabel: UILabel!
```

**Metodo configure:**
```swift
func configure(with trip: Trip, photoCount: Int)
```

### 7.2 PhotoCell

**File:** `Views/Cells/PhotoCell.swift`

**UI Elements:**
```swift
@IBOutlet weak var imageView: UIImageView!
@IBOutlet weak var timestampLabel: UILabel!
```

**Metodo configure:**
```swift
func configure(with photo: Photo)
```

### 7.3 NoteCell

**File:** `Views/Cells/NoteCell.swift`

**UI Elements:**
```swift
@IBOutlet weak var contentLabel: UILabel!
@IBOutlet weak var timestampLabel: UILabel!
@IBOutlet weak var locationLabel: UILabel!
```

**Metodo configure:**
```swift
func configure(with note: Note)
```

### 7.4 ChatMessageCell (User e Assistant)

**File:** `Views/Cells/ChatMessageCell.swift`

**Varianti:**
- ChatUserCell: messaggio allineato a destra, sfondo blu
- ChatAssistantCell: messaggio allineato a sinistra, sfondo grigio

**UI Elements:**
```swift
@IBOutlet weak var messageLabel: UILabel!
@IBOutlet weak var bubbleView: UIView!
@IBOutlet weak var timestampLabel: UILabel!
```

---

## Fase 8: Utilities

### 8.1 Constants.swift

**File:** `Utilities/Constants.swift`

```swift
struct Constants {
    struct Segue {
        static let showNewTrip = "showNewTrip"
        static let showActiveTrip = "showActiveTrip"
        static let showTripDetail = "showTripDetail"
        static let showTripMap = "showTripMap"
        static let showSettings = "showSettings"
        static let showGeofence = "showGeofence"
    }

    struct Cell {
        static let tripCell = "TripCell"
        static let photoCell = "PhotoCell"
        static let noteCell = "NoteCell"
        static let chatUserCell = "ChatUserCell"
        static let chatAssistantCell = "ChatAssistantCell"
    }

    struct UserDefaultsKeys {
        static let notificationsEnabled = "notificationsEnabled"
        static let poiNotificationsEnabled = "poiNotificationsEnabled"
        static let reminderInterval = "reminderInterval"
        static let lastTripDate = "lastTripDate"
    }

    struct Notification {
        static let tripUpdated = "tripUpdated"
        static let locationUpdated = "locationUpdated"
        static let geofenceTriggered = "geofenceTriggered"
    }

    struct Defaults {
        static let geofenceRadius: Double = 100.0
        static let reminderIntervalDays: Int = 7
        static let maxGeofenceZones: Int = 20
    }
}
```

### 8.2 DistanceCalculator.swift

**File:** `Utilities/DistanceCalculator.swift`

```swift
struct DistanceCalculator {
    static func calculateDistance(from locations: [CLLocation]) -> CLLocationDistance
    static func formatDistance(_ meters: CLLocationDistance) -> String
    static func calculateDuration(from start: Date, to end: Date) -> TimeInterval
    static func formatDuration(_ seconds: TimeInterval) -> String
}
```

---

## Fase 9: Testing

### 9.1 Unit Tests

**File da creare:**
- `TravelCompanionTests/CoreDataManagerTests.swift`
- `TravelCompanionTests/LocationManagerTests.swift`
- `TravelCompanionTests/ChatServiceTests.swift`
- `TravelCompanionTests/DistanceCalculatorTests.swift`

### 9.2 UI Tests

**File:** `TravelCompanionUITests/TravelCompanionUITests.swift`

**Test da implementare:**
- Test creazione nuovo viaggio
- Test avvio/stop tracking
- Test aggiunta foto
- Test aggiunta nota
- Test filtro lista viaggi
- Test navigazione tra tab

---

## Riepilogo file da creare

### Application (2)
- [x] AppDelegate.swift (già esiste, da modificare)
- [x] SceneDelegate.swift (già esiste, da modificare)

### Models (4)
- [ ] TripType.swift
- [ ] GeofenceEventType.swift
- [ ] ChatMessage.swift
- [ ] TravelCompanion.xcdatamodeld (già esiste, da modificare)

### Services (6)
- [ ] CoreDataManager.swift
- [ ] LocationManager.swift
- [ ] GeofenceManager.swift
- [ ] NotificationManager.swift
- [ ] PhotoStorageManager.swift
- [ ] ChatService.swift

### Extensions (5)
- [ ] Date+Extensions.swift
- [ ] CLLocation+Extensions.swift
- [ ] UIViewController+Extensions.swift
- [ ] UIColor+Extensions.swift
- [ ] String+Extensions.swift

### Utilities (2)
- [ ] Constants.swift
- [ ] DistanceCalculator.swift

### Config (1)
- [ ] Config.swift

### Controllers (10)
- [ ] HomeViewController.swift
- [ ] TripListViewController.swift
- [ ] TripDetailViewController.swift
- [ ] NewTripViewController.swift
- [ ] ActiveTripViewController.swift
- [ ] MapViewController.swift
- [ ] StatisticsViewController.swift
- [ ] ChatViewController.swift
- [ ] SettingsViewController.swift
- [ ] GeofenceViewController.swift

### Cells (4)
- [ ] TripCell.swift
- [ ] PhotoCell.swift
- [ ] NoteCell.swift
- [ ] ChatMessageCell.swift

### Storyboards (2)
- [ ] Main.storyboard (da creare completamente)
- [x] LaunchScreen.storyboard (già esiste)

### Totale: 36 file da creare/modificare

---

## Ordine di implementazione consigliato

### Blocco 1: Fondamenta
1. Constants.swift
2. Config.swift
3. TripType.swift
4. GeofenceEventType.swift
5. ChatMessage.swift
6. TravelCompanion.xcdatamodeld (schema completo)

### Blocco 2: Extensions
7. Date+Extensions.swift
8. String+Extensions.swift
9. UIColor+Extensions.swift
10. UIViewController+Extensions.swift
11. CLLocation+Extensions.swift

### Blocco 3: Utilities
12. DistanceCalculator.swift

### Blocco 4: Services Core
13. CoreDataManager.swift
14. PhotoStorageManager.swift

### Blocco 5: Services Location
15. LocationManager.swift
16. GeofenceManager.swift

### Blocco 6: Services Notification & Chat
17. NotificationManager.swift
18. ChatService.swift

### Blocco 7: Cells
19. TripCell.swift
20. PhotoCell.swift
21. NoteCell.swift
22. ChatMessageCell.swift

### Blocco 8: Controllers Base
23. HomeViewController.swift
24. NewTripViewController.swift
25. TripListViewController.swift
26. TripDetailViewController.swift

### Blocco 9: Controllers Tracking
27. ActiveTripViewController.swift
28. MapViewController.swift

### Blocco 10: Controllers Avanzati
29. StatisticsViewController.swift
30. ChatViewController.swift
31. SettingsViewController.swift
32. GeofenceViewController.swift

### Blocco 11: Storyboard
33. Main.storyboard (tutte le scene e segue)

### Blocco 12: Application
34. AppDelegate.swift (setup notifiche, Core Data)
35. SceneDelegate.swift (window setup)

### Blocco 13: Finalizzazione
36. Info.plist (permessi)
37. Testing
38. Bug fixing

---

## Note tecniche importanti

### Core Data
- Usare `NSManagedObject` subclass generate automaticamente da Xcode
- Implementare save context dopo ogni modifica
- Usare `NSFetchRequest` con predicati per filtri
- Gestire errori di fetch con do-catch

### Location
- Richiedere permessi prima di usare location
- Gestire caso permessi negati
- Usare `kCLLocationAccuracyBest` per tracking
- Implementare `allowsBackgroundLocationUpdates` per geofencing

### Notifiche
- Richiedere autorizzazione all'avvio app
- Usare `UNUserNotificationCenter` per notifiche locali
- Implementare delegate per gestire tap su notifica

### Camera
- Verificare disponibilità camera con `isSourceTypeAvailable`
- Gestire caso simulatore (no camera)
- Comprimere immagini prima di salvare

### OpenAI API
- Non esporre API key nel codice (usare Config.swift in .gitignore)
- Gestire errori di rete
- Implementare timeout
- Limitare lunghezza conversazione per evitare costi eccessivi

### AutoLayout
- Usare Safe Area per constraint principali
- Testare su diverse dimensioni schermo
- Usare UIStackView dove possibile

### Performance
- Caricare foto in background
- Usare thumbnail per liste
- Paginare risultati se necessario
- Usare `NSFetchedResultsController` per UITableView con Core Data
