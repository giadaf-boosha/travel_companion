import UIKit
import MapKit
import CoreLocation

/// ViewController per la gestione delle zone geofence
final class GeofenceViewController: UIViewController {

    // MARK: - UI Components

    private let mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.showsUserLocation = true
        map.layer.cornerRadius = 12
        map.clipsToBounds = true
        return map
    }()

    private let controlsContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()

    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Nome zona"
        textField.borderStyle = .none
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.backgroundColor = .secondarySystemBackground
        textField.font = UIFont.systemFont(ofSize: 16)

        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 40))
        textField.leftView = paddingView
        textField.leftViewMode = .always

        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 40))
        textField.rightView = rightPaddingView
        textField.rightViewMode = .always

        return textField
    }()

    private let radiusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = "Raggio: 100 m"
        return label
    }()

    private let radiusSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = Float(Constants.Defaults.geofenceRadiusMin)
        slider.maximumValue = Float(Constants.Defaults.geofenceRadiusMax)
        slider.value = Float(Constants.Defaults.geofenceRadiusDefault)
        slider.tintColor = .systemBlue
        return slider
    }()

    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Aggiungi Zona", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.isEnabled = false
        return button
    }()

    private let zonesTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.layer.cornerRadius = 12
        tableView.clipsToBounds = true
        tableView.backgroundColor = .systemBackground
        return tableView
    }()

    private let zonesHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Zone Geofence Attive"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Tocca e tieni premuto sulla mappa per selezionare una posizione"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    // MARK: - Properties

    private let geofenceManager = GeofenceManager.shared
    private let coreDataManager = CoreDataManager.shared
    private let locationManager = CLLocationManager()

    private var selectedCoordinate: CLLocationCoordinate2D?
    private var selectedAnnotation: MKPointAnnotation?
    private var zones: [GeofenceZone] = []
    private var currentRadius: Double = Constants.Defaults.geofenceRadiusDefault

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupMapView()
        setupTableView()
        setupLocationManager()
        setupActions()
        loadZones()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadZones()
        checkLocationAuthorization()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Zone Geofence"
        view.backgroundColor = .systemGroupedBackground

        // Add subviews
        view.addSubview(mapView)
        view.addSubview(instructionLabel)
        view.addSubview(controlsContainer)
        view.addSubview(zonesHeaderLabel)
        view.addSubview(zonesTableView)

        controlsContainer.addSubview(nameTextField)
        controlsContainer.addSubview(radiusLabel)
        controlsContainer.addSubview(radiusSlider)
        controlsContainer.addSubview(addButton)

        setupConstraints()
        updateRadiusLabel()

        // Gesture per lungo press sulla mappa
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(mapLongPressed(_:)))
        longPressGesture.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGesture)

        // Nascondi tastiera quando si tocca fuori
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // MapView - occupa circa 1/3 superiore dello schermo
            mapView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.28),

            // Instruction Label
            instructionLabel.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 8),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Controls Container
            controlsContainer.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 12),
            controlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Name TextField
            nameTextField.topAnchor.constraint(equalTo: controlsContainer.topAnchor, constant: 16),
            nameTextField.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor, constant: -16),
            nameTextField.heightAnchor.constraint(equalToConstant: 44),

            // Radius Label
            radiusLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 16),
            radiusLabel.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor, constant: 16),
            radiusLabel.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor, constant: -16),

            // Radius Slider
            radiusSlider.topAnchor.constraint(equalTo: radiusLabel.bottomAnchor, constant: 8),
            radiusSlider.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor, constant: 16),
            radiusSlider.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor, constant: -16),

            // Add Button
            addButton.topAnchor.constraint(equalTo: radiusSlider.bottomAnchor, constant: 16),
            addButton.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 48),
            addButton.bottomAnchor.constraint(equalTo: controlsContainer.bottomAnchor, constant: -16),

            // Zones Header Label
            zonesHeaderLabel.topAnchor.constraint(equalTo: controlsContainer.bottomAnchor, constant: 24),
            zonesHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            zonesHeaderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Zones TableView
            zonesTableView.topAnchor.constraint(equalTo: zonesHeaderLabel.bottomAnchor, constant: 12),
            zonesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            zonesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            zonesTableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -16)
        ])
    }

    private func setupMapView() {
        mapView.delegate = self

        // Zoom sulla posizione utente
        if let userLocation = locationManager.location {
            let region = MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            )
            mapView.setRegion(region, animated: false)
        }
    }

    private func setupTableView() {
        zonesTableView.delegate = self
        zonesTableView.dataSource = self
        zonesTableView.register(GeofenceZoneCell.self, forCellReuseIdentifier: Constants.Cell.geofenceZoneCell)
        zonesTableView.rowHeight = UITableView.automaticDimension
        zonesTableView.estimatedRowHeight = 70
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    private func setupActions() {
        radiusSlider.addTarget(self, action: #selector(radiusSliderChanged(_:)), for: .valueChanged)
        addButton.addTarget(self, action: #selector(addButtonTapped(_:)), for: .touchUpInside)
    }

    private func checkLocationAuthorization() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse:
            // Chiedi autorizzazione Always per il geofencing
            showAlwaysAuthorizationAlert()

        case .authorizedAlways:
            break

        case .restricted, .denied:
            showLocationDeniedAlert()

        @unknown default:
            break
        }
    }

    // MARK: - Data Loading

    private func loadZones() {
        zones = coreDataManager.fetchAllGeofenceZones()
        zonesTableView.reloadData()

        // Mostra le zone sulla mappa
        updateMapOverlays()
    }

    private func updateMapOverlays() {
        // Rimuovi overlay esistenti
        mapView.removeOverlays(mapView.overlays)

        // Aggiungi overlay per ogni zona
        for zone in zones {
            let center = CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude)
            let circle = MKCircle(center: center, radius: zone.radius)
            mapView.addOverlay(circle)
        }
    }

    // MARK: - Map Interaction

    @objc private func mapLongPressed(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            selectLocation(coordinate)
        }
    }

    private func selectLocation(_ coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate

        // Rimuovi pin precedente
        if let annotation = selectedAnnotation {
            mapView.removeAnnotation(annotation)
        }

        // Aggiungi nuovo pin
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Nuova zona"
        mapView.addAnnotation(annotation)
        selectedAnnotation = annotation

        // Aggiungi overlay per il raggio
        updateTempOverlay()

        // Abilita il bottone aggiungi
        addButton.isEnabled = true
        addButton.backgroundColor = .systemBlue

        // Focus sul pin
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: currentRadius * 4,
            longitudinalMeters: currentRadius * 4
        )
        mapView.setRegion(region, animated: true)
    }

    private func updateTempOverlay() {
        guard let coordinate = selectedCoordinate else { return }

        // Rimuovi overlay temporaneo
        if let tempOverlay = mapView.overlays.last(where: { $0 is TempCircleOverlay }) {
            mapView.removeOverlay(tempOverlay)
        }

        // Aggiungi nuovo overlay
        let circle = TempCircleOverlay(center: coordinate, radius: currentRadius)
        mapView.addOverlay(circle)
    }

    // MARK: - Actions

    @objc private func radiusSliderChanged(_ sender: UISlider) {
        currentRadius = Double(sender.value)
        updateRadiusLabel()
        updateTempOverlay()
    }

    @objc private func addButtonTapped(_ sender: UIButton) {
        guard let coordinate = selectedCoordinate else { return }
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            showAlert(title: "Errore", message: "Inserisci un nome per la zona")
            return
        }

        // Verifica limite zone
        if zones.count >= Constants.Defaults.maxGeofenceZones {
            showAlert(
                title: "Limite Raggiunto",
                message: "Hai raggiunto il limite massimo di \(Constants.Defaults.maxGeofenceZones) zone geofence. Elimina alcune zone per aggiungerne di nuove."
            )
            return
        }

        // Crea la zona
        let zone = coreDataManager.createGeofenceZone(
            name: name,
            center: coordinate,
            radius: currentRadius
        )

        // Registra la geofence
        let success = geofenceManager.addGeofence(for: zone)

        if success {
            // Reset UI
            resetSelectionUI()

            // Ricarica le zone
            loadZones()

            showAlert(title: "Successo", message: "Zona geofence '\(name)' aggiunta con successo!")
        } else {
            // Elimina la zona dal database se non è stato possibile registrarla
            coreDataManager.deleteGeofenceZone(zone)

            showAlert(
                title: "Errore",
                message: "Non è stato possibile aggiungere la zona geofence. Verifica di avere i permessi di localizzazione 'Sempre'."
            )
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - UI Updates

    private func updateRadiusLabel() {
        radiusLabel.text = String(format: "Raggio: %.0f m", currentRadius)
    }

    private func resetSelectionUI() {
        selectedCoordinate = nil
        nameTextField.text = ""
        addButton.isEnabled = false
        addButton.backgroundColor = .systemGray3

        // Rimuovi pin
        if let annotation = selectedAnnotation {
            mapView.removeAnnotation(annotation)
            selectedAnnotation = nil
        }

        // Rimuovi overlay temporaneo
        if let tempOverlay = mapView.overlays.last(where: { $0 is TempCircleOverlay }) {
            mapView.removeOverlay(tempOverlay)
        }

        // Reset slider
        radiusSlider.value = Float(Constants.Defaults.geofenceRadiusDefault)
        currentRadius = Constants.Defaults.geofenceRadiusDefault
        updateRadiusLabel()

        // Nascondi tastiera
        view.endEditing(true)
    }

    // MARK: - Alerts

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showAlwaysAuthorizationAlert() {
        let alert = UIAlertController(
            title: "Autorizzazione Richiesta",
            message: "Per utilizzare le zone geofence, è necessario autorizzare l'accesso alla posizione 'Sempre'. Vuoi aprire le Impostazioni?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Impostazioni", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })

        present(alert, animated: true)
    }

    private func showLocationDeniedAlert() {
        let alert = UIAlertController(
            title: "Permesso Negato",
            message: "L'accesso alla posizione è stato negato. Per utilizzare le zone geofence, abilita i servizi di localizzazione dalle Impostazioni.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Impostazioni", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })

        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension GeofenceViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return zones.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cell.geofenceZoneCell, for: indexPath) as! GeofenceZoneCell
        let zone = zones[indexPath.row]
        cell.configure(with: zone)
        cell.delegate = self
        return cell
    }
}

