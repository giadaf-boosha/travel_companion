import UIKit
import CoreLocation

/// Protocollo delegato per la generazione del journal
protocol JournalGeneratorDelegate: AnyObject {
    func didGenerateJournal(_ note: Note)
    func didCancelJournalGeneration()
}

/// Controller per la generazione del diario di viaggio giornaliero
@available(iOS 26.0, *)
final class JournalGeneratorViewController: UIViewController {

    // MARK: - Delegate

    weak var delegate: JournalGeneratorDelegate?

    // MARK: - Properties

    /// Trip associato (obbligatorio)
    var associatedTrip: Trip?

    private var isGenerating = false
    private var selectedDate: Date?
    private var availableDays: [Date] = []
    private var generatedJournalData: JournalEntryData?

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Diario di Viaggio"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Genera un racconto della tua giornata basato su foto, note e percorsi"
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // Day Selection
    private let daySelectionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Seleziona giornata"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    private let dayPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.accessibilityIdentifier = AccessibilityIdentifiers.JournalGenerator.dayPicker
        return picker
    }()

    // Empty State
    private let emptyStateView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private let emptyStateIcon: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "text.badge.xmark")
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Nessun dato disponibile per questa giornata.\nAggiungi foto o note per generare il diario."
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // Generate Button
    private let generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Genera Diario", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.accessibilityIdentifier = AccessibilityIdentifiers.JournalGenerator.generateButton
        return button
    }()

    // Preview Section
    private let previewContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 16
        v.isHidden = true
        return v
    }()

    private let previewTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.numberOfLines = 0
        return label
    }()

    private let previewDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let previewNarrativeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        return label
    }()

    private let previewHighlightContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.15)
        v.layer.cornerRadius = 10
        return v
    }()

    private let previewHighlightIcon: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "star.fill")
        iv.tintColor = .systemYellow
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let previewHighlightLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.numberOfLines = 0
        return label
    }()

    private let previewStatsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let aiBadgeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Generato con AI"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.backgroundColor = UIColor.systemIndigo
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        return label
    }()

    // Save Button
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Salva nel Viaggio", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.isHidden = true
        button.accessibilityIdentifier = AccessibilityIdentifiers.JournalGenerator.saveButton
        return button
    }()

    // Loading
    private let loadingContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        v.isHidden = true
        return v
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.accessibilityIdentifier = AccessibilityIdentifiers.JournalGenerator.loadingIndicator
        return indicator
    }()

    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Generazione diario in corso..."
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
        setupActions()
        loadAvailableDays()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(daySelectionLabel)
        contentView.addSubview(dayPicker)
        contentView.addSubview(emptyStateView)
        contentView.addSubview(generateButton)
        contentView.addSubview(previewContainer)
        contentView.addSubview(saveButton)

        // Empty State
        emptyStateView.addSubview(emptyStateIcon)
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateView.accessibilityIdentifier = AccessibilityIdentifiers.JournalGenerator.emptyStateView

        // Preview Container
        previewContainer.addSubview(aiBadgeLabel)
        previewContainer.addSubview(previewTitleLabel)
        previewContainer.addSubview(previewDateLabel)
        previewContainer.addSubview(previewNarrativeLabel)
        previewContainer.addSubview(previewHighlightContainer)
        previewContainer.addSubview(previewStatsLabel)
        previewContainer.accessibilityIdentifier = AccessibilityIdentifiers.JournalGenerator.previewView

        previewHighlightContainer.addSubview(previewHighlightIcon)
        previewHighlightContainer.addSubview(previewHighlightLabel)

        // Loading
        view.addSubview(loadingContainer)
        loadingContainer.addSubview(loadingIndicator)
        loadingContainer.addSubview(loadingLabel)

        // Setup picker
        dayPicker.delegate = self
        dayPicker.dataSource = self
    }

    private func setupConstraints() {
        let padding: CGFloat = 20

        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Header
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Day Selection Label
            daySelectionLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            daySelectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            // Day Picker
            dayPicker.topAnchor.constraint(equalTo: daySelectionLabel.bottomAnchor, constant: 8),
            dayPicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            dayPicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            dayPicker.heightAnchor.constraint(equalToConstant: 150),

            // Empty State
            emptyStateView.topAnchor.constraint(equalTo: dayPicker.bottomAnchor, constant: 16),
            emptyStateView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            emptyStateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            emptyStateIcon.topAnchor.constraint(equalTo: emptyStateView.topAnchor, constant: 16),
            emptyStateIcon.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateIcon.widthAnchor.constraint(equalToConstant: 48),
            emptyStateIcon.heightAnchor.constraint(equalToConstant: 48),

            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateIcon.bottomAnchor, constant: 12),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 16),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -16),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor, constant: -16),

            // Generate Button
            generateButton.topAnchor.constraint(equalTo: dayPicker.bottomAnchor, constant: 24),
            generateButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            generateButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            generateButton.heightAnchor.constraint(equalToConstant: 50),

            // Preview Container
            previewContainer.topAnchor.constraint(equalTo: generateButton.bottomAnchor, constant: 24),
            previewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            previewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // AI Badge
            aiBadgeLabel.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 16),
            aiBadgeLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 16),
            aiBadgeLabel.widthAnchor.constraint(equalToConstant: 110),
            aiBadgeLabel.heightAnchor.constraint(equalToConstant: 24),

            // Preview Title
            previewTitleLabel.topAnchor.constraint(equalTo: aiBadgeLabel.bottomAnchor, constant: 12),
            previewTitleLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 16),
            previewTitleLabel.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -16),

            // Preview Date
            previewDateLabel.topAnchor.constraint(equalTo: previewTitleLabel.bottomAnchor, constant: 4),
            previewDateLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 16),

            // Preview Narrative
            previewNarrativeLabel.topAnchor.constraint(equalTo: previewDateLabel.bottomAnchor, constant: 16),
            previewNarrativeLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 16),
            previewNarrativeLabel.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -16),

            // Highlight Container
            previewHighlightContainer.topAnchor.constraint(equalTo: previewNarrativeLabel.bottomAnchor, constant: 16),
            previewHighlightContainer.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 16),
            previewHighlightContainer.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -16),

            previewHighlightIcon.leadingAnchor.constraint(equalTo: previewHighlightContainer.leadingAnchor, constant: 12),
            previewHighlightIcon.topAnchor.constraint(equalTo: previewHighlightContainer.topAnchor, constant: 12),
            previewHighlightIcon.widthAnchor.constraint(equalToConstant: 20),
            previewHighlightIcon.heightAnchor.constraint(equalToConstant: 20),

            previewHighlightLabel.leadingAnchor.constraint(equalTo: previewHighlightIcon.trailingAnchor, constant: 8),
            previewHighlightLabel.trailingAnchor.constraint(equalTo: previewHighlightContainer.trailingAnchor, constant: -12),
            previewHighlightLabel.topAnchor.constraint(equalTo: previewHighlightContainer.topAnchor, constant: 10),
            previewHighlightLabel.bottomAnchor.constraint(equalTo: previewHighlightContainer.bottomAnchor, constant: -10),

            // Stats Label
            previewStatsLabel.topAnchor.constraint(equalTo: previewHighlightContainer.bottomAnchor, constant: 12),
            previewStatsLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 16),
            previewStatsLabel.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -16),
            previewStatsLabel.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -16),

            // Save Button
            saveButton.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            // Loading Container
            loadingContainer.topAnchor.constraint(equalTo: view.topAnchor),
            loadingContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loadingContainer.centerYAnchor, constant: -20),

            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor)
        ])
    }

    private func setupNavigationBar() {
        title = "Diario AI"

        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.leftBarButtonItem = cancelButton
    }

    private func setupActions() {
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    private func loadAvailableDays() {
        guard let trip = associatedTrip, let startDate = trip.startDate else {
            showNoTripError()
            return
        }

        let calendar = Calendar.current
        let endDate = trip.endDate ?? Date()

        // Genera i giorni disponibili dal startDate fino a endDate o oggi
        var currentDate = startDate
        let today = calendar.startOfDay(for: Date())

        while currentDate <= endDate && currentDate <= today {
            availableDays.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        if availableDays.isEmpty {
            showNoDataError()
        } else {
            selectedDate = availableDays.first
            dayPicker.reloadAllComponents()
            checkDataForSelectedDay()
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.didCancelJournalGeneration()
        dismiss(animated: true)
    }

    @objc private func generateTapped() {
        guard let trip = associatedTrip, let date = selectedDate else {
            showAlert(title: "Errore", message: "Seleziona una giornata valida")
            return
        }

        // Gather trip day data
        let tripDayData = gatherTripDayData(for: trip, on: date)

        guard tripDayData.hasData else {
            showAlert(title: "Nessun Dato", message: "Non ci sono foto, note o percorsi per questa giornata.")
            return
        }

        // Check if journal already exists for this day
        if CoreDataManager.shared.hasJournalEntry(for: trip, date: date) {
            showJournalExistsAlert()
            return
        }

        generateJournal(tripDayData: tripDayData)
    }

    @objc private func saveTapped() {
        guard let trip = associatedTrip,
              let date = selectedDate,
              let journalData = generatedJournalData else {
            return
        }

        // Save to Core Data
        let note = CoreDataManager.shared.createJournalEntry(
            for: trip,
            title: journalData.title,
            narrative: journalData.narrative,
            highlight: journalData.highlight,
            statsNarrative: journalData.statsNarrative,
            date: date
        )

        delegate?.didGenerateJournal(note)

        // Show success and dismiss
        let alert = UIAlertController(
            title: "Salvato",
            message: "Il diario e stato salvato nel viaggio.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    // MARK: - Private Methods

    private func gatherTripDayData(for trip: Trip, on date: Date) -> TripDayData {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        // Get photos for the day
        let allPhotos = CoreDataManager.shared.fetchPhotos(for: trip)
        let dayPhotos = allPhotos.filter { photo in
            guard let timestamp = photo.timestamp else { return false }
            return timestamp >= startOfDay && timestamp < endOfDay
        }

        // Get notes for the day
        let allNotes = CoreDataManager.shared.fetchNotes(for: trip)
        let dayNotes = allNotes.filter { note in
            guard let timestamp = note.timestamp else { return false }
            return timestamp >= startOfDay && timestamp < endOfDay && !(note.isJournalEntry)
        }

        // Get routes for the day and calculate distance
        let allRoutes = CoreDataManager.shared.fetchRoute(for: trip)
        let dayRoutes = allRoutes.filter { route in
            guard let timestamp = route.timestamp else { return false }
            return timestamp >= startOfDay && timestamp < endOfDay
        }

        var dayDistance: Double = 0
        if dayRoutes.count >= 2 {
            for i in 1..<dayRoutes.count {
                let prevLocation = CLLocation(latitude: dayRoutes[i-1].latitude, longitude: dayRoutes[i-1].longitude)
                let currentLocation = CLLocation(latitude: dayRoutes[i].latitude, longitude: dayRoutes[i].longitude)
                dayDistance += currentLocation.distance(from: prevLocation)
            }
        }

        // Extract note contents
        let noteContents = dayNotes.compactMap { $0.content }

        // Extract places (from photo captions or note content)
        var places: [String] = []
        for photo in dayPhotos {
            if let caption = photo.caption, !caption.isEmpty {
                places.append(caption)
            }
        }

        return TripDayData(
            tripId: trip.id ?? UUID(),
            date: date,
            photoCount: dayPhotos.count,
            noteContents: noteContents,
            totalDistance: dayDistance,
            placesVisited: places
        )
    }

    private func generateJournal(tripDayData: TripDayData) {
        // Check availability
        let availabilityResult = FoundationModelService.shared.checkAvailability()
        switch availabilityResult {
        case .available:
            break
        case .unavailable(let title, let message, let action):
            showUnavailableAlert(title: title, message: message, action: action)
            return
        }

        showLoading(true)
        isGenerating = true

        #if canImport(FoundationModels)
        Task {
            do {
                let journalEntry = try await FoundationModelService.shared.generateJournalEntry(tripData: tripDayData)

                // Convert to Data structure for UI display
                let journalData = JournalEntryData(
                    title: journalEntry.title,
                    date: journalEntry.date,
                    narrative: journalEntry.narrative,
                    highlight: journalEntry.highlight,
                    statsNarrative: journalEntry.statsNarrative
                )

                await MainActor.run {
                    self.showLoading(false)
                    self.isGenerating = false
                    self.displayJournalPreview(journalData)
                }
            } catch {
                await MainActor.run {
                    self.showLoading(false)
                    self.isGenerating = false
                    self.handleGenerationError(error)
                }
            }
        }
        #else
        showLoading(false)
        isGenerating = false
        showAlert(title: "Non Disponibile", message: "Le funzionalita AI richiedono iOS 26 o successivo.")
        #endif
    }

    private func displayJournalPreview(_ journalData: JournalEntryData) {
        generatedJournalData = journalData

        previewTitleLabel.text = journalData.title
        previewDateLabel.text = journalData.date
        previewNarrativeLabel.text = journalData.narrative
        previewHighlightLabel.text = journalData.highlight
        previewStatsLabel.text = journalData.statsNarrative

        previewContainer.isHidden = false
        saveButton.isHidden = false
        generateButton.setTitle("Rigenera", for: .normal)

        // Scroll to preview
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.bounds.size.height + 40)
            if bottomOffset.y > 0 {
                self.scrollView.setContentOffset(bottomOffset, animated: true)
            }
        }
    }

    private func checkDataForSelectedDay() {
        guard let trip = associatedTrip, let date = selectedDate else { return }

        let tripDayData = gatherTripDayData(for: trip, on: date)

        emptyStateView.isHidden = tripDayData.hasData
        generateButton.isEnabled = tripDayData.hasData
        generateButton.alpha = tripDayData.hasData ? 1.0 : 0.5
    }

    private func showLoading(_ show: Bool) {
        loadingContainer.isHidden = !show
        if show {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        generateButton.isEnabled = !show
        saveButton.isEnabled = !show
        navigationItem.leftBarButtonItem?.isEnabled = !show
    }

    private func handleGenerationError(_ error: Error) {
        let userFacingError = FoundationModelService.shared.handleGenerationError(error)

        let alert = UIAlertController(
            title: userFacingError.title,
            message: userFacingError.message,
            preferredStyle: .alert
        )

        if userFacingError.canRetry {
            alert.addAction(UIAlertAction(title: "Riprova", style: .default) { [weak self] _ in
                self?.generateTapped()
            })
        }

        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func showUnavailableAlert(title: String, message: String, action: AvailabilityAction?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if let action = action {
            switch action {
            case .openSettings:
                alert.addAction(UIAlertAction(title: "Apri Impostazioni", style: .default) { _ in
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                })
            case .retry:
                alert.addAction(UIAlertAction(title: "Riprova", style: .default) { [weak self] _ in
                    self?.generateTapped()
                })
            }
        }

        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func showJournalExistsAlert() {
        let alert = UIAlertController(
            title: "Diario Esistente",
            message: "Esiste gia un diario per questa giornata. Vuoi sovrascriverlo?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Sovrascrivi", style: .destructive) { [weak self] _ in
            guard let self = self,
                  let trip = self.associatedTrip,
                  let date = self.selectedDate else { return }

            let tripDayData = self.gatherTripDayData(for: trip, on: date)
            self.generateJournal(tripDayData: tripDayData)
        })

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        present(alert, animated: true)
    }

    private func showNoTripError() {
        let alert = UIAlertController(
            title: "Nessun Viaggio",
            message: "Seleziona un viaggio per generare il diario.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    private func showNoDataError() {
        emptyStateView.isHidden = false
        generateButton.isEnabled = false
        generateButton.alpha = 0.5
        dayPicker.isUserInteractionEnabled = false
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIPickerViewDelegate & DataSource

@available(iOS 26.0, *)
extension JournalGeneratorViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return availableDays.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let date = availableDays[row]
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard row < availableDays.count else { return }
        selectedDate = availableDays[row]
        checkDataForSelectedDay()

        // Hide preview when changing day
        if !previewContainer.isHidden {
            previewContainer.isHidden = true
            saveButton.isHidden = true
            generateButton.setTitle("Genera Diario", for: .normal)
            generatedJournalData = nil
        }
    }
}
