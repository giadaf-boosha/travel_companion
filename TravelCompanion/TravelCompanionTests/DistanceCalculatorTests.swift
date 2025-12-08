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

    func testCalculateDistance_WithTwoLocations_ShouldReturnCorrectDistance() {
        // Given - Two locations approximately 1km apart
        let location1 = CLLocation(latitude: 44.4949, longitude: 11.3426) // Bologna
        let location2 = CLLocation(latitude: 44.5049, longitude: 11.3426) // ~1.1km north

        // When
        let distance = DistanceCalculator.calculateDistance(from: [location1, location2])

        // Then - Should be approximately 1100 meters
        XCTAssertGreaterThan(distance, 1000)
        XCTAssertLessThan(distance, 1200)
    }

    func testCalculateDistance_WithEmptyArray_ShouldReturnZero() {
        // Given
        let locations: [CLLocation] = []

        // When
        let distance = DistanceCalculator.calculateDistance(from: locations)

        // Then
        XCTAssertEqual(distance, 0.0)
    }

    func testCalculateDistance_WithSingleLocation_ShouldReturnZero() {
        // Given
        let location = CLLocation(latitude: 44.4949, longitude: 11.3426)

        // When
        let distance = DistanceCalculator.calculateDistance(from: [location])

        // Then
        XCTAssertEqual(distance, 0.0)
    }

    func testCalculateDistance_WithMultipleLocations_ShouldSumDistances() {
        // Given - Three locations forming a path
        let location1 = CLLocation(latitude: 44.4949, longitude: 11.3426)
        let location2 = CLLocation(latitude: 44.5049, longitude: 11.3426)
        let location3 = CLLocation(latitude: 44.5049, longitude: 11.3526)

        // When
        let distance = DistanceCalculator.calculateDistance(from: [location1, location2, location3])

        // Then - Should be greater than 0
        XCTAssertGreaterThan(distance, 0)
    }

    // MARK: - Format Distance Tests

    func testFormatDistance_UnderOneKm_ShouldShowMeters() {
        // Given
        let meters = 500.0

        // When
        let formatted = DistanceCalculator.formatDistance(meters)

        // Then
        XCTAssertEqual(formatted, "500 m")
    }

    func testFormatDistance_OverOneKm_ShouldShowKilometers() {
        // Given
        let meters = 2500.0

        // When
        let formatted = DistanceCalculator.formatDistance(meters)

        // Then
        XCTAssertEqual(formatted, "2.5 km")
    }

    func testFormatDistance_ExactlyOneKm_ShouldShowKilometers() {
        // Given
        let meters = 1000.0

        // When
        let formatted = DistanceCalculator.formatDistance(meters)

        // Then
        XCTAssertEqual(formatted, "1.0 km")
    }

    func testFormatDistance_Zero_ShouldShowZeroMeters() {
        // Given
        let meters = 0.0

        // When
        let formatted = DistanceCalculator.formatDistance(meters)

        // Then
        XCTAssertEqual(formatted, "0 m")
    }

    // MARK: - Duration Calculation Tests

    func testCalculateDuration_ShouldReturnCorrectSeconds() {
        // Given
        let start = Date()
        let end = start.addingTimeInterval(3600) // 1 hour later

        // When
        let duration = DistanceCalculator.calculateDuration(from: start, to: end)

        // Then
        XCTAssertEqual(duration, 3600)
    }

    func testCalculateDuration_WithSameDate_ShouldReturnZero() {
        // Given
        let date = Date()

        // When
        let duration = DistanceCalculator.calculateDuration(from: date, to: date)

        // Then
        XCTAssertEqual(duration, 0)
    }

    // MARK: - Format Duration Tests

    func testFormatDuration_UnderOneMinute_ShouldShowSeconds() {
        // Given
        let seconds: TimeInterval = 45

        // When
        let formatted = DistanceCalculator.formatDuration(seconds)

        // Then
        XCTAssertEqual(formatted, "45s")
    }

    func testFormatDuration_UnderOneHour_ShouldShowMinutesAndSeconds() {
        // Given
        let seconds: TimeInterval = 330 // 5 minutes 30 seconds

        // When
        let formatted = DistanceCalculator.formatDuration(seconds)

        // Then
        XCTAssertEqual(formatted, "5m 30s")
    }

    func testFormatDuration_OverOneHour_ShouldShowHoursAndMinutes() {
        // Given
        let seconds: TimeInterval = 7500 // 2 hours 5 minutes

        // When
        let formatted = DistanceCalculator.formatDuration(seconds)

        // Then
        XCTAssertEqual(formatted, "2h 5m")
    }

    // MARK: - Speed Calculation Tests

    func testCalculateAverageSpeed_ShouldReturnCorrectValue() {
        // Given
        let distance: CLLocationDistance = 10000 // 10 km
        let duration: TimeInterval = 3600 // 1 hour

        // When
        let speed = DistanceCalculator.calculateAverageSpeed(distance: distance, duration: duration)

        // Then
        XCTAssertEqual(speed, 10.0, accuracy: 0.01)
    }

    func testCalculateAverageSpeed_WithZeroDuration_ShouldReturnZero() {
        // Given
        let distance: CLLocationDistance = 1000
        let duration: TimeInterval = 0

        // When
        let speed = DistanceCalculator.calculateAverageSpeed(distance: distance, duration: duration)

        // Then
        XCTAssertEqual(speed, 0.0)
    }

    func testCalculateAverageSpeed_WithZeroDistance_ShouldReturnZero() {
        // Given
        let distance: CLLocationDistance = 0
        let duration: TimeInterval = 3600

        // When
        let speed = DistanceCalculator.calculateAverageSpeed(distance: distance, duration: duration)

        // Then
        XCTAssertEqual(speed, 0.0)
    }

    // MARK: - Format Speed Tests

    func testFormatSpeed_ShouldReturnFormattedString() {
        // Given
        let speed = 25.5

        // When
        let formatted = DistanceCalculator.formatSpeed(speed)

        // Then
        XCTAssertEqual(formatted, "25.5 km/h")
    }

    func testFormatSpeed_WithZero_ShouldReturnZeroFormatted() {
        // Given
        let speed = 0.0

        // When
        let formatted = DistanceCalculator.formatSpeed(speed)

        // Then
        XCTAssertEqual(formatted, "0.0 km/h")
    }
}
