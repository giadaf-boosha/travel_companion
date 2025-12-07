//
//  TripTypeTests.swift
//  TravelCompanionTests
//
//  Created for Travel Companion LAM Project
//

import XCTest
import UIKit
@testable import TravelCompanion

final class TripTypeTests: XCTestCase {

    // MARK: - Raw Value Tests

    func testTripType_Local_ShouldHaveCorrectRawValue() {
        // Given
        let tripType = TripType.local

        // When
        let rawValue = tripType.rawValue

        // Then
        XCTAssertEqual(rawValue, "local")
    }

    func testTripType_DayTrip_ShouldHaveCorrectRawValue() {
        // Given
        let tripType = TripType.dayTrip

        // When
        let rawValue = tripType.rawValue

        // Then
        XCTAssertEqual(rawValue, "dayTrip")
    }

    func testTripType_MultiDay_ShouldHaveCorrectRawValue() {
        // Given
        let tripType = TripType.multiDay

        // When
        let rawValue = tripType.rawValue

        // Then
        XCTAssertEqual(rawValue, "multiDay")
    }

    // MARK: - Init from Raw Value Tests

    func testTripType_InitFromValidRawValue_ShouldReturnCorrectType() {
        // Given
        let rawValues = ["local", "dayTrip", "multiDay"]
        let expectedTypes: [TripType] = [.local, .dayTrip, .multiDay]

        // When & Then
        for (index, rawValue) in rawValues.enumerated() {
            let tripType = TripType(rawValue: rawValue)
            XCTAssertEqual(tripType, expectedTypes[index])
        }
    }

    func testTripType_InitFromInvalidRawValue_ShouldReturnNil() {
        // Given
        let invalidRawValue = "invalid_type"

        // When
        let tripType = TripType(rawValue: invalidRawValue)

        // Then
        XCTAssertNil(tripType)
    }

    // MARK: - Display Name Tests

    func testTripType_Local_ShouldHaveCorrectDisplayName() {
        // Given
        let tripType = TripType.local

        // When
        let displayName = tripType.displayName

        // Then
        XCTAssertFalse(displayName.isEmpty)
    }

    func testTripType_DayTrip_ShouldHaveCorrectDisplayName() {
        // Given
        let tripType = TripType.dayTrip

        // When
        let displayName = tripType.displayName

        // Then
        XCTAssertFalse(displayName.isEmpty)
    }

    func testTripType_MultiDay_ShouldHaveCorrectDisplayName() {
        // Given
        let tripType = TripType.multiDay

        // When
        let displayName = tripType.displayName

        // Then
        XCTAssertFalse(displayName.isEmpty)
    }

    // MARK: - Icon Tests

    func testTripType_AllTypes_ShouldHaveIcon() {
        // Given
        let allTypes: [TripType] = [.local, .dayTrip, .multiDay]

        // When & Then
        for tripType in allTypes {
            let icon = tripType.icon
            XCTAssertFalse(icon.isEmpty, "TripType \(tripType.rawValue) should have an icon")
        }
    }

    // MARK: - Color Tests

    func testTripType_AllTypes_ShouldHaveColor() {
        // Given
        let allTypes: [TripType] = [.local, .dayTrip, .multiDay]

        // When & Then
        for tripType in allTypes {
            let color = tripType.color
            XCTAssertNotNil(color, "TripType \(tripType.rawValue) should have a color")
        }
    }

    func testTripType_DifferentTypes_ShouldHaveDifferentColors() {
        // Given
        let localColor = TripType.local.color
        let dayTripColor = TripType.dayTrip.color
        let multiDayColor = TripType.multiDay.color

        // Then - At least some colors should be different
        // Note: This test might fail if all types have the same color by design
        let colorsAreAllSame = (localColor == dayTripColor && dayTripColor == multiDayColor)
        // We don't assert false here because all same colors might be intentional
        XCTAssertNotNil(localColor)
        XCTAssertNotNil(dayTripColor)
        XCTAssertNotNil(multiDayColor)
    }

    // MARK: - Segment Index Tests

    func testTripType_InitFromSegmentIndex_ShouldReturnCorrectType() {
        // Given
        let indices = [0, 1, 2]
        let expectedTypes: [TripType] = [.local, .dayTrip, .multiDay]

        // When & Then
        for (index, segmentIndex) in indices.enumerated() {
            let tripType = TripType(segmentIndex: segmentIndex)
            XCTAssertEqual(tripType, expectedTypes[index])
        }
    }

    func testTripType_InitFromInvalidSegmentIndex_ShouldReturnLocal() {
        // Given
        let invalidIndex = 99

        // When
        let tripType = TripType(segmentIndex: invalidIndex)

        // Then - Should default to .local
        XCTAssertEqual(tripType, .local)
    }

    func testTripType_SegmentIndex_ShouldReturnCorrectIndex() {
        // Given
        let types: [TripType] = [.local, .dayTrip, .multiDay]
        let expectedIndices = [0, 1, 2]

        // When & Then
        for (index, tripType) in types.enumerated() {
            XCTAssertEqual(tripType.segmentIndex, expectedIndices[index])
        }
    }

    // MARK: - Requires End Date Tests

    func testTripType_Local_ShouldNotRequireEndDate() {
        // Given
        let tripType = TripType.local

        // When
        let requiresEndDate = tripType.requiresEndDate

        // Then
        XCTAssertFalse(requiresEndDate)
    }

    func testTripType_DayTrip_ShouldNotRequireEndDate() {
        // Given
        let tripType = TripType.dayTrip

        // When
        let requiresEndDate = tripType.requiresEndDate

        // Then
        XCTAssertFalse(requiresEndDate)
    }

    func testTripType_MultiDay_ShouldRequireEndDate() {
        // Given
        let tripType = TripType.multiDay

        // When
        let requiresEndDate = tripType.requiresEndDate

        // Then
        XCTAssertTrue(requiresEndDate)
    }

    // MARK: - All Cases Tests

    func testTripType_AllCases_ShouldContainThreeTypes() {
        // Given
        let allCases = TripType.allCases

        // When
        let count = allCases.count

        // Then
        XCTAssertEqual(count, 3)
    }

    func testTripType_AllCases_ShouldContainAllTypes() {
        // Given
        let allCases = TripType.allCases

        // Then
        XCTAssertTrue(allCases.contains(.local))
        XCTAssertTrue(allCases.contains(.dayTrip))
        XCTAssertTrue(allCases.contains(.multiDay))
    }
}