// MARK: - UITableViewDelegate

extension GeofenceViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let zone = zones[indexPath.row]
        let coordinate = CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude)

        // Zoom sulla zona
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: zone.radius * 4,
            longitudinalMeters: zone.radius * 4
        )
        mapView.setRegion(region, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let zone = zones[indexPath.row]

            // Rimuovi la geofence
            geofenceManager.removeGeofence(for: zone)

            // Elimina dal database
            coreDataManager.deleteGeofenceZone(zone)

            // Ricarica le zone
            loadZones()
        }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Elimina"
    }
}

// MARK: - GeofenceZoneCellDelegate

protocol GeofenceZoneCellDelegate: AnyObject {
    func geofenceZoneCell(_ cell: GeofenceZoneCell, didToggleActive isActive: Bool, for zone: GeofenceZone)
}

extension GeofenceViewController: GeofenceZoneCellDelegate {

    func geofenceZoneCell(_ cell: GeofenceZoneCell, didToggleActive isActive: Bool, for zone: GeofenceZone) {
        coreDataManager.setGeofenceZoneActive(zone, isActive: isActive)

        if isActive {
            geofenceManager.addGeofence(for: zone)
        } else {
            geofenceManager.removeGeofence(for: zone)
        }
    }
}

// MARK: - MKMapViewDelegate

