//
//  AccessibilityIdentifiers.swift
//  TravelCompanion
//
//  Identificatori di accessibilita per UI Testing con XCUITest.
//  Centralizza tutti gli ID per evitare stringhe duplicate nel codice di test.
//

import Foundation

// MARK: - Accessibility Identifiers

/// Identificatori di accessibilita per i test UI automatizzati.
///
/// **Convenzione di naming:** `[schermata]_[tipoElemento]_[nomeElemento]`
///
/// Esempi:
/// - `home_button_newTrip` - Pulsante nella Home
/// - `tripList_tableView` - TableView nella lista viaggi
/// - `newTrip_textField_destination` - Campo testo nella creazione viaggio
///
/// **Uso nei test:**
/// ```swift
/// let button = app.buttons[AccessibilityIdentifiers.Home.newTripButton]
/// button.tap()
/// ```
///
/// **Uso nel codice UI:**
/// ```swift
/// button.accessibilityIdentifier = AccessibilityIdentifiers.Home.newTripButton
/// ```
struct AccessibilityIdentifiers {

    // MARK: - Schermata Home
    /// Identificatori per la schermata Home principale
    struct Home {
        static let newTripButton = "home_button_newTrip"
        static let continueTripButton = "home_button_continueTrip"
        static let settingsButton = "home_button_settings"
        static let statsCard = "home_card_stats"
        static let lastTripCard = "home_card_lastTrip"
        static let totalTripsLabel = "home_label_totalTrips"
        static let totalDistanceLabel = "home_label_totalDistance"
        static let emptyStateView = "home_view_emptyState"
    }

    // MARK: - Trip List Screen
    struct TripList {
        static let tableView = "tripList_tableView"
        static let searchBar = "tripList_searchBar"
        static let filterSegment = "tripList_segment_filter"
        static let addButton = "tripList_button_add"
        static let emptyStateView = "tripList_view_emptyState"
        static let emptyStateLabel = "tripList_label_emptyState"
        static let tripCell = "tripList_cell_trip"
    }

    // MARK: - New Trip Screen
    struct NewTrip {
        static let scrollView = "newTrip_scrollView"
        static let destinationTextField = "newTrip_textField_destination"
        static let startDatePicker = "newTrip_datePicker_startDate"
        static let endDatePicker = "newTrip_datePicker_endDate"
        static let tripTypeSegment = "newTrip_segment_tripType"
        static let startTrackingSwitch = "newTrip_switch_startTracking"
        static let createButton = "newTrip_button_create"
        static let cancelButton = "newTrip_button_cancel"
    }

    // MARK: - Active Trip Screen
    struct ActiveTrip {
        static let mapView = "activeTrip_mapView"
        static let trackingButton = "activeTrip_button_tracking"
        static let photoButton = "activeTrip_button_photo"
        static let noteButton = "activeTrip_button_note"
        static let destinationLabel = "activeTrip_label_destination"
        static let timerLabel = "activeTrip_label_timer"
        static let distanceLabel = "activeTrip_label_distance"
        static let speedLabel = "activeTrip_label_speed"
        static let completeButton = "activeTrip_button_complete"
    }

    // MARK: - Trip Detail Screen
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

