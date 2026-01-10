//
//  SceneDelegate.swift
//  TravelCompanion
//
//  Gestisce il ciclo di vita delle scene (windows) dell'applicazione.
//  Configura l'interfaccia utente principale e la navigazione.
//
//  Responsabilita:
//  - Creazione e configurazione della UIWindow principale
//  - Setup del TabBarController con tutti i tab dell'app
//  - Gestione transizioni foreground/background
//  - Salvataggio automatico Core Data in background
//  - Prewarm del modello AI (iOS 26+)
//  - Gestione navigazione da notifiche
//

import UIKit

// MARK: - Scene Delegate

/// Delegate per la gestione delle scene (windows) dell'applicazione.
///
/// In iOS 13+, SceneDelegate gestisce:
/// - Ciclo di vita delle singole istanze dell'app (scene)
/// - Configurazione iniziale dell'interfaccia utente
/// - Risposta agli eventi di sistema (background, foreground)
/// - State restoration per continuita dell'esperienza utente
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    /// Window principale dell'applicazione
    var window: UIWindow?

    // MARK: - Ciclo di Vita Scene

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Crea la window
        window = UIWindow(windowScene: windowScene)

        // Crea il TabBarController principale
        let tabBarController = createMainTabBarController()

        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()

        // Prewarm AI model se disponibile (iOS 26+)
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            FoundationModelService.shared.prewarmIfAvailable()
        }
        #endif

        // Gestisci eventuali notifiche che hanno aperto l'app
        if let notificationResponse = connectionOptions.notificationResponse {
            handleNotificationResponse(notificationResponse)
        }

        // Registra observer per notifiche
        setupNotificationObservers()

        if Config.verboseLogging {
            print("SceneDelegate: Scene connected")
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Chiamato quando la scena viene rilasciata dal sistema
        if Config.verboseLogging {
            print("SceneDelegate: Scene disconnected")
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // App tornata attiva
        NotificationManager.shared.resetBadge()

        if Config.verboseLogging {
            print("SceneDelegate: Scene became active")
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // App sta per diventare inattiva
        CoreDataManager.shared.saveContext()

        if Config.verboseLogging {
            print("SceneDelegate: Scene will resign active")
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // App sta per tornare in foreground
        if Config.verboseLogging {
            print("SceneDelegate: Scene will enter foreground")
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // App entrata in background
        CoreDataManager.shared.saveContext()

        if Config.verboseLogging {
            print("SceneDelegate: Scene entered background")
        }
    }

    // MARK: - Tab Bar Setup

    /// Crea il TabBarController principale con tutti i tab
    private func createMainTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()

        // Tab 1: Home
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        // Tab 2: Viaggi
        let tripsVC = TripListViewController()
        let tripsNav = UINavigationController(rootViewController: tripsVC)
        tripsNav.tabBarItem = UITabBarItem(
            title: "Viaggi",
            image: UIImage(systemName: "suitcase"),
            selectedImage: UIImage(systemName: "suitcase.fill")
        )

        // Tab 3: Mappa
        let mapVC = MapViewController()
        let mapNav = UINavigationController(rootViewController: mapVC)
        mapNav.tabBarItem = UITabBarItem(
            title: "Mappa",
            image: UIImage(systemName: "map"),
            selectedImage: UIImage(systemName: "map.fill")
        )

        // Tab 4: Statistiche
        let statsVC = StatisticsViewController()
        let statsNav = UINavigationController(rootViewController: statsVC)
        statsNav.tabBarItem = UITabBarItem(
            title: "Statistiche",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )

        // Tab 5: AI Assistente
        let aiAssistantVC: UIViewController
        if #available(iOS 26.0, *) {
            aiAssistantVC = AIAssistantViewController()
        } else {
            aiAssistantVC = AIAssistantFallbackViewController()
        }
        let aiNav = UINavigationController(rootViewController: aiAssistantVC)
        aiNav.tabBarItem = UITabBarItem(
            title: "AI Assistente",
            image: UIImage(systemName: "sparkles"),
            selectedImage: UIImage(systemName: "sparkles")
        )
        aiNav.tabBarItem.accessibilityIdentifier = AccessibilityIdentifiers.TabBar.aiAssistantTab

        tabBarController.viewControllers = [homeNav, tripsNav, mapNav, statsNav, aiNav]

        return tabBarController
    }

    // MARK: - Notification Handling

    /// Setup observer per gestire notifiche
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenNewTrip),
            name: Notification.Name("OpenNewTrip"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenFromNotification(_:)),
            name: Notification.Name("OpenFromNotification"),
            object: nil
        )
    }

    /// Gestisce la risposta a una notifica che ha aperto l'app
    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        let identifier = response.notification.request.identifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier

        if Config.verboseLogging {
            print("SceneDelegate: Handling notification: \(identifier), category: \(categoryIdentifier)")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.navigateBasedOnNotification(category: categoryIdentifier)
        }
    }

    /// Naviga alla schermata appropriata in base alla categoria della notifica
    private func navigateBasedOnNotification(category: String) {
        guard let tabBarController = window?.rootViewController as? UITabBarController else { return }

        switch category {
        case "POI_NEARBY", "GEOFENCE_EVENT":
            // Vai alla mappa
            tabBarController.selectedIndex = 2

        case "LOGGING_REMINDER":
            // Vai alla home e apri nuovo viaggio
            tabBarController.selectedIndex = 0
            if let homeNav = tabBarController.viewControllers?.first as? UINavigationController,
               let homeVC = homeNav.viewControllers.first as? HomeViewController {
                homeVC.navigateToNewTrip()
            }

        default:
            break
        }
    }

    @objc private func handleOpenNewTrip() {
        guard let tabBarController = window?.rootViewController as? UITabBarController else { return }

        tabBarController.selectedIndex = 0
        if let homeNav = tabBarController.viewControllers?.first as? UINavigationController,
           let homeVC = homeNav.viewControllers.first as? HomeViewController {
            homeVC.navigateToNewTrip()
        }
    }

    @objc private func handleOpenFromNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let category = userInfo["category"] as? String else { return }

        navigateBasedOnNotification(category: category)
    }

    // MARK: - State Restoration

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        // Supporto per state restoration
        return scene.userActivity
    }
}
