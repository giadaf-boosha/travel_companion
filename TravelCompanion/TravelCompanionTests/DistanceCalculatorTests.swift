//
//  DistanceCalculatorTests.swift
//  TravelCompanionTests
//
//  Created for Travel Companion LAM Project
//

import XCTest
import CoreLocation
@testable import TravelCompanion

final class DistanceCalculatorTests: XCTestCase {

    // MARK: - Distance Calculation Tests

    func testCalculateDistance_BetweenTwoPoints_ShouldReturnCorrectDistance() {
        // Given - Roma Colosseo e Roma Vaticano (circa 3.5km di distanza)
        let point1 = CLLocationCoordinate2D(latitude: 41.8902, longitude: 12.4922) // Colosseo
        let point2 = CLLocationCoordinate2D(latitude: 41.9022, longitude: 12.4539) // Vaticano

        // When
        let distance = DistanceCalculator.calculateDistance(from: point1, to: point2)

        // Then - La distanza dovrebbe essere circa 3.5 km (3500 metri)
        XCTAssertGreaterThan(distance, 3000)
        XCTAssertLessThan(distance, 4000)
    }

    func testCalculateDistance_SamePoint_ShouldReturnZero() {
        // Given
        let point = CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)

        // When
        let distance = DistanceCalculator.calculateDistance(from: point, to: point)

