//
//  DateExtensionsTests.swift
//  TravelCompanionTests
//
//  Created for Travel Companion LAM Project
//

import XCTest
@testable import TravelCompanion

final class DateExtensionsTests: XCTestCase {

    // MARK: - Properties

    let calendar = Calendar.current

    // MARK: - Start/End of Day Tests

    func testStartOfDay_ShouldReturnMidnight() {
        // Given
        let date = Date()

        // When
        let startOfDay = date.startOfDay

        // Then
        let components = calendar.dateComponents([.hour, .minute, .second], from: startOfDay)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testEndOfDay_ShouldReturn2359() {
        // Given
        let date = Date()

        // When
        let endOfDay = date.endOfDay

        // Then
        let components = calendar.dateComponents([.hour, .minute, .second], from: endOfDay)
        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 59)
    }

    // MARK: - Same Day Comparison Tests

    func testIsSameDay_WithSameDay_ShouldReturnTrue() {
        // Given
        let date1 = Date()
        let date2 = Date().addingTimeInterval(3600) // 1 hour later same day

        // When
        let isSameDay = date1.isSameDay(as: date2)

        // Then
        XCTAssertTrue(isSameDay)
    }

    func testIsSameDay_WithDifferentDay_ShouldReturnFalse() {
        // Given
        let date1 = Date()
        let date2 = calendar.date(byAdding: .day, value: 1, to: date1)!

        // When
        let isSameDay = date1.isSameDay(as: date2)

        // Then
        XCTAssertFalse(isSameDay)
    }

    // MARK: - Days Between Tests

    func testDaysBetween_WithPositiveDifference_ShouldReturnCorrectCount() {
        // Given
        let startDate = Date()
        let endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!

        // When
        let days = startDate.daysBetween(endDate)

        // Then
        XCTAssertEqual(days, 7)
    }

    func testDaysBetween_WithNegativeDifference_ShouldReturnNegativeCount() {
        // Given
        let startDate = Date()
        let endDate = calendar.date(byAdding: .day, value: -3, to: startDate)!

        // When
        let days = startDate.daysBetween(endDate)

        // Then
        XCTAssertEqual(days, -3)
    }

    func testDaysBetween_SameDay_ShouldReturnZero() {
        // Given
        let date = Date()

        // When
        let days = date.daysBetween(date)

        // Then
        XCTAssertEqual(days, 0)
    }

    // MARK: - Months Between Tests

    func testMonthsBetween_ShouldReturnCorrectCount() {
        // Given
        let startDate = Date()
        let endDate = calendar.date(byAdding: .month, value: 3, to: startDate)!

        // When
        let months = startDate.monthsBetween(endDate)

        // Then
        XCTAssertEqual(months, 3)
    }

    // MARK: - Formatting Tests

    func testFormatted_WithMediumStyle_ShouldReturnFormattedString() {
        // Given
        let date = Date()

        // When
        let formatted = date.formatted(style: .medium)

        // Then
        XCTAssertFalse(formatted.isEmpty)
    }

    func testFormattedWithTime_ShouldReturnNonEmptyString() {
        // Given
        let date = Date()

        // When
        let formatted = date.formattedWithTime()

        // Then
        XCTAssertFalse(formatted.isEmpty)
    }

    // MARK: - TimeAgo Tests

    func testTimeAgo_JustNow_ShouldReturnCorrectString() {
        // Given
        let date = Date()

        // When
        let timeAgo = date.timeAgo()

        // Then
        XCTAssertEqual(timeAgo, "Just now")
    }

    func testTimeAgo_MinutesAgo_ShouldReturnCorrectString() {
        // Given
        let date = Date().addingTimeInterval(-120) // 2 minutes ago

        // When
        let timeAgo = date.timeAgo()

        // Then
        XCTAssertTrue(timeAgo.contains("minute"))
    }

    func testTimeAgo_HoursAgo_ShouldReturnCorrectString() {
        // Given
        let date = Date().addingTimeInterval(-7200) // 2 hours ago

        // When
        let timeAgo = date.timeAgo()

        // Then
        XCTAssertTrue(timeAgo.contains("hour"))
    }

    // MARK: - Month Range Tests

    func testStartOfMonth_ShouldReturnFirstDayOfMonth() {
        // Given
        let date = Date()

        // When
        let startOfMonth = date.startOfMonth

        // Then
        let components = calendar.dateComponents([.day], from: startOfMonth)
        XCTAssertEqual(components.day, 1)
    }

    func testEndOfMonth_ShouldReturnLastDayOfMonth() {
        // Given
        let date = Date()

        // When
        let endOfMonth = date.endOfMonth

        // Then
        // Next day should be first of next month
        let nextDay = calendar.date(byAdding: .day, value: 1, to: endOfMonth)!
        let components = calendar.dateComponents([.day], from: nextDay)
        XCTAssertEqual(components.day, 1)
    }
}
