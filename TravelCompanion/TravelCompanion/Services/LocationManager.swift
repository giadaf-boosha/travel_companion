import Foundation
import CoreLocation

/// Protocollo delegate per il LocationManager
protocol LocationManagerDelegate: AnyObject {
    func locationManager(_ manager: LocationManager, didUpdateLocation location: CLLocation)
    func locationManager(_ manager: LocationManager, didFailWithError error: Error)
    func locationManager(_ manager: LocationManager, didChangeAuthorization status: CLAuthorizationStatus)
}

/// Extension opzionale per i metodi delegate
extension LocationManagerDelegate {
    func locationManager(_ manager: LocationManager, didFailWithError error: Error) {}
    func locationManager(_ manager: LocationManager, didChangeAuthorization status: CLAuthorizationStatus) {}
}

/// Manager singleton per la gestione della localizzazione GPS
final class LocationManager: NSObject {

    // MARK: - Singleton

    static let shared = LocationManager()

    // MARK: - Properties

    weak var delegate: LocationManagerDelegate?

    private let locationManager = CLLocationManager()

    /// Posizione corrente
    private(set) var currentLocation: CLLocation?

    /// Indica se il tracking è attivo
    private(set) var isTracking: Bool = false

    /// Posizioni registrate durante il tracking
    private(set) var recordedLocations: [CLLocation] = []

    /// Flag per riprovare la richiesta location dopo autorizzazione
    private var shouldRequestLocationAfterAuth: Bool = false

