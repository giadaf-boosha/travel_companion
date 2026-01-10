<div align="center">

# ✈️ Travel Companion

### 🌍 La tua app iOS intelligente per pianificare, tracciare e documentare viaggi

<br/>

[![Swift](https://img.shields.io/badge/Swift-5.9-F05138.svg?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0+-007AFF.svg?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Xcode](https://img.shields.io/badge/Xcode-16.0+-147EFB.svg?style=for-the-badge&logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-34C759.svg?style=for-the-badge)](LICENSE)

<br/>

[![Core Data](https://img.shields.io/badge/Core_Data-Persistence-5856D6.svg?style=flat-square&logo=apple)](https://developer.apple.com/documentation/coredata)
[![MapKit](https://img.shields.io/badge/MapKit-Maps-FF3B30.svg?style=flat-square&logo=apple)](https://developer.apple.com/documentation/mapkit)
[![CoreLocation](https://img.shields.io/badge/CoreLocation-GPS-34C759.svg?style=flat-square&logo=apple)](https://developer.apple.com/documentation/corelocation)
[![Foundation Models](https://img.shields.io/badge/Foundation_Models-AI-FF9500.svg?style=flat-square&logo=apple)](https://developer.apple.com/documentation/foundationmodels)

---

**📚 Progetto universitario per il corso "Laboratorio di Applicazioni Mobili"**

**🏛️ Alma Mater Studiorum - Università di Bologna**

**📅 Anno Accademico 2024/2025**

<br/>

[📱 Funzionalità](#-funzionalità-principali) •
[🤖 AI Features](#-funzionalità-ai-ios-26) •
[🏗️ Architettura](#️-architettura) •
[📋 Requisiti](#-requisiti-di-sistema) •
[🚀 Installazione](#-installazione) •
[🧪 Testing](#-testing)

</div>

---

## 📑 Indice

1. [Panoramica](#-panoramica)
2. [Funzionalità Principali](#-funzionalità-principali)
3. [Funzionalità AI (iOS 26+)](#-funzionalità-ai-ios-26)
4. [Screenshot](#-screenshot)
5. [Architettura](#️-architettura)
6. [Struttura del Progetto](#-struttura-del-progetto)
7. [Requisiti di Sistema](#-requisiti-di-sistema)
8. [Installazione](#-installazione)
9. [Configurazione](#️-configurazione)
10. [Testing](#-testing)
11. [Tecnologie Utilizzate](#-tecnologie-utilizzate)
12. [Conformità Requisiti Universitari](#-conformità-requisiti-universitari)
13. [Documentazione del Codice](#-documentazione-del-codice)
14. [Autori](#-autori)
15. [Licenza](#-licenza)

---

## 🎯 Panoramica

**Travel Companion** è un'applicazione iOS nativa sviluppata in **Swift** con **UIKit** che assiste gli utenti nella:

| Funzione | Descrizione |
|----------|-------------|
| 📍 **Pianificazione** | Crea piani di viaggio con destinazione, date e tipo |
| 🛤️ **Tracciamento** | Registra percorsi GPS in tempo reale durante i viaggi |
| 📸 **Documentazione** | Allega foto e note geolocalizzate ai momenti del viaggio |
| 📊 **Visualizzazione** | Esplora statistiche, mappe e grafici della cronologia viaggi |
| 🔔 **Notifiche** | Ricevi alert su POI vicini e reminder per registrare viaggi |
| 🤖 **AI Assistant** | Genera itinerari, packing list e briefing con Apple Intelligence |

L'applicazione segue il pattern architetturale **MVC (Model-View-Controller)** ed è costruita interamente con **UIKit programmatico** (senza Storyboard) per massima manutenibilità.

---

## ✨ Funzionalità Principali

### 🗺️ Gestione Viaggi

<table>
<tr>
<td width="50%">

#### Creazione Viaggio
- ✅ Campo destinazione con validazione
- ✅ Selettore date (inizio/fine)
- ✅ 3 tipi viaggio obbligatori
- ✅ Opzione tracking automatico

</td>
<td width="50%">

#### Tracking GPS
- ✅ Start/Stop manuale
- ✅ Coordinate in tempo reale
- ✅ Timer durata viaggio
- ✅ Calcolo distanza totale

</td>
</tr>
</table>

### 📸 Documentazione Multimediale

| Funzionalità | Descrizione | Geolocalizzazione |
|--------------|-------------|:-----------------:|
| **Foto via Camera** | Cattura foto durante il viaggio | ✅ Automatica |
| **Foto da Galleria** | Importa foto esistenti | ✅ Se disponibile |
| **Note Testuali** | Aggiungi note ai momenti | ✅ Automatica |
| **Timestamp** | Data/ora automatici | ✅ |

### 📊 Visualizzazioni Interattive

```
┌─────────────────────────────────────────────────────────┐
│                    MAP VIEW                              │
│  ┌─────────────────────────────────────────────────┐    │
│  │     🗺️ Percorsi GPS colorati per tipo           │    │
│  │     🔥 Heatmap zone visitate                    │    │
│  │     📍 Marker foto e note                       │    │
│  └─────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────┤
│                   BAR CHARTS                             │
│  ┌─────────────────────────────────────────────────┐    │
│  │     📊 Viaggi per mese                          │    │
│  │     📈 Distanza percorsa per mese               │    │
│  │     🎯 Selezione anno interattiva               │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### 🔔 Background Jobs

| Job | Tipo | Trigger |
|-----|------|---------|
| **POI Nearby** | Notifica locale | GPS vicino a landmark |
| **Logging Reminder** | Notifica periodica | Giornaliera ore 10:00 |
| **Geofencing** | Background task | Entry/Exit da zone definite |

### 📍 Tipi di Viaggio Supportati

| Tipo | Icona | Colore | Descrizione |
|------|:-----:|:------:|-------------|
| **Local Trip** | 🏠 | 🟢 Verde | Viaggio in città |
| **Day Trip** | 🚗 | 🟠 Arancione | Escursione giornaliera |
| **Multi-day Trip** | ✈️ | 🟣 Viola | Vacanza di più giorni |

---

## 🤖 Funzionalità AI (iOS 26+)

> ⚡ **Powered by Apple Foundation Models** - Esecuzione on-device, privacy garantita

<table>
<tr>
<td width="33%" align="center">

### 📋 Smart Itinerary
Genera itinerari personalizzati giorno per giorno con attività, orari e consigli

</td>
<td width="33%" align="center">

### 🧳 Packing List
Lista valigia intelligente basata su destinazione, durata e tipo viaggio

</td>
<td width="33%" align="center">

### 🌍 Destination Briefing
Info culturali, frasi utili, clima, cucina e consigli di sicurezza

</td>
</tr>
<tr>
<td width="33%" align="center">

### 🎙️ Voice Notes
Trascrizione vocale e strutturazione automatica delle note

</td>
<td width="33%" align="center">

### 📔 Smart Journal
Genera diario di viaggio dalle attività e foto del giorno

</td>
<td width="33%" align="center">

### 📝 Trip Summary
Narrativa completa del viaggio concluso con highlights

</td>
</tr>
</table>

### Architettura AI

```
┌─────────────────────────────────────────────────────────┐
│                  AI ASSISTANT TAB                        │
│                                                          │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│   │Itinerario│  │ Packing  │  │ Briefing │             │
│   └────┬─────┘  └────┬─────┘  └────┬─────┘             │
│        │             │             │                    │
│   ┌────┴─────┐  ┌────┴─────┐  ┌────┴─────┐             │
│   │ Voice    │  │ Journal  │  │ Summary  │             │
│   │ Note     │  │          │  │          │             │
│   └────┬─────┘  └────┬─────┘  └────┴─────┘             │
│        │             │             │                    │
│        └─────────────┴─────────────┘                    │
│                      │                                   │
│              ┌───────▼───────┐                          │
│              │FoundationModel│                          │
│              │   Service     │                          │
│              └───────────────┘                          │
│                      │                                   │
│              ┌───────▼───────┐                          │
│              │Apple Foundation│                         │
│              │    Models     │                          │
│              │  (On-Device)  │                          │
│              └───────────────┘                          │
└─────────────────────────────────────────────────────────┘
```

### Strutture @Generable

| Struttura | Descrizione | Attributi Principali |
|-----------|-------------|---------------------|
| `TravelItinerary` | Itinerario completo | `dailyPlans`, `generalTips` |
| `GeneratedPackingList` | Lista valigia | `categories`, `items` |
| `TripBriefing` | Briefing destinazione | `quickFacts`, `phrases`, `tips` |
| `JournalEntry` | Entry diario | `narrative`, `highlights` |
| `StructuredNote` | Nota strutturata | `category`, `rating`, `tags` |
| `TripSummary` | Riassunto viaggio | `tagline`, `narrative`, `stats` |

---

## 📱 Screenshot

<div align="center">

| Home | Nuovo Viaggio | Tracking Attivo |
|:----:|:-------------:|:---------------:|
| Dashboard con stats | Form creazione | GPS in tempo reale |

| Lista Viaggi | Mappa Percorsi | Statistiche |
|:------------:|:--------------:|:-----------:|
| Filtri e ricerca | Polylines colorate | Charts interattivi |

| AI Assistant | Itinerario AI | Packing List |
|:------------:|:-------------:|:------------:|
| Hub funzionalità | Piano giornaliero | Checklist interattiva |

</div>

> 📸 Per screenshot dettagliati, consulta la cartella `docs/screenshots/`

---

## 🏗️ Architettura

### Pattern MVC con Services Layer

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                           │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              UIKit ViewControllers (20+)                   │  │
│  │  Home │ TripList │ TripDetail │ Map │ Stats │ AI │ etc.   │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              Custom UITableViewCells (4)                   │  │
│  │         TripCell │ PhotoCell │ NoteCell │ ChatCell        │  │
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
│  ┌─────────────┐ ┌─────────────┐                               │
│  │ChatService  │ │SpeechRecog  │                               │
│  │(OpenAI)     │ │nizerService │                               │
│  └─────────────┘ └─────────────┘                               │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                                │
│  ┌─────────────────────────┐ ┌─────────────────────────┐       │
│  │      Core Data          │ │      FileManager        │       │
│  │   (SQLite Database)     │ │   (Photo Storage)       │       │
│  │                         │ │                         │       │
│  │  Trip │ Route │ Photo   │ │  /Documents/Photos/     │       │
│  │  Note │ GeofenceZone    │ │  UUID.jpg               │       │
│  │  GeofenceEvent          │ │                         │       │
│  └─────────────────────────┘ └─────────────────────────┘       │
│  ┌─────────────────────────┐ ┌─────────────────────────┐       │
│  │     UserDefaults        │ │    Keychain (futuri)    │       │
│  │   (Preferences)         │ │    (API Keys)           │       │
│  └─────────────────────────┘ └─────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

### Design Patterns Utilizzati

| Pattern | Utilizzo | Esempio |
|---------|----------|---------|
| **Singleton** | Servizi condivisi | `CoreDataManager.shared` |
| **Delegate** | Comunicazione VC | `NewTripViewControllerDelegate` |
| **Observer** | Eventi globali | `NotificationCenter.default` |
| **Repository** | Accesso dati | `CoreDataManager` CRUD |
| **Factory** | Creazione oggetti | `TripCell.createProgrammatically()` |

---

## 📁 Struttura del Progetto

```
TravelCompanion/
├── 📂 TravelCompanion/
│   ├── 📂 Application/
│   │   ├── AppDelegate.swift              # Entry point, Core Data stack
│   │   └── SceneDelegate.swift            # TabBar setup, prewarm AI
│   │
│   ├── 📂 Config/
│   │   └── Config.swift                   # Configurazione centralizzata
│   │
│   ├── 📂 Models/
│   │   ├── ChatMessage.swift              # Modello messaggi chat
│   │   ├── GeofenceEventType.swift        # Enum entry/exit
│   │   ├── TripType.swift                 # Enum local/day/multi-day
│   │   └── 📂 AI/
│   │       ├── GenerableStructures.swift  # @Generable per Foundation Models
│   │       ├── FoundationModelError.swift # Errori AI custom
│   │       └── AITools.swift              # Tool protocol implementations
│   │
│   ├── 📂 Services/
│   │   ├── CoreDataManager.swift          # CRUD Core Data (500+ linee)
│   │   ├── LocationManager.swift          # GPS tracking
│   │   ├── PhotoStorageManager.swift      # Salvataggio foto
│   │   ├── NotificationManager.swift      # Notifiche locali
│   │   ├── GeofenceManager.swift          # Monitoraggio zone
│   │   ├── ChatService.swift              # Integrazione OpenAI
│   │   ├── FoundationModelService.swift   # Apple AI (iOS 26+)
│   │   └── SpeechRecognizerService.swift  # Riconoscimento vocale
│   │
│   ├── 📂 Controllers/
│   │   ├── HomeViewController.swift           # Dashboard principale
│   │   ├── NewTripViewController.swift        # Form creazione viaggio
│   │   ├── ActiveTripViewController.swift     # Tracking attivo
│   │   ├── TripDetailViewController.swift     # Dettaglio viaggio
│   │   ├── TripListViewController.swift       # Lista viaggi + filtri
│   │   ├── MapViewController.swift            # Mappa + heatmap
│   │   ├── StatisticsViewController.swift     # Grafici statistiche
│   │   ├── ChatViewController.swift           # Chat OpenAI legacy
│   │   ├── SettingsViewController.swift       # Impostazioni app
│   │   ├── GeofenceViewController.swift       # Gestione zone
│   │   ├── AIAssistantViewController.swift    # Hub AI (iOS 26+)
│   │   └── 📂 AI/
│   │       ├── ItineraryGeneratorViewController.swift
│   │       ├── ItineraryDetailViewController.swift
│   │       ├── PackingListViewController.swift
│   │       ├── BriefingDetailViewController.swift
│   │       ├── VoiceNoteViewController.swift
│   │       ├── StructuredNotePreviewViewController.swift
│   │       ├── JournalGeneratorViewController.swift
│   │       └── TripSummaryViewController.swift
│   │
│   ├── 📂 Views/Cells/
│   │   ├── TripCell.swift                 # Cella lista viaggi
│   │   ├── PhotoCell.swift                # Cella galleria foto
│   │   ├── NoteCell.swift                 # Cella lista note
│   │   └── ChatMessageCell.swift          # Cella messaggi chat
│   │
│   ├── 📂 Extensions/
│   │   ├── String+Extensions.swift        # Validazione, formatting
│   │   ├── Date+Extensions.swift          # Tempo relativo, formati
│   │   ├── UIColor+Extensions.swift       # Colori tema, hex
│   │   ├── UIViewController+Extensions.swift  # Alert, loading
│   │   └── CLLocation+Extensions.swift    # Coordinate formatting
│   │
│   ├── 📂 Utilities/
│   │   ├── Constants.swift                # Tutte le costanti app
│   │   ├── DistanceCalculator.swift       # Calcoli distanza/velocità
│   │   └── AccessibilityIdentifiers.swift # ID per UI Testing
│   │
│   └── 📂 Resources/
│       ├── TravelCompanion.xcdatamodeld   # Modello Core Data
│       ├── Assets.xcassets                # Immagini e colori
│       ├── LaunchScreen.storyboard        # Splash screen
│       └── Info.plist                     # Configurazione app
│
├── 📂 TravelCompanionTests/               # 123 Unit Tests
│   ├── StringExtensionsTests.swift        # 31 test
│   ├── DateExtensionsTests.swift          # 14 test
│   ├── CoreDataManagerTests.swift         # 22 test
│   ├── ChatServiceTests.swift             # 18 test
│   ├── DistanceCalculatorTests.swift      # 18 test
│   └── TripTypeTests.swift                # 20 test
│
├── 📂 TravelCompanionUITests/             # 70+ UI Tests
│   ├── TravelCompanionUITests.swift
│   ├── TripCreationUITests.swift
│   ├── TripListUITests.swift
│   ├── TripLifecycleUITests.swift
│   └── AIFeatureUITests.swift
│
├── README.md                              # Questo file
├── VERIFICA_REQUISITI.md                  # Verifica conformità
└── TravelCompanion.xcodeproj              # Progetto Xcode
```

---

## 💻 Requisiti di Sistema

### Ambiente di Sviluppo

| Requisito | Versione Minima | Consigliata |
|-----------|:---------------:|:-----------:|
| **macOS** | 14.0 (Sonoma) | 15.0+ |
| **Xcode** | 16.0 | 16.2+ |
| **Swift** | 5.9 | 5.9+ |
| **iOS SDK** | 17.0 | 18.0+ |

### Requisiti Runtime

| Requisito | Base | AI Features |
|-----------|:----:|:-----------:|
| **iOS** | 17.0+ | 26.0+ |
| **Dispositivo** | iPhone con GPS | iPhone 15 Pro+ |
| **Spazio** | ~100 MB | ~150 MB |

### Permessi Richiesti (Info.plist)

| Permesso | Chiave | Motivo |
|----------|--------|--------|
| 📍 **Localizzazione (In Uso)** | `NSLocationWhenInUseUsageDescription` | Tracking percorsi |
| 📍 **Localizzazione (Sempre)** | `NSLocationAlwaysAndWhenInUseUsageDescription` | Geofencing |
| 📷 **Fotocamera** | `NSCameraUsageDescription` | Scattare foto |
| 🖼️ **Libreria Foto** | `NSPhotoLibraryUsageDescription` | Accesso galleria |
| 💾 **Salvataggio Foto** | `NSPhotoLibraryAddUsageDescription` | Salvare foto |
| 🎤 **Microfono** | `NSMicrophoneUsageDescription` | Note vocali |
| 🗣️ **Riconoscimento Vocale** | `NSSpeechRecognitionUsageDescription` | Trascrizione |

---

## 🚀 Installazione

### 1️⃣ Clona il Repository

```bash
git clone https://github.com/giadaf-boosha/travel_companion.git
cd travel_companion
```

### 2️⃣ Apri il Progetto

```bash
open TravelCompanion/TravelCompanion.xcodeproj
```

### 3️⃣ Seleziona Target e Dispositivo

1. In Xcode, seleziona **TravelCompanion** come scheme
2. Scegli un simulatore o dispositivo fisico
3. Premi `Cmd + R` per compilare ed eseguire

### 4️⃣ (Opzionale) Configura API Key OpenAI

Per la funzionalità chat legacy con OpenAI:

```bash
# Copia il file di esempio
cp TravelCompanion/Config/Secrets.xcconfig.example \
   TravelCompanion/Config/Secrets.xcconfig

# Modifica con la tua API key
open TravelCompanion/Config/Secrets.xcconfig
```

> ⚠️ **Nota:** Le funzionalità AI native (iOS 26+) utilizzano Apple Foundation Models e **non richiedono API key esterne**.

---

## ⚙️ Configurazione

### File di Configurazione

| File | Descrizione | Modificabile |
|------|-------------|:------------:|
| `Config.swift` | Configurazione centralizzata app | ✅ |
| `Constants.swift` | Costanti globali | ⚠️ Con cautela |
| `Secrets.xcconfig` | API keys (non committato) | ✅ |

### Feature Flags

```swift
// Config.swift

// Funzionalità base
static let enableAIChatbot = true          // Chat OpenAI legacy
static let enableGeofencing = true         // Geofencing
static let enablePOINotifications = true   // Notifiche POI

// Funzionalità AI (iOS 26+)
static let enableFoundationModels = true   // Apple AI
static let aiGenerationTimeout: TimeInterval = 30.0
static let aiMaxRetryAttempts = 3
```

---

## 🧪 Testing

### Unit Tests (123 test)

```bash
# Esegui tutti gli unit test
xcodebuild test \
  -project TravelCompanion/TravelCompanion.xcodeproj \
  -scheme TravelCompanion \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -only-testing:TravelCompanionTests
```

### UI Tests (70+ test)

```bash
# Esegui tutti gli UI test
xcodebuild test \
  -project TravelCompanion/TravelCompanion.xcodeproj \
  -scheme TravelCompanion \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
  -only-testing:TravelCompanionUITests
```

### Coverage Test

| Suite | Test | Copertura |
|-------|:----:|:---------:|
| **StringExtensionsTests** | 31 | ✅ 100% |
| **DateExtensionsTests** | 14 | ✅ 100% |
| **CoreDataManagerTests** | 22 | ✅ CRUD completo |
| **ChatServiceTests** | 18 | ✅ 100% |
| **DistanceCalculatorTests** | 18 | ✅ 100% |
| **TripTypeTests** | 20 | ✅ 100% |
| **UI Tests** | 70+ | ✅ Flussi principali |

---

## 🛠️ Tecnologie Utilizzate

### Framework Apple

| Framework | Versione | Utilizzo |
|-----------|:--------:|----------|
| **UIKit** | - | Interfaccia utente |
| **Core Data** | - | Persistenza locale |
| **MapKit** | - | Mappe e percorsi |
| **CoreLocation** | - | GPS e geofencing |
| **UserNotifications** | - | Notifiche locali |
| **AVFoundation** | - | Cattura foto |
| **Speech** | - | Riconoscimento vocale |
| **Foundation Models** | iOS 26+ | AI on-device |

### Dipendenze Esterne

> 🎯 **Zero dipendenze** - L'applicazione utilizza esclusivamente framework Apple nativi.

---

## ✅ Conformità Requisiti Universitari

L'applicazione soddisfa **tutti i 34 requisiti** specificati nel progetto "Travel Companion" per il corso LAM 2024/2025.

### Riepilogo Conformità

| Categoria | Requisiti | Rispettati | Status |
|-----------|:---------:|:----------:|:------:|
| **Record Activities** | 14 | 14 | 🟢 100% |
| **Display Charts** | 6 | 6 | 🟢 100% |
| **Background Jobs** | 8 | 8 | 🟢 100% |
| **Requisiti Tecnici** | 6 | 6 | 🟢 100% |
| **TOTALE** | **34** | **34** | 🟢 **100%** |

### Requisiti Chiave

| Requisito | Status | Implementazione |
|-----------|:------:|-----------------|
| 3 tipi viaggio | ✅ | Local, Day, Multi-day |
| Start/Stop logging | ✅ | Pulsante toggle |
| Foto via camera | ✅ | UIImagePickerController |
| Note geolocalizzate | ✅ | Coordinate GPS salvate |
| Database locale | ✅ | Core Data |
| Map View | ✅ | Percorsi + Heatmap |
| Bar Chart | ✅ | Viaggi/Distanza per mese |
| Notifica POI | ✅ | Alert GPS-based |
| Geofencing | ✅ | Entry/Exit monitoring |

> 📋 Per la verifica dettagliata di ogni singolo requisito, consulta **[VERIFICA_REQUISITI.md](VERIFICA_REQUISITI.md)**

---

## 📖 Documentazione del Codice

Tutto il codice sorgente è documentato in **italiano** seguendo le best practices Swift:

### Convenzioni di Documentazione

| Elemento | Formato | Esempio |
|----------|---------|---------|
| **File Header** | Commento blocco | Descrizione, responsabilità |
| **Classi/Struct** | `///` DocC | Descrizione e responsabilità |
| **Metodi Pubblici** | `///` con params | Parameters, Returns, Example |
| **Sezioni** | `// MARK: -` | Organizzazione logica |
| **Commenti Inline** | `//` | Solo per logica complessa |

### Esempio Documentazione

```swift
/// Calcola la distanza totale percorsa da un array di posizioni GPS
///
/// Somma le distanze tra punti consecutivi usando il metodo geodetico.
///
/// - Parameter locations: Array di posizioni GPS ordinate cronologicamente
/// - Returns: Distanza totale in metri (0.0 se meno di 2 punti)
///
/// - Example:
///   ```swift
///   let distance = DistanceCalculator.calculateDistance(from: locations)
///   print(DistanceCalculator.formatDistance(distance)) // "2.5 km"
///   ```
static func calculateDistance(from locations: [CLLocation]) -> CLLocationDistance
```

---

## 👥 Autori

<table>
<tr>
<td align="center">
<b>Giada Franceschini</b><br/>
<sub>Sviluppatore</sub><br/>
<a href="mailto:giada.franceschini@studio.unibo.it">📧 Email</a>
</td>
</tr>
</table>

### Corso

| | |
|---|---|
| **Corso** | Laboratorio di Applicazioni Mobili (LAM) |
| **Docenti** | Federico Montori, Lorenzo Gigli |
| **Università** | Alma Mater Studiorum - Università di Bologna |
| **Anno Accademico** | 2024/2025 |

---

## 📄 Licenza

Questo progetto è sviluppato per scopi didattici nell'ambito del corso universitario LAM.

```
MIT License

Copyright (c) 2025 Giada Franceschini

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

<div align="center">

### Made with ❤️ in Bologna

[![UniBO](https://img.shields.io/badge/Alma_Mater_Studiorum-Università_di_Bologna-A31F34.svg?style=for-the-badge)](https://www.unibo.it)

**⭐ Se questo progetto ti è stato utile, lascia una stella!**

</div>
