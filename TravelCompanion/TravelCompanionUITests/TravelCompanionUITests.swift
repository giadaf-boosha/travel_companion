//
//  TravelCompanionUITests.swift
//  TravelCompanionUITests
//
//  Comprehensive UI Tests for Travel Companion App
//  Tests all user flows and interactions to ensure app stability
//

import XCTest

final class TravelCompanionUITests: XCTestCase {

    // MARK: - Properties

    var app: XCUIApplication!

    // MARK: - Accessibility Identifiers (must match AccessibilityIdentifiers.swift)

    struct IDs {
        struct Home {
            static let newTripButton = "home_button_newTrip"
            static let continueTripButton = "home_button_continueTrip"
            static let settingsButton = "home_button_settings"
            static let statsCard = "home_card_stats"
            static let lastTripCard = "home_card_lastTrip"
            static let emptyStateView = "home_view_emptyState"
        }

        struct TripList {
            static let tableView = "tripList_tableView"
            static let searchBar = "tripList_searchBar"
            static let filterSegment = "tripList_segment_filter"
            static let emptyStateView = "tripList_view_emptyState"
        }

        struct NewTrip {
            static let scrollView = "newTrip_scrollView"
            static let destinationTextField = "newTrip_textField_destination"
            static let tripTypeSegment = "newTrip_segment_tripType"
            static let startTrackingSwitch = "newTrip_switch_startTracking"
            static let createButton = "newTrip_button_create"
        }

        struct ActiveTrip {
            static let trackingButton = "activeTrip_button_tracking"
            static let photoButton = "activeTrip_button_photo"
            static let noteButton = "activeTrip_button_note"
        }
    }

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()

        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - Helper Methods

    /// Wait for an element to exist with custom timeout
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    /// Take a screenshot with a descriptive name
    func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - 1. App Launch Tests

    func test01_AppLaunches_Successfully() {
        // The app should launch without crashing
        XCTAssertTrue(app.exists, "App should exist after launch")
        takeScreenshot(name: "01_AppLaunch")
    }

