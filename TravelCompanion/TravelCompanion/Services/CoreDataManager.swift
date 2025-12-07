import Foundation
import CoreData
import CoreLocation

/// Manager singleton per la gestione di Core Data
final class CoreDataManager {

    // MARK: - Singleton

    static let shared = CoreDataManager()

    private init() {}

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: Config.coreDataModelName)
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Core Data store failed to load: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Save Context

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Core Data save error: \(nsError), \(nsError.userInfo)")

                // Rollback delle modifiche non salvate
                context.rollback()

                // Notifica che il save è fallito
                NotificationCenter.default.post(
                    name: NSNotification.Name("CoreDataSaveFailed"),
                    object: self,
                    userInfo: ["error": nsError]
                )
            }
        }
    }

    // MARK: - Trip CRUD Operations

    /// Crea un nuovo viaggio
    func createTrip(destination: String, startDate: Date, endDate: Date?, type: TripType, isActive: Bool = false) -> Trip? {
        let trip = Trip(context: context)
        trip.id = UUID()
        trip.destination = destination
        trip.startDate = startDate
        trip.endDate = endDate
        trip.tripTypeRaw = type.rawValue
        trip.totalDistance = 0
        trip.isActive = isActive
        trip.createdAt = Date()
        saveContext()

        NotificationCenter.default.post(name: Constants.NotificationName.tripCreated, object: trip)
        return trip
    }

    /// Recupera tutti i viaggi ordinati per data
    func fetchAllTrips() -> [Trip] {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching trips: \(error)")
            return []
        }
    }

    /// Recupera viaggi filtrati per tipo
    func fetchTrips(filteredBy type: TripType?) -> [Trip] {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]

        if let type = type {
            request.predicate = NSPredicate(format: "tripTypeRaw == %@", type.rawValue)
        }

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching trips by type: \(error)")
            return []
        }
    }

    /// Recupera viaggi in un intervallo di date
    func fetchTrips(from startDate: Date, to endDate: Date) -> [Trip] {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        request.predicate = NSPredicate(format: "startDate >= %@ AND startDate <= %@", startDate as NSDate, endDate as NSDate)

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching trips by date range: \(error)")
            return []
        }
    }

    /// Recupera viaggi per destinazione (ricerca)
    func fetchTrips(destination searchText: String) -> [Trip] {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        request.predicate = NSPredicate(format: "destination CONTAINS[cd] %@", searchText)

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching trips by destination: \(error)")
            return []
        }
    }

    /// Recupera il viaggio attivo (se esiste)
    func fetchActiveTrip() -> Trip? {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching active trip: \(error)")
            return nil
        }
    }

    /// Aggiorna un viaggio
    func updateTrip(_ trip: Trip) {
        saveContext()
        NotificationCenter.default.post(name: Constants.NotificationName.tripUpdated, object: trip)
    }

    /// Elimina un viaggio
    func deleteTrip(_ trip: Trip) {
        // Elimina le foto dal filesystem
        let photos = fetchPhotos(for: trip)
        for photo in photos {
            if let imagePath = photo.imagePath {
                PhotoStorageManager.shared.deletePhoto(at: imagePath)
            }
        }

        context.delete(trip)
        saveContext()
        NotificationCenter.default.post(name: Constants.NotificationName.tripDeleted, object: nil)
    }

    /// Imposta lo stato attivo di un viaggio
    func setTripActive(_ trip: Trip, isActive: Bool) {
        // Prima disattiva tutti gli altri viaggi
        if isActive {
            let allTrips = fetchAllTrips()
            for t in allTrips where t.isActive {
                t.isActive = false
            }
        }

        trip.isActive = isActive
        saveContext()

        if isActive {
            NotificationCenter.default.post(name: Constants.NotificationName.trackingStarted, object: trip)
        } else {
            NotificationCenter.default.post(name: Constants.NotificationName.trackingStopped, object: trip)
        }
    }

    // MARK: - Route Operations

    /// Aggiunge un punto al percorso di un viaggio
    func addRoutePoint(to trip: Trip, location: CLLocation) {
        let route = Route(context: context)
        route.id = UUID()
        route.latitude = location.coordinate.latitude
        route.longitude = location.coordinate.longitude
        route.altitude = location.altitude
        route.timestamp = Date()
        route.speed = location.speed >= 0 ? location.speed : 0
        route.accuracy = location.horizontalAccuracy
        route.trip = trip

        // Aggiorna la distanza totale del viaggio
        updateTotalDistance(for: trip)

        saveContext()
    }

    /// Recupera tutti i punti del percorso di un viaggio
    func fetchRoute(for trip: Trip) -> [Route] {
        let request: NSFetchRequest<Route> = Route.fetchRequest()
        request.predicate = NSPredicate(format: "trip == %@", trip)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching route: \(error)")
            return []
        }
    }

    /// Calcola e aggiorna la distanza totale di un viaggio
    func updateTotalDistance(for trip: Trip) {
        let routes = fetchRoute(for: trip)
        guard routes.count >= 2 else { return }

        var totalDistance: Double = 0
        for i in 1..<routes.count {
            let prevLocation = CLLocation(latitude: routes[i-1].latitude, longitude: routes[i-1].longitude)
            let currentLocation = CLLocation(latitude: routes[i].latitude, longitude: routes[i].longitude)
            totalDistance += currentLocation.distance(from: prevLocation)
        }

        trip.totalDistance = totalDistance
        saveContext()
    }

    /// Recupera tutti i routes per un viaggio (alias per fetchRoute)
    func fetchRoutes(for trip: Trip) -> [Route] {
        return fetchRoute(for: trip)
    }

    /// Converte i punti Route in CLLocation
    func getLocations(for trip: Trip) -> [CLLocation] {
        let routes = fetchRoute(for: trip)
        return routes.map { route in
            CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: route.latitude, longitude: route.longitude),
                altitude: route.altitude,
                horizontalAccuracy: route.accuracy,
                verticalAccuracy: -1,
                timestamp: route.timestamp ?? Date()
            )
        }
    }

    // MARK: - Photo Operations

    /// Crea una foto per un viaggio (versione con parametri separati)
    func createPhoto(for trip: Trip, filename: String, latitude: Double, longitude: Double) -> Photo? {
        let photo = Photo(context: context)
        photo.id = UUID()
        photo.imagePath = filename
        photo.latitude = latitude
        photo.longitude = longitude
        photo.timestamp = Date()
        photo.trip = trip

        saveContext()
        NotificationCenter.default.post(name: Constants.NotificationName.photoAdded, object: photo)
        return photo
    }

    /// Aggiunge una foto a un viaggio
    func addPhoto(to trip: Trip, imagePath: String, location: CLLocation) -> Photo {
        let photo = Photo(context: context)
        photo.id = UUID()
        photo.imagePath = imagePath
        photo.latitude = location.coordinate.latitude
        photo.longitude = location.coordinate.longitude
        photo.timestamp = Date()
        photo.trip = trip

        saveContext()
        NotificationCenter.default.post(name: Constants.NotificationName.photoAdded, object: photo)
        return photo
    }

    /// Recupera tutte le foto di un viaggio
    func fetchPhotos(for trip: Trip) -> [Photo] {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        request.predicate = NSPredicate(format: "trip == %@", trip)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching photos: \(error)")
            return []
        }
    }

    /// Aggiorna la caption di una foto
    func updatePhotoCaption(_ photo: Photo, caption: String) {
        photo.caption = caption
        saveContext()
    }

    /// Elimina una foto
    func deletePhoto(_ photo: Photo) {
        if let imagePath = photo.imagePath {
            PhotoStorageManager.shared.deletePhoto(at: imagePath)
        }
        context.delete(photo)
        saveContext()
    }

    // MARK: - Note Operations

    /// Crea una nota per un viaggio (versione con parametri separati)
    func createNote(for trip: Trip, text: String, latitude: Double, longitude: Double) -> Note? {
        let note = Note(context: context)
        note.id = UUID()
        note.content = text
        note.timestamp = Date()
        note.latitude = latitude
        note.longitude = longitude
        note.trip = trip

        saveContext()
        NotificationCenter.default.post(name: Constants.NotificationName.noteAdded, object: note)
        return note
    }

    /// Aggiunge una nota a un viaggio
    func addNote(to trip: Trip, content: String, location: CLLocation?) -> Note {
        let note = Note(context: context)
        note.id = UUID()
        note.content = content
        note.timestamp = Date()
        note.trip = trip

        if let location = location {
            note.latitude = location.coordinate.latitude
            note.longitude = location.coordinate.longitude
        }

        saveContext()
        NotificationCenter.default.post(name: Constants.NotificationName.noteAdded, object: note)
        return note
    }

    /// Recupera tutte le note di un viaggio
    func fetchNotes(for trip: Trip) -> [Note] {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "trip == %@", trip)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching notes: \(error)")
            return []
        }
    }

    /// Aggiorna il contenuto di una nota
    func updateNote(_ note: Note, content: String) {
        note.content = content
        saveContext()
    }

    /// Elimina una nota
    func deleteNote(_ note: Note) {
        context.delete(note)
        saveContext()
    }

    // MARK: - GeofenceZone Operations

    /// Crea una nuova zona geofence
    func createGeofenceZone(name: String, center: CLLocationCoordinate2D, radius: Double) -> GeofenceZone {
        let zone = GeofenceZone(context: context)
        zone.id = UUID()
        zone.name = name
        zone.latitude = center.latitude
        zone.longitude = center.longitude
        zone.radius = radius
        zone.isActive = true
        zone.createdAt = Date()

        saveContext()
        return zone
    }

    /// Recupera tutte le zone geofence
    func fetchAllGeofenceZones() -> [GeofenceZone] {
        let request: NSFetchRequest<GeofenceZone> = GeofenceZone.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching geofence zones: \(error)")
            return []
        }
    }

    /// Recupera solo le zone attive
    func fetchActiveGeofenceZones() -> [GeofenceZone] {
        let request: NSFetchRequest<GeofenceZone> = GeofenceZone.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching active geofence zones: \(error)")
            return []
        }
    }

    /// Aggiorna lo stato attivo di una zona
    func setGeofenceZoneActive(_ zone: GeofenceZone, isActive: Bool) {
        zone.isActive = isActive
        saveContext()
    }

    /// Elimina una zona geofence
    func deleteGeofenceZone(_ zone: GeofenceZone) {
        context.delete(zone)
        saveContext()
    }

    // MARK: - GeofenceEvent Operations

    /// Salva un evento geofence
    func saveGeofenceEvent(zone: GeofenceZone, eventType: GeofenceEventType) {
        let event = GeofenceEvent(context: context)
        event.id = UUID()
        event.eventTypeRaw = eventType.rawValue
        event.timestamp = Date()
        event.zone = zone

        saveContext()

        let notificationName = eventType == .enter ?
            Constants.NotificationName.geofenceEntered :
            Constants.NotificationName.geofenceExited
        NotificationCenter.default.post(name: notificationName, object: zone)
    }

    /// Recupera gli eventi per una zona
    func fetchEvents(for zone: GeofenceZone) -> [GeofenceEvent] {
        let request: NSFetchRequest<GeofenceEvent> = GeofenceEvent.fetchRequest()
        request.predicate = NSPredicate(format: "zone == %@", zone)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching geofence events: \(error)")
            return []
        }
    }

    /// Recupera tutti gli eventi geofence recenti
    func fetchRecentGeofenceEvents(limit: Int = 50) -> [GeofenceEvent] {
        let request: NSFetchRequest<GeofenceEvent> = GeofenceEvent.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching recent geofence events: \(error)")
            return []
        }
    }

    // MARK: - Statistics

    /// Restituisce il numero totale di viaggi
    func getTotalTripsCount() -> Int {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        do {
            return try context.count(for: request)
        } catch {
            print("Error counting trips: \(error)")
            return 0
        }
    }

    /// Restituisce la distanza totale percorsa
    func getTotalDistance() -> Double {
        let trips = fetchAllTrips()
        return trips.reduce(0) { $0 + $1.totalDistance }
    }

    /// Restituisce il numero di viaggi per mese in un anno
    func getTripsCountByMonth(year: Int) -> [Int: Int] {
        var result: [Int: Int] = [:]
        for month in 1...12 {
            result[month] = 0
        }

        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = 1
        startComponents.day = 1
        guard let startOfYear = calendar.date(from: startComponents) else { return result }

        var endComponents = DateComponents()
        endComponents.year = year
        endComponents.month = 12
        endComponents.day = 31
        guard let endOfYear = calendar.date(from: endComponents) else { return result }

        let trips = fetchTrips(from: startOfYear, to: endOfYear)

        for trip in trips {
            if let startDate = trip.startDate {
                let month = calendar.component(.month, from: startDate)
                result[month, default: 0] += 1
            }
        }

        return result
    }

    /// Restituisce la distanza totale per mese in un anno
    func getDistanceByMonth(year: Int) -> [Int: Double] {
        var result: [Int: Double] = [:]
        for month in 1...12 {
            result[month] = 0
        }

        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = 1
        startComponents.day = 1
        guard let startOfYear = calendar.date(from: startComponents) else { return result }

        var endComponents = DateComponents()
        endComponents.year = year
        endComponents.month = 12
        endComponents.day = 31
        guard let endOfYear = calendar.date(from: endComponents) else { return result }

        let trips = fetchTrips(from: startOfYear, to: endOfYear)

        for trip in trips {
            if let startDate = trip.startDate {
                let month = calendar.component(.month, from: startDate)
                result[month, default: 0] += trip.totalDistance
            }
        }

        return result
    }

    /// Restituisce il numero totale di foto
    func getTotalPhotosCount() -> Int {
        let request: NSFetchRequest<Photo> = Photo.fetchRequest()
        do {
            return try context.count(for: request)
        } catch {
            print("Error counting photos: \(error)")
            return 0
        }
    }

    /// Restituisce il numero totale di note
    func getTotalNotesCount() -> Int {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        do {
            return try context.count(for: request)
        } catch {
            print("Error counting notes: \(error)")
            return 0
        }
    }

    /// Restituisce l'ultimo viaggio completato
    func getLastCompletedTrip() -> Trip? {
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching last completed trip: \(error)")
            return nil
        }
    }
}
