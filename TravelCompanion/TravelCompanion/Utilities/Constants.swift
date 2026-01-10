import Foundation
import CoreLocation

struct Constants {

    // MARK: - Segue Identifiers
    struct Segue {
        static let showNewTrip = "showNewTrip"
        static let showActiveTrip = "showActiveTrip"
        static let showTripDetail = "showTripDetail"
        static let showTripMap = "showTripMap"
        static let showSettings = "showSettings"
        static let showGeofence = "showGeofence"
        static let showPhotoDetail = "showPhotoDetail"
        static let unwindToHome = "unwindToHome"
        static let unwindToTripList = "unwindToTripList"
    }

    // MARK: - Cell Identifiers
    struct Cell {
        static let tripCell = "TripCell"
        static let photoCell = "PhotoCell"
        static let noteCell = "NoteCell"
        static let chatUserCell = "ChatUserCell"
        static let chatAssistantCell = "ChatAssistantCell"
        static let geofenceZoneCell = "GeofenceZoneCell"
        static let settingsCell = "SettingsCell"
    }

    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let notificationsEnabled = "notificationsEnabled"
        static let poiNotificationsEnabled = "poiNotificationsEnabled"
        static let reminderNotificationsEnabled = "reminderNotificationsEnabled"
        static let reminderIntervalDays = "reminderIntervalDays"
        static let lastTripDate = "lastTripDate"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedMapType = "selectedMapType"
    }

    // MARK: - Notification Names
    struct NotificationName {
        static let tripCreated = Notification.Name("tripCreated")
        static let tripUpdated = Notification.Name("tripUpdated")
        static let tripDeleted = Notification.Name("tripDeleted")
        static let locationUpdated = Notification.Name("locationUpdated")
        static let trackingStarted = Notification.Name("trackingStarted")
        static let trackingStopped = Notification.Name("trackingStopped")
        static let geofenceEntered = Notification.Name("geofenceEntered")
        static let geofenceExited = Notification.Name("geofenceExited")
        static let photoAdded = Notification.Name("photoAdded")
        static let noteAdded = Notification.Name("noteAdded")

        // AI Feature Notifications
        static let itineraryGenerated = Notification.Name("itineraryGenerated")
        static let packingListGenerated = Notification.Name("packingListGenerated")
        static let briefingGenerated = Notification.Name("briefingGenerated")
        static let journalGenerated = Notification.Name("journalGenerated")
        static let summaryGenerated = Notification.Name("summaryGenerated")
    }

    // MARK: - Local Notification Identifiers
    struct LocalNotification {
        static let poiNearbyPrefix = "poi_nearby_"
        static let loggingReminder = "logging_reminder"
        static let geofenceEnter = "geofence_enter_"
        static let geofenceExit = "geofence_exit_"
    }

    // MARK: - Default Values
    struct Defaults {
        static let geofenceRadiusMin: Double = 50.0
        static let geofenceRadiusMax: Double = 500.0
        static let geofenceRadiusDefault: Double = 100.0
        static let reminderIntervalDays: Int = 7
        static let maxGeofenceZones: Int = 20
        static let locationUpdateInterval: TimeInterval = 5.0
        static let locationDistanceFilter: CLLocationDistance = 10.0
        static let poiSearchRadius: CLLocationDistance = 500.0
        static let photoCompressionQuality: CGFloat = 0.7
        static let thumbnailSize: CGSize = CGSize(width: 150, height: 150)
        static let chatMaxTokens: Int = 500
        static let chatTemperature: Double = 0.7
    }

    // MARK: - Date Formats
    struct DateFormat {
        static let display = "dd MMM yyyy"
        static let displayWithTime = "dd MMM yyyy HH:mm"
        static let time = "HH:mm"
        static let monthYear = "MMMM yyyy"
        static let dayMonth = "dd MMM"
        static let iso8601 = "yyyy-MM-dd'T'HH:mm:ssZ"
    }

    // MARK: - Map
    struct Map {
        static let defaultSpan: Double = 0.01
        static let routeLineWidth: CGFloat = 4.0
        static let heatmapRadius: CGFloat = 40.0
    }

    // MARK: - Colors (Asset Names)
    struct ColorName {
        static let primary = "PrimaryColor"
        static let secondary = "SecondaryColor"
        static let accent = "AccentColor"
        static let localTrip = "LocalTripColor"
        static let dayTrip = "DayTripColor"
        static let multiDayTrip = "MultiDayTripColor"
        static let userMessage = "UserMessageColor"
        static let assistantMessage = "AssistantMessageColor"
    }

    // MARK: - Animation
    struct Animation {
        static let shortDuration: TimeInterval = 0.2
        static let standardDuration: TimeInterval = 0.3
        static let longDuration: TimeInterval = 0.5
    }

    // MARK: - Validation
    struct Validation {
        static let minDestinationLength = 2
        static let maxDestinationLength = 100
        static let maxNoteLength = 1000
        static let maxChatMessageLength = 500
    }

    // MARK: - AI Assistant
    struct AIAssistant {
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 0.5
        static let generationTimeout: TimeInterval = 30.0
        static let maxInputLength = 2000
        static let tokenLimit = 4096

        // Packing List Categories
        static let packingCategories = [
            "documents",
            "clothing",
            "toiletries",
            "electronics",
            "specialItems",
            "healthKit"
        ]

        static let packingCategoryDisplayNames: [String: String] = [
            "documents": "Documenti",
            "clothing": "Abbigliamento",
            "toiletries": "Igiene Personale",
            "electronics": "Elettronica",
            "specialItems": "Articoli Speciali",
            "healthKit": "Kit Medico"
        ]
    }
}
