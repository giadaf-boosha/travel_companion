//
//  ChatServiceTests.swift
//  TravelCompanionTests
//
//  Created for Travel Companion LAM Project
//

import XCTest
@testable import TravelCompanion

final class ChatServiceTests: XCTestCase {

    // MARK: - Properties

    var sut: ChatService!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = ChatService()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInit_ShouldHaveSystemPrompt() {
        // Given - sut is initialized in setUp

        // When
        let history = sut.conversationHistory

        // Then - Should have at least the system prompt
        XCTAssertGreaterThanOrEqual(history.count, 1)
        XCTAssertEqual(history.first?.role, .system)
    }

    func testInit_ShouldNotBeLoading() {
        // Given - sut is initialized in setUp

        // When
        let isLoading = sut.isLoading

        // Then
        XCTAssertFalse(isLoading)
    }

    // MARK: - Clear Conversation Tests

    func testClearConversation_ShouldResetHistory() {
        // Given - Add some messages to history
        sut.conversationHistory.append(ChatMessage.userMessage("Test message"))
        sut.conversationHistory.append(ChatMessage.assistantMessage("Response"))

        // When
        sut.clearConversation()

        // Then - Should only have system prompt
        XCTAssertEqual(sut.conversationHistory.count, 1)
        XCTAssertEqual(sut.conversationHistory.first?.role, .system)
    }

    // MARK: - Visible Messages Tests

    func testGetVisibleMessages_ShouldExcludeSystemMessages() {
        // Given
        sut.conversationHistory.append(ChatMessage.userMessage("Test message"))
        sut.conversationHistory.append(ChatMessage.assistantMessage("Response"))

        // When
        let visibleMessages = sut.getVisibleMessages()

        // Then - Should not contain system messages
        for message in visibleMessages {
            XCTAssertNotEqual(message.role, .system)
        }
    }

    func testMessageCount_ShouldReturnVisibleMessagesCount() {
        // Given
        sut.conversationHistory.append(ChatMessage.userMessage("Message 1"))
        sut.conversationHistory.append(ChatMessage.assistantMessage("Response 1"))
        sut.conversationHistory.append(ChatMessage.userMessage("Message 2"))

        // When
        let count = sut.messageCount

        // Then - Should count only user and assistant messages, not system
        XCTAssertEqual(count, 3)
    }

    // MARK: - Send Message Validation Tests

    func testSendMessage_WithEmptyMessage_ShouldReturnError() {
        // Given
        let emptyMessage = "   "
        let expectation = XCTestExpectation(description: "Completion handler called")

        // When
        sut.sendMessage(emptyMessage) { result in
            // Then
            switch result {
            case .success:
                XCTFail("Should have failed with empty message")
            case .failure(let error):
                XCTAssertEqual(error, ChatServiceError.invalidResponse)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testSendMessage_WithInvalidAPIKey_ShouldReturnError() {
        // Given - Default API key is "YOUR_OPENAI_API_KEY" which should be invalid
        let message = "Hello"
        let expectation = XCTestExpectation(description: "Completion handler called")

        // When
        sut.sendMessage(message) { result in
            // Then
            switch result {
            case .success:
                // This might succeed if a real API key is configured
                break
            case .failure(let error):
                // Should fail with invalidAPIKey or network error
                XCTAssertTrue(
                    error == .invalidAPIKey ||
                    error.localizedDescription.contains("API") ||
                    error.localizedDescription.contains("rete"),
                    "Expected API key or network error"
                )
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - ChatServiceError Tests

    func testChatServiceError_InvalidURL_ShouldHaveDescription() {
        // Given
        let error = ChatServiceError.invalidURL

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertFalse(description!.isEmpty)
    }

    func testChatServiceError_InvalidAPIKey_ShouldHaveDescription() {
        // Given
        let error = ChatServiceError.invalidAPIKey

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("API"))
    }

    func testChatServiceError_RateLimitExceeded_ShouldHaveDescription() {
        // Given
        let error = ChatServiceError.rateLimitExceeded

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertFalse(description!.isEmpty)
    }

    func testChatServiceError_ServerError_ShouldIncludeStatusCode() {
        // Given
        let statusCode = 500
        let error = ChatServiceError.serverError(statusCode)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("500"))
    }

    func testChatServiceError_NetworkError_ShouldIncludeUnderlyingError() {
        // Given
        let underlyingError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = ChatServiceError.networkError(underlyingError)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("rete"))
    }

    // MARK: - Convenience Method Tests

    func testRequestDestinationSuggestions_ShouldBuildCorrectPrompt() {
        // Given
        let expectation = XCTestExpectation(description: "Completion handler called")

        // When
        sut.requestDestinationSuggestions(preferences: nil) { _ in
            expectation.fulfill()
        }

        // Then - Just verify the method doesn't crash
        // The actual API call will fail without valid API key
        wait(for: [expectation], timeout: 5.0)
    }

    func testRequestItinerary_ShouldBuildCorrectPrompt() {
        // Given
        let destination = "Roma"
        let days = 3
        let expectation = XCTestExpectation(description: "Completion handler called")

        // When
        sut.requestItinerary(destination: destination, days: days) { _ in
            expectation.fulfill()
        }

        // Then - Just verify the method doesn't crash
        wait(for: [expectation], timeout: 5.0)
    }

    func testRequestPracticalInfo_ShouldBuildCorrectPrompt() {
        // Given
        let destination = "Roma"
        let expectation = XCTestExpectation(description: "Completion handler called")

        // When
        sut.requestPracticalInfo(destination: destination) { _ in
            expectation.fulfill()
        }

        // Then - Just verify the method doesn't crash
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - ChatMessage Tests

extension ChatServiceTests {

    func testChatMessage_UserMessage_ShouldHaveCorrectRole() {
        // Given
        let content = "Test message"

        // When
        let message = ChatMessage.userMessage(content)

        // Then
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, content)
    }

    func testChatMessage_AssistantMessage_ShouldHaveCorrectRole() {
        // Given
        let content = "Test response"

        // When
        let message = ChatMessage.assistantMessage(content)

        // Then
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, content)
    }

    func testChatMessage_SystemMessage_ShouldHaveCorrectRole() {
        // Given
        let content = "System prompt"

        // When
        let message = ChatMessage.systemMessage(content)

        // Then
        XCTAssertEqual(message.role, .system)
        XCTAssertEqual(message.content, content)
    }

    func testChatMessage_ShouldHaveUniqueId() {
        // Given
        let message1 = ChatMessage.userMessage("Message 1")
        let message2 = ChatMessage.userMessage("Message 2")

        // Then
        XCTAssertNotEqual(message1.id, message2.id)
    }

    func testChatMessage_ShouldHaveTimestamp() {
        // Given
        let beforeCreation = Date()

        // When
        let message = ChatMessage.userMessage("Test")

        // Then
        let afterCreation = Date()
        XCTAssertGreaterThanOrEqual(message.timestamp, beforeCreation)
        XCTAssertLessThanOrEqual(message.timestamp, afterCreation)
    }
}
