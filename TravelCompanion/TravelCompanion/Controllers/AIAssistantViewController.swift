import UIKit

/// Controller principale per il tab AI Assistente
/// Mostra 6 pulsanti per le funzionalita AI disponibili
@available(iOS 26.0, *)
final class AIAssistantViewController: UIViewController {

    // MARK: - Properties

    private var activeTrip: Trip?
    private var completedTrips: [Trip] = []

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

    // Welcome Section
    private let welcomeContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        v.layer.cornerRadius = 16
        return v
    }()

    private let welcomeIconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "sparkles")
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Ciao! Sono il tuo assistente di viaggio AI"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.AIAssistant.welcomeLabel
        return label
    }()

    private let welcomeSubtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Posso aiutarti a pianificare viaggi, creare liste, generare diari e molto altro. Scegli una delle opzioni qui sotto per iniziare."
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    // Section Header
    private let sectionHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Cosa posso fare per te?"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }()

    // Starter Buttons Stack
    private let buttonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()

    // Individual Buttons
    private lazy var itineraryButton: UIButton = createStarterButton(
        title: "Genera Itinerario",
        subtitle: "Crea un piano di viaggio personalizzato",
        icon: "map.fill",
        color: .systemBlue,
        accessibilityId: AccessibilityIdentifiers.AIAssistant.itineraryButton
    )

    private lazy var packingListButton: UIButton = createStarterButton(
        title: "Packing List",
        subtitle: "Lista intelligente degli oggetti da portare",
        icon: "bag.fill",
        color: .systemOrange,
        accessibilityId: AccessibilityIdentifiers.AIAssistant.packingListButton
    )

    private lazy var briefingButton: UIButton = createStarterButton(
        title: "Briefing Destinazione",
        subtitle: "Info utili su cultura, lingua e usanze",
        icon: "info.circle.fill",
        color: .systemPurple,
        accessibilityId: AccessibilityIdentifiers.AIAssistant.briefingButton
    )

    private lazy var journalButton: UIButton = createStarterButton(
        title: "Diario di Oggi",
        subtitle: "Genera un'entry del diario di viaggio",
        icon: "book.fill",
        color: .systemGreen,
        accessibilityId: AccessibilityIdentifiers.AIAssistant.journalButton
    )

    private lazy var voiceNoteButton: UIButton = createStarterButton(
        title: "Nota Vocale",
        subtitle: "Registra e struttura una nota",
        icon: "mic.fill",
        color: .systemRed,
        accessibilityId: AccessibilityIdentifiers.AIAssistant.voiceNoteButton
    )

    private lazy var summaryButton: UIButton = createStarterButton(
        title: "Riassunto Viaggio",
        subtitle: "Genera un riassunto del viaggio completato",
        icon: "text.document.fill",
        color: .systemTeal,
        accessibilityId: AccessibilityIdentifiers.AIAssistant.summaryButton
    )

    // Availability Warning
    private let availabilityWarningView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemYellow.withAlphaComponent(0.2)
        v.layer.cornerRadius = 12
        v.isHidden = true
        return v
    }()

    private let availabilityWarningLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 0
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
        checkAvailability()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTrips()
        updateButtonStates()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Welcome container
        contentView.addSubview(welcomeContainer)
        welcomeContainer.addSubview(welcomeIconView)
        welcomeContainer.addSubview(welcomeLabel)
        welcomeContainer.addSubview(welcomeSubtitleLabel)

        // Section header
        contentView.addSubview(sectionHeaderLabel)

        // Buttons
        contentView.addSubview(buttonsStackView)
        buttonsStackView.addArrangedSubview(itineraryButton)
        buttonsStackView.addArrangedSubview(packingListButton)
        buttonsStackView.addArrangedSubview(briefingButton)
        buttonsStackView.addArrangedSubview(journalButton)
        buttonsStackView.addArrangedSubview(voiceNoteButton)
        buttonsStackView.addArrangedSubview(summaryButton)

        // Availability warning
        contentView.addSubview(availabilityWarningView)
        availabilityWarningView.addSubview(availabilityWarningLabel)
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

            // Welcome Container
            welcomeContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            welcomeContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            welcomeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Welcome Icon
            welcomeIconView.topAnchor.constraint(equalTo: welcomeContainer.topAnchor, constant: 16),
            welcomeIconView.leadingAnchor.constraint(equalTo: welcomeContainer.leadingAnchor, constant: 16),
            welcomeIconView.widthAnchor.constraint(equalToConstant: 32),
            welcomeIconView.heightAnchor.constraint(equalToConstant: 32),

            // Welcome Label
            welcomeLabel.topAnchor.constraint(equalTo: welcomeContainer.topAnchor, constant: 16),
            welcomeLabel.leadingAnchor.constraint(equalTo: welcomeIconView.trailingAnchor, constant: 12),
            welcomeLabel.trailingAnchor.constraint(equalTo: welcomeContainer.trailingAnchor, constant: -16),

            // Welcome Subtitle
            welcomeSubtitleLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 8),
            welcomeSubtitleLabel.leadingAnchor.constraint(equalTo: welcomeContainer.leadingAnchor, constant: 16),
            welcomeSubtitleLabel.trailingAnchor.constraint(equalTo: welcomeContainer.trailingAnchor, constant: -16),
            welcomeSubtitleLabel.bottomAnchor.constraint(equalTo: welcomeContainer.bottomAnchor, constant: -16),

            // Availability Warning
            availabilityWarningView.topAnchor.constraint(equalTo: welcomeContainer.bottomAnchor, constant: 12),
            availabilityWarningView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            availabilityWarningView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            availabilityWarningLabel.topAnchor.constraint(equalTo: availabilityWarningView.topAnchor, constant: 12),
            availabilityWarningLabel.leadingAnchor.constraint(equalTo: availabilityWarningView.leadingAnchor, constant: 12),
            availabilityWarningLabel.trailingAnchor.constraint(equalTo: availabilityWarningView.trailingAnchor, constant: -12),
            availabilityWarningLabel.bottomAnchor.constraint(equalTo: availabilityWarningView.bottomAnchor, constant: -12),

            // Section Header
            sectionHeaderLabel.topAnchor.constraint(equalTo: availabilityWarningView.bottomAnchor, constant: 24),
            sectionHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            sectionHeaderLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Buttons Stack
            buttonsStackView.topAnchor.constraint(equalTo: sectionHeaderLabel.bottomAnchor, constant: 16),
            buttonsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            buttonsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            buttonsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])

        // Button heights
        [itineraryButton, packingListButton, briefingButton, journalButton, voiceNoteButton, summaryButton].forEach { button in
            button.heightAnchor.constraint(equalToConstant: 72).isActive = true
        }
    }

    private func setupNavigationBar() {
        title = "AI Assistente"
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    private func setupActions() {
        itineraryButton.addTarget(self, action: #selector(itineraryTapped), for: .touchUpInside)
        packingListButton.addTarget(self, action: #selector(packingListTapped), for: .touchUpInside)
        briefingButton.addTarget(self, action: #selector(briefingTapped), for: .touchUpInside)
        journalButton.addTarget(self, action: #selector(journalTapped), for: .touchUpInside)
        voiceNoteButton.addTarget(self, action: #selector(voiceNoteTapped), for: .touchUpInside)
        summaryButton.addTarget(self, action: #selector(summaryTapped), for: .touchUpInside)
    }

    // MARK: - Data Loading

    private func loadTrips() {
        activeTrip = CoreDataManager.shared.fetchActiveTrip()
        completedTrips = CoreDataManager.shared.fetchTrips(filteredBy: nil).filter { !$0.isActive }
    }

    private func checkAvailability() {
        #if canImport(FoundationModels)
        let result = FoundationModelService.shared.checkAvailability()
        switch result {
        case .available:
            availabilityWarningView.isHidden = true
        case .unavailable(let title, let message, _):
            availabilityWarningView.isHidden = false
            availabilityWarningLabel.text = "\(title): \(message)"
        }
        #else
        // iOS 26 SDK non disponibile - mostra avviso
        availabilityWarningView.isHidden = false
        availabilityWarningLabel.text = "Le funzionalita AI richiedono iOS 26 o successivo."
        #endif
    }

    private func updateButtonStates() {
        // Journal requires active trip
        let hasActiveTrip = activeTrip != nil
        updateButtonEnabled(journalButton, enabled: hasActiveTrip, reason: "Richiede un viaggio attivo")
        updateButtonEnabled(voiceNoteButton, enabled: hasActiveTrip, reason: "Richiede un viaggio attivo")

        // Summary requires completed trip with data
        let hasCompletedTrip = !completedTrips.isEmpty
        updateButtonEnabled(summaryButton, enabled: hasCompletedTrip, reason: "Richiede un viaggio completato")
    }

    private func updateButtonEnabled(_ button: UIButton, enabled: Bool, reason: String) {
        button.isEnabled = enabled
        button.alpha = enabled ? 1.0 : 0.5

        // Update subtitle if disabled
        if !enabled, let stackView = button.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
            if let subtitleLabel = stackView.arrangedSubviews.compactMap({ $0 as? UILabel }).last {
                subtitleLabel.text = reason
                subtitleLabel.textColor = .systemRed
            }
        }
    }

    // MARK: - Button Factory

    private func createStarterButton(
        title: String,
        subtitle: String,
        icon: String,
        color: UIColor,
        accessibilityId: String
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = color.withAlphaComponent(0.1)
        button.layer.cornerRadius = 12
        button.accessibilityIdentifier = accessibilityId

        // Icon
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = color
        iconView.contentMode = .scaleAspectFit

        // Title
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel

        // Text Stack
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.isUserInteractionEnabled = false

        // Arrow
        let arrowView = UIImageView()
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        arrowView.image = UIImage(systemName: "chevron.right")
        arrowView.tintColor = .tertiaryLabel
        arrowView.contentMode = .scaleAspectFit

        button.addSubview(iconView)
        button.addSubview(textStack)
        button.addSubview(arrowView)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: arrowView.leadingAnchor, constant: -8),

            arrowView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            arrowView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            arrowView.widthAnchor.constraint(equalToConstant: 12),
            arrowView.heightAnchor.constraint(equalToConstant: 16)
        ])

        return button
    }

    // MARK: - Actions

    @objc private func itineraryTapped() {
        #if canImport(FoundationModels)
        let generatorVC = ItineraryGeneratorViewController()
        generatorVC.associatedTrip = activeTrip
        let nav = UINavigationController(rootViewController: generatorVC)
        present(nav, animated: true)
        #else
        showNotAvailableAlert()
        #endif
    }

    @objc private func packingListTapped() {
        #if canImport(FoundationModels)
        let packingVC = PackingListViewController()
        packingVC.associatedTrip = activeTrip
        let nav = UINavigationController(rootViewController: packingVC)
        present(nav, animated: true)
        #else
        showNotAvailableAlert()
        #endif
    }

    @objc private func briefingTapped() {
        #if canImport(FoundationModels)
        presentDestinationInput { [weak self] destination in
            let briefingVC = BriefingDetailViewController()
            briefingVC.destination = destination
            briefingVC.associatedTrip = self?.activeTrip
            let nav = UINavigationController(rootViewController: briefingVC)
            self?.present(nav, animated: true)
        }
        #else
        showNotAvailableAlert()
        #endif
    }

    @objc private func journalTapped() {
        #if canImport(FoundationModels)
        guard let trip = activeTrip else {
            showAlert(title: "Viaggio Richiesto", message: "Per generare il diario devi avere un viaggio attivo.")
            return
        }

        let journalVC = JournalGeneratorViewController()
        journalVC.associatedTrip = trip
        let nav = UINavigationController(rootViewController: journalVC)
        present(nav, animated: true)
        #else
        showNotAvailableAlert()
        #endif
    }

    @objc private func voiceNoteTapped() {
        #if canImport(FoundationModels)
        guard let trip = activeTrip else {
            showAlert(title: "Viaggio Richiesto", message: "Per registrare una nota vocale devi avere un viaggio attivo.")
            return
        }

        let voiceVC = VoiceNoteViewController()
        voiceVC.associatedTrip = trip
        let nav = UINavigationController(rootViewController: voiceVC)
        present(nav, animated: true)
        #else
        showNotAvailableAlert()
        #endif
    }

    @objc private func summaryTapped() {
        #if canImport(FoundationModels)
        if completedTrips.isEmpty {
            showAlert(title: "Nessun Viaggio Completato", message: "Completa un viaggio per poter generare il riassunto.")
            return
        }

        if completedTrips.count == 1 {
            presentSummary(for: completedTrips[0])
        } else {
            presentTripSelector { [weak self] selectedTrip in
                self?.presentSummary(for: selectedTrip)
            }
        }
        #else
        showNotAvailableAlert()
        #endif
    }

    // MARK: - Navigation Helpers

    #if canImport(FoundationModels)
    private func presentDestinationInput(completion: @escaping (String) -> Void) {
        // If we have an active trip, use its destination
        if let destination = activeTrip?.destination, !destination.isEmpty {
            completion(destination)
            return
        }

        // Otherwise ask for destination
        let alert = UIAlertController(
            title: "Destinazione",
            message: "Inserisci la destinazione per il briefing",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Es. Roma, Parigi, Tokyo"
            textField.autocapitalizationType = .words
        }

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Continua", style: .default) { _ in
            if let destination = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
               !destination.isEmpty {
                completion(destination)
            }
        })

        present(alert, animated: true)
    }

    private func presentTripSelector(completion: @escaping (Trip) -> Void) {
        let alert = UIAlertController(
            title: "Seleziona Viaggio",
            message: "Scegli il viaggio per cui generare il riassunto",
            preferredStyle: .actionSheet
        )

        for trip in completedTrips {
            let title = trip.destination ?? "Viaggio senza nome"
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                completion(trip)
            })
        }

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))

        // iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = summaryButton
            popover.sourceRect = summaryButton.bounds
        }

        present(alert, animated: true)
    }

    private func presentSummary(for trip: Trip) {
        let summaryVC = TripSummaryViewController()
        summaryVC.associatedTrip = trip

        // Check if summary already exists
        if let existingSummary = CoreDataManager.shared.fetchSummary(for: trip) {
            summaryVC.existingSummary = existingSummary
        }

        let nav = UINavigationController(rootViewController: summaryVC)
        present(nav, animated: true)
    }
    #endif

    private func showNotAvailableAlert() {
        showAlert(title: "Non Disponibile", message: "Le funzionalita AI richiedono iOS 26 o successivo.")
    }

    // MARK: - Alerts

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Fallback for older iOS versions

/// Versione placeholder per iOS < 26
final class AIAssistantFallbackViewController: UIViewController {

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Le funzionalita AI richiedono iOS 26 o successivo."
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "sparkles")
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "AI Assistente"

        view.addSubview(iconView)
        view.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            iconView.widthAnchor.constraint(equalToConstant: 60),
            iconView.heightAnchor.constraint(equalToConstant: 60),

            messageLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
}
