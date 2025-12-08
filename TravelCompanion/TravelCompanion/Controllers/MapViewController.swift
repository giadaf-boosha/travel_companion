//
//  MapViewController.swift
//  TravelCompanion
//
//  Created by Travel Companion on 2025-12-07.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate {

    // MARK: - Properties
    var trip: Trip? // nil = mostra tutti i viaggi

    // MARK: - UI Components
    private var mapView: MKMapView!
    private var segmentedControl: UISegmentedControl!

    // MARK: - Private Properties
    private var allTrips: [Trip] = []
    private var allPolylines: [MKPolyline] = []
    private var photoAnnotations: [PhotoAnnotation] = []
    private var heatmapOverlay: MKPolygon?
    private var isHeatmapMode = false

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMapView()
        setupSegmentedControl()
        loadMapData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshMapData()
    }

    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground

        if let trip = trip {
            title = trip.destination ?? "Trip Map"
        } else {
            title = "All Trips"
        }

        // Create segmented control
        segmentedControl = UISegmentedControl(items: ["Percorsi", "Heatmap"])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
        view.addSubview(segmentedControl)

        // Create map view
        mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)

        // Layout constraints
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            mapView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true

        // Set initial region (centered on Italy as default)
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964),
            latitudinalMeters: 1000000,
            longitudinalMeters: 1000000
        )
        mapView.setRegion(region, animated: false)
    }

    private func setupSegmentedControl() {
        // Already setup in setupUI
    }

    // MARK: - Data Loading
    private func loadMapData() {
        if let trip = trip {
            // Show single trip
            allTrips = [trip]
        } else {
            // Show all trips
            allTrips = CoreDataManager.shared.fetchAllTrips()
        }

        displayRoutesOnMap()
        displayPhotosOnMap()
    }

    private func refreshMapData() {
        // Clear existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        allPolylines.removeAll()
        photoAnnotations.removeAll()

        // Reload data
        loadMapData()
    }

    private func displayRoutesOnMap() {
        guard !isHeatmapMode else { return }

        var allCoordinates: [CLLocationCoordinate2D] = []

        for trip in allTrips {
            // Fetch routes using CoreDataManager
            let routes = CoreDataManager.shared.fetchRoutes(for: trip)

            // Convert Route objects to coordinates
            let coordinates = routes.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }

            if coordinates.count > 1 {
                let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)

                // Store trip reference in polyline title
                polyline.title = trip.objectID.uriRepresentation().absoluteString

                mapView.addOverlay(polyline)
                allPolylines.append(polyline)
                allCoordinates.append(contentsOf: coordinates)
            }
        }

        // Zoom to fit all routes
        if !allCoordinates.isEmpty {
            zoomToFitCoordinates(allCoordinates)
        }
    }

    private func displayPhotosOnMap() {
        for trip in allTrips {
            if let photos = trip.photos as? Set<Photo> {
                for photo in photos {
                    let annotation = PhotoAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: photo.latitude, longitude: photo.longitude)
                    annotation.title = "Photo"
                    annotation.subtitle = trip.destination ?? "Trip"
                    annotation.photo = photo

                    mapView.addAnnotation(annotation)
                    photoAnnotations.append(annotation)
                }
            }
        }
    }

    private func displayHeatmap() {
        // Remove route overlays
        mapView.removeOverlays(allPolylines)

        // Collect all coordinates from all trips
        var allCoordinates: [CLLocationCoordinate2D] = []

        for trip in allTrips {
            // Fetch routes using CoreDataManager
            let routes = CoreDataManager.shared.fetchRoutes(for: trip)

            // Convert Route objects to coordinates
            let coordinates = routes.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            allCoordinates.append(contentsOf: coordinates)
        }

        // Create heatmap overlay
        if !allCoordinates.isEmpty {
            let heatmap = createHeatmapOverlay(from: allCoordinates)
            mapView.addOverlay(heatmap, level: .aboveLabels)
            heatmapOverlay = heatmap
        }
    }

    private func createHeatmapOverlay(from coordinates: [CLLocationCoordinate2D]) -> MKPolygon {
        // Create density map by grouping coordinates
        var densityMap: [String: Int] = [:]
        let gridSize = 0.01 // Approximately 1km

        for coord in coordinates {
            let gridLat = round(coord.latitude / gridSize) * gridSize
            let gridLon = round(coord.longitude / gridSize) * gridSize
            let key = "\(gridLat),\(gridLon)"
            densityMap[key, default: 0] += 1
        }

        // Create polygons for high-density areas
        var polygonCoordinates: [CLLocationCoordinate2D] = []

        for (key, count) in densityMap {
            if count > 5 { // Threshold for "hot" areas
                let components = key.split(separator: ",")
                if components.count == 2,
                   let lat = Double(components[0]),
                   let lon = Double(components[1]) {

                    // Create a small square around this point
                    let offset = gridSize / 2
                    polygonCoordinates.append(CLLocationCoordinate2D(latitude: lat - offset, longitude: lon - offset))
                    polygonCoordinates.append(CLLocationCoordinate2D(latitude: lat - offset, longitude: lon + offset))
                    polygonCoordinates.append(CLLocationCoordinate2D(latitude: lat + offset, longitude: lon + offset))
                    polygonCoordinates.append(CLLocationCoordinate2D(latitude: lat + offset, longitude: lon - offset))
                }
            }
        }

        // If we have hotspots, create polygon, otherwise use all coordinates
        if polygonCoordinates.isEmpty {
            polygonCoordinates = coordinates
        }

        return MKPolygon(coordinates: polygonCoordinates, count: polygonCoordinates.count)
    }

    // MARK: - IBActions
    @objc private func segmentedControlChanged() {
        isHeatmapMode = (segmentedControl.selectedSegmentIndex == 1)

        if isHeatmapMode {
            displayHeatmap()
        } else {
            // Remove heatmap
            if let heatmapOverlay = heatmapOverlay {
                mapView.removeOverlay(heatmapOverlay)
                self.heatmapOverlay = nil
            }

            // Show routes again
            displayRoutesOnMap()
        }
    }

    // MARK: - Map Helpers
    private func zoomToFitCoordinates(_ coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }

        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )

        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }

    private func getTripColor(for trip: Trip) -> UIColor {
        guard let tripTypeRaw = trip.tripTypeRaw,
              let tripType = TripType(rawValue: tripTypeRaw) else {
            return .systemBlue
        }
        return tripType.color
    }

    private func findTripForPolyline(_ polyline: MKPolyline) -> Trip? {
        guard let uriString = polyline.title,
              let url = URL(string: uriString) else { return nil }

        let coordinator = CoreDataManager.shared.persistentContainer.persistentStoreCoordinator

        if let objectID = coordinator.managedObjectID(forURIRepresentation: url) {
            return try? CoreDataManager.shared.context.existingObject(with: objectID) as? Trip
        }

        return nil
    }

    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)

            // Find the trip for this polyline to get its color
            if let trip = findTripForPolyline(polyline) {
                renderer.strokeColor = getTripColor(for: trip)
            } else {
                renderer.strokeColor = .systemBlue
            }

            renderer.lineWidth = 4.0
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }

        if let polygon = overlay as? MKPolygon {
            // Heatmap rendering
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.3)
            renderer.strokeColor = UIColor.systemRed.withAlphaComponent(0.7)
            renderer.lineWidth = 1.0
            return renderer
        }

        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        if let photoAnnotation = annotation as? PhotoAnnotation {
            let identifier = "PhotoAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true

                // Add detail button
                let detailButton = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = detailButton

                // Set marker color
                annotationView?.markerTintColor = .systemBlue
                annotationView?.glyphImage = UIImage(systemName: "camera.fill")
            } else {
                annotationView?.annotation = annotation
            }

            // Add thumbnail if available
            if let photo = photoAnnotation.photo,
               let imagePath = photo.imagePath,
               let image = PhotoStorageManager.shared.loadPhoto(at: imagePath) {

                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
                imageView.image = image
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 5
                annotationView?.leftCalloutAccessoryView = imageView
            }

            return annotationView
        }

        return nil
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let photoAnnotation = view.annotation as? PhotoAnnotation,
              let photo = photoAnnotation.photo else { return }

        showPhotoDetail(photo)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Zoom to selected annotation
        if let coordinate = view.annotation?.coordinate {
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )
            mapView.setRegion(region, animated: true)
        }
    }

    // MARK: - Photo Detail
    private func showPhotoDetail(_ photo: Photo) {
        let alert = UIAlertController(title: "Photo Details", message: nil, preferredStyle: .alert)

        // Load and display photo
        if let imagePath = photo.imagePath,
           let image = PhotoStorageManager.shared.loadPhoto(at: imagePath) {

            let imageView = UIImageView(frame: CGRect(x: 10, y: 50, width: 250, height: 250))
            imageView.image = image
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 10

            alert.view.addSubview(imageView)

            // Add constraint to accommodate image
            let height = NSLayoutConstraint(
                item: alert.view!,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1,
                constant: 370
            )
            alert.view.addConstraint(height)
        }

        // Add location info
        let locationText = String(format: "Location: %.6f, %.6f", photo.latitude, photo.longitude)
        alert.message = locationText

        // Add timestamp if available
        if let timestamp = photo.timestamp {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            alert.message = "\(locationText)\n\(formatter.string(from: timestamp))"
        }

        alert.addAction(UIAlertAction(title: "Close", style: .default))

        // Option to delete photo
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deletePhoto(photo)
        })

        present(alert, animated: true)
    }

    private func deletePhoto(_ photo: Photo) {
        let confirmAlert = UIAlertController(
            title: "Delete Photo",
            message: "Are you sure you want to delete this photo?",
            preferredStyle: .alert
        )

        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            // Delete from storage
            if let imagePath = photo.imagePath {
                PhotoStorageManager.shared.deletePhoto(at: imagePath)
            }

            // Delete from Core Data
            CoreDataManager.shared.context.delete(photo)
            CoreDataManager.shared.saveContext()

            // Refresh map
            self?.refreshMapData()
        })

        present(confirmAlert, animated: true)
    }
}

// MARK: - PhotoAnnotation Class
class PhotoAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var title: String?
    var subtitle: String?
    var photo: Photo?
}

