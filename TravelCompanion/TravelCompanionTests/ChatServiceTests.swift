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

    var chatService: ChatService!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        chatService = ChatService()
    }

    override func tearDownWithError() throws {
        chatService = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testChatService_Init_ShouldHaveSystemPrompt() {
        // Given
        let service = ChatService()

        // When
        let history = service.conversationHistory

        // Then - Should have at least the system prompt
        XCTAssertFalse(history.isEmpty)
        XCTAssertEqual(history.first?.role, .system)
    }

    func testChatService_Init_IsLoadingShouldBeFalse() {
        // Given & When
        let service = ChatService()

        // Then
        XCTAssertFalse(service.isLoading)
    }

    // MARK: - Clear Conversation Tests

    func testChatService_ClearConversation_ShouldResetHistory() {
        // Given
        let service = ChatService()
        let initialCount = service.conversationHistory.count

        // When
        service.clearConversation()

        // Then - Should still have system prompt
        XCTAssertEqual(service.conversationHistory.count, initialCount)
    }

    // MARK: - Visible Messages Tests

    func testChatService_GetVisibleMessages_ShouldExcludeSystemMessages() {
        // Given
        let service = ChatService()

        // When
        let visibleMessages = service.getVisibleMessages()

        // Then - System messages should not be visible
        XCTAssertTrue(visibleMessages.allSatisfy { $0.role != .system })
    }

    func testChatService_MessageCount_ShouldReturnVisibleCount() {
        // Given
        let service = ChatService()

        // When
        let count = service.messageCount

        // Then - Initially should be 0 (no user/assistant messages)
        XCTAssertEqual(count, 0)
    }

    // MARK: - Send Message Validation Tests

    func testChatService_SendEmptyMessage_ShouldReturnError() {
        // Given
        let service = ChatService()
        let expectation = XCTestExpectation(description: "Empty message should fail")

        // When
        service.sendMessage("   ") { result in
            // Then
            switch result {
            case .success:
                XCTFail("Should not succeed with empty message")
            case .failure(let error):
                // Should return an error
                XCTAssertNotNil(error)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - ChatMessage Tests

    func testChatMessage_UserMessage_ShouldHaveCorrectRole() {
        // Given & When
        let message = ChatMessage.userMessage("Hello")

        // Then
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Hello")
    }

    func testChatMessage_AssistantMessage_ShouldHaveCorrectRole() {
        // Given & When
        let message = ChatMessage.assistantMessage("Hi there!")

        // Then
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Hi there!")
    }

    func testChatMessage_SystemMessage_ShouldHaveCorrectRole() {
        // Given & When
        let message = ChatMessage.systemMessage("System prompt")

        // Then
        XCTAssertEqual(message.role, .system)
        XCTAssertEqual(message.content, "System prompt")
    }

    func testChatMessage_ShouldHaveTimestamp() {
        // Given & When
        let beforeCreation = Date()
        let message = ChatMessage.userMessage("Test")
        let afterCreation = Date()

        // Then
        XCTAssertGreaterThanOrEqual(message.timestamp, beforeCreation)
        XCTAssertLessThanOrEqual(message.timestamp, afterCreation)
    }

    func testChatMessage_ShouldHaveUniqueId() {
        // Given & When
        let message1 = ChatMessage.userMessage("Test 1")
        let message2 = ChatMessage.userMessage("Test 2")

        // Then
        XCTAssertNotEqual(message1.id, message2.id)
    }

    // MARK: - ChatMessage.Role Tests

    func testChatMessageRole_User_ShouldHaveCorrectRawValue() {
        XCTAssertEqual(ChatMessage.Role.user.rawValue, "user")
    }

    func testChatMessageRole_Assistant_ShouldHaveCorrectRawValue() {
        XCTAssertEqual(ChatMessage.Role.assistant.rawValue, "assistant")
    }

    func testChatMessageRole_System_ShouldHaveCorrectRawValue() {
        XCTAssertEqual(ChatMessage.Role.system.rawValue, "system")
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
        XCTAssertFalse(description!.isEmpty)
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
        XCTAssertTrue(description!.contains("\(statusCode)"))
    }
}
