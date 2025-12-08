//
//  ActiveTripViewController.swift
//  TravelCompanion
//
//  Created by Travel Companion on 2025-12-07.
//

import UIKit
import MapKit
import CoreLocation

class ActiveTripViewController: UIViewController, LocationManagerDelegate, MKMapViewDelegate {

    // MARK: - Properties
    var trip: Trip!

    // MARK: - UI Components
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.showsUserLocation = true
        map.userTrackingMode = .follow
        return map
    }()

    private let statsPanel: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 8
        return view
    }()

    private let destinationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let timerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "00:00:00"
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 32, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "0.00 km"
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

    private let speedLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "0 km/h"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()

    private let trackingButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Start Tracking", for: .normal)
        button.backgroundColor = UIColor.systemGreen
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()

    private let photoButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("📷", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 28)
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 28
        button.isEnabled = false
        button.alpha = 0.5
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()

    private let noteButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("📝", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 28)
        button.backgroundColor = UIColor.systemOrange
        button.layer.cornerRadius = 28
        button.isEnabled = false
        button.alpha = 0.5
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()

    private let gpsIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.systemGray
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()

    private let gpsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "GPS"
        label.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    // MARK: - Private Properties
    private var isTracking = false
    private var startTime: Date?
    private var timer: Timer?
    private var totalDistance: Double = 0.0
    private var currentSpeed: Double = 0.0
    private var lastLocation: CLLocation?
    private var routePoints: [CLLocationCoordinate2D] = []
    private var currentPolyline: MKPolyline?
    private let imagePicker = UIImagePickerController()

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupUI()
        setupMapView()
        setupLocationManager()
        setupImagePicker()
        setupActions()
        loadExistingRoute()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isTracking {
            startTimer()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isTracking {
            stopTracking()
        }
    }

    deinit {
        timer?.invalidate()
        LocationManager.shared.stopTracking()
    }

    // MARK: - Setup Methods
    private func setupViews() {
        view.backgroundColor = .systemBackground

        // Add subviews
        view.addSubview(mapView)
        view.addSubview(statsPanel)
        statsPanel.addSubview(destinationLabel)
        statsPanel.addSubview(timerLabel)
        statsPanel.addSubview(distanceLabel)
        statsPanel.addSubview(speedLabel)
        statsPanel.addSubview(trackingButton)
        statsPanel.addSubview(photoButton)
        statsPanel.addSubview(noteButton)
        view.addSubview(gpsIndicator)
        gpsIndicator.addSubview(gpsLabel)

        // Setup accessibility identifiers
        mapView.accessibilityIdentifier = AccessibilityIdentifiers.ActiveTrip.mapView
        trackingButton.accessibilityIdentifier = AccessibilityIdentifiers.ActiveTrip.trackingButton
        photoButton.accessibilityIdentifier = AccessibilityIdentifiers.ActiveTrip.photoButton
        noteButton.accessibilityIdentifier = AccessibilityIdentifiers.ActiveTrip.noteButton
        destinationLabel.accessibilityIdentifier = AccessibilityIdentifiers.ActiveTrip.destinationLabel
        timerLabel.accessibilityIdentifier = AccessibilityIdentifiers.ActiveTrip.timerLabel
        distanceLabel.accessibilityIdentifier = AccessibilityIdentifiers.ActiveTrip.distanceLabel
        speedLabel.accessibilityIdentifier = AccessibilityIdentifiers.ActiveTrip.speedLabel
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // MapView - occupies top portion
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: statsPanel.topAnchor),

            // Stats Panel - bottom panel with stats and controls
            statsPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statsPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statsPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            statsPanel.heightAnchor.constraint(equalToConstant: 280),

            // Destination Label
            destinationLabel.topAnchor.constraint(equalTo: statsPanel.topAnchor, constant: 16),
            destinationLabel.leadingAnchor.constraint(equalTo: statsPanel.leadingAnchor, constant: 20),
            destinationLabel.trailingAnchor.constraint(equalTo: statsPanel.trailingAnchor, constant: -20),

            // Timer Label
            timerLabel.topAnchor.constraint(equalTo: destinationLabel.bottomAnchor, constant: 12),
            timerLabel.centerXAnchor.constraint(equalTo: statsPanel.centerXAnchor),

            // Distance Label
            distanceLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 8),
            distanceLabel.centerXAnchor.constraint(equalTo: statsPanel.centerXAnchor),

            // Speed Label
            speedLabel.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 4),
            speedLabel.centerXAnchor.constraint(equalTo: statsPanel.centerXAnchor),

            // Tracking Button
            trackingButton.topAnchor.constraint(equalTo: speedLabel.bottomAnchor, constant: 16),
            trackingButton.centerXAnchor.constraint(equalTo: statsPanel.centerXAnchor),
            trackingButton.widthAnchor.constraint(equalToConstant: 200),
            trackingButton.heightAnchor.constraint(equalToConstant: 50),

            // Photo Button
            photoButton.centerYAnchor.constraint(equalTo: trackingButton.centerYAnchor),
            photoButton.trailingAnchor.constraint(equalTo: trackingButton.leadingAnchor, constant: -16),
            photoButton.widthAnchor.constraint(equalToConstant: 56),
            photoButton.heightAnchor.constraint(equalToConstant: 56),

            // Note Button
            noteButton.centerYAnchor.constraint(equalTo: trackingButton.centerYAnchor),
            noteButton.leadingAnchor.constraint(equalTo: trackingButton.trailingAnchor, constant: 16),
            noteButton.widthAnchor.constraint(equalToConstant: 56),
            noteButton.heightAnchor.constraint(equalToConstant: 56),

            // GPS Indicator
            gpsIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            gpsIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            gpsIndicator.widthAnchor.constraint(equalToConstant: 50),
            gpsIndicator.heightAnchor.constraint(equalToConstant: 32),

            // GPS Label
            gpsLabel.centerXAnchor.constraint(equalTo: gpsIndicator.centerXAnchor),
            gpsLabel.centerYAnchor.constraint(equalTo: gpsIndicator.centerYAnchor)
        ])
    }

    private func setupUI() {
        title = "Active Trip"

        // Setup destination label
        destinationLabel.text = trip.destination ?? "Unknown Destination"
    }

    private func setupActions() {
        trackingButton.addTarget(self, action: #selector(trackingButtonTapped), for: .touchUpInside)
        photoButton.addTarget(self, action: #selector(photoButtonTapped), for: .touchUpInside)
        noteButton.addTarget(self, action: #selector(noteButtonTapped), for: .touchUpInside)
    }

    private func setupMapView() {
        mapView.delegate = self

        // Set initial region
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.0, longitude: 10.0),
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )
        mapView.setRegion(region, animated: false)
    }

    private func setupLocationManager() {
        LocationManager.shared.delegate = self
        LocationManager.shared.requestAuthorization()
    }

    private func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }

    private func loadExistingRoute() {
        // Load existing route points from CoreData
        let routes = CoreDataManager.shared.fetchRoute(for: trip)

        if !routes.isEmpty {
            routePoints = routes.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            totalDistance = trip.totalDistance
            updatePolyline()
            updateDistanceLabel()
            centerMapOnRoute()
        }
    }

    // MARK: - Actions
    @objc private func trackingButtonTapped() {
        if isTracking {
            stopTracking()
        } else {
            startTracking()
        }
    }

    @objc private func photoButtonTapped() {
        let alert = UIAlertController(title: "Take Photo", message: "Choose source", preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.imagePicker.sourceType = .camera
                self.present(self.imagePicker, animated: true)
            })
        }

        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = photoButton
            popover.sourceRect = photoButton.bounds
        }

        present(alert, animated: true)
    }

    @objc private func noteButtonTapped() {
        let alert = UIAlertController(title: "Add Note", message: "Enter your note", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Type your note here..."
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            self?.saveNote(text)
        })

        present(alert, animated: true)
    }

    // MARK: - Tracking Methods
    private func startTracking() {
        isTracking = true
        startTime = Date()

        LocationManager.shared.startTracking()

        // Update UI
        trackingButton.setTitle("Stop Tracking", for: .normal)
        trackingButton.backgroundColor = UIColor.systemRed
        photoButton.isEnabled = true
        photoButton.alpha = 1.0
        noteButton.isEnabled = true
        noteButton.alpha = 1.0

        startTimer()
        updateGPSIndicator(isActive: true)
    }

    private func stopTracking() {
        isTracking = false

        LocationManager.shared.stopTracking()

        // Update UI
        trackingButton.setTitle("Start Tracking", for: .normal)
        trackingButton.backgroundColor = UIColor.systemGreen
        photoButton.isEnabled = false
        photoButton.alpha = 0.5
        noteButton.isEnabled = false
        noteButton.alpha = 0.5

        timer?.invalidate()
        timer = nil
        updateGPSIndicator(isActive: false)

        // Save final data
        saveRouteData()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }

    private func updateTimer() {
        guard let startTime = startTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)

        let hours = Int(elapsed) / 3600
        let minutes = Int(elapsed) / 60 % 60
        let seconds = Int(elapsed) % 60

        timerLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Location Handling
    private func handleLocationUpdate(_ location: CLLocation) {
        guard isTracking else { return }

        let coordinate = location.coordinate
        routePoints.append(coordinate)

        // Calculate distance
        if let lastLocation = lastLocation {
            let distance = location.distance(from: lastLocation)
            totalDistance += distance
            updateDistanceLabel()

            // Calculate speed (km/h)
            let timeInterval = location.timestamp.timeIntervalSince(lastLocation.timestamp)
            if timeInterval > 0 {
                currentSpeed = (distance / timeInterval) * 3.6 // Convert m/s to km/h
                updateSpeedLabel()
            }
        }

        lastLocation = location

        // Save route point to CoreData
        CoreDataManager.shared.addRoutePoint(to: trip, location: location)

        // Update polyline
        updatePolyline()

        // Center map on user location
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: true)

        updateGPSIndicator(isActive: true)
    }

    private func updatePolyline() {
        // Remove old polyline
        if let currentPolyline = currentPolyline {
            mapView.removeOverlay(currentPolyline)
        }

        // Add new polyline
        if routePoints.count > 1 {
            let polyline = MKPolyline(coordinates: routePoints, count: routePoints.count)
            mapView.addOverlay(polyline)
            currentPolyline = polyline
        }
    }

    private func updateDistanceLabel() {
        let distanceInKm = totalDistance / 1000.0
        distanceLabel.text = String(format: "Distance: %.2f km", distanceInKm)
    }

    private func updateSpeedLabel() {
        speedLabel.text = String(format: "Speed: %.1f km/h", currentSpeed)
    }

    private func updateGPSIndicator(isActive: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.gpsIndicator.backgroundColor = isActive ? UIColor.systemGreen : UIColor.systemGray
        }
    }

    private func centerMapOnRoute() {
        guard !routePoints.isEmpty else { return }

        var minLat = routePoints[0].latitude
        var maxLat = routePoints[0].latitude
        var minLon = routePoints[0].longitude
        var maxLon = routePoints[0].longitude

        for point in routePoints {
            minLat = min(minLat, point.latitude)
            maxLat = max(maxLat, point.latitude)
            minLon = min(minLon, point.longitude)
            maxLon = max(maxLon, point.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )

        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }

    // MARK: - Data Persistence
    private func saveRouteData() {
        // Update total distance in trip
        trip.totalDistance = totalDistance
        CoreDataManager.shared.saveContext()
    }

    private func saveNote(_ text: String) {
        guard let currentLocation = lastLocation else {
            showAlert(title: "Error", message: "Current location not available")
            return
        }

        let note = CoreDataManager.shared.createNote(
            for: trip,
            text: text,
            latitude: currentLocation.coordinate.latitude,
            longitude: currentLocation.coordinate.longitude
        )

        if note != nil {
            showAlert(title: "Success", message: "Note saved successfully")
        } else {
            showAlert(title: "Error", message: "Failed to save note")
        }
    }

    // MARK: - LocationManagerDelegate
    func locationManager(_ manager: LocationManager, didUpdateLocation location: CLLocation) {
        handleLocationUpdate(location)
    }

    func locationManager(_ manager: LocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        updateGPSIndicator(isActive: false)
    }

    func locationManager(_ manager: LocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if isTracking {
                LocationManager.shared.startTracking()
            }
        case .denied, .restricted:
            showAlert(title: "Location Permission", message: "Please enable location services in Settings")
        default:
            break
        }
    }

    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = getTripColor()
            renderer.lineWidth = 4.0
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        let identifier = "PhotoAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }

        return annotationView
    }

    // MARK: - Helper Methods
    private func getTripColor() -> UIColor {
        guard let tripTypeRaw = trip.tripTypeRaw,
              let tripType = TripType(rawValue: tripTypeRaw) else {
            return .systemBlue
        }

        return tripType.color
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ActiveTripViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            showAlert(title: "Error", message: "Failed to get image")
            return
        }

        guard let currentLocation = lastLocation else {
            showAlert(title: "Error", message: "Current location not available")
            return
        }

        // Save photo
        guard let tripId = trip.id else {
            showAlert(title: "Error", message: "Invalid trip ID")
            return
        }

        guard let filename = PhotoStorageManager.shared.savePhoto(image, for: tripId) else {
            showAlert(title: "Error", message: "Failed to save photo")
            return
        }

        if !filename.isEmpty {
            let photo = CoreDataManager.shared.createPhoto(
                for: trip,
                filename: filename,
                latitude: currentLocation.coordinate.latitude,
                longitude: currentLocation.coordinate.longitude
            )

            if photo != nil {
                // Add annotation to map
                let annotation = MKPointAnnotation()
                annotation.coordinate = currentLocation.coordinate
                annotation.title = "Photo"
                annotation.subtitle = "Tap to view"
                mapView.addAnnotation(annotation)

                showAlert(title: "Success", message: "Photo saved successfully")
            } else {
                showAlert(title: "Error", message: "Failed to save photo")
            }
        } else {
            showAlert(title: "Error", message: "Failed to save photo to storage")
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