    /// Stato dell'autorizzazione
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }

    /// Indica se i servizi di localizzazione sono abilitati
    var isLocationServicesEnabled: Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    /// Indica se l'app ha l'autorizzazione per la localizzazione
    var hasLocationPermission: Bool {
        let status = authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    /// Indica se l'app ha l'autorizzazione per la localizzazione in background
    var hasBackgroundPermission: Bool {
        return authorizationStatus == .authorizedAlways
    }

    // MARK: - Initialization

    private override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = Constants.Defaults.locationDistanceFilter
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - Authorization

    /// Richiede l'autorizzazione per la localizzazione durante l'uso
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Richiede l'autorizzazione per la localizzazione sempre (necessaria per geofencing)
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    /// Richiede l'autorizzazione appropriata
    func requestAuthorization() {
        switch authorizationStatus {
        case .notDetermined:
            requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // Se serve il background, richiedi always
            if Config.enableGeofencing {
                requestAlwaysAuthorization()
            }
        default:
            break
        }
    }

    // MARK: - Single Location Update

    /// Richiede una singola posizione corrente
    func requestCurrentLocation() {
        guard hasLocationPermission else {
            // Salva il fatto che location è stata richiesta
            shouldRequestLocationAfterAuth = true
            requestAuthorization()
            return
        }
        locationManager.requestLocation()
    }

    // MARK: - Continuous Tracking

    /// Avvia il tracking continuo della posizione
    func startTracking() {
        guard hasLocationPermission else {
            requestAuthorization()
            return
        }

        guard !isTracking else { return }

        isTracking = true
        recordedLocations.removeAll()

        locationManager.allowsBackgroundLocationUpdates = hasBackgroundPermission
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.startUpdatingLocation()

        NotificationCenter.default.post(name: Constants.NotificationName.trackingStarted, object: nil)

        if Config.verboseLogging {
            print("LocationManager: Started tracking")
        }
    }

    /// Ferma il tracking della posizione
    func stopTracking() {
        guard isTracking else { return }

        isTracking = false
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false

        NotificationCenter.default.post(name: Constants.NotificationName.trackingStopped, object: nil)

        if Config.verboseLogging {
            print("LocationManager: Stopped tracking. Recorded \(recordedLocations.count) locations")
        }
    }

    // MARK: - Route Data

    /// Restituisce le coordinate registrate
    func getRecordedRoute() -> [CLLocationCoordinate2D] {
        return recordedLocations.map { $0.coordinate }
    }

    /// Calcola la distanza totale del percorso registrato
    func calculateTotalDistance() -> CLLocationDistance {
        guard recordedLocations.count >= 2 else { return 0 }

        var totalDistance: CLLocationDistance = 0
        for i in 1..<recordedLocations.count {
            totalDistance += recordedLocations[i].distance(from: recordedLocations[i-1])
        }
        return totalDistance
    }

    /// Calcola la durata del tracking
    func calculateTrackingDuration() -> TimeInterval {
        guard let firstLocation = recordedLocations.first,
              let lastLocation = recordedLocations.last else {
            return 0
        }
        return lastLocation.timestamp.timeIntervalSince(firstLocation.timestamp)
    }

    /// Calcola la velocità media
    func calculateAverageSpeed() -> CLLocationSpeed {
        let distance = calculateTotalDistance()
        let duration = calculateTrackingDuration()

        guard duration > 0 else { return 0 }
        return distance / duration // m/s
    }

    /// Pulisce le posizioni registrate
    func clearRecordedLocations() {
        recordedLocations.removeAll()
    }

    // MARK: - Utility Methods

    /// Restituisce la distanza tra la posizione corrente e una coordinata
    func distanceFromCurrentLocation(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let currentLocation = currentLocation else { return nil }
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return currentLocation.distance(from: targetLocation)
    }

    /// Verifica se una posizione è accurata
    func isLocationAccurate(_ location: CLLocation) -> Bool {
        return location.horizontalAccuracy >= 0 &&
               location.horizontalAccuracy <= Config.desiredLocationAccuracy * 2
    }

    /// Filtra le posizioni inaccurate
    private func shouldRecordLocation(_ location: CLLocation) -> Bool {
        // Ignora posizioni troppo inaccurate
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 50 else {
            return false
        }

        // Ignora posizioni troppo vicine alla precedente (filtro rumore)
        if let lastLocation = recordedLocations.last {
            let distance = location.distance(from: lastLocation)
            let timeDiff = location.timestamp.timeIntervalSince(lastLocation.timestamp)

            // Se la distanza è molto piccola e il tempo trascorso è breve, ignora
            if distance < 5 && timeDiff < 3 {
                return false
            }

            // Ignora velocità impossibili (> 200 km/h per un'app di viaggi generica)
            if timeDiff > 0 {
                let speed = distance / timeDiff
                if speed > 55 { // ~200 km/h in m/s
                    return false
                }
            }
        }

        return true
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        currentLocation = location

        // Se stiamo tracciando, registra la posizione
        if isTracking && shouldRecordLocation(location) {
            recordedLocations.append(location)

            if Config.verboseLogging {
                print("LocationManager: Recorded location #\(recordedLocations.count): \(location.coordinate)")
            }
        }

        // Notifica il delegate
        delegate?.locationManager(self, didUpdateLocation: location)

        // Posta notifica globale
        NotificationCenter.default.post(
            name: Constants.NotificationName.locationUpdated,
            object: location
        )
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager error: \(error.localizedDescription)")
        delegate?.locationManager(self, didFailWithError: error)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus

        if Config.verboseLogging {
            print("LocationManager: Authorization changed to \(status.rawValue)")
        }

        delegate?.locationManager(self, didChangeAuthorization: status)

        // Se abbiamo ottenuto l'autorizzazione e era stata richiesta una singola location
        if hasLocationPermission && shouldRequestLocationAfterAuth {
            shouldRequestLocationAfterAuth = false
            locationManager.requestLocation()
        }

        // Se abbiamo ottenuto l'autorizzazione e il tracking era richiesto, avvialo
        if hasLocationPermission && isTracking {
            locationManager.startUpdatingLocation()
        }
    }
}

// MARK: - CLAuthorizationStatus Extension

extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Non determinato"
        case .restricted:
            return "Limitato"
        case .denied:
            return "Negato"
        case .authorizedWhenInUse:
            return "Durante l'uso"
        case .authorizedAlways:
            return "Sempre"
        @unknown default:
            return "Sconosciuto"
        }
    }
}