extension GeofenceViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circleOverlay = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circleOverlay)

            if overlay is TempCircleOverlay {
                renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.7)
                renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.2)
            } else {
                renderer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.7)
                renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.2)
            }

            renderer.lineWidth = 2
            return renderer
        }

        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Non personalizzare la user location
        if annotation is MKUserLocation {
            return nil
        }

        let identifier = "ZonePin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }

        annotationView?.markerTintColor = .systemBlue

        return annotationView
    }
}

// MARK: - CLLocationManagerDelegate

extension GeofenceViewController: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}

// MARK: - Custom Cell

class GeofenceZoneCell: UITableViewCell {

    weak var delegate: GeofenceZoneCellDelegate?
    private var zone: GeofenceZone?

    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let activeSwitch = UISwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = .secondaryLabel
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailLabel)

        activeSwitch.addTarget(self, action: #selector(switchToggled(_:)), for: .valueChanged)
        activeSwitch.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(activeSwitch)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: activeSwitch.leadingAnchor, constant: -8),

            detailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            detailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detailLabel.trailingAnchor.constraint(equalTo: activeSwitch.leadingAnchor, constant: -8),
            detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            activeSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            activeSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(with zone: GeofenceZone) {
        self.zone = zone
        nameLabel.text = zone.name
        detailLabel.text = "Raggio: \(Int(zone.radius))m"
        activeSwitch.isOn = zone.isActive
    }

    @objc private func switchToggled(_ sender: UISwitch) {
        guard let zone = zone else { return }
        delegate?.geofenceZoneCell(self, didToggleActive: sender.isOn, for: zone)
    }
}

// MARK: - Custom Overlay

class TempCircleOverlay: MKCircle {}
