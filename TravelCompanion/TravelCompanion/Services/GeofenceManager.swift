import Foundation
import CoreLocation

/// Protocollo delegate per il GeofenceManager
protocol GeofenceManagerDelegate: AnyObject {
    func geofenceManager(_ manager: GeofenceManager, didEnterRegion region: CLRegion, zone: GeofenceZone?)
    func geofenceManager(_ manager: GeofenceManager, didExitRegion region: CLRegion, zone: GeofenceZone?)
    func geofenceManager(_ manager: GeofenceManager, didFailWithError error: Error)
}

/// Extension opzionale per i metodi delegate
extension GeofenceManagerDelegate {
    func geofenceManager(_ manager: GeofenceManager, didFailWithError error: Error) {}
}

/// Manager singleton per la gestione del geofencing
final class GeofenceManager: NSObject {

    // MARK: - Singleton

    static let shared = GeofenceManager()

    // MARK: - Properties

    weak var delegate: GeofenceManagerDelegate?

    private let locationManager = CLLocationManager()

    /// Numero massimo di regioni che iOS può monitorare
    static let maxMonitoredRegions = 20

    /// Indica se il geofencing è attivo
    private(set) var isMonitoring: Bool = false

    /// Regioni attualmente monitorate
    var monitoredRegions: Set<CLRegion> {
        return locationManager.monitoredRegions
    }

    /// Numero di regioni monitorate
    var monitoredRegionsCount: Int {
        return locationManager.monitoredRegions.count
    }

    /// Spazio disponibile per nuove regioni
    var availableRegionSlots: Int {
        return GeofenceManager.maxMonitoredRegions - monitoredRegionsCount
    }

    // MARK: - Initialization

    private override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Authorization

    /// Verifica se il geofencing è disponibile
    var isGeofencingAvailable: Bool {
        return CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
    }

    /// Verifica se abbiamo i permessi necessari per il geofencing
    var hasRequiredPermissions: Bool {
        let status = locationManager.authorizationStatus
        return status == .authorizedAlways
    }

    /// Richiede l'autorizzazione Always necessaria per il geofencing
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - Add Geofence

    /// Aggiunge una regione geofence per una zona
    @discardableResult
    func addGeofence(for zone: GeofenceZone) -> Bool {
        guard isGeofencingAvailable else {
            print("GeofenceManager: Geofencing not available on this device")
            return false
        }

        guard hasRequiredPermissions else {
            print("GeofenceManager: Missing Always authorization")
            requestAlwaysAuthorization()
            return false
        }

        guard availableRegionSlots > 0 else {
            print("GeofenceManager: Maximum number of regions reached")
            return false
        }

        guard let zoneId = zone.id?.uuidString else {
            print("GeofenceManager: Invalid zone ID")
            return false
        }

        // Validazione del raggio
        guard zone.radius > 0 else {
            print("GeofenceManager: Invalid zone radius - must be greater than 0")
            return false
        }

        // Verifica se la zona è già monitorata
        if isZoneMonitored(zone) {
            print("GeofenceManager: Zone already monitored")
            return true
        }

        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude),
            radius: min(zone.radius, locationManager.maximumRegionMonitoringDistance),
            identifier: zoneId
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true

        locationManager.startMonitoring(for: region)
        isMonitoring = true

        if Config.verboseLogging {
            print("GeofenceManager: Started monitoring zone '\(zone.name ?? "Unknown")' with radius \(zone.radius)m")
        }

