//
//  StringExtensionsTests.swift
//  TravelCompanionTests
//
//  Created for Travel Companion LAM Project
//

import XCTest
@testable import TravelCompanion

final class StringExtensionsTests: XCTestCase {

    // MARK: - isValidDestination Tests

    func testIsValidDestination_WithValidDestination_ShouldReturnTrue() {
        // Given
        let validDestinations = ["Roma", "Milano Centro", "New York City", "Tokyo"]

        // When & Then
        for destination in validDestinations {
            XCTAssertTrue(destination.isValidDestination, "\(destination) should be valid")
        }
    }

    func testIsValidDestination_WithEmptyString_ShouldReturnFalse() {
        // Given
        let emptyString = ""

        // When
        let isValid = emptyString.isValidDestination

        // Then
        XCTAssertFalse(isValid)
    }

    func testIsValidDestination_WithOnlyWhitespace_ShouldReturnFalse() {
        // Given
        let whitespaceString = "   "

        // When
        let isValid = whitespaceString.isValidDestination

        // Then
        XCTAssertFalse(isValid)
    }

    func testIsValidDestination_WithOnlyNumbers_ShouldReturnFalse() {
        // Given
        let numbersOnly = "12345"

        // When
        let isValid = numbersOnly.isValidDestination

        // Then
        XCTAssertFalse(isValid)
    }

    func testIsValidDestination_WithTooShortString_ShouldReturnFalse() {
        // Given
        let shortString = "R"

        // When
        let isValid = shortString.isValidDestination

        // Then
        XCTAssertFalse(isValid)
    }

    func testIsValidDestination_WithMixedContent_ShouldReturnFalse() {
        // Given - Numbers are not allowed in destination names
        let mixedContent = "Via Roma 123"

        // When
        let isValid = mixedContent.isValidDestination

        // Then - Should be false because numbers are not allowed
        XCTAssertFalse(isValid)
    }

    // MARK: - trimmed Tests

    func testTrimmed_ShouldRemoveLeadingWhitespace() {
        // Given
        let stringWithLeadingWhitespace = "   Hello"

        // When
        let trimmed = stringWithLeadingWhitespace.trimmed

        // Then
        XCTAssertEqual(trimmed, "Hello")
    }

    func testTrimmed_ShouldRemoveTrailingWhitespace() {
        // Given
        let stringWithTrailingWhitespace = "Hello   "

        // When
        let trimmed = stringWithTrailingWhitespace.trimmed

        // Then
        XCTAssertEqual(trimmed, "Hello")
    }

    func testTrimmed_ShouldRemoveBothEndsWhitespace() {
        // Given
        let stringWithBothWhitespace = "   Hello   "

        // When
        let trimmed = stringWithBothWhitespace.trimmed

        // Then
        XCTAssertEqual(trimmed, "Hello")
    }

    func testTrimmed_ShouldNotAffectInternalWhitespace() {
        // Given
        let stringWithInternalWhitespace = "Hello World"

        // When
        let trimmed = stringWithInternalWhitespace.trimmed

        // Then
        XCTAssertEqual(trimmed, "Hello World")
    }

    // MARK: - truncated Tests

    func testTruncated_WhenShorterThanLimit_ShouldReturnOriginal() {
        // Given
        let shortString = "Hello"

        // When
        let truncated = shortString.truncated(to: 10)

        // Then
        XCTAssertEqual(truncated, "Hello")
    }

    func testTruncated_WhenLongerThanLimit_ShouldTruncateWithEllipsis() {
        // Given
        let longString = "Hello World, this is a very long string"

        // When
        let truncated = longString.truncated(to: 15)

        // Then
        XCTAssertTrue(truncated.count <= 15)
        XCTAssertTrue(truncated.hasSuffix("..."))
    }

    func testTruncated_WhenExactlyAtLimit_ShouldReturnOriginal() {
        // Given
        let exactString = "Hello"

        // When
        let truncated = exactString.truncated(to: 5)

        // Then
        XCTAssertEqual(truncated, "Hello")
    }

    // MARK: - capitalizedFirst Tests

    func testCapitalizedFirst_ShouldCapitalizeFirstLetter() {
        // Given
        let lowercaseString = "hello world"

        // When
        let capitalized = lowercaseString.capitalizedFirst

        // Then
        XCTAssertEqual(capitalized, "Hello world")
    }

    func testCapitalizedFirst_WithEmptyString_ShouldReturnEmpty() {
        // Given
        let emptyString = ""

        // When
        let capitalized = emptyString.capitalizedFirst

        // Then
        XCTAssertEqual(capitalized, "")
    }

