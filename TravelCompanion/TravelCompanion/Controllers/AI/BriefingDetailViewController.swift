import UIKit

/// Controller per visualizzare il briefing di destinazione generato dall'AI
@available(iOS 26.0, *)
final class BriefingDetailViewController: UIViewController {

    // MARK: - Properties

    /// Trip associato
    var associatedTrip: Trip?

    /// Briefing salvato in Core Data
    var savedBriefing: TripBriefing?

    /// Destinazione per la generazione
    var destination: String?

    /// Briefing generato (convertito in formato Data)
    private var generatedBriefingData: TripBriefingData?

    private var isGenerating = false

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        sv.accessibilityIdentifier = AccessibilityIdentifiers.BriefingDetail.scrollView
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let headerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBlue
        v.layer.cornerRadius = 16
        return v
    }()

    private let destinationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.accessibilityIdentifier = AccessibilityIdentifiers.BriefingDetail.destinationLabel
        return label
    }()

    private let aiBadge: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        v.layer.cornerRadius = 8
        return v
    }()

    private let aiBadgeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Briefing AI"
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        return label
    }()

    private let mainStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 20
        return sv
    }()

    private let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Le informazioni sono generate dall'AI e potrebbero non essere aggiornate. Verifica sempre i dettagli importanti (visti, restrizioni sanitarie, ecc.) prima del viaggio."
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.BriefingDetail.aiDisclaimer
        return label
    }()

    private let loadingContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        v.isHidden = true
        return v
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.accessibilityIdentifier = AccessibilityIdentifiers.BriefingDetail.loadingIndicator
        return indicator
    }()

    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Generazione briefing in corso..."
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let emptyStateView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Nessun briefing disponibile.\nTocca 'Genera' per creare un briefing."
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Genera Briefing", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
        loadData()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerView)
        headerView.addSubview(destinationLabel)
        headerView.addSubview(aiBadge)
        aiBadge.addSubview(aiBadgeLabel)

        contentView.addSubview(mainStackView)
        contentView.addSubview(disclaimerLabel)

        view.addSubview(loadingContainer)
        loadingContainer.addSubview(loadingIndicator)
        loadingContainer.addSubview(loadingLabel)

        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateView.addSubview(generateButton)

        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
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

            // Header View
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            destinationLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 24),
            destinationLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            destinationLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),

            aiBadge.topAnchor.constraint(equalTo: destinationLabel.bottomAnchor, constant: 12),
            aiBadge.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            aiBadge.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),

            aiBadgeLabel.topAnchor.constraint(equalTo: aiBadge.topAnchor, constant: 6),
            aiBadgeLabel.leadingAnchor.constraint(equalTo: aiBadge.leadingAnchor, constant: 12),
            aiBadgeLabel.trailingAnchor.constraint(equalTo: aiBadge.trailingAnchor, constant: -12),
            aiBadgeLabel.bottomAnchor.constraint(equalTo: aiBadge.bottomAnchor, constant: -6),

            // Main Stack
            mainStackView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Disclaimer
            disclaimerLabel.topAnchor.constraint(equalTo: mainStackView.bottomAnchor, constant: 32),
            disclaimerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            disclaimerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            disclaimerLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),

            // Loading Container
            loadingContainer.topAnchor.constraint(equalTo: view.topAnchor),
            loadingContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loadingContainer.centerYAnchor, constant: -20),

            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor),

            // Empty State
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),

            generateButton.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 24),
            generateButton.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            generateButton.widthAnchor.constraint(equalToConstant: 200),
            generateButton.heightAnchor.constraint(equalToConstant: 50),
            generateButton.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }

    private func setupNavigationBar() {
        title = "Briefing Destinazione"

        let regenerateButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(regenerateTapped)
        )
        regenerateButton.accessibilityIdentifier = AccessibilityIdentifiers.BriefingDetail.regenerateButton
        navigationItem.rightBarButtonItem = regenerateButton
    }

    // MARK: - Data Loading

    private func loadData() {
        if let saved = savedBriefing {
            populateFromSaved(saved)
            showContent(true)
        } else if let trip = associatedTrip {
            // Prova a caricare briefing esistente
            if let existingBriefing = CoreDataManager.shared.fetchBriefing(for: trip) {
                savedBriefing = existingBriefing
                populateFromSaved(existingBriefing)
                showContent(true)
            } else if let dest = trip.destination {
                destination = dest
                generateBriefing()
            } else {
                showContent(false)
            }
        } else if let _ = destination {
            generateBriefing()
        } else {
            showContent(false)
        }
    }

    private func populateFromSaved(_ briefing: TripBriefing) {
        destinationLabel.text = briefing.destination

        // Clear existing content
        mainStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Quick Facts
        if let quickFactsData = briefing.quickFactsJSON as? Data {
            do {
                let quickFacts = try JSONDecoder().decode(QuickFactsData.self, from: quickFactsData)
                let quickFactsCard = createQuickFactsCard(quickFacts)
                mainStackView.addArrangedSubview(quickFactsCard)
            } catch {
                #if DEBUG
                print("Error decoding quick facts: \(error)")
                #endif
            }
        }

        // Cultural Tips
        if let tips = briefing.culturalTips as? [String], !tips.isEmpty {
            let section = createSection(
                title: "Consigli Culturali",
                icon: "person.2.fill",
                items: tips,
                identifier: AccessibilityIdentifiers.BriefingDetail.culturalTipsSection
            )
            mainStackView.addArrangedSubview(section)
        }

        // Useful Phrases
        if let phrasesData = briefing.usefulPhrasesJSON as? Data {
            do {
                let phrases = try JSONDecoder().decode([LocalPhraseData].self, from: phrasesData)
                let phrasesSection = createPhrasesSection(phrases)
                mainStackView.addArrangedSubview(phrasesSection)
            } catch {
                #if DEBUG
                print("Error decoding phrases: \(error)")
                #endif
            }
        }

        // Climate Info
        if let climate = briefing.climateInfo, !climate.isEmpty {
            let climateCard = createInfoCard(
                title: "Clima",
                icon: "cloud.sun.fill",
                text: climate,
                identifier: AccessibilityIdentifiers.BriefingDetail.climateSection
            )
            mainStackView.addArrangedSubview(climateCard)
        }

        // Food Culture
        if let food = briefing.foodCulture as? [String], !food.isEmpty {
            let section = createSection(
                title: "Cucina Locale",
                icon: "fork.knife",
                items: food,
                identifier: AccessibilityIdentifiers.BriefingDetail.foodSection
            )
            mainStackView.addArrangedSubview(section)
        }

        // Safety Notes
        if let safety = briefing.safetyNotes as? [String], !safety.isEmpty {
            let section = createSection(
                title: "Note sulla Sicurezza",
                icon: "shield.fill",
                items: safety,
                identifier: AccessibilityIdentifiers.BriefingDetail.safetySection
            )
            mainStackView.addArrangedSubview(section)
        }
    }

    private func populateFromData(_ briefing: TripBriefingData) {
        destinationLabel.text = briefing.destination

        // Clear existing content
        mainStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Quick Facts
        let quickFactsCard = createQuickFactsCard(briefing.quickFacts)
        mainStackView.addArrangedSubview(quickFactsCard)

        // Cultural Tips
        if !briefing.culturalTips.isEmpty {
            let section = createSection(
                title: "Consigli Culturali",
                icon: "person.2.fill",
                items: briefing.culturalTips,
                identifier: AccessibilityIdentifiers.BriefingDetail.culturalTipsSection
            )
            mainStackView.addArrangedSubview(section)
        }

        // Useful Phrases
        if !briefing.usefulPhrases.isEmpty {
            let phrasesSection = createPhrasesSection(briefing.usefulPhrases)
            mainStackView.addArrangedSubview(phrasesSection)
        }

        // Climate Info
        if !briefing.climateInfo.isEmpty {
            let climateCard = createInfoCard(
                title: "Clima",
                icon: "cloud.sun.fill",
                text: briefing.climateInfo,
                identifier: AccessibilityIdentifiers.BriefingDetail.climateSection
            )
            mainStackView.addArrangedSubview(climateCard)
        }

        // Food Culture
        if !briefing.foodCulture.isEmpty {
            let section = createSection(
                title: "Cucina Locale",
                icon: "fork.knife",
                items: briefing.foodCulture,
                identifier: AccessibilityIdentifiers.BriefingDetail.foodSection
            )
            mainStackView.addArrangedSubview(section)
        }

        // Safety Notes
        if !briefing.safetyNotes.isEmpty {
            let section = createSection(
                title: "Note sulla Sicurezza",
                icon: "shield.fill",
                items: briefing.safetyNotes,
                identifier: AccessibilityIdentifiers.BriefingDetail.safetySection
            )
            mainStackView.addArrangedSubview(section)
        }
    }

    // MARK: - UI Creation Helpers

    private func createQuickFactsCard(_ facts: QuickFactsData) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.accessibilityIdentifier = AccessibilityIdentifiers.BriefingDetail.quickFactsCard

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Informazioni Rapide"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        card.addSubview(titleLabel)

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        card.addSubview(stackView)

        stackView.addArrangedSubview(createFactRow(icon: "globe", label: "Lingua", value: facts.language))
        stackView.addArrangedSubview(createFactRow(icon: "banknote", label: "Valuta", value: facts.currency))
        stackView.addArrangedSubview(createFactRow(icon: "clock", label: "Fuso Orario", value: facts.timeZone))
        stackView.addArrangedSubview(createFactRow(icon: "powerplug", label: "Presa Elettrica", value: facts.electricalOutlet))

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    private func createFactRow(icon: String, label: String, value: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)

        let labelView = UILabel()
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.text = label
        labelView.font = .systemFont(ofSize: 14, weight: .medium)
        labelView.textColor = .secondaryLabel
        container.addSubview(labelView)

        let valueView = UILabel()
        valueView.translatesAutoresizingMaskIntoConstraints = false
        valueView.text = value
        valueView.font = .systemFont(ofSize: 15, weight: .regular)
        valueView.textAlignment = .right
        valueView.numberOfLines = 0
        container.addSubview(valueView)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            labelView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            labelView.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            valueView.leadingAnchor.constraint(greaterThanOrEqualTo: labelView.trailingAnchor, constant: 8),
            valueView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueView.topAnchor.constraint(equalTo: container.topAnchor),
            valueView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        container.heightAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true

        return container
    }

    private func createSection(title: String, icon: String, items: [String], identifier: String) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.accessibilityIdentifier = identifier

        let headerStack = UIStackView()
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        card.addSubview(headerStack)

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        headerStack.addArrangedSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        headerStack.addArrangedSubview(titleLabel)

        let itemsStack = UIStackView()
        itemsStack.translatesAutoresizingMaskIntoConstraints = false
        itemsStack.axis = .vertical
        itemsStack.spacing = 8
        card.addSubview(itemsStack)

        for item in items {
            let itemView = createBulletItem(item)
            itemsStack.addArrangedSubview(itemView)
        }

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            itemsStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            itemsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            itemsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            itemsStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    private func createBulletItem(_ text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let bullet = UILabel()
        bullet.translatesAutoresizingMaskIntoConstraints = false
        bullet.text = "•"
        bullet.font = .systemFont(ofSize: 16, weight: .bold)
        bullet.textColor = .systemOrange
        container.addSubview(bullet)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.numberOfLines = 0
        container.addSubview(label)

        NSLayoutConstraint.activate([
            bullet.topAnchor.constraint(equalTo: container.topAnchor),
            bullet.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bullet.widthAnchor.constraint(equalToConstant: 16),

            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: bullet.trailingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func createPhrasesSection(_ phrases: [LocalPhraseData]) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.accessibilityIdentifier = AccessibilityIdentifiers.BriefingDetail.phrasesSection

        let headerStack = UIStackView()
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        card.addSubview(headerStack)

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: "text.bubble.fill")
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        headerStack.addArrangedSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.text = "Frasi Utili"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        headerStack.addArrangedSubview(titleLabel)

        let phrasesStack = UIStackView()
        phrasesStack.translatesAutoresizingMaskIntoConstraints = false
        phrasesStack.axis = .vertical
        phrasesStack.spacing = 16
        card.addSubview(phrasesStack)

        for phrase in phrases {
            let phraseView = createPhraseRow(phrase)
            phrasesStack.addArrangedSubview(phraseView)
        }

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            phrasesStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            phrasesStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            phrasesStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            phrasesStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    private func createPhraseRow(_ phrase: LocalPhraseData) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .tertiarySystemBackground
        container.layer.cornerRadius = 8

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4
        container.addSubview(stackView)

        let italianLabel = UILabel()
        italianLabel.text = "\(phrase.italian)"
        italianLabel.font = .systemFont(ofSize: 15, weight: .medium)
        stackView.addArrangedSubview(italianLabel)

        let localLabel = UILabel()
        localLabel.text = "→ \(phrase.local)"
        localLabel.font = .systemFont(ofSize: 15, weight: .regular)
        localLabel.textColor = .systemBlue
        stackView.addArrangedSubview(localLabel)

        let pronunciationLabel = UILabel()
        pronunciationLabel.text = "Pronuncia: \(phrase.pronunciation)"
        pronunciationLabel.font = .italicSystemFont(ofSize: 13)
        pronunciationLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(pronunciationLabel)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        return container
    }

    private func createInfoCard(title: String, icon: String, text: String, identifier: String) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.accessibilityIdentifier = identifier

        let headerStack = UIStackView()
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        card.addSubview(headerStack)

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        headerStack.addArrangedSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        headerStack.addArrangedSubview(titleLabel)

        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 15, weight: .regular)
        textLabel.numberOfLines = 0
        card.addSubview(textLabel)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            textLabel.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            textLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            textLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    // MARK: - Generation

    private func generateBriefing() {
        guard let dest = destination ?? associatedTrip?.destination else {
            showContent(false)
            return
        }

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
                let briefing = try await FoundationModelService.shared.generateBriefing(destination: dest)

                // Convert to Data structure for storage and display
                let briefingData = TripBriefingData(
                    destination: briefing.destination,
                    quickFacts: QuickFactsData(
                        language: briefing.quickFacts.language,
                        currency: briefing.quickFacts.currency,
                        timeZone: briefing.quickFacts.timeZone,
                        electricalOutlet: briefing.quickFacts.electricalOutlet
                    ),
                    culturalTips: briefing.culturalTips,
                    usefulPhrases: briefing.usefulPhrases.map {
                        LocalPhraseData(italian: $0.italian, local: $0.local, pronunciation: $0.pronunciation)
                    },
                    climateInfo: briefing.climateInfo,
                    foodCulture: briefing.foodCulture,
                    safetyNotes: briefing.safetyNotes
                )

                await MainActor.run {
                    self.showLoading(false)
                    self.isGenerating = false
                    self.generatedBriefingData = briefingData
                    self.populateFromData(briefingData)
                    self.showContent(true)
                    self.saveBriefingIfNeeded(briefingData)
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
        showContent(false)
        showAlert(title: "Non Disponibile", message: "Le funzionalita AI richiedono iOS 26 o successivo.")
        #endif
    }

    private func saveBriefingIfNeeded(_ briefingData: TripBriefingData) {
        guard let trip = associatedTrip else { return }

        // Elimina briefing esistente
        if let existingBriefing = CoreDataManager.shared.fetchBriefing(for: trip) {
            CoreDataManager.shared.deleteBriefing(existingBriefing)
        }

        // Codifica dati
        let quickFactsData = try? JSONEncoder().encode(briefingData.quickFacts)
        let phrasesData = try? JSONEncoder().encode(briefingData.usefulPhrases)

        let saved = CoreDataManager.shared.createTripBriefing(
            destination: briefingData.destination,
            quickFactsData: quickFactsData,
            culturalTips: briefingData.culturalTips,
            usefulPhrasesData: phrasesData,
            climateInfo: briefingData.climateInfo,
            foodCulture: briefingData.foodCulture,
            safetyNotes: briefingData.safetyNotes,
            for: trip
        )

        savedBriefing = saved

        // Notifica
        NotificationCenter.default.post(name: Constants.NotificationName.briefingGenerated, object: nil)
    }

    // MARK: - Actions

    @objc private func generateTapped() {
        if destination == nil && associatedTrip?.destination == nil {
            showDestinationInput()
        } else {
            generateBriefing()
        }
    }

    @objc private func regenerateTapped() {
        let alert = UIAlertController(
            title: "Rigenera Briefing",
            message: "Vuoi rigenerare il briefing? Le informazioni attuali verranno sostituite.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Rigenera", style: .destructive) { [weak self] _ in
            self?.generateBriefing()
        })

        present(alert, animated: true)
    }

    private func showDestinationInput() {
        let alert = UIAlertController(title: "Destinazione", message: "Inserisci la destinazione per il briefing.", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Es. Tokyo, Parigi, New York"
            textField.autocapitalizationType = .words
        }

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Genera", style: .default) { [weak self] _ in
            guard let dest = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !dest.isEmpty else {
                return
            }
            self?.destination = dest
            self?.generateBriefing()
        })

        present(alert, animated: true)
    }

    // MARK: - UI State

    private func showContent(_ show: Bool) {
        scrollView.isHidden = !show
        emptyStateView.isHidden = show
    }

    private func showLoading(_ show: Bool) {
        loadingContainer.isHidden = !show
        if show {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    // MARK: - Error Handling

    private func handleGenerationError(_ error: Error) {
        let userFacingError = FoundationModelService.shared.handleGenerationError(error)

        let alert = UIAlertController(
            title: userFacingError.title,
            message: userFacingError.message,
            preferredStyle: .alert
        )

        if userFacingError.canRetry {
            alert.addAction(UIAlertAction(title: "Riprova", style: .default) { [weak self] _ in
                self?.generateBriefing()
            })
        }

        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { [weak self] _ in
            self?.showContent(false)
        })

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
                    self?.generateBriefing()
                })
            }
        }

        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { [weak self] _ in
            self?.showContent(false)
        })

        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