        // AI Section
        static let aiSectionLabel = "tripDetail_label_aiSection"
        static let aiItineraryButton = "tripDetail_button_aiItinerary"
        static let aiPackingListButton = "tripDetail_button_aiPackingList"
        static let aiBriefingButton = "tripDetail_button_aiBriefing"
    }

    // MARK: - Map Screen
    struct Map {
        static let mapView = "map_mapView"
        static let modeSegment = "map_segment_mode"
    }

    // MARK: - Statistics Screen
    struct Statistics {
        static let scrollView = "statistics_scrollView"
        static let yearSegment = "statistics_segment_year"
        static let totalTripsCard = "statistics_card_totalTrips"
        static let totalDistanceCard = "statistics_card_totalDistance"
        static let totalPhotosCard = "statistics_card_totalPhotos"
        static let totalNotesCard = "statistics_card_totalNotes"
        static let tripsChartView = "statistics_chart_trips"
        static let distanceChartView = "statistics_chart_distance"
    }

    // MARK: - Chat Screen
    struct Chat {
        static let tableView = "chat_tableView"
        static let inputTextField = "chat_textField_input"
        static let sendButton = "chat_button_send"
        static let clearButton = "chat_button_clear"
        static let loadingIndicator = "chat_indicator_loading"
    }

    // MARK: - Settings Screen
    struct Settings {
        static let tableView = "settings_tableView"
        static let poiNotificationsSwitch = "settings_switch_poiNotifications"
        static let reminderNotificationsSwitch = "settings_switch_reminderNotifications"
        static let geofenceRow = "settings_row_geofence"
    }

    // MARK: - Geofence Screen
    struct Geofence {
        static let mapView = "geofence_mapView"
        static let nameTextField = "geofence_textField_name"
        static let radiusSlider = "geofence_slider_radius"
        static let radiusLabel = "geofence_label_radius"
        static let addButton = "geofence_button_add"
        static let zonesTableView = "geofence_tableView_zones"
    }

    // MARK: - Tab Bar
    struct TabBar {
        static let homeTab = "tabBar_tab_home"
        static let tripsTab = "tabBar_tab_trips"
        static let mapTab = "tabBar_tab_map"
        static let statisticsTab = "tabBar_tab_statistics"
        static let chatTab = "tabBar_tab_chat"
        static let aiAssistantTab = "tabBar_tab_aiAssistant"
    }

    // MARK: - AI Assistant Screen
    struct AIAssistant {
        static let welcomeLabel = "aiAssistant_label_welcome"
        static let starterButton = "aiAssistant_button_starter"
        static let itineraryButton = "aiAssistant_button_itinerary"
        static let packingListButton = "aiAssistant_button_packingList"
        static let briefingButton = "aiAssistant_button_briefing"
    }

    // MARK: - Itinerary Generator Screen
    struct ItineraryGenerator {
        static let scrollView = "itineraryGenerator_scrollView"
        static let destinationTextField = "itineraryGenerator_textField_destination"
        static let durationPicker = "itineraryGenerator_picker_duration"
        static let tripTypeSegment = "itineraryGenerator_segment_tripType"
        static let travelStylePicker = "itineraryGenerator_picker_travelStyle"
        static let generateButton = "itineraryGenerator_button_generate"
        static let cancelButton = "itineraryGenerator_button_cancel"
        static let loadingIndicator = "itineraryGenerator_indicator_loading"
    }

    // MARK: - Itinerary Detail Screen
    struct ItineraryDetail {
        static let scrollView = "itineraryDetail_scrollView"
        static let destinationLabel = "itineraryDetail_label_destination"
        static let daysLabel = "itineraryDetail_label_days"
        static let styleLabel = "itineraryDetail_label_style"
        static let dayCard = "itineraryDetail_card_day"
        static let tipsSection = "itineraryDetail_section_tips"
        static let regenerateButton = "itineraryDetail_button_regenerate"
        static let aiDisclaimer = "itineraryDetail_label_aiDisclaimer"
    }

    // MARK: - Packing List Screen
    struct PackingList {
        static let tableView = "packingList_tableView"
        static let categoryHeader = "packingList_header_category"
        static let itemCell = "packingList_cell_item"
        static let checkboxButton = "packingList_button_checkbox"
        static let addItemButton = "packingList_button_addItem"
        static let regenerateButton = "packingList_button_regenerate"
        static let progressLabel = "packingList_label_progress"
        static let loadingIndicator = "packingList_indicator_loading"
    }

    // MARK: - Briefing Detail Screen
    struct BriefingDetail {
        static let scrollView = "briefingDetail_scrollView"
        static let destinationLabel = "briefingDetail_label_destination"
        static let quickFactsCard = "briefingDetail_card_quickFacts"
        static let culturalTipsSection = "briefingDetail_section_culturalTips"
        static let phrasesSection = "briefingDetail_section_phrases"
        static let climateSection = "briefingDetail_section_climate"
        static let foodSection = "briefingDetail_section_food"
        static let safetySection = "briefingDetail_section_safety"
        static let regenerateButton = "briefingDetail_button_regenerate"
        static let aiDisclaimer = "briefingDetail_label_aiDisclaimer"
        static let loadingIndicator = "briefingDetail_indicator_loading"
    }

}