        // Then
        XCTAssertEqual(distance, 0, accuracy: 0.001)
    }

    func testCalculateDistance_FromCLLocations_ShouldReturnCorrectDistance() {
        // Given
        let location1 = CLLocation(latitude: 41.8902, longitude: 12.4922)
        let location2 = CLLocation(latitude: 41.9022, longitude: 12.4539)

        // When
        let distance = DistanceCalculator.calculateDistance(from: location1, to: location2)

        // Then
        XCTAssertGreaterThan(distance, 3000)
        XCTAssertLessThan(distance, 4000)
    }

    // MARK: - Total Distance Tests

    func testCalculateTotalDistance_WithValidRoute_ShouldSumDistances() {
        // Given - Un percorso triangolare
        let route = [
            CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964),
            CLLocationCoordinate2D(latitude: 41.9100, longitude: 12.4964),
            CLLocationCoordinate2D(latitude: 41.9100, longitude: 12.5064),
            CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964) // Ritorno al punto iniziale
        ]

        // When
        let totalDistance = DistanceCalculator.calculateTotalDistance(for: route)

        // Then - La distanza totale dovrebbe essere maggiore di 0
        XCTAssertGreaterThan(totalDistance, 0)
    }

    func testCalculateTotalDistance_WithEmptyRoute_ShouldReturnZero() {
        // Given
        let route: [CLLocationCoordinate2D] = []

        // When
        let totalDistance = DistanceCalculator.calculateTotalDistance(for: route)

        // Then
        XCTAssertEqual(totalDistance, 0)
    }

    func testCalculateTotalDistance_WithSinglePoint_ShouldReturnZero() {
        // Given
        let route = [CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)]

        // When
        let totalDistance = DistanceCalculator.calculateTotalDistance(for: route)

        // Then
        XCTAssertEqual(totalDistance, 0)
    }

    // MARK: - Average Speed Tests

    func testCalculateAverageSpeed_WithValidData_ShouldReturnCorrectSpeed() {
        // Given - 10 km in 1 ora
        let distance: CLLocationDistance = 10000 // 10 km in metri
        let duration: TimeInterval = 3600 // 1 ora in secondi

        // When
        let speed = DistanceCalculator.calculateAverageSpeed(distance: distance, duration: duration)

        // Then - Velocità media = 10 km/h
        XCTAssertEqual(speed, 10.0, accuracy: 0.001)
    }

    func testCalculateAverageSpeed_WithZeroDuration_ShouldReturnZero() {
        // Given
        let distance: CLLocationDistance = 10000
        let duration: TimeInterval = 0

        // When
        let speed = DistanceCalculator.calculateAverageSpeed(distance: distance, duration: duration)

        // Then
        XCTAssertEqual(speed, 0)
    }

    func testCalculateAverageSpeed_WithZeroDistance_ShouldReturnZero() {
        // Given
        let distance: CLLocationDistance = 0
        let duration: TimeInterval = 3600

        // When
        let speed = DistanceCalculator.calculateAverageSpeed(distance: distance, duration: duration)

        // Then
        XCTAssertEqual(speed, 0)
    }

    // MARK: - Duration Formatting Tests

    func testFormatDuration_LessThanMinute_ShouldShowSeconds() {
        // Given
        let duration: TimeInterval = 45 // 45 secondi

        // When
        let formatted = DistanceCalculator.formatDuration(duration)

        // Then
        XCTAssertEqual(formatted, "00:00:45")
    }

    func testFormatDuration_Minutes_ShouldShowMinutesAndSeconds() {
        // Given
        let duration: TimeInterval = 125 // 2 minuti e 5 secondi

        // When
        let formatted = DistanceCalculator.formatDuration(duration)

        // Then
        XCTAssertEqual(formatted, "00:02:05")
    }

    func testFormatDuration_Hours_ShouldShowHoursMinutesSeconds() {
        // Given
        let duration: TimeInterval = 3725 // 1 ora, 2 minuti, 5 secondi

        // When
        let formatted = DistanceCalculator.formatDuration(duration)

        // Then
        XCTAssertEqual(formatted, "01:02:05")
    }

    func testFormatDuration_Zero_ShouldShowAllZeros() {
        // Given
        let duration: TimeInterval = 0

        // When
        let formatted = DistanceCalculator.formatDuration(duration)

        // Then
        XCTAssertEqual(formatted, "00:00:00")
    }

    // MARK: - Distance Formatting Tests

    func testFormatDistance_Meters_ShouldShowMeters() {
        // Given
        let distance: CLLocationDistance = 500

        // When
        let formatted = DistanceCalculator.formatDistance(distance)

        // Then
        XCTAssertTrue(formatted.contains("m"))
        XCTAssertFalse(formatted.contains("km"))
    }

    func testFormatDistance_Kilometers_ShouldShowKilometers() {
        // Given
        let distance: CLLocationDistance = 5500 // 5.5 km

        // When
        let formatted = DistanceCalculator.formatDistance(distance)

        // Then
        XCTAssertTrue(formatted.contains("km"))
    }

    func testFormatDistance_Zero_ShouldShowZeroMeters() {
        // Given
        let distance: CLLocationDistance = 0

        // When
        let formatted = DistanceCalculator.formatDistance(distance)

        // Then
        XCTAssertTrue(formatted.contains("0"))
    }

    // MARK: - ETA Calculation Tests

    func testCalculateETA_WithValidSpeedAndDistance_ShouldReturnCorrectTime() {
        // Given - 10 km a 20 km/h
        let distance: CLLocationDistance = 10000 // 10 km
        let speedKmH: Double = 20 // 20 km/h

        // When
        let eta = DistanceCalculator.calculateETA(distance: distance, averageSpeedKmH: speedKmH)

        // Then - ETA = 30 minuti = 1800 secondi
        XCTAssertEqual(eta, 1800, accuracy: 1)
    }

    func testCalculateETA_WithZeroSpeed_ShouldReturnZero() {
        // Given
        let distance: CLLocationDistance = 10000
        let speedKmH: Double = 0

        // When
        let eta = DistanceCalculator.calculateETA(distance: distance, averageSpeedKmH: speedKmH)

        // Then
        XCTAssertEqual(eta, 0)
    }

    // MARK: - Coordinate Validation Tests

    func testIsValidCoordinate_WithValidCoordinates_ShouldReturnTrue() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)

        // When
        let isValid = DistanceCalculator.isValidCoordinate(coordinate)

        // Then
        XCTAssertTrue(isValid)
    }

    func testIsValidCoordinate_WithInvalidLatitude_ShouldReturnFalse() {
        // Given - Latitudine fuori range (-90, 90)
        let coordinate = CLLocationCoordinate2D(latitude: 91.0, longitude: 12.4964)

        // When
        let isValid = DistanceCalculator.isValidCoordinate(coordinate)

        // Then
        XCTAssertFalse(isValid)
    }

    func testIsValidCoordinate_WithInvalidLongitude_ShouldReturnFalse() {
        // Given - Longitudine fuori range (-180, 180)
        let coordinate = CLLocationCoordinate2D(latitude: 41.9028, longitude: 181.0)

        // When
        let isValid = DistanceCalculator.isValidCoordinate(coordinate)

        // Then
        XCTAssertFalse(isValid)
    }

    func testIsValidCoordinate_WithZeroCoordinates_ShouldReturnTrue() {
        // Given - (0, 0) è una coordinata valida (Oceano Atlantico)
        let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

        // When
        let isValid = DistanceCalculator.isValidCoordinate(coordinate)

        // Then
        XCTAssertTrue(isValid)
    }
}
