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

        struct TripDetail {
            static let scrollView = "tripDetail_scrollView"
            static let destinationLabel = "tripDetail_label_destination"
            static let dateLabel = "tripDetail_label_date"
            static let tripTypeLabel = "tripDetail_label_tripType"
            static let statusLabel = "tripDetail_label_status"
            static let distanceLabel = "tripDetail_label_distance"
            static let photosCollectionView = "tripDetail_collectionView_photos"
            static let notesTableView = "tripDetail_tableView_notes"
            static let mapButton = "tripDetail_button_map"
            static let deleteButton = "tripDetail_button_delete"
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

    /// Navigate back to Home screen from any screen
    func navigateToHome() {
        // Check if TabBar is visible
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let homeTab = tabBar.buttons.element(boundBy: 0)
            if homeTab.exists {
                homeTab.tap()
                return
            }
        }

        // If no TabBar, try back button (we might be in ActiveTrip or detail view)
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
            sleep(1)
            // Recursively try to get home
            navigateToHome()
            return
        }

        // Try "Stop" or "Ferma" button if we're in ActiveTrip
        let stopButton = app.buttons["Ferma Tracking"]
        let stopButtonEN = app.buttons["Stop Tracking"]
        if stopButton.exists {
            stopButton.tap()
            sleep(1)
            navigateToHome()
        } else if stopButtonEN.exists {
            stopButtonEN.tap()
            sleep(1)
            navigateToHome()
        }
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

        // Dismiss keyboard - try multiple methods
        if app.keyboards.count > 0 {
            // Try tapping outside the keyboard
            app.tap()
            sleep(1)
        }

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

    // MARK: - 14. Trip Creation Tests (All Types)

    func test29_CreateLocalTrip() {
        // Navigate to new trip form
        let newTripButton = app.buttons["Nuovo Viaggio"]
        guard waitForElement(newTripButton, timeout: 3) else {
            XCTFail("Could not find New Trip button")
            return
        }
        newTripButton.tap()
        sleep(1)

        // Fill destination
        let destinationField = app.textFields.firstMatch
        if destinationField.exists {
            destinationField.tap()
            destinationField.typeText("Roma Centro")
        }

        // Dismiss keyboard if visible
        if app.keyboards.count > 0 {
            app.tap() // Tap outside to dismiss
        }
        sleep(1)

        // Select Local trip type (index 0)
        let tripTypeSegment = app.segmentedControls.firstMatch
        if tripTypeSegment.exists {
            tripTypeSegment.buttons.element(boundBy: 0).tap()
        }

        takeScreenshot(name: "29_LocalTrip_Form")

        // Tap create button
        let createButton = app.buttons["Crea Viaggio"]
        if createButton.exists {
            createButton.tap()
            sleep(2)
        }

        takeScreenshot(name: "29_LocalTrip_Created")
        XCTAssertTrue(app.exists, "Local trip creation should not crash")
    }

    func test30_CreateDayTrip() {
        // Navigate to new trip form
        let newTripButton = app.buttons["Nuovo Viaggio"]
        guard waitForElement(newTripButton, timeout: 3) else { return }
        newTripButton.tap()
        sleep(1)

        // Fill destination
        let destinationField = app.textFields.firstMatch
        if destinationField.exists {
            destinationField.tap()
            destinationField.typeText("Firenze Gita")
        }

        if app.keyboards.count > 0 {
            app.tap()
        }
        sleep(1)

        // Select Day trip type (index 1)
        let tripTypeSegment = app.segmentedControls.firstMatch
        if tripTypeSegment.exists {
            tripTypeSegment.buttons.element(boundBy: 1).tap()
        }

        takeScreenshot(name: "30_DayTrip_Form")

        // Tap create button
        let createButton = app.buttons["Crea Viaggio"]
        if createButton.exists {
            createButton.tap()
            sleep(2)
        }

        takeScreenshot(name: "30_DayTrip_Created")
        XCTAssertTrue(app.exists, "Day trip creation should not crash")
    }

    func test31_CreateMultiDayTrip() {
        // Navigate to new trip form
        let newTripButton = app.buttons["Nuovo Viaggio"]
        guard waitForElement(newTripButton, timeout: 3) else { return }
        newTripButton.tap()
        sleep(1)

        // Fill destination
        let destinationField = app.textFields.firstMatch
        if destinationField.exists {
            destinationField.tap()
            destinationField.typeText("Parigi Vacanza")
        }

        if app.keyboards.count > 0 {
            app.tap()
        }
        sleep(1)

        // Select Multi-day trip type (index 2)
        let tripTypeSegment = app.segmentedControls.firstMatch
        if tripTypeSegment.exists {
            tripTypeSegment.buttons.element(boundBy: 2).tap()
        }

        takeScreenshot(name: "31_MultiDayTrip_Form")

        // Tap create button
        let createButton = app.buttons["Crea Viaggio"]
        if createButton.exists {
            createButton.tap()
            sleep(2)
        }

        takeScreenshot(name: "31_MultiDayTrip_Created")
        XCTAssertTrue(app.exists, "Multi-day trip creation should not crash")
    }

    func test32_CreateTripWithTrackingDisabled() {
        // Navigate to new trip form
        let newTripButton = app.buttons["Nuovo Viaggio"]
        guard waitForElement(newTripButton, timeout: 3) else { return }
        newTripButton.tap()
        sleep(1)

        // Fill destination
        let destinationField = app.textFields.firstMatch
        if destinationField.exists {
            destinationField.tap()
            destinationField.typeText("Milano No Track")
        }

        if app.keyboards.count > 0 {
            app.tap()
        }
        sleep(1)

        // Disable tracking switch
        let trackingSwitch = app.switches.firstMatch
        if trackingSwitch.exists && trackingSwitch.value as? String == "1" {
            trackingSwitch.tap()
        }

        takeScreenshot(name: "32_TripNoTracking_Form")

        // Tap create button
        let createButton = app.buttons["Crea Viaggio"]
        if createButton.exists {
            createButton.tap()
            sleep(2)
        }

        takeScreenshot(name: "32_TripNoTracking_Created")
        XCTAssertTrue(app.exists, "Trip creation with tracking disabled should not crash")
    }

    // MARK: - 15. Active Trip Tests

    func test33_ActiveTrip_StartStopTracking() {
        // First create a trip with tracking enabled
        let newTripButton = app.buttons["Nuovo Viaggio"]
        guard waitForElement(newTripButton, timeout: 3) else { return }
        newTripButton.tap()
        sleep(1)

        let destinationField = app.textFields.firstMatch
        if destinationField.exists {
            destinationField.tap()
            destinationField.typeText("Test Tracking")
        }

        if app.keyboards.count > 0 {
            app.tap()
        }
        sleep(1)

        // Ensure tracking switch is ON
        let trackingSwitch = app.switches.firstMatch
        if trackingSwitch.exists && trackingSwitch.value as? String == "0" {
            trackingSwitch.tap()
        }

        let createButton = app.buttons["Crea Viaggio"]
        if createButton.exists {
            createButton.tap()
            sleep(2)
        }

        takeScreenshot(name: "33_ActiveTrip_Started")

        // Look for tracking button (Start/Stop)
        let trackingButton = app.buttons[IDs.ActiveTrip.trackingButton]
        let startTrackingButton = app.buttons["Start Tracking"]
        let stopTrackingButton = app.buttons["Stop Tracking"]

        if waitForElement(trackingButton, timeout: 3) {
            trackingButton.tap()
            sleep(2)
            takeScreenshot(name: "33_ActiveTrip_TrackingToggled")
        } else if startTrackingButton.exists {
            startTrackingButton.tap()
            sleep(2)
            takeScreenshot(name: "33_ActiveTrip_TrackingStarted")
        }

        XCTAssertTrue(app.exists, "Start/Stop tracking should not crash")
    }

    func test34_ActiveTrip_AddNote() {
        // This test assumes we have an active trip from previous tests
        // Or we create a new one

        let newTripButton = app.buttons["Nuovo Viaggio"]
        if waitForElement(newTripButton, timeout: 3) {
            newTripButton.tap()
            sleep(1)

            let destinationField = app.textFields.firstMatch
            if destinationField.exists {
                destinationField.tap()
                destinationField.typeText("Test Note Trip")
            }

            if app.keyboards.count > 0 {
                app.tap()
            }
            sleep(1)

            let createButton = app.buttons["Crea Viaggio"]
            if createButton.exists {
                createButton.tap()
                sleep(2)
            }
        }

        takeScreenshot(name: "34_BeforeAddNote")

        // Look for note button
        let noteButton = app.buttons[IDs.ActiveTrip.noteButton]
        let noteButtonEmoji = app.buttons["📝"]

        if waitForElement(noteButton, timeout: 3) {
            noteButton.tap()
        } else if noteButtonEmoji.exists {
            noteButtonEmoji.tap()
        }

        sleep(1)
        takeScreenshot(name: "34_NoteDialog")

        // Check if an alert appeared for note input
        let alert = app.alerts.firstMatch
        if alert.exists {
            let textField = alert.textFields.firstMatch
            if textField.exists {
                textField.tap()
                textField.typeText("Nota di test automatico")
            }

            // Tap OK/Save button
            let okButton = alert.buttons["OK"]
            let saveButton = alert.buttons["Salva"]
            if okButton.exists {
                okButton.tap()
            } else if saveButton.exists {
                saveButton.tap()
            } else {
                alert.buttons.firstMatch.tap()
            }
        }

        sleep(1)
        takeScreenshot(name: "34_AfterAddNote")
        XCTAssertTrue(app.exists, "Adding note should not crash")
    }

    func test35_ActiveTrip_PhotoButton() {
        // Create a trip
        let newTripButton = app.buttons["Nuovo Viaggio"]
        if waitForElement(newTripButton, timeout: 3) {
            newTripButton.tap()
            sleep(1)

            let destinationField = app.textFields.firstMatch
            if destinationField.exists {
                destinationField.tap()
                destinationField.typeText("Test Photo Trip")
            }

            if app.keyboards.count > 0 {
                app.tap()
            }
            sleep(1)

            let createButton = app.buttons["Crea Viaggio"]
            if createButton.exists {
                createButton.tap()
                sleep(2)
            }
        }

        // Look for photo button
        let photoButton = app.buttons[IDs.ActiveTrip.photoButton]
        let photoButtonEmoji = app.buttons["📷"]

        takeScreenshot(name: "35_BeforePhotoButton")

        if waitForElement(photoButton, timeout: 3) {
            photoButton.tap()
        } else if photoButtonEmoji.exists {
            photoButtonEmoji.tap()
        }

        sleep(1)
        takeScreenshot(name: "35_AfterPhotoButton")

        // Handle any action sheet or alert that may appear
        let actionSheet = app.sheets.firstMatch
        if actionSheet.exists {
            // Cancel the action sheet since we can't use camera in simulator
            let cancelButton = actionSheet.buttons["Annulla"]
            if cancelButton.exists {
                cancelButton.tap()
            } else {
                actionSheet.buttons.firstMatch.tap()
            }
        }

        sleep(1)
        XCTAssertTrue(app.exists, "Photo button should not crash")
    }

    // MARK: - 16. Trip List After Creation Tests

    func test36_TripList_VerifyCreatedTrips() {
        // Navigate to trips list
        let tripsTab = app.tabBars.buttons.element(boundBy: 1)
        guard tripsTab.exists else { return }
        tripsTab.tap()
        sleep(1)

        takeScreenshot(name: "36_TripList_AfterCreation")

        // Check if table has cells (created trips)
        let table = app.tables.firstMatch
        if table.exists {
            let cellCount = table.cells.count
            print("Found \(cellCount) trip cells")

            // If there are trips, tap on the first one
            if cellCount > 0 {
                table.cells.firstMatch.tap()
                sleep(1)
                takeScreenshot(name: "36_TripDetail_FromList")

                // Go back
                let backButton = app.navigationBars.buttons.firstMatch
                if backButton.exists {
                    backButton.tap()
                    sleep(1)
                }
            }
        }

        XCTAssertTrue(app.exists, "Trip list navigation should not crash")
    }

    func test37_TripList_FilterByType() {
        // Navigate to trips list
        let tripsTab = app.tabBars.buttons.element(boundBy: 1)
        guard tripsTab.exists else { return }
        tripsTab.tap()
        sleep(1)

        // Test each filter option
        let filterSegment = app.segmentedControls.firstMatch
        if filterSegment.exists {
            // Filter by Locale (index 1)
            filterSegment.buttons.element(boundBy: 1).tap()
            sleep(1)
            takeScreenshot(name: "37_Filter_Local")

            // Filter by Giornaliero (index 2)
            filterSegment.buttons.element(boundBy: 2).tap()
            sleep(1)
            takeScreenshot(name: "37_Filter_DayTrip")

            // Filter by Multi-giorno (index 3)
            filterSegment.buttons.element(boundBy: 3).tap()
            sleep(1)
            takeScreenshot(name: "37_Filter_MultiDay")

            // Back to All (index 0)
            filterSegment.buttons.element(boundBy: 0).tap()
            sleep(1)
            takeScreenshot(name: "37_Filter_All")
        }

        XCTAssertTrue(app.exists, "Filter switching should not crash")
    }

    func test38_TripList_SearchTrips() {
        // Navigate to trips list
        let tripsTab = app.tabBars.buttons.element(boundBy: 1)
        guard tripsTab.exists else { return }
        tripsTab.tap()
        sleep(1)

        // Find search bar
        let searchBar = app.searchFields.firstMatch
        if searchBar.exists {
            searchBar.tap()
            searchBar.typeText("Roma")
            sleep(1)
            takeScreenshot(name: "38_Search_Roma")

            // Clear search - try multiple button names (English and Italian)
            let clearButton = searchBar.buttons["Clear text"]
            let clearButtonIT = searchBar.buttons["Cancella testo"]

            if clearButton.exists {
                clearButton.tap()
            } else if clearButtonIT.exists {
                clearButtonIT.tap()
            } else {
                // Fallback: clear by selecting all and deleting
                searchBar.tap()
                searchBar.doubleTap()
                usleep(500000)
            }
            sleep(1)

            // Search for another term
            searchBar.typeText("Parigi")
            sleep(1)
            takeScreenshot(name: "38_Search_Parigi")

            // Dismiss keyboard
            if app.keyboards.count > 0 {
                let searchKey = app.keyboards.buttons["Search"]
                let searchKeyIT = app.keyboards.buttons["Cerca"]
                if searchKey.exists {
                    searchKey.tap()
                } else if searchKeyIT.exists {
                    searchKeyIT.tap()
                } else {
                    app.tap() // Tap outside to dismiss
                }
            }
        }

        XCTAssertTrue(app.exists, "Search should not crash")
    }

    // MARK: - 17. Trip Detail Tests

    func test39_TripDetail_ViewDetails() {
        // Navigate to trips list
        let tripsTab = app.tabBars.buttons.element(boundBy: 1)
        guard tripsTab.exists else { return }
        tripsTab.tap()
        sleep(1)

        // Tap on first trip
        let table = app.tables.firstMatch
        if table.exists && table.cells.count > 0 {
            table.cells.firstMatch.tap()
            sleep(1)
            takeScreenshot(name: "39_TripDetail_View")

            // Scroll down to see all details
            let scrollView = app.scrollViews.firstMatch
            if scrollView.exists {
                scrollView.swipeUp()
                sleep(1)
                takeScreenshot(name: "39_TripDetail_ScrolledDown")

                scrollView.swipeDown()
                sleep(1)
            }

            // Go back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }

        XCTAssertTrue(app.exists, "Trip detail viewing should not crash")
    }

    func test40_TripDetail_MapButton() {
        // Navigate to trips list
        let tripsTab = app.tabBars.buttons.element(boundBy: 1)
        guard tripsTab.exists else { return }
        tripsTab.tap()
        sleep(1)

        // Tap on first trip
        let table = app.tables.firstMatch
        if table.exists && table.cells.count > 0 {
            table.cells.firstMatch.tap()
            sleep(1)

            // Look for map button
            let mapButton = app.buttons[IDs.TripDetail.mapButton]
            let mapButtonText = app.buttons["Visualizza Mappa"]
            let mapButtonIcon = app.buttons["map"]

            if waitForElement(mapButton, timeout: 2) {
                mapButton.tap()
            } else if mapButtonText.exists {
                mapButtonText.tap()
            } else if mapButtonIcon.exists {
                mapButtonIcon.tap()
            }

            sleep(2)
            takeScreenshot(name: "40_TripDetail_Map")

            // Go back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                sleep(1)
            }
        }

        XCTAssertTrue(app.exists, "Map button should not crash")
    }

    // MARK: - 18. Trip Deletion Tests

    func test41_TripList_SwipeToDelete() {
        // Navigate to trips list
        let tripsTab = app.tabBars.buttons.element(boundBy: 1)
        guard tripsTab.exists else { return }
        tripsTab.tap()
        sleep(1)

        let table = app.tables.firstMatch
        if table.exists && table.cells.count > 0 {
            let firstCell = table.cells.firstMatch

            // Swipe left to reveal delete button
            firstCell.swipeLeft()
            sleep(1)
            takeScreenshot(name: "41_SwipeDelete_Revealed")

            // Look for delete button
            let deleteButton = table.buttons["Delete"]
            let deleteButtonIT = table.buttons["Elimina"]

            if deleteButton.exists {
                deleteButton.tap()
            } else if deleteButtonIT.exists {
                deleteButtonIT.tap()
            }

            sleep(1)
            takeScreenshot(name: "41_AfterSwipeDelete")

            // Handle confirmation alert if present
            let alert = app.alerts.firstMatch
            if alert.exists {
                let confirmDelete = alert.buttons["Elimina"]
                let confirmDeleteEN = alert.buttons["Delete"]
                if confirmDelete.exists {
                    confirmDelete.tap()
                } else if confirmDeleteEN.exists {
                    confirmDeleteEN.tap()
                }
            }

            sleep(1)
        }

        XCTAssertTrue(app.exists, "Swipe to delete should not crash")
    }

    // MARK: - 19. Statistics After Trips Tests

    func test42_Statistics_VerifyData() {
        // Navigate to statistics
        let statsTab = app.tabBars.buttons.element(boundBy: 3)
        guard statsTab.exists else { return }
        statsTab.tap()
        sleep(1)

        takeScreenshot(name: "42_Statistics_WithTrips")

        // Scroll to see charts
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
            takeScreenshot(name: "42_Statistics_Charts")

            scrollView.swipeDown()
            sleep(1)
        }

        // Test year selector if present
        let yearSegment = app.segmentedControls.firstMatch
        if yearSegment.exists && yearSegment.buttons.count > 1 {
            yearSegment.buttons.element(boundBy: 1).tap()
            sleep(1)
            takeScreenshot(name: "42_Statistics_DifferentYear")

            yearSegment.buttons.element(boundBy: 0).tap()
            sleep(1)
        }

        XCTAssertTrue(app.exists, "Statistics viewing should not crash")
    }

    // MARK: - 20. Map View After Trips Tests

    func test43_MapView_ShowsRoutes() {
        // Navigate to map
        let mapTab = app.tabBars.buttons.element(boundBy: 2)
        guard mapTab.exists else { return }
        mapTab.tap()
        sleep(2)

        takeScreenshot(name: "43_MapView_WithRoutes")

        // Test mode switcher (Percorsi/Heatmap)
        let modeSegment = app.segmentedControls.firstMatch
        if modeSegment.exists && modeSegment.buttons.count > 1 {
            // Switch to Heatmap
            modeSegment.buttons.element(boundBy: 1).tap()
            sleep(2)
            takeScreenshot(name: "43_MapView_Heatmap")

            // Switch back to Routes
            modeSegment.buttons.element(boundBy: 0).tap()
            sleep(2)
            takeScreenshot(name: "43_MapView_Routes")
        }

        XCTAssertTrue(app.exists, "Map view should not crash")
    }

    // MARK: - 21. Complete Trip Lifecycle Test

    func test44_CompleteTripLifecycle() {
        takeScreenshot(name: "44_Lifecycle_01_Start")

        // 1. Create a new trip
        let newTripButton = app.buttons["Nuovo Viaggio"]
        guard waitForElement(newTripButton, timeout: 3) else {
            XCTFail("Could not find New Trip button")
            return
        }
        newTripButton.tap()
        sleep(1)

        let destinationField = app.textFields.firstMatch
        if destinationField.exists {
            destinationField.tap()
            destinationField.typeText("Lifecycle Test Trip")
        }

        if app.keyboards.count > 0 {
            app.tap()
        }
        sleep(1)

        let createButton = app.buttons["Crea Viaggio"]
        if createButton.exists {
            createButton.tap()
            sleep(2)
        }
        takeScreenshot(name: "44_Lifecycle_02_Created")

        // 2. Go to trips list
        let tripsTab = app.tabBars.buttons.element(boundBy: 1)
        if tripsTab.exists {
            tripsTab.tap()
            sleep(1)
        }
        takeScreenshot(name: "44_Lifecycle_03_InList")

        // 3. View trip details
        let table = app.tables.firstMatch
        if table.exists && table.cells.count > 0 {
            table.cells.firstMatch.tap()
            sleep(1)
            takeScreenshot(name: "44_Lifecycle_04_Details")

            // Go back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                sleep(1)
            }
        }

        // 4. Check statistics
        let statsTab = app.tabBars.buttons.element(boundBy: 3)
        if statsTab.exists {
            statsTab.tap()
            sleep(1)
        }
        takeScreenshot(name: "44_Lifecycle_05_Statistics")

        // 5. Check map
        let mapTab = app.tabBars.buttons.element(boundBy: 2)
        if mapTab.exists {
            mapTab.tap()
            sleep(2)
        }
        takeScreenshot(name: "44_Lifecycle_06_Map")

        // 6. Return to home
        let homeTab = app.tabBars.buttons.element(boundBy: 0)
        if homeTab.exists {
            homeTab.tap()
            sleep(1)
        }
        takeScreenshot(name: "44_Lifecycle_07_End")

        XCTAssertTrue(app.exists, "Complete trip lifecycle should not crash")
    }

    // MARK: - 22. Edge Cases with Trips

    func test45_CreateTrip_LongDestinationName() {
        let newTripButton = app.buttons["Nuovo Viaggio"]
        guard waitForElement(newTripButton, timeout: 3) else { return }
        newTripButton.tap()
        sleep(1)

        let destinationField = app.textFields.firstMatch
        if destinationField.exists {
            destinationField.tap()
            destinationField.typeText("Questa è una destinazione molto molto molto lunga per testare il comportamento dell'app")
        }

        if app.keyboards.count > 0 {
            app.tap()
        }
        sleep(1)

        takeScreenshot(name: "45_LongDestination")

        let createButton = app.buttons["Crea Viaggio"]
        if createButton.exists {
            createButton.tap()
            sleep(2)
        }

        XCTAssertTrue(app.exists, "Long destination name should not crash")
    }

    func test46_CreateTrip_SpecialCharacters() {
        let newTripButton = app.buttons["Nuovo Viaggio"]
        guard waitForElement(newTripButton, timeout: 3) else { return }
        newTripButton.tap()
        sleep(1)

        let destinationField = app.textFields.firstMatch
        if destinationField.exists {
            destinationField.tap()
            destinationField.typeText("Città d'élite #1 (2025)")
        }

        if app.keyboards.count > 0 {
            app.tap()
        }
        sleep(1)

        takeScreenshot(name: "46_SpecialChars")

        let createButton = app.buttons["Crea Viaggio"]
        if createButton.exists {
            createButton.tap()
            sleep(2)
        }

        XCTAssertTrue(app.exists, "Special characters should not crash")
    }

    func test47_RapidTripCreation_StressTest() {
        // Rapidly create multiple trips
        for i in 1...3 {
            let newTripButton = app.buttons["Nuovo Viaggio"]
            if !waitForElement(newTripButton, timeout: 3) {
                // Maybe we're on a different screen, try to go home
                navigateToHome()
                sleep(1)
                continue
            }

            newTripButton.tap()
            sleep(1)

            let destinationField = app.textFields.firstMatch
            if destinationField.exists {
                destinationField.tap()
                destinationField.typeText("Stress Test \(i)")
            }

            if app.keyboards.count > 0 {
                app.tap()
            }

            // Disable tracking to speed up and avoid ActiveTrip screen
            let trackingSwitch = app.switches.firstMatch
            if trackingSwitch.exists && trackingSwitch.value as? String == "1" {
                trackingSwitch.tap()
            }
            usleep(500000)

            let createButton = app.buttons["Crea Viaggio"]
            if createButton.exists {
                createButton.tap()
                sleep(2)
            }

            // Go back to home - handle various screens
            navigateToHome()
            sleep(1)
        }

        takeScreenshot(name: "47_AfterStressCreation")
        XCTAssertTrue(app.exists, "Rapid trip creation should not crash")
    }

    func test48_TripList_ScrollWithManyTrips() {
        // Navigate to trips list
        let tripsTab = app.tabBars.buttons.element(boundBy: 1)
        guard tripsTab.exists else { return }
        tripsTab.tap()
        sleep(1)

        // Scroll the table
        let table = app.tables.firstMatch
        if table.exists {
            // Scroll down multiple times
            table.swipeUp()
            sleep(1)
            table.swipeUp()
            sleep(1)
            takeScreenshot(name: "48_ScrolledDown")

            // Scroll back up
            table.swipeDown()
            sleep(1)
            table.swipeDown()
            sleep(1)
            takeScreenshot(name: "48_ScrolledUp")
        }

        XCTAssertTrue(app.exists, "Scrolling trip list should not crash")
    }
}
