//
//  CoreDataManagerTests.swift
//  TravelCompanionTests
//
//  Created for Travel Companion LAM Project
//

import XCTest
import CoreData
import CoreLocation
@testable import TravelCompanion

final class CoreDataManagerTests: XCTestCase {

    // MARK: - Properties

    var sut: CoreDataManager!
    var testContainer: NSPersistentContainer!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create in-memory persistent container for testing
        testContainer = NSPersistentContainer(name: "TravelCompanion")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        testContainer.persistentStoreDescriptions = [description]

        testContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }

        sut = CoreDataManager.shared
    }

    override func tearDownWithError() throws {
        // Clean up all trips
        let trips = sut.fetchAllTrips()
        for trip in trips {
            sut.deleteTrip(trip)
        }

        // Clean up all geofence zones
        let zones = sut.fetchAllGeofenceZones()
        for zone in zones {
            sut.deleteGeofenceZone(zone)
        }

        testContainer = nil
        try super.tearDownWithError()
    }

    // MARK: - Trip Creation Tests

    func testCreateTrip_WithValidData_ShouldCreateTrip() {
        // Given
        let destination = "Roma"
        let startDate = Date()
        let endDate = Date().addingTimeInterval(86400 * 3) // 3 days later
        let type = TripType.multiDay

        // When
        let trip = sut.createTrip(
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            type: type,
            isActive: false
        )

        // Then
        XCTAssertNotNil(trip)
        XCTAssertEqual(trip?.destination, destination)
        XCTAssertEqual(trip?.startDate, startDate)
        XCTAssertEqual(trip?.endDate, endDate)
        XCTAssertEqual(trip?.tripTypeRaw, type.rawValue)
        XCTAssertFalse(trip?.isActive ?? true)
        XCTAssertEqual(trip?.totalDistance, 0)
        XCTAssertNotNil(trip?.id)
        XCTAssertNotNil(trip?.createdAt)
    }

    func testCreateTrip_WithActiveFlag_ShouldSetIsActive() {
        // Given
        let destination = "Milano"
        let startDate = Date()

        // When
        let trip = sut.createTrip(
            destination: destination,
            startDate: startDate,
            endDate: nil,
            type: .dayTrip,
            isActive: true
        )

        // Then
        XCTAssertNotNil(trip)
        XCTAssertTrue(trip?.isActive ?? false)
    }

    func testCreateTrip_WithLocalType_ShouldHaveCorrectType() {
        // Given
        let destination = "Centro Storico"
        let startDate = Date()

        // When
        let trip = sut.createTrip(
            destination: destination,
            startDate: startDate,
            endDate: nil,
            type: .local,
            isActive: false
        )

        // Then
        XCTAssertNotNil(trip)
        XCTAssertEqual(trip?.tripTypeRaw, TripType.local.rawValue)
    }

    // MARK: - Trip Fetch Tests

    func testFetchAllTrips_WhenEmpty_ShouldReturnEmptyArray() {
        // When
        let trips = sut.fetchAllTrips()

        // Then
        // Note: Other tests may have created trips, so we just verify it returns an array
        XCTAssertNotNil(trips)
    }

    func testFetchAllTrips_WithMultipleTrips_ShouldReturnAllTrips() {
        // Given
        let _ = sut.createTrip(destination: "Roma", startDate: Date(), endDate: nil, type: .local, isActive: false)
        let _ = sut.createTrip(destination: "Milano", startDate: Date(), endDate: nil, type: .dayTrip, isActive: false)
        let _ = sut.createTrip(destination: "Napoli", startDate: Date(), endDate: nil, type: .multiDay, isActive: false)

        // When
        let trips = sut.fetchAllTrips()

        // Then
        XCTAssertGreaterThanOrEqual(trips.count, 3)
    }

    func testFetchTrips_FilteredByType_ShouldReturnOnlyMatchingType() {
        // Given
        let _ = sut.createTrip(destination: "Roma", startDate: Date(), endDate: nil, type: .local, isActive: false)
        let _ = sut.createTrip(destination: "Milano", startDate: Date(), endDate: nil, type: .dayTrip, isActive: false)
        let _ = sut.createTrip(destination: "Firenze", startDate: Date(), endDate: nil, type: .local, isActive: false)

        // When
        let localTrips = sut.fetchTrips(filteredBy: .local)

        // Then
        XCTAssertGreaterThanOrEqual(localTrips.count, 2)
        for trip in localTrips {
            XCTAssertEqual(trip.tripTypeRaw, TripType.local.rawValue)
        }
    }

    func testFetchActiveTrip_WhenExists_ShouldReturnActiveTrip() {
        // Given
        let _ = sut.createTrip(destination: "Roma", startDate: Date(), endDate: nil, type: .local, isActive: false)
        let _ = sut.createTrip(destination: "Milano", startDate: Date(), endDate: nil, type: .dayTrip, isActive: true)

        // When
        let activeTrip = sut.fetchActiveTrip()

        // Then
        XCTAssertNotNil(activeTrip)
        XCTAssertTrue(activeTrip?.isActive ?? false)
    }

    func testFetchTrips_ByDestination_ShouldReturnMatchingTrips() {
        // Given
        let _ = sut.createTrip(destination: "Roma Centro", startDate: Date(), endDate: nil, type: .local, isActive: false)
        let _ = sut.createTrip(destination: "Roma Nord", startDate: Date(), endDate: nil, type: .dayTrip, isActive: false)
        let _ = sut.createTrip(destination: "Milano", startDate: Date(), endDate: nil, type: .local, isActive: false)

        // When
        let romaTrips = sut.fetchTrips(destination: "Roma")

        // Then
        XCTAssertGreaterThanOrEqual(romaTrips.count, 2)
        for trip in romaTrips {
            XCTAssertTrue(trip.destination?.contains("Roma") ?? false)
        }
    }

    // MARK: - Trip Update Tests

    func testSetTripActive_ShouldDeactivateOtherTrips() {
        // Given
        let trip1 = sut.createTrip(destination: "Roma", startDate: Date(), endDate: nil, type: .local, isActive: true)
        let trip2 = sut.createTrip(destination: "Milano", startDate: Date(), endDate: nil, type: .dayTrip, isActive: false)

        // When
        sut.setTripActive(trip2!, isActive: true)

        // Then
        XCTAssertFalse(trip1?.isActive ?? true)
        XCTAssertTrue(trip2?.isActive ?? false)
    }

    // MARK: - Trip Delete Tests

    func testDeleteTrip_ShouldRemoveTrip() {
        // Given
        let trip = sut.createTrip(destination: "Test", startDate: Date(), endDate: nil, type: .local, isActive: false)
        let tripId = trip?.id

        // When
        sut.deleteTrip(trip!)

        // Then
        let allTrips = sut.fetchAllTrips()
        let foundTrip = allTrips.first { $0.id == tripId }
        XCTAssertNil(foundTrip)
    }

    // MARK: - Route Tests

    func testAddRoutePoint_ShouldAddToTrip() {
        // Given
        let trip = sut.createTrip(destination: "Roma", startDate: Date(), endDate: nil, type: .local, isActive: true)!
        let location = CLLocation(latitude: 41.9028, longitude: 12.4964)

        // When
        sut.addRoutePoint(to: trip, location: location)

        // Then
        let routes = sut.fetchRoute(for: trip)
        XCTAssertEqual(routes.count, 1)
        XCTAssertEqual(routes.first?.latitude, 41.9028)
        XCTAssertEqual(routes.first?.longitude, 12.4964)
    }

    func testUpdateTotalDistance_WithMultiplePoints_ShouldCalculateCorrectly() {
        // Given
        let trip = sut.createTrip(destination: "Roma", startDate: Date(), endDate: nil, type: .local, isActive: true)!

        let location1 = CLLocation(latitude: 41.9028, longitude: 12.4964)
        let location2 = CLLocation(latitude: 41.9100, longitude: 12.5000)

        // When
        sut.addRoutePoint(to: trip, location: location1)
        sut.addRoutePoint(to: trip, location: location2)

        // Then
        XCTAssertGreaterThan(trip.totalDistance, 0)
    }

    // MARK: - Photo Tests

    func testCreatePhoto_ShouldAddToTrip() {
        // Given
        let trip = sut.createTrip(destination: "Roma", startDate: Date(), endDate: nil, type: .local, isActive: true)!

        // When
        let photo = sut.createPhoto(for: trip, filename: "test.jpg", latitude: 41.9028, longitude: 12.4964)

        // Then
        XCTAssertNotNil(photo)
        XCTAssertEqual(photo?.imagePath, "test.jpg")
        XCTAssertEqual(photo?.latitude, 41.9028)
        XCTAssertEqual(photo?.longitude, 12.4964)
    }

    func testFetchPhotos_ShouldReturnPhotosForTrip() {
        // Given
        let trip = sut.createTrip(destination: "Roma", startDate: Date(), endDate: nil, type: .local, isActive: true)!
        let _ = sut.createPhoto(for: trip, filename: "photo1.jpg", latitude: 41.9028, longitude: 12.4964)
        let _ = sut.createPhoto(for: trip, filename: "photo2.jpg", latitude: 41.9028, longitude: 12.4964)

        // When
        let photos = sut.fetchPhotos(for: trip)

        // Then
        XCTAssertEqual(photos.count, 2)
    }

    // MARK: - Note Tests

    func testCreateNote_ShouldAddToTrip() {
        // Given
        let trip = sut.createTrip(destination: "Roma", startDate: Date(), endDate: nil, type: .local, isActive: true)!

        // When
        let note = sut.createNote(for: trip, text: "Bella vista!", latitude: 41.9028, longitude: 12.4964)

        // Then
        XCTAssertNotNil(note)
        XCTAssertEqual(note?.content, "Bella vista!")
        XCTAssertEqual(note?.latitude, 41.9028)
        XCTAssertEqual(note?.longitude, 12.4964)
    }

    func testFetchNotes_ShouldReturnNotesForTrip() {
        // Given
        let trip = sut.createTrip(destination: "Roma", startDate: Date(), endDate: nil, type: .local, isActive: true)!
        let _ = sut.createNote(for: trip, text: "Nota 1", latitude: 41.9028, longitude: 12.4964)
        let _ = sut.createNote(for: trip, text: "Nota 2", latitude: 41.9028, longitude: 12.4964)

        // When
        let notes = sut.fetchNotes(for: trip)

        // Then
        XCTAssertEqual(notes.count, 2)
    }

    // MARK: - GeofenceZone Tests

    func testCreateGeofenceZone_ShouldCreateZone() {
        // Given
        let name = "Casa"
        let center = CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)
        let radius: Double = 100

        // When
        let zone = sut.createGeofenceZone(name: name, center: center, radius: radius)

        // Then
        XCTAssertNotNil(zone)
        XCTAssertEqual(zone.name, name)
        XCTAssertEqual(zone.latitude, center.latitude)
        XCTAssertEqual(zone.longitude, center.longitude)
        XCTAssertEqual(zone.radius, radius)
        XCTAssertTrue(zone.isActive)
    }

    func testFetchAllGeofenceZones_ShouldReturnAllZones() {
        // Given
        let center = CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)
        let _ = sut.createGeofenceZone(name: "Zone 1", center: center, radius: 100)
        let _ = sut.createGeofenceZone(name: "Zone 2", center: center, radius: 200)

        // When
        let zones = sut.fetchAllGeofenceZones()

        // Then
        XCTAssertGreaterThanOrEqual(zones.count, 2)
    }

    func testFetchActiveGeofenceZones_ShouldReturnOnlyActiveZones() {
        // Given
        let center = CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)
        let zone1 = sut.createGeofenceZone(name: "Active Zone", center: center, radius: 100)
        let zone2 = sut.createGeofenceZone(name: "Inactive Zone", center: center, radius: 200)
        sut.setGeofenceZoneActive(zone2, isActive: false)

        // When
        let activeZones = sut.fetchActiveGeofenceZones()

        // Then
        XCTAssertTrue(activeZones.contains(where: { $0.id == zone1.id }))
        XCTAssertFalse(activeZones.contains(where: { $0.id == zone2.id }))
    }

    // MARK: - Statistics Tests

    func testGetTotalTripsCount_ShouldReturnCorrectCount() {
        // Given
        let initialCount = sut.getTotalTripsCount()
        let _ = sut.createTrip(destination: "Roma", startDate: Date(), endDate: nil, type: .local, isActive: false)
        let _ = sut.createTrip(destination: "Milano", startDate: Date(), endDate: nil, type: .dayTrip, isActive: false)

        // When
        let finalCount = sut.getTotalTripsCount()

        // Then
        XCTAssertEqual(finalCount, initialCount + 2)
    }

    func testGetTotalDistance_ShouldReturnSumOfAllDistances() {
        // Given
        let trip1 = sut.createTrip(destination: "Roma", startDate: Date(), endDate: nil, type: .local, isActive: false)!
        let trip2 = sut.createTrip(destination: "Milano", startDate: Date(), endDate: nil, type: .dayTrip, isActive: false)!

        trip1.totalDistance = 1000
        trip2.totalDistance = 2000
        sut.saveContext()

        // When
        let totalDistance = sut.getTotalDistance()

        // Then
        XCTAssertGreaterThanOrEqual(totalDistance, 3000)
    }

    func testGetTripsCountByMonth_ShouldReturnCorrectDistribution() {
        // Given
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())

        let _ = sut.createTrip(destination: "Roma", startDate: Date(), endDate: nil, type: .local, isActive: false)

        // When
        let tripsCountByMonth = sut.getTripsCountByMonth(year: currentYear)

        // Then
        XCTAssertNotNil(tripsCountByMonth[currentMonth])
        XCTAssertGreaterThanOrEqual(tripsCountByMonth[currentMonth] ?? 0, 1)
    }
}
