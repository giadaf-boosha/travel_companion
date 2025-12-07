import Foundation
import UserNotifications
import CoreLocation

/// Manager singleton per la gestione delle notifiche locali
final class NotificationManager: NSObject {

    // MARK: - Singleton

    static let shared = NotificationManager()

    // MARK: - Properties

    private let notificationCenter = UNUserNotificationCenter.current()

    /// Indica se le notifiche sono autorizzate
    private(set) var isAuthorized: Bool = false

    /// Stato dell'autorizzazione
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Initialization

    private override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Richiede l'autorizzazione per le notifiche
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                self?.authorizationStatus = granted ? .authorized : .denied

                if let error = error {
                    print("NotificationManager: Authorization error - \(error.localizedDescription)")
                }

                if Config.verboseLogging {
                    print("NotificationManager: Authorization \(granted ? "granted" : "denied")")
                }

                completion(granted)
            }
        }
    }

    /// Verifica lo stato corrente dell'autorizzazione
    func checkAuthorizationStatus(completion: ((UNAuthorizationStatus) -> Void)? = nil) {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized

                completion?(settings.authorizationStatus)
            }
        }
    }

    // MARK: - POI Notifications

    /// Invia una notifica per un punto di interesse nelle vicinanze
    func scheduleNearbyPOINotification(poiName: String, distance: Double) {
        guard isAuthorized else { return }
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.poiNotificationsEnabled) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Punto di interesse nelle vicinanze"
        content.body = "Sei a \(DistanceCalculator.formatDistance(distance)) da \(poiName). Vuoi aggiungerlo al tuo viaggio?"
        content.sound = .default
        content.categoryIdentifier = "POI_NEARBY"

        let identifier = "\(Constants.LocalNotification.poiNearbyPrefix)\(UUID().uuidString)"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationManager: Error scheduling POI notification - \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Reminder Notifications

    /// Programma un promemoria per registrare un viaggio
    func scheduleLoggingReminder(daysInterval: Int = 7) {
        guard isAuthorized else { return }
        guard UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.reminderNotificationsEnabled) else { return }

        // Rimuovi eventuali reminder esistenti
        cancelLoggingReminder()

        let content = UNMutableNotificationContent()
        content.title = "Registra il tuo viaggio"
        content.body = "Non hai registrato viaggi di recente. Stai pianificando qualcosa di nuovo?"
        content.sound = .default
        content.categoryIdentifier = "LOGGING_REMINDER"

        // Trigger giornaliero alle 10:00
        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: Constants.LocalNotification.loggingReminder,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationManager: Error scheduling logging reminder - \(error.localizedDescription)")
            } else if Config.verboseLogging {
                print("NotificationManager: Logging reminder scheduled")
            }
        }
    }

    /// Annulla il promemoria di logging
    func cancelLoggingReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [Constants.LocalNotification.loggingReminder])
    }

    /// Aggiorna la data dell'ultimo viaggio e resetta il reminder
    func updateLastTripDate() {
        UserDefaults.standard.set(Date(), forKey: Constants.UserDefaultsKeys.lastTripDate)

        // Riprogramma il reminder
        let interval = UserDefaults.standard.integer(forKey: Constants.UserDefaultsKeys.reminderIntervalDays)
        if interval > 0 {
            scheduleLoggingReminder(daysInterval: interval)
        }
    }

    // MARK: - Geofence Notifications

    /// Invia una notifica per un evento geofence
    func sendGeofenceNotification(zone: GeofenceZone, eventType: GeofenceEventType) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()

        switch eventType {
        case .enter:
            content.title = "Sei arrivato!"
            content.body = "Sei entrato nella zona '\(zone.name ?? "Sconosciuta")'"
        case .exit:
            content.title = "Alla prossima!"
            content.body = "Sei uscito dalla zona '\(zone.name ?? "Sconosciuta")'"
        }

        content.sound = .default
        content.categoryIdentifier = "GEOFENCE_EVENT"

        let identifier = "\(eventType == .enter ? Constants.LocalNotification.geofenceEnter : Constants.LocalNotification.geofenceExit)\(UUID().uuidString)"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationManager: Error sending geofence notification - \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Trip Notifications

    /// Invia una notifica di inizio viaggio
    func sendTripStartedNotification(destination: String) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Viaggio iniziato!"
        content.body = "Buon viaggio verso \(destination)! Il tracking GPS è attivo."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "trip_started_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        notificationCenter.add(request)
    }

    /// Invia una notifica di fine viaggio
    func sendTripEndedNotification(destination: String, distance: Double, duration: TimeInterval) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Viaggio completato!"
        content.body = "Hai percorso \(DistanceCalculator.formatDistance(distance)) in \(DistanceCalculator.formatDuration(duration)) verso \(destination)."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "trip_ended_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        notificationCenter.add(request)
    }

    // MARK: - Management

    /// Annulla tutte le notifiche pendenti
    func cancelAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()

        if Config.verboseLogging {
            print("NotificationManager: All pending notifications cancelled")
        }
    }

    /// Annulla tutte le notifiche consegnate
    func clearDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }

    /// Resetta il badge dell'app
    func resetBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    // MARK: - Notification Categories

    /// Configura le categorie di notifica con azioni
    func setupNotificationCategories() {
        // Categoria POI
        let viewPOIAction = UNNotificationAction(
            identifier: "VIEW_POI",
            title: "Visualizza",
            options: .foreground
        )
        let dismissPOIAction = UNNotificationAction(
            identifier: "DISMISS_POI",
            title: "Ignora",
            options: .destructive
        )
        let poiCategory = UNNotificationCategory(
            identifier: "POI_NEARBY",
            actions: [viewPOIAction, dismissPOIAction],
            intentIdentifiers: []
        )

        // Categoria Reminder
        let startTripAction = UNNotificationAction(
            identifier: "START_TRIP",
            title: "Inizia viaggio",
            options: .foreground
        )
        let reminderCategory = UNNotificationCategory(
            identifier: "LOGGING_REMINDER",
            actions: [startTripAction],
            intentIdentifiers: []
        )

        // Categoria Geofence
        let viewGeofenceAction = UNNotificationAction(
            identifier: "VIEW_GEOFENCE",
            title: "Visualizza",
            options: .foreground
        )
        let geofenceCategory = UNNotificationCategory(
            identifier: "GEOFENCE_EVENT",
            actions: [viewGeofenceAction],
            intentIdentifiers: []
        )

        notificationCenter.setNotificationCategories([poiCategory, reminderCategory, geofenceCategory])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Gestisce le notifiche quando l'app è in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Mostra la notifica anche quando l'app è in foreground
        completionHandler([.banner, .sound])
    }

    /// Gestisce il tap sulla notifica
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier

        if Config.verboseLogging {
            print("NotificationManager: Received action '\(actionIdentifier)' for category '\(categoryIdentifier)'")
        }

        switch actionIdentifier {
        case "VIEW_POI", "VIEW_GEOFENCE":
            // L'app si aprirà in foreground - gestire nella scena appropriata
            NotificationCenter.default.post(
                name: Notification.Name("OpenFromNotification"),
                object: nil,
                userInfo: ["category": categoryIdentifier]
            )

        case "START_TRIP":
            // Apri la schermata di nuovo viaggio
            NotificationCenter.default.post(
                name: Notification.Name("OpenNewTrip"),
                object: nil
            )

        case UNNotificationDefaultActionIdentifier:
            // Tap sulla notifica stessa (non su un'azione)
            NotificationCenter.default.post(
                name: Notification.Name("OpenFromNotification"),
                object: nil,
                userInfo: ["category": categoryIdentifier]
            )

        default:
            break
        }

        completionHandler()
    }
}