        return true
    }

    /// Aggiunge più zone geofence
    func addGeofences(for zones: [GeofenceZone]) -> Int {
        var addedCount = 0
        for zone in zones where zone.isActive {
            if addGeofence(for: zone) {
                addedCount += 1
            }
            if availableRegionSlots == 0 {
                break
            }
        }
        return addedCount
    }

    // MARK: - Remove Geofence

    /// Rimuove una regione geofence
    func removeGeofence(identifier: String) {
        for region in locationManager.monitoredRegions {
            if region.identifier == identifier {
                locationManager.stopMonitoring(for: region)

                if Config.verboseLogging {
                    print("GeofenceManager: Stopped monitoring region \(identifier)")
                }
                break
            }
        }

        updateMonitoringStatus()
    }

    /// Rimuove la geofence per una zona
    func removeGeofence(for zone: GeofenceZone) {
        guard let zoneId = zone.id?.uuidString else { return }
        removeGeofence(identifier: zoneId)
    }

    /// Rimuove tutte le regioni geofence
    func removeAllGeofences() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        isMonitoring = false

        if Config.verboseLogging {
            print("GeofenceManager: Removed all geofences")
        }
    }

    // MARK: - Query Methods

    /// Verifica se una zona è attualmente monitorata
    func isZoneMonitored(_ zone: GeofenceZone) -> Bool {
        guard let zoneId = zone.id?.uuidString else { return false }
        return locationManager.monitoredRegions.contains { $0.identifier == zoneId }
    }

    /// Restituisce le regioni monitorate
    func getMonitoredRegions() -> Set<CLRegion> {
        return locationManager.monitoredRegions
    }

    /// Trova la zona corrispondente a un identificatore
    private func findZone(for identifier: String) -> GeofenceZone? {
        guard let uuid = UUID(uuidString: identifier) else { return nil }
        let zones = CoreDataManager.shared.fetchAllGeofenceZones()
        return zones.first { $0.id == uuid }
    }

    // MARK: - State Management

    /// Sincronizza le regioni monitorate con le zone nel database
    func syncWithDatabase() {
        let activeZones = CoreDataManager.shared.fetchActiveGeofenceZones()
        let activeZoneIds = Set(activeZones.compactMap { $0.id?.uuidString })

        // Rimuovi regioni che non sono più nel database o non sono attive
        for region in locationManager.monitoredRegions {
            if !activeZoneIds.contains(region.identifier) {
                locationManager.stopMonitoring(for: region)
            }
        }

        // Aggiungi regioni mancanti
        let monitoredIds = Set(locationManager.monitoredRegions.map { $0.identifier })
        for zone in activeZones {
            if let zoneId = zone.id?.uuidString, !monitoredIds.contains(zoneId) {
                addGeofence(for: zone)
            }
        }

        updateMonitoringStatus()
    }

    /// Aggiorna lo stato di monitoring
    private func updateMonitoringStatus() {
        isMonitoring = !locationManager.monitoredRegions.isEmpty
    }

    // MARK: - Request State

    /// Richiede lo stato corrente per una regione (utile per debug)
    func requestState(for zone: GeofenceZone) {
        guard let zoneId = zone.id?.uuidString else { return }
        for region in locationManager.monitoredRegions {
            if region.identifier == zoneId {
                locationManager.requestState(for: region)
                break
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension GeofenceManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }

        if Config.verboseLogging {
            print("GeofenceManager: Entered region \(region.identifier)")
        }

        let zone = findZone(for: region.identifier)

        // Salva l'evento nel database
        if let zone = zone {
            CoreDataManager.shared.saveGeofenceEvent(zone: zone, eventType: .enter)

            // Invia notifica locale
            NotificationManager.shared.sendGeofenceNotification(
                zone: zone,
                eventType: .enter
            )
        }

        // Notifica il delegate
        delegate?.geofenceManager(self, didEnterRegion: region, zone: zone)

        // Posta notifica globale
        NotificationCenter.default.post(
            name: Constants.NotificationName.geofenceEntered,
            object: zone,
            userInfo: ["region": circularRegion]
        )
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }

        if Config.verboseLogging {
            print("GeofenceManager: Exited region \(region.identifier)")
        }

        let zone = findZone(for: region.identifier)

        // Salva l'evento nel database
        if let zone = zone {
            CoreDataManager.shared.saveGeofenceEvent(zone: zone, eventType: .exit)

            // Invia notifica locale
            NotificationManager.shared.sendGeofenceNotification(
                zone: zone,
                eventType: .exit
            )
        }

        // Notifica il delegate
        delegate?.geofenceManager(self, didExitRegion: region, zone: zone)

        // Posta notifica globale
        NotificationCenter.default.post(
            name: Constants.NotificationName.geofenceExited,
            object: zone,
            userInfo: ["region": circularRegion]
        )
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if Config.verboseLogging {
            print("GeofenceManager: Started monitoring for region \(region.identifier)")
        }

        // Richiedi lo stato iniziale
        manager.requestState(for: region)
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if Config.verboseLogging {
            let stateString: String
            switch state {
            case .inside:
                stateString = "inside"
            case .outside:
                stateString = "outside"
            case .unknown:
                stateString = "unknown"
            }
            print("GeofenceManager: State for region \(region.identifier) is \(stateString)")
        }
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("GeofenceManager: Monitoring failed for region \(region?.identifier ?? "unknown"): \(error.localizedDescription)")

        delegate?.geofenceManager(self, didFailWithError: error)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if Config.verboseLogging {
            print("GeofenceManager: Authorization changed to \(manager.authorizationStatus.rawValue)")
        }

        // Se abbiamo ottenuto l'autorizzazione Always, sincronizza con il database
        if hasRequiredPermissions {
            syncWithDatabase()
        }
    }
}
