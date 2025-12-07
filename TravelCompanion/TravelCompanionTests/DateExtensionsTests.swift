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

    // MARK: - Adding Components Tests

    func testAddingDays_ShouldAddCorrectDays() {
        // Given
        let date = Date()

        // When
        let futureDate = date.adding(days: 5)

        // Then
        let daysDifference = calendar.dateComponents([.day], from: date, to: futureDate).day
        XCTAssertEqual(daysDifference, 5)
    }

    func testAddingDays_WithNegative_ShouldSubtractDays() {
        // Given
        let date = Date()

        // When
        let pastDate = date.adding(days: -3)

        // Then
        let daysDifference = calendar.dateComponents([.day], from: pastDate, to: date).day
        XCTAssertEqual(daysDifference, 3)
    }

    func testAddingMonths_ShouldAddCorrectMonths() {
        // Given
        let date = Date()

        // When
        let futureDate = date.adding(months: 2)

        // Then
        let monthsDifference = calendar.dateComponents([.month], from: date, to: futureDate).month
        XCTAssertEqual(monthsDifference, 2)
    }

    func testAddingYears_ShouldAddCorrectYears() {
        // Given
        let date = Date()

        // When
        let futureDate = date.adding(years: 1)

        // Then
        let yearsDifference = calendar.dateComponents([.year], from: date, to: futureDate).year
        XCTAssertEqual(yearsDifference, 1)
    }

    // MARK: - Date Comparison Tests

    func testIsToday_WithCurrentDate_ShouldReturnTrue() {
        // Given
        let today = Date()

        // When
        let isToday = today.isToday

        // Then
        XCTAssertTrue(isToday)
    }

    func testIsToday_WithYesterdayDate_ShouldReturnFalse() {
        // Given
        let yesterday = Date().adding(days: -1)

        // When
        let isToday = yesterday.isToday

        // Then
        XCTAssertFalse(isToday)
    }

    func testIsYesterday_WithYesterdayDate_ShouldReturnTrue() {
        // Given
        let yesterday = Date().adding(days: -1)

        // When
        let isYesterday = yesterday.isYesterday

        // Then
        XCTAssertTrue(isYesterday)
    }

    func testIsTomorrow_WithTomorrowDate_ShouldReturnTrue() {
        // Given
        let tomorrow = Date().adding(days: 1)

        // When
        let isTomorrow = tomorrow.isTomorrow

        // Then
        XCTAssertTrue(isTomorrow)
    }

    func testIsInPast_WithPastDate_ShouldReturnTrue() {
        // Given
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago

        // When
        let isInPast = pastDate.isInPast

        // Then
        XCTAssertTrue(isInPast)
    }

    func testIsInFuture_WithFutureDate_ShouldReturnTrue() {
        // Given
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now

        // When
        let isInFuture = futureDate.isInFuture

        // Then
        XCTAssertTrue(isInFuture)
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
        let date2 = Date().adding(days: 1)

        // When
        let isSameDay = date1.isSameDay(as: date2)

        // Then
        XCTAssertFalse(isSameDay)
    }

    // MARK: - Days Between Tests

    func testDaysBetween_WithPositiveDifference_ShouldReturnCorrectCount() {
        // Given
        let startDate = Date()
        let endDate = Date().adding(days: 7)

        // When
        let days = startDate.daysBetween(endDate)

        // Then
        XCTAssertEqual(days, 7)
    }

    func testDaysBetween_WithNegativeDifference_ShouldReturnNegativeCount() {
        // Given
        let startDate = Date()
        let endDate = Date().adding(days: -3)

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

    // MARK: - Formatting Tests

    func testFormatted_WithDisplayFormat_ShouldReturnFormattedString() {
        // Given
        let date = Date()

        // When
        let formatted = date.formatted(with: Constants.DateFormat.display)

        // Then
        XCTAssertFalse(formatted.isEmpty)
    }

    func testFormatted_WithTimeFormat_ShouldReturnTimeString() {
        // Given
        let date = Date()

        // When
        let formatted = date.formatted(with: Constants.DateFormat.time)

        // Then
        // Should contain colon (HH:mm format)
        XCTAssertTrue(formatted.contains(":"))
    }

    func testFormattedRelative_ShouldReturnNonEmptyString() {
        // Given
        let date = Date()

        // When
        let formatted = date.formattedRelative

        // Then
        XCTAssertFalse(formatted.isEmpty)
    }

    // MARK: - Component Extraction Tests

    func testYear_ShouldReturnCorrectYear() {
        // Given
        let date = Date()
        let expectedYear = calendar.component(.year, from: date)

        // When
        let year = date.year

        // Then
        XCTAssertEqual(year, expectedYear)
    }

    func testMonth_ShouldReturnCorrectMonth() {
        // Given
        let date = Date()
        let expectedMonth = calendar.component(.month, from: date)

        // When
        let month = date.month

        // Then
        XCTAssertEqual(month, expectedMonth)
    }

    func testDay_ShouldReturnCorrectDay() {
        // Given
        let date = Date()
        let expectedDay = calendar.component(.day, from: date)

        // When
        let day = date.day

        // Then
        XCTAssertEqual(day, expectedDay)
    }

    func testWeekday_ShouldReturnValueBetween1And7() {
        // Given
        let date = Date()

        // When
        let weekday = date.weekday

        // Then
        XCTAssertGreaterThanOrEqual(weekday, 1)
        XCTAssertLessThanOrEqual(weekday, 7)
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

    // MARK: - Weekday Name Tests

    func testWeekdayName_ShouldReturnNonEmptyString() {
        // Given
        let date = Date()

        // When
        let weekdayName = date.weekdayName

        // Then
        XCTAssertFalse(weekdayName.isEmpty)
    }

    func testMonthName_ShouldReturnNonEmptyString() {
        // Given
        let date = Date()

        // When
        let monthName = date.monthName

        // Then
        XCTAssertFalse(monthName.isEmpty)
    }
}