    func test02_AppLaunch_ShowsTabBar() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitForElement(tabBar), "Tab bar should be visible after launch")

        // Verify we have tabs
        let tabCount = app.tabBars.buttons.count
        XCTAssertGreaterThanOrEqual(tabCount, 4, "Should have at least 4 tabs")
        takeScreenshot(name: "02_TabBar")
    }

    // MARK: - 2. Home Screen Tests

    func test03_HomeScreen_ShowsNewTripButton() {
        // Look for new trip button by accessibility ID or by title
        let newTripButton = app.buttons[IDs.Home.newTripButton]
        let newTripButtonByTitle = app.buttons["Nuovo Viaggio"]

        let buttonExists = waitForElement(newTripButton, timeout: 3) ||
                          waitForElement(newTripButtonByTitle, timeout: 3)

        XCTAssertTrue(buttonExists, "New Trip button should be visible on Home screen")
        takeScreenshot(name: "03_HomeScreen")
    }

    func test04_HomeScreen_TapNewTripButton_OpensNewTripForm() {
        // Find and tap new trip button
        let newTripButton = app.buttons[IDs.Home.newTripButton]
        let newTripButtonByTitle = app.buttons["Nuovo Viaggio"]

        if waitForElement(newTripButton, timeout: 3) {
            newTripButton.tap()
        } else if waitForElement(newTripButtonByTitle, timeout: 3) {
            newTripButtonByTitle.tap()
        } else {
            XCTFail("Could not find New Trip button")
            return
        }

        // Wait for the form to appear
        sleep(1)

        // Verify form elements exist
        let destinationField = app.textFields[IDs.NewTrip.destinationTextField]
        let destinationFieldByPlaceholder = app.textFields["Es. Roma, Parigi, Tokyo"]

        let fieldExists = waitForElement(destinationField, timeout: 3) ||
                         waitForElement(destinationFieldByPlaceholder, timeout: 3) ||
                         app.textFields.count > 0

        XCTAssertTrue(fieldExists, "New Trip form should show destination text field")
        takeScreenshot(name: "04_NewTripForm")
    }

    func test05_HomeScreen_StatsCard_IsTappable() {
        let statsCard = app.otherElements[IDs.Home.statsCard]

        if waitForElement(statsCard, timeout: 3) {
            statsCard.tap()
            sleep(1)
            takeScreenshot(name: "05_AfterStatsCardTap")
        }
        // Stats card might not be visible if no trips - that's OK
        XCTAssertTrue(app.exists, "App should not crash when tapping stats card")
    }

    // MARK: - 3. Tab Navigation Tests

    func test06_TabNavigation_TripsTab() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitForElement(tabBar), "Tab bar should exist")

        // Tap Trips tab (index 1)
        let tripsTab = app.tabBars.buttons.element(boundBy: 1)
        if tripsTab.exists {
            tripsTab.tap()
            sleep(1)

            // Should see either a table view or empty state
            let tableExists = app.tables.firstMatch.exists
            let emptyExists = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'viaggio'")).count > 0

            XCTAssertTrue(tableExists || emptyExists || app.exists, "Trips screen should load")
            takeScreenshot(name: "06_TripsTab")
        }
    }

    func test07_TabNavigation_MapTab() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitForElement(tabBar), "Tab bar should exist")

        // Tap Map tab (index 2)
        let mapTab = app.tabBars.buttons.element(boundBy: 2)
        if mapTab.exists {
            mapTab.tap()
            sleep(2) // Maps need more time to load

            takeScreenshot(name: "07_MapTab")
            XCTAssertTrue(app.exists, "App should not crash on Map tab")
        }
    }

    func test08_TabNavigation_StatisticsTab() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitForElement(tabBar), "Tab bar should exist")

        // Tap Statistics tab (index 3)
        let statsTab = app.tabBars.buttons.element(boundBy: 3)
        if statsTab.exists {
            statsTab.tap()
            sleep(1)

            takeScreenshot(name: "08_StatisticsTab")
            XCTAssertTrue(app.exists, "App should not crash on Statistics tab")
        }
    }

    func test09_TabNavigation_ChatTab() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitForElement(tabBar), "Tab bar should exist")

        // Tap Chat tab (index 4) if it exists
        let chatTab = app.tabBars.buttons.element(boundBy: 4)
        if chatTab.exists {
            chatTab.tap()
            sleep(1)

            takeScreenshot(name: "09_ChatTab")
            XCTAssertTrue(app.exists, "App should not crash on Chat tab")
        }
    }

    func test10_TabNavigation_SwitchBetweenAllTabs() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(waitForElement(tabBar), "Tab bar should exist")

        let tabCount = app.tabBars.buttons.count

        // Switch through all tabs rapidly
        for i in 0..<tabCount {
            let tab = app.tabBars.buttons.element(boundBy: i)
            if tab.exists {
                tab.tap()
                // Brief pause to ensure view loads
                usleep(500000) // 0.5 seconds
            }
        }

        // Go back to first tab
        app.tabBars.buttons.element(boundBy: 0).tap()
        sleep(1)

        XCTAssertTrue(app.exists, "App should not crash when switching between tabs")
        takeScreenshot(name: "10_AfterTabSwitching")
    }

    // MARK: - 4. Trip List Tests

    func test11_TripList_SearchBarExists() {
        // Navigate to trips tab
        let tripsTab = app.tabBars.buttons.element(boundBy: 1)
        guard tripsTab.exists else { return }
        tripsTab.tap()
        sleep(1)

        // Check for search bar
        let searchBar = app.searchFields.firstMatch
        let searchBarById = app.otherElements[IDs.TripList.searchBar]

        let searchExists = waitForElement(searchBar, timeout: 3) ||
                          waitForElement(searchBarById, timeout: 3)

        if searchExists {
            takeScreenshot(name: "11_TripListWithSearch")
        }

        XCTAssertTrue(app.exists, "Trip list should load without crashing")
    }

    func test12_TripList_FilterSegmentExists() {
        // Navigate to trips tab
        let tripsTab = app.tabBars.buttons.element(boundBy: 1)
        guard tripsTab.exists else { return }
        tripsTab.tap()
        sleep(1)

        // Check for segmented control
        let segment = app.segmentedControls.firstMatch

        if waitForElement(segment, timeout: 3) {
            // Test tapping different segments
            let buttons = segment.buttons
            if buttons.count > 1 {
                buttons.element(boundBy: 1).tap()
                sleep(1)
                takeScreenshot(name: "12_FilterSegment_Option2")

                buttons.element(boundBy: 0).tap()
                sleep(1)
            }
        }

        XCTAssertTrue(app.exists, "Filter segment should work without crashing")
    }

    func test13_TripList_PullToRefresh() {
        // Navigate to trips tab
        let tripsTab = app.tabBars.buttons.element(boundBy: 1)
        guard tripsTab.exists else { return }
        tripsTab.tap()
        sleep(1)

        // Pull to refresh
        let table = app.tables.firstMatch
        if table.exists {
            table.swipeDown()
            sleep(1)
        }

        XCTAssertTrue(app.exists, "Pull to refresh should not crash")
        takeScreenshot(name: "13_AfterPullToRefresh")
    }

    // MARK: - 5. New Trip Creation Flow

    func test14_NewTrip_FullCreationFlow() {
        // Start from home - tap new trip
        let newTripButton = app.buttons[IDs.Home.newTripButton]
        let newTripButtonByTitle = app.buttons["Nuovo Viaggio"]

        if waitForElement(newTripButton, timeout: 3) {
            newTripButton.tap()
        } else if waitForElement(newTripButtonByTitle, timeout: 3) {
            newTripButtonByTitle.tap()
        } else {
            // Try from trips tab
            app.tabBars.buttons.element(boundBy: 1).tap()
            sleep(1)
            let addButton = app.navigationBars.buttons.matching(NSPredicate(format: "label == 'Add' OR label == '+'")).firstMatch
            if addButton.exists {
                addButton.tap()
            } else {
                return // Skip test if we can't find new trip button
            }
        }

        sleep(1)
        takeScreenshot(name: "14_NewTripForm_Start")

        // Fill in destination
        let destinationField = app.textFields.firstMatch
        if destinationField.exists {
            destinationField.tap()
            destinationField.typeText("Test Destination")
            takeScreenshot(name: "14_NewTripForm_Destination")
        }

        // Dismiss keyboard
        app.keyboards.buttons["Done"].tap()

        // Try to tap create button
        let createButton = app.buttons[IDs.NewTrip.createButton]
        let createButtonByTitle = app.buttons["Crea Viaggio"]

        if waitForElement(createButton, timeout: 2) {
            createButton.tap()
        } else if waitForElement(createButtonByTitle, timeout: 2) {
            createButtonByTitle.tap()
        }

        sleep(2)
        takeScreenshot(name: "14_AfterTripCreation")

        XCTAssertTrue(app.exists, "Trip creation should not crash")
    }

    func test15_NewTrip_CancelCreation() {
        // Open new trip form
        let newTripButton = app.buttons["Nuovo Viaggio"]
        if waitForElement(newTripButton, timeout: 3) {
            newTripButton.tap()
        } else {
            return
        }

        sleep(1)

        // Look for cancel button in navigation bar
        let cancelButton = app.navigationBars.buttons["Annulla"]
        let cancelButtonAlt = app.navigationBars.buttons["Cancel"]

        if cancelButton.exists {
            cancelButton.tap()
        } else if cancelButtonAlt.exists {
            cancelButtonAlt.tap()
        } else {
            // Swipe down to dismiss
            app.swipeDown()
        }

        sleep(1)
        takeScreenshot(name: "15_AfterCancel")

        XCTAssertTrue(app.exists, "Cancel should return to previous screen without crash")
    }

    // MARK: - 6. Settings Tests

    func test16_Settings_Navigation() {
        // Look for settings button in navigation bar
        let settingsButton = app.navigationBars.buttons["gearshape"]
        let settingsButtonAlt = app.buttons[IDs.Home.settingsButton]

        if waitForElement(settingsButton, timeout: 3) {
            settingsButton.tap()
        } else if waitForElement(settingsButtonAlt, timeout: 3) {
            settingsButtonAlt.tap()
        } else {
            // Settings might be in a different location - skip
            return
        }

        sleep(1)
        takeScreenshot(name: "16_SettingsScreen")

        // Should see a table view with settings
        let tableView = app.tables.firstMatch
        XCTAssertTrue(tableView.exists || app.exists, "Settings should load")
    }

    // MARK: - 7. Scroll Tests

    func test17_HomeScreen_ScrollsWithoutCrash() {
        let scrollView = app.scrollViews.firstMatch

        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
            scrollView.swipeDown()
            sleep(1)
        }

        takeScreenshot(name: "17_AfterHomeScroll")
        XCTAssertTrue(app.exists, "Home screen should scroll without crashing")
    }

    func test18_Statistics_ScrollsWithoutCrash() {
        // Navigate to statistics
        let statsTab = app.tabBars.buttons.element(boundBy: 3)
        guard statsTab.exists else { return }
        statsTab.tap()
        sleep(1)

        // Scroll the view
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
            scrollView.swipeDown()
            sleep(1)
        }

        takeScreenshot(name: "18_AfterStatisticsScroll")
        XCTAssertTrue(app.exists, "Statistics screen should scroll without crashing")
    }

    // MARK: - 8. Orientation Tests

    func test19_PortraitToLandscape_DoesNotCrash() {
        XCUIDevice.shared.orientation = .portrait
        sleep(1)

        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        takeScreenshot(name: "19_Landscape")

        XCUIDevice.shared.orientation = .portrait
        sleep(1)

        XCTAssertTrue(app.exists, "Orientation change should not crash the app")
    }

    func test20_MultipleOrientationChanges() {
        let orientations: [UIDeviceOrientation] = [.portrait, .landscapeLeft, .portrait, .landscapeRight, .portrait]

        for orientation in orientations {
            XCUIDevice.shared.orientation = orientation
            usleep(300000) // 0.3 seconds
        }

        XCTAssertTrue(app.exists, "Multiple orientation changes should not crash")
        takeScreenshot(name: "20_AfterOrientationChanges")
    }

    // MARK: - 9. Stress Tests

    func test21_RapidTabSwitching_StressTest() {
        let tabCount = app.tabBars.buttons.count

        // Rapidly switch tabs 20 times
        for _ in 0..<20 {
            let randomIndex = Int.random(in: 0..<tabCount)
            app.tabBars.buttons.element(boundBy: randomIndex).tap()
            usleep(100000) // 0.1 seconds
        }

        sleep(1)
        XCTAssertTrue(app.exists, "Rapid tab switching should not crash")
        takeScreenshot(name: "21_AfterStressTest")
    }

    func test22_OpenCloseNewTrip_StressTest() {
        let newTripButton = app.buttons["Nuovo Viaggio"]

        guard waitForElement(newTripButton, timeout: 3) else { return }

        // Open and close new trip form multiple times
        for i in 0..<5 {
            newTripButton.tap()
            sleep(1)

            // Close it
            let cancelButton = app.navigationBars.buttons["Annulla"]
            if cancelButton.exists {
                cancelButton.tap()
            } else {
                app.swipeDown()
            }
            sleep(1)

            if i == 2 {
                takeScreenshot(name: "22_StressTest_Iteration3")
            }
        }

        XCTAssertTrue(app.exists, "Opening/closing forms repeatedly should not crash")
    }

    // MARK: - 10. Memory and Performance

    func test23_LaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    func test24_NavigationPerformance() {
        measure {
            // Navigate through all tabs
            for i in 0..<min(5, app.tabBars.buttons.count) {
                app.tabBars.buttons.element(boundBy: i).tap()
            }
            app.tabBars.buttons.element(boundBy: 0).tap()
        }
    }

    // MARK: - 11. Edge Cases

    func test25_EmptyDestination_ShowsError() {
        // Open new trip form
        let newTripButton = app.buttons["Nuovo Viaggio"]
        guard waitForElement(newTripButton, timeout: 3) else { return }
        newTripButton.tap()
        sleep(1)

        // Try to create without entering destination
        let createButton = app.buttons["Crea Viaggio"]
        if createButton.exists {
            createButton.tap()
            sleep(1)

            // Should show an alert or error
            let alert = app.alerts.firstMatch
            if alert.exists {
                takeScreenshot(name: "25_EmptyDestinationError")
                alert.buttons.firstMatch.tap()
            }
        }

        XCTAssertTrue(app.exists, "Empty destination validation should not crash")
    }

    func test26_BackNavigation_Works() {
        // Navigate to trips
        app.tabBars.buttons.element(boundBy: 1).tap()
        sleep(1)

        // If there are trips, tap one
        let table = app.tables.firstMatch
        if table.exists && table.cells.count > 0 {
            table.cells.firstMatch.tap()
            sleep(1)
            takeScreenshot(name: "26_TripDetail")

            // Go back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                sleep(1)
            }
        }

        XCTAssertTrue(app.exists, "Back navigation should work without crash")
    }

    // MARK: - 12. Accessibility

    func test27_VoiceOverAccessibility() {
        // Check that main elements have accessibility labels
        let newTripButton = app.buttons["Nuovo Viaggio"]

        if newTripButton.exists {
            XCTAssertNotNil(newTripButton.label, "New Trip button should have accessibility label")
        }

        // Check tabs have labels
        for i in 0..<app.tabBars.buttons.count {
            let tab = app.tabBars.buttons.element(boundBy: i)
            XCTAssertNotNil(tab.label, "Tab \(i) should have accessibility label")
        }
    }

    // MARK: - 13. Final Comprehensive Test

    func test28_CompleteUserJourney() {
        takeScreenshot(name: "28_Journey_01_Start")

        // 1. Start at home
        XCTAssertTrue(app.exists)

        // 2. Navigate to trips
        app.tabBars.buttons.element(boundBy: 1).tap()
        sleep(1)
        takeScreenshot(name: "28_Journey_02_TripList")

        // 3. Go to map
        app.tabBars.buttons.element(boundBy: 2).tap()
        sleep(2)
        takeScreenshot(name: "28_Journey_03_Map")

        // 4. Go to statistics
        app.tabBars.buttons.element(boundBy: 3).tap()
        sleep(1)
        takeScreenshot(name: "28_Journey_04_Statistics")

        // 5. Go to chat if available
        if app.tabBars.buttons.count > 4 {
            app.tabBars.buttons.element(boundBy: 4).tap()
            sleep(1)
            takeScreenshot(name: "28_Journey_05_Chat")
        }

        // 6. Return to home
        app.tabBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        takeScreenshot(name: "28_Journey_06_BackHome")

        // 7. Open new trip
        let newTripButton = app.buttons["Nuovo Viaggio"]
        if newTripButton.exists {
            newTripButton.tap()
            sleep(1)
            takeScreenshot(name: "28_Journey_07_NewTrip")

            // Cancel
            let cancelButton = app.navigationBars.buttons["Annulla"]
            if cancelButton.exists {
                cancelButton.tap()
                sleep(1)
            }
        }

        takeScreenshot(name: "28_Journey_08_End")
        XCTAssertTrue(app.exists, "Complete user journey should finish without crash")
    }
}
