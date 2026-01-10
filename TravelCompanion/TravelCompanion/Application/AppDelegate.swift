//
//  AppDelegate.swift
//  TravelCompanion
//
//  Entry point dell'applicazione iOS.
//  Gestisce il ciclo di vita dell'app, setup iniziale e Core Data stack.
//
//  Responsabilita:
//  - Configurazione iniziale dell'applicazione (notifiche, geofencing)
//  - Gestione del persistent container Core Data
//  - Configurazione aspetto globale (NavigationBar, TabBar)
//  - Gestione background fetch per reminder
//  - Delegate per notifiche locali (UNUserNotificationCenter)
//

import UIKit
import CoreData
import UserNotifications

// MARK: - App Delegate

/// Classe principale delegate dell'applicazione.
///
/// Gestisce:
/// - Inizializzazione dell'app al lancio
/// - Stack Core Data per persistenza dati
/// - Setup notifiche locali e geofencing
/// - Background fetch per invio reminder periodici
/// - Configurazione aspetto UI globale
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Ciclo di Vita Applicazione

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Setup notifiche
        setupNotifications()

        // Setup geofencing
        setupGeofencing()

        // Setup default values
        setupDefaultUserDefaults()

        // Configura aspetto globale
        configureGlobalAppearance()

        if Config.verboseLogging {
            print("AppDelegate: Application did finish launching")
        }

        return true
    }

    // MARK: - UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        // Chiamato quando l'utente chiude scene dalla app switcher
    }

    // MARK: - Setup Methods

    /// Configura le notifiche locali
    private func setupNotifications() {
        // Imposta il delegate per le notifiche
        UNUserNotificationCenter.current().delegate = NotificationManager.shared

        // Configura le categorie di notifica
        NotificationManager.shared.setupNotificationCategories()

        // Verifica lo stato dell'autorizzazione
        NotificationManager.shared.checkAuthorizationStatus { status in
            if Config.verboseLogging {
                print("AppDelegate: Notification authorization status: \(status.rawValue)")
            }
        }
    }

    /// Configura il geofencing
    private func setupGeofencing() {
        guard Config.enableGeofencing else { return }

        // Sincronizza le zone geofence con il database
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            GeofenceManager.shared.syncWithDatabase()

            if Config.verboseLogging {
                print("AppDelegate: Geofencing synced. Monitoring \(GeofenceManager.shared.monitoredRegionsCount) regions")
            }
        }
    }

    /// Imposta i valori di default per UserDefaults
    private func setupDefaultUserDefaults() {
        let defaults = UserDefaults.standard

        // Imposta valori di default solo se non esistono già
        if defaults.object(forKey: Constants.UserDefaultsKeys.notificationsEnabled) == nil {
            defaults.set(true, forKey: Constants.UserDefaultsKeys.notificationsEnabled)
        }

        if defaults.object(forKey: Constants.UserDefaultsKeys.poiNotificationsEnabled) == nil {
            defaults.set(true, forKey: Constants.UserDefaultsKeys.poiNotificationsEnabled)
        }

        if defaults.object(forKey: Constants.UserDefaultsKeys.reminderNotificationsEnabled) == nil {
            defaults.set(true, forKey: Constants.UserDefaultsKeys.reminderNotificationsEnabled)
        }

        if defaults.object(forKey: Constants.UserDefaultsKeys.reminderIntervalDays) == nil {
            defaults.set(Constants.Defaults.reminderIntervalDays, forKey: Constants.UserDefaultsKeys.reminderIntervalDays)
        }
    }

    /// Configura l'aspetto globale dell'app
    private func configureGlobalAppearance() {
        // Navigation Bar
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .systemBackground
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = .systemBlue

        // Tab Bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = .systemBlue
    }

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: Config.coreDataModelName)
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    // MARK: - Core Data Saving Support

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // MARK: - Background Tasks

    func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Background fetch per aggiornamenti periodici
        if Config.verboseLogging {
            print("AppDelegate: Background fetch triggered")
        }

        // Verifica se è necessario inviare un reminder
        checkAndSendReminderIfNeeded()

        completionHandler(.newData)
    }

    /// Verifica e invia reminder se necessario
    private func checkAndSendReminderIfNeeded() {
        let defaults = UserDefaults.standard

        guard defaults.bool(forKey: Constants.UserDefaultsKeys.reminderNotificationsEnabled) else {
            return
        }

        let intervalDays = defaults.integer(forKey: Constants.UserDefaultsKeys.reminderIntervalDays)
        guard intervalDays > 0 else { return }

        if let lastTripDate = defaults.object(forKey: Constants.UserDefaultsKeys.lastTripDate) as? Date {
            let daysSinceLastTrip = Calendar.current.dateComponents([.day], from: lastTripDate, to: Date()).day ?? 0

            if daysSinceLastTrip >= intervalDays {
                NotificationManager.shared.scheduleLoggingReminder(daysInterval: intervalDays)
            }
        } else {
            // Nessun viaggio mai registrato, invia reminder
            NotificationManager.shared.scheduleLoggingReminder(daysInterval: intervalDays)
        }
    }

    // MARK: - Handle Location Events

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Gestisce notifiche remote (se implementate in futuro)
        completionHandler(.newData)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Mostra notifica anche quando app è in foreground
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Gestisci tap su notifica
        let identifier = response.notification.request.identifier

        if Config.verboseLogging {
            print("AppDelegate: Notification tapped: \(identifier)")
        }

        // Posta notifica per gestire navigazione
        NotificationCenter.default.post(
            name: Notification.Name("HandleNotificationTap"),
            object: nil,
            userInfo: ["identifier": identifier]
        )

        completionHandler()
    }
}