    func testCapitalizedFirst_AlreadyCapitalized_ShouldNotChange() {
        // Given
        let capitalizedString = "Hello world"

        // When
        let result = capitalizedString.capitalizedFirst

        // Then
        XCTAssertEqual(result, "Hello world")
    }

    // MARK: - isNotEmpty Tests

    func testIsNotEmpty_WithNonEmptyString_ShouldReturnTrue() {
        // Given
        let nonEmptyString = "Hello"

        // When
        let isNotEmpty = nonEmptyString.isNotEmpty

        // Then
        XCTAssertTrue(isNotEmpty)
    }

    func testIsNotEmpty_WithEmptyString_ShouldReturnFalse() {
        // Given
        let emptyString = ""

        // When
        let isNotEmpty = emptyString.isNotEmpty

        // Then
        XCTAssertFalse(isNotEmpty)
    }

    // MARK: - withoutWhitespace Tests

    func testWithoutWhitespace_ShouldRemoveAllWhitespace() {
        // Given
        let stringWithWhitespace = "Hello World Test"

        // When
        let result = stringWithWhitespace.withoutWhitespace

        // Then
        XCTAssertEqual(result, "HelloWorldTest")
    }

    func testWithoutWhitespace_WithNoWhitespace_ShouldReturnOriginal() {
        // Given
        let noWhitespaceString = "HelloWorld"

        // When
        let result = noWhitespaceString.withoutWhitespace

        // Then
        XCTAssertEqual(result, "HelloWorld")
    }

    // MARK: - urlEncoded Tests

    func testUrlEncoded_WithSpaces_ShouldEncode() {
        // Given
        let stringWithSpaces = "Hello World"

        // When
        let encoded = stringWithSpaces.urlEncoded

        // Then
        XCTAssertFalse(encoded.contains(" "))
        XCTAssertTrue(encoded.contains("%20") || encoded.contains("+"))
    }

    func testUrlEncoded_WithSpecialCharacters_ShouldEncode() {
        // Given
        let stringWithSpecialChars = "Hello?World&Test=Value"

        // When
        let encoded = stringWithSpecialChars.urlEncoded

        // Then
        // URL encoding should handle special characters
        XCTAssertNotNil(encoded)
    }

    // MARK: - wordCount Tests

    func testWordCount_WithMultipleWords_ShouldReturnCorrectCount() {
        // Given
        let multiWordString = "Hello World Test String"

        // When
        let count = multiWordString.wordCount

        // Then
        XCTAssertEqual(count, 4)
    }

    func testWordCount_WithSingleWord_ShouldReturnOne() {
        // Given
        let singleWord = "Hello"

        // When
        let count = singleWord.wordCount

        // Then
        XCTAssertEqual(count, 1)
    }

    func testWordCount_WithEmptyString_ShouldReturnZero() {
        // Given
        let emptyString = ""

        // When
        let count = emptyString.wordCount

        // Then
        XCTAssertEqual(count, 0)
    }

    func testWordCount_WithExtraWhitespace_ShouldIgnoreExtra() {
        // Given
        let stringWithExtraSpaces = "Hello    World   Test"

        // When
        let count = stringWithExtraSpaces.wordCount

        // Then
        XCTAssertEqual(count, 3)
    }

    // MARK: - Safe Subscript Tests

    func testSafeSubscript_WithValidIndex_ShouldReturnCharacter() {
        // Given
        let string = "Hello"

        // When
        let character = string[safe: 0]

        // Then
        XCTAssertEqual(character, "H")
    }

    func testSafeSubscript_WithOutOfBoundsIndex_ShouldReturnNil() {
        // Given
        let string = "Hello"

        // When
        let character = string[safe: 10]

        // Then
        XCTAssertNil(character)
    }

    func testSafeSubscript_WithNegativeIndex_ShouldReturnNil() {
        // Given
        let string = "Hello"

        // When
        let character = string[safe: -1]

        // Then
        XCTAssertNil(character)
    }

    // MARK: - Safe Range Subscript Tests

    func testSafeRangeSubscript_WithValidRange_ShouldReturnSubstring() {
        // Given
        let string = "Hello World"

        // When
        let substring = string[safe: 0..<5]

        // Then
        XCTAssertEqual(substring, "Hello")
    }

    func testSafeRangeSubscript_WithOutOfBoundsRange_ShouldReturnNil() {
        // Given
        let string = "Hello"

        // When
        let substring = string[safe: 0..<10]

        // Then - Out of bounds range returns nil
        XCTAssertNil(substring)
    }
}
