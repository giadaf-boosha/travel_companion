import UIKit

/// Protocollo delegato per la generazione del riassunto
protocol TripSummaryDelegate: AnyObject {
    func didGenerateSummary(_ summary: TripSummary)
    func didCancelSummaryGeneration()
}

/// Controller per la visualizzazione e generazione del riassunto del viaggio
@available(iOS 26.0, *)
final class TripSummaryViewController: UIViewController {

    // MARK: - Delegate

    weak var delegate: TripSummaryDelegate?

    // MARK: - Properties

    /// Trip associato (obbligatorio, deve essere completato)
    var associatedTrip: Trip?

    /// Summary esistente da visualizzare
    var existingSummary: TripSummary?

    private var isGenerating = false
    private var selectedVariant: SummaryVariant = .standard
    private var generatedSummaryData: TripSummaryData?

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        sv.accessibilityIdentifier = AccessibilityIdentifiers.TripSummary.scrollView
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
        label.text = "Riassunto Viaggio"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Un racconto narrativo del tuo viaggio generato dall'AI"
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // Variant Selection
    private let variantLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Stile del riassunto"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    private let variantSegment: UISegmentedControl = {
        let items = ["Standard", "Breve", "Dettagliato", "Emotivo", "Fattuale"]
        let segment = UISegmentedControl(items: items)
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.selectedSegmentIndex = 0
        segment.accessibilityIdentifier = AccessibilityIdentifiers.TripSummary.variantPicker
        return segment
    }()

    // Generate Button
    private let generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Genera Riassunto", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.accessibilityIdentifier = AccessibilityIdentifiers.TripSummary.regenerateButton
        return button
    }()

    // Summary Container
    private let summaryContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 16
        v.isHidden = true
        return v
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

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.accessibilityIdentifier = AccessibilityIdentifiers.TripSummary.titleLabel
        return label
    }()

    private let taglineLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        label.accessibilityIdentifier = AccessibilityIdentifiers.TripSummary.taglineLabel
        return label
    }()

    private let narrativeSeparator: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .separator
        return v
    }()

    private let narrativeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        return label
    }()

    // Highlights Section
    private let highlightsHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Momenti Memorabili"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()

    private let highlightsStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 8
        sv.accessibilityIdentifier = AccessibilityIdentifiers.TripSummary.highlightsSection
        return sv
    }()

    // Stats Section
    private let statsContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        v.layer.cornerRadius = 12
        return v
    }()

    private let statsIcon: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "chart.bar.fill")
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let statsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.TripSummary.statsSection
        return label
    }()

    // Suggestion Section
    private let suggestionContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        v.layer.cornerRadius = 12
        return v
    }()

    private let suggestionIcon: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "lightbulb.fill")
        iv.tintColor = .systemGreen
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let suggestionHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Prossimo Viaggio?"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .systemGreen
        return label
    }()

    private let suggestionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.TripSummary.suggestionSection
        return label
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
        indicator.accessibilityIdentifier = AccessibilityIdentifiers.TripSummary.loadingIndicator
        return indicator
    }()

    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Generazione riassunto in corso..."
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
        checkPrerequisites()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(variantLabel)
        contentView.addSubview(variantSegment)
        contentView.addSubview(generateButton)
        contentView.addSubview(summaryContainer)

        // Summary Container
        summaryContainer.addSubview(aiBadgeLabel)
        summaryContainer.addSubview(titleLabel)
        summaryContainer.addSubview(taglineLabel)
        summaryContainer.addSubview(narrativeSeparator)
        summaryContainer.addSubview(narrativeLabel)
        summaryContainer.addSubview(highlightsHeaderLabel)
        summaryContainer.addSubview(highlightsStackView)
        summaryContainer.addSubview(statsContainer)
        summaryContainer.addSubview(suggestionContainer)

        // Stats Container
        statsContainer.addSubview(statsIcon)
        statsContainer.addSubview(statsLabel)

        // Suggestion Container
        suggestionContainer.addSubview(suggestionIcon)
        suggestionContainer.addSubview(suggestionHeaderLabel)
        suggestionContainer.addSubview(suggestionLabel)

        // Loading
        view.addSubview(loadingContainer)
        loadingContainer.addSubview(loadingIndicator)
        loadingContainer.addSubview(loadingLabel)
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

            // Variant Label
            variantLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            variantLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            // Variant Segment
            variantSegment.topAnchor.constraint(equalTo: variantLabel.bottomAnchor, constant: 8),
            variantSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            variantSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Generate Button
            generateButton.topAnchor.constraint(equalTo: variantSegment.bottomAnchor, constant: 24),
            generateButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            generateButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            generateButton.heightAnchor.constraint(equalToConstant: 50),

            // Summary Container
            summaryContainer.topAnchor.constraint(equalTo: generateButton.bottomAnchor, constant: 24),
            summaryContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            summaryContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            summaryContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            // AI Badge
            aiBadgeLabel.topAnchor.constraint(equalTo: summaryContainer.topAnchor, constant: 16),
            aiBadgeLabel.centerXAnchor.constraint(equalTo: summaryContainer.centerXAnchor),
            aiBadgeLabel.widthAnchor.constraint(equalToConstant: 110),
            aiBadgeLabel.heightAnchor.constraint(equalToConstant: 24),

            // Title
            titleLabel.topAnchor.constraint(equalTo: aiBadgeLabel.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: summaryContainer.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: summaryContainer.trailingAnchor, constant: -16),

            // Tagline
            taglineLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            taglineLabel.leadingAnchor.constraint(equalTo: summaryContainer.leadingAnchor, constant: 16),
            taglineLabel.trailingAnchor.constraint(equalTo: summaryContainer.trailingAnchor, constant: -16),

            // Separator
            narrativeSeparator.topAnchor.constraint(equalTo: taglineLabel.bottomAnchor, constant: 16),
            narrativeSeparator.leadingAnchor.constraint(equalTo: summaryContainer.leadingAnchor, constant: 32),
            narrativeSeparator.trailingAnchor.constraint(equalTo: summaryContainer.trailingAnchor, constant: -32),
            narrativeSeparator.heightAnchor.constraint(equalToConstant: 1),

            // Narrative
            narrativeLabel.topAnchor.constraint(equalTo: narrativeSeparator.bottomAnchor, constant: 16),
            narrativeLabel.leadingAnchor.constraint(equalTo: summaryContainer.leadingAnchor, constant: 16),
            narrativeLabel.trailingAnchor.constraint(equalTo: summaryContainer.trailingAnchor, constant: -16),

            // Highlights Header
            highlightsHeaderLabel.topAnchor.constraint(equalTo: narrativeLabel.bottomAnchor, constant: 24),
            highlightsHeaderLabel.leadingAnchor.constraint(equalTo: summaryContainer.leadingAnchor, constant: 16),

            // Highlights Stack
            highlightsStackView.topAnchor.constraint(equalTo: highlightsHeaderLabel.bottomAnchor, constant: 12),
            highlightsStackView.leadingAnchor.constraint(equalTo: summaryContainer.leadingAnchor, constant: 16),
            highlightsStackView.trailingAnchor.constraint(equalTo: summaryContainer.trailingAnchor, constant: -16),

            // Stats Container
            statsContainer.topAnchor.constraint(equalTo: highlightsStackView.bottomAnchor, constant: 20),
            statsContainer.leadingAnchor.constraint(equalTo: summaryContainer.leadingAnchor, constant: 16),
            statsContainer.trailingAnchor.constraint(equalTo: summaryContainer.trailingAnchor, constant: -16),

            statsIcon.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 12),
            statsIcon.topAnchor.constraint(equalTo: statsContainer.topAnchor, constant: 12),
            statsIcon.widthAnchor.constraint(equalToConstant: 24),
            statsIcon.heightAnchor.constraint(equalToConstant: 24),

            statsLabel.leadingAnchor.constraint(equalTo: statsIcon.trailingAnchor, constant: 12),
            statsLabel.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor, constant: -12),
            statsLabel.topAnchor.constraint(equalTo: statsContainer.topAnchor, constant: 12),
            statsLabel.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: -12),

            // Suggestion Container
            suggestionContainer.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 16),
            suggestionContainer.leadingAnchor.constraint(equalTo: summaryContainer.leadingAnchor, constant: 16),
            suggestionContainer.trailingAnchor.constraint(equalTo: summaryContainer.trailingAnchor, constant: -16),
            suggestionContainer.bottomAnchor.constraint(equalTo: summaryContainer.bottomAnchor, constant: -16),

            suggestionIcon.leadingAnchor.constraint(equalTo: suggestionContainer.leadingAnchor, constant: 12),
            suggestionIcon.topAnchor.constraint(equalTo: suggestionContainer.topAnchor, constant: 12),
            suggestionIcon.widthAnchor.constraint(equalToConstant: 24),
            suggestionIcon.heightAnchor.constraint(equalToConstant: 24),

            suggestionHeaderLabel.leadingAnchor.constraint(equalTo: suggestionIcon.trailingAnchor, constant: 8),
            suggestionHeaderLabel.centerYAnchor.constraint(equalTo: suggestionIcon.centerYAnchor),

            suggestionLabel.topAnchor.constraint(equalTo: suggestionIcon.bottomAnchor, constant: 8),
            suggestionLabel.leadingAnchor.constraint(equalTo: suggestionContainer.leadingAnchor, constant: 12),
            suggestionLabel.trailingAnchor.constraint(equalTo: suggestionContainer.trailingAnchor, constant: -12),
            suggestionLabel.bottomAnchor.constraint(equalTo: suggestionContainer.bottomAnchor, constant: -12),

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
        title = "Riassunto AI"

        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.leftBarButtonItem = cancelButton
    }

    private func setupActions() {
        variantSegment.addTarget(self, action: #selector(variantChanged), for: .valueChanged)
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
    }

    private func checkPrerequisites() {
        guard let trip = associatedTrip else {
            showPrerequisiteError(message: "Seleziona un viaggio per generare il riassunto.")
            return
        }

        // Check if trip is completed (not active)
        if trip.isActive {
            showPrerequisiteError(message: "Il viaggio deve essere completato per generare il riassunto.")
            return
        }

        // Check if trip has data
        let photos = CoreDataManager.shared.fetchPhotos(for: trip)
        let notes = CoreDataManager.shared.fetchNotes(for: trip)

        if photos.isEmpty && notes.isEmpty && trip.totalDistance == 0 {
            showPrerequisiteError(message: "Il viaggio non contiene dati sufficienti per generare un riassunto.")
            return
        }

        // Check if existing summary
        if let existingSummary = existingSummary ?? CoreDataManager.shared.fetchSummary(for: trip) {
            displayExistingSummary(existingSummary)
        }
    }

    private func displayExistingSummary(_ summary: TripSummary) {
        let summaryData = TripSummaryData(
            title: summary.title ?? "Il tuo viaggio",
            tagline: summary.tagline ?? "",
            narrative: summary.narrative ?? "",
            highlights: (summary.highlights as? [String]) ?? [],
            statsNarrative: summary.statsNarrative ?? "",
            nextTripSuggestion: summary.nextTripSuggestion ?? ""
        )

        displaySummary(summaryData)
        generateButton.setTitle("Rigenera Riassunto", for: .normal)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.didCancelSummaryGeneration()
        dismiss(animated: true)
    }

    @objc private func variantChanged() {
        selectedVariant = SummaryVariant.allCases[variantSegment.selectedSegmentIndex]
    }

    @objc private func generateTapped() {
        guard let trip = associatedTrip else {
            showAlert(title: "Errore", message: "Nessun viaggio selezionato")
            return
        }

        generateSummary(for: trip)
    }

    // MARK: - Private Methods

    private func generateSummary(for trip: Trip) {
        // Check availability
        let availabilityResult = FoundationModelService.shared.checkAvailability()
        switch availabilityResult {
        case .available:
            break
        case .unavailable(let title, let message, let action):
            showUnavailableAlert(title: title, message: message, action: action)
            return
        }

        // Gather trip data
        let photos = CoreDataManager.shared.fetchPhotos(for: trip)
        let notes = CoreDataManager.shared.fetchNotes(for: trip)

        // Calculate duration
        var duration = 1
        if let startDate = trip.startDate, let endDate = trip.endDate {
            duration = max(1, (Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1)
        }

        // Extract highlights from notes
        var highlights: [String] = []
        for note in notes.prefix(5) {
            if let content = note.content, !content.isEmpty {
                highlights.append(String(content.prefix(100)))
            }
        }

        showLoading(true)
        isGenerating = true

        #if canImport(FoundationModels)
        Task {
            do {
                let summary = try await FoundationModelService.shared.generateTripSummary(
                    destination: trip.destination ?? "Viaggio",
                    duration: duration,
                    photoCount: photos.count,
                    noteCount: notes.count,
                    totalDistance: trip.totalDistance,
                    highlights: highlights,
                    variant: selectedVariant
                )

                // Convert to Data structure
                let summaryData = TripSummaryData(
                    title: summary.title,
                    tagline: summary.tagline,
                    narrative: summary.narrative,
                    highlights: summary.highlights,
                    statsNarrative: summary.statsNarrative,
                    nextTripSuggestion: summary.nextTripSuggestion
                )

                // Save to Core Data
                let savedSummary = CoreDataManager.shared.createTripSummary(
                    title: summary.title,
                    tagline: summary.tagline,
                    narrative: summary.narrative,
                    highlights: summary.highlights,
                    statsNarrative: summary.statsNarrative,
                    nextTripSuggestion: summary.nextTripSuggestion,
                    variant: selectedVariant.rawValue,
                    for: trip
                )

                await MainActor.run {
                    self.showLoading(false)
                    self.isGenerating = false
                    self.displaySummary(summaryData)
                    self.delegate?.didGenerateSummary(savedSummary)
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

    private func displaySummary(_ summaryData: TripSummaryData) {
        generatedSummaryData = summaryData

        titleLabel.text = summaryData.title
        taglineLabel.text = summaryData.tagline
        narrativeLabel.text = summaryData.narrative
        statsLabel.text = summaryData.statsNarrative
        suggestionLabel.text = summaryData.nextTripSuggestion

        // Clear and populate highlights
        highlightsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, highlight) in summaryData.highlights.enumerated() {
            let highlightView = createHighlightView(index: index + 1, text: highlight)
            highlightsStackView.addArrangedSubview(highlightView)
        }

        summaryContainer.isHidden = false
        generateButton.setTitle("Rigenera Riassunto", for: .normal)

        // Scroll to summary
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height - self.scrollView.bounds.size.height + 40)
            if bottomOffset.y > 0 {
                self.scrollView.setContentOffset(bottomOffset, animated: true)
            }
        }
    }

    private func createHighlightView(index: Int, text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let numberLabel = UILabel()
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.text = "\(index)."
        numberLabel.font = .systemFont(ofSize: 16, weight: .bold)
        numberLabel.textColor = .systemBlue

        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 15, weight: .regular)
        textLabel.numberOfLines = 0

        container.addSubview(numberLabel)
        container.addSubview(textLabel)

        NSLayoutConstraint.activate([
            numberLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            numberLabel.topAnchor.constraint(equalTo: container.topAnchor),
            numberLabel.widthAnchor.constraint(equalToConstant: 24),

            textLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 8),
            textLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textLabel.topAnchor.constraint(equalTo: container.topAnchor),
            textLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func showLoading(_ show: Bool) {
        loadingContainer.isHidden = !show
        if show {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        generateButton.isEnabled = !show
        variantSegment.isEnabled = !show
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

    private func showPrerequisiteError(message: String) {
        generateButton.isEnabled = false
        generateButton.alpha = 0.5
        variantSegment.isEnabled = false

        let alert = UIAlertController(
            title: "Prerequisiti Non Soddisfatti",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
