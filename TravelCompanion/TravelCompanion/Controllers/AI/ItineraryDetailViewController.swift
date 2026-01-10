import UIKit

/// Controller per visualizzare i dettagli di un itinerario generato
@available(iOS 26.0, *)
final class ItineraryDetailViewController: UIViewController {

    // MARK: - Properties

    /// L'itinerario da visualizzare (impostato prima della presentazione)
    var itinerary: TravelItinerary?

    /// Trip associato (opzionale, per salvare l'itinerario)
    var associatedTrip: Trip?

    /// Itinerario salvato in Core Data (per visualizzazione di itinerari esistenti)
    var savedItinerary: Itinerary?

    private var expandedDays: Set<Int> = []

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

    private let headerCard: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 16
        return v
    }()

    private let destinationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.accessibilityIdentifier = AccessibilityIdentifiers.ItineraryDetail.destinationLabel
        return label
    }()

    private let infoStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.alignment = .center
        return sv
    }()

    private let daysLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.accessibilityIdentifier = AccessibilityIdentifiers.ItineraryDetail.daysLabel
        return label
    }()

    private let styleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBlue
        label.accessibilityIdentifier = AccessibilityIdentifiers.ItineraryDetail.styleLabel
        return label
    }()

    private let aiBadge: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemPurple.withAlphaComponent(0.15)
        v.layer.cornerRadius = 8
        return v
    }()

    private let aiBadgeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Generato con AI"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemPurple
        return label
    }()

    private let daysStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 12
        return sv
    }()

    private let tipsHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Consigli Generali"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()

    private let tipsStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 8
        sv.accessibilityIdentifier = AccessibilityIdentifiers.ItineraryDetail.tipsSection
        return sv
    }()

    private let disclaimerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Le informazioni sono generate dall'AI e potrebbero non essere completamente accurate. Verifica sempre i dettagli importanti prima del viaggio."
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.ItineraryDetail.aiDisclaimer
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
        populateData()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        scrollView.accessibilityIdentifier = AccessibilityIdentifiers.ItineraryDetail.scrollView

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerCard)
        headerCard.addSubview(destinationLabel)
        headerCard.addSubview(infoStackView)
        headerCard.addSubview(aiBadge)
        aiBadge.addSubview(aiBadgeLabel)

        infoStackView.addArrangedSubview(daysLabel)
        infoStackView.addArrangedSubview(styleLabel)

        contentView.addSubview(daysStackView)
        contentView.addSubview(tipsHeaderLabel)
        contentView.addSubview(tipsStackView)
        contentView.addSubview(disclaimerLabel)
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

            // Header Card
            headerCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            headerCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            headerCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Destination Label
            destinationLabel.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 16),
            destinationLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            destinationLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),

            // Info Stack
            infoStackView.topAnchor.constraint(equalTo: destinationLabel.bottomAnchor, constant: 8),
            infoStackView.centerXAnchor.constraint(equalTo: headerCard.centerXAnchor),

            // AI Badge
            aiBadge.topAnchor.constraint(equalTo: infoStackView.bottomAnchor, constant: 12),
            aiBadge.centerXAnchor.constraint(equalTo: headerCard.centerXAnchor),
            aiBadge.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -16),

            aiBadgeLabel.topAnchor.constraint(equalTo: aiBadge.topAnchor, constant: 6),
            aiBadgeLabel.leadingAnchor.constraint(equalTo: aiBadge.leadingAnchor, constant: 12),
            aiBadgeLabel.trailingAnchor.constraint(equalTo: aiBadge.trailingAnchor, constant: -12),
            aiBadgeLabel.bottomAnchor.constraint(equalTo: aiBadge.bottomAnchor, constant: -6),

            // Days Stack
            daysStackView.topAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: 24),
            daysStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            daysStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Tips Header
            tipsHeaderLabel.topAnchor.constraint(equalTo: daysStackView.bottomAnchor, constant: 32),
            tipsHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            // Tips Stack
            tipsStackView.topAnchor.constraint(equalTo: tipsHeaderLabel.bottomAnchor, constant: 12),
            tipsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            tipsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Disclaimer
            disclaimerLabel.topAnchor.constraint(equalTo: tipsStackView.bottomAnchor, constant: 32),
            disclaimerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            disclaimerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            disclaimerLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }

    private func setupNavigationBar() {
        title = "Itinerario"

        // Save button se abbiamo un trip associato e l'itinerario non e ancora salvato
        if associatedTrip != nil && savedItinerary == nil {
            let saveButton = UIBarButtonItem(
                barButtonSystemItem: .save,
                target: self,
                action: #selector(saveTapped)
            )
            navigationItem.rightBarButtonItem = saveButton
        }

        // Regenerate button
        if savedItinerary == nil {
            let regenerateButton = UIBarButtonItem(
                image: UIImage(systemName: "arrow.clockwise"),
                style: .plain,
                target: self,
                action: #selector(regenerateTapped)
            )
            regenerateButton.accessibilityIdentifier = AccessibilityIdentifiers.ItineraryDetail.regenerateButton

            if navigationItem.rightBarButtonItem != nil {
                navigationItem.rightBarButtonItems = [navigationItem.rightBarButtonItem!, regenerateButton]
            } else {
                navigationItem.rightBarButtonItem = regenerateButton
            }
        }
    }

    // MARK: - Data Population

    private func populateData() {
        // Popola da itinerario generato o da itinerario salvato
        if let itinerary = itinerary {
            populateFromGenerated(itinerary)
        } else if let saved = savedItinerary {
            populateFromSaved(saved)
        }
    }

    private func populateFromGenerated(_ itinerary: TravelItinerary) {
        destinationLabel.text = itinerary.destination
        daysLabel.text = "\(itinerary.totalDays) giorni"
        styleLabel.text = itinerary.travelStyle.capitalized

        // Popola i giorni
        for dayPlan in itinerary.dailyPlans {
            let dayCard = createDayCard(for: dayPlan)
            daysStackView.addArrangedSubview(dayCard)
        }

        // Popola i consigli
        for tip in itinerary.generalTips {
            let tipView = createTipView(tip)
            tipsStackView.addArrangedSubview(tipView)
        }
    }

    private func populateFromSaved(_ saved: Itinerary) {
        destinationLabel.text = saved.destination
        daysLabel.text = "\(saved.totalDays) giorni"
        styleLabel.text = saved.travelStyle?.capitalized ?? "Standard"

        // Decodifica i piani giornalieri dal JSON
        if let jsonData = saved.dailyPlansJSON as? Data {
            do {
                let dailyPlans = try JSONDecoder().decode([DayPlanData].self, from: jsonData)
                for dayPlan in dailyPlans {
                    let dayCard = createDayCardFromData(dayPlan)
                    daysStackView.addArrangedSubview(dayCard)
                }
            } catch {
                #if DEBUG
                print("Error decoding daily plans: \(error)")
                #endif
            }
        }

        // Popola i consigli
        if let tips = saved.generalTips as? [String] {
            for tip in tips {
                let tipView = createTipView(tip)
                tipsStackView.addArrangedSubview(tipView)
            }
        }
    }

    // MARK: - UI Creation Helpers

    private func createDayCard(for dayPlan: DayPlan) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.accessibilityIdentifier = "\(AccessibilityIdentifiers.ItineraryDetail.dayCard)_\(dayPlan.dayNumber)"

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        card.addSubview(stackView)

        // Header con giorno e tema
        let headerView = createDayHeader(dayNumber: dayPlan.dayNumber, theme: dayPlan.theme)
        stackView.addArrangedSubview(headerView)

        // Attivita
        let morningView = createActivityRow(icon: "sunrise.fill", title: "Mattina", text: dayPlan.morningActivity)
        stackView.addArrangedSubview(morningView)

        let lunchView = createActivityRow(icon: "fork.knife", title: "Pranzo", text: dayPlan.lunchArea)
        stackView.addArrangedSubview(lunchView)

        let afternoonView = createActivityRow(icon: "sun.max.fill", title: "Pomeriggio", text: dayPlan.afternoonActivity)
        stackView.addArrangedSubview(afternoonView)

        let dinnerView = createActivityRow(icon: "moon.stars.fill", title: "Cena", text: dayPlan.dinnerArea)
        stackView.addArrangedSubview(dinnerView)

        if let evening = dayPlan.eveningActivity, !evening.isEmpty {
            let eveningView = createActivityRow(icon: "sparkles", title: "Sera", text: evening)
            stackView.addArrangedSubview(eveningView)
        }

        // Note trasporti
        if !dayPlan.transportNotes.isEmpty {
            let transportView = createTransportNote(dayPlan.transportNotes)
            stackView.addArrangedSubview(transportView)
        }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    private func createDayCardFromData(_ dayPlan: DayPlanData) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        card.addSubview(stackView)

        // Header con giorno e tema
        let headerView = createDayHeader(dayNumber: dayPlan.dayNumber, theme: dayPlan.theme)
        stackView.addArrangedSubview(headerView)

        // Attivita
        let morningView = createActivityRow(icon: "sunrise.fill", title: "Mattina", text: dayPlan.morningActivity)
        stackView.addArrangedSubview(morningView)

        let lunchView = createActivityRow(icon: "fork.knife", title: "Pranzo", text: dayPlan.lunchArea)
        stackView.addArrangedSubview(lunchView)

        let afternoonView = createActivityRow(icon: "sun.max.fill", title: "Pomeriggio", text: dayPlan.afternoonActivity)
        stackView.addArrangedSubview(afternoonView)

        let dinnerView = createActivityRow(icon: "moon.stars.fill", title: "Cena", text: dayPlan.dinnerArea)
        stackView.addArrangedSubview(dinnerView)

        if let evening = dayPlan.eveningActivity, !evening.isEmpty {
            let eveningView = createActivityRow(icon: "sparkles", title: "Sera", text: evening)
            stackView.addArrangedSubview(eveningView)
        }

        // Note trasporti
        if !dayPlan.transportNotes.isEmpty {
            let transportView = createTransportNote(dayPlan.transportNotes)
            stackView.addArrangedSubview(transportView)
        }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    private func createDayHeader(dayNumber: Int, theme: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let dayLabel = UILabel()
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.text = "Giorno \(dayNumber)"
        dayLabel.font = .systemFont(ofSize: 18, weight: .bold)
        dayLabel.textColor = .systemBlue
        container.addSubview(dayLabel)

        let themeLabel = UILabel()
        themeLabel.translatesAutoresizingMaskIntoConstraints = false
        themeLabel.text = theme
        themeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        themeLabel.textColor = .secondaryLabel
        container.addSubview(themeLabel)

        NSLayoutConstraint.activate([
            dayLabel.topAnchor.constraint(equalTo: container.topAnchor),
            dayLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            themeLabel.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 2),
            themeLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            themeLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func createActivityRow(icon: String, title: String, text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .systemOrange
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        container.addSubview(titleLabel)

        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 15, weight: .regular)
        textLabel.numberOfLines = 0
        container.addSubview(textLabel)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),

            textLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
            textLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func createTransportNote(_ note: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        container.layer.cornerRadius = 8

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: "bus.fill")
        iconView.tintColor = .systemBlue
        container.addSubview(iconView)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = note
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .systemBlue
        label.numberOfLines = 0
        container.addSubview(label)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),

            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        return container
    }

    private func createTipView(_ tip: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let bulletLabel = UILabel()
        bulletLabel.translatesAutoresizingMaskIntoConstraints = false
        bulletLabel.text = "•"
        bulletLabel.font = .systemFont(ofSize: 16, weight: .bold)
        bulletLabel.textColor = .systemGreen
        container.addSubview(bulletLabel)

        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.text = tip
        textLabel.font = .systemFont(ofSize: 15, weight: .regular)
        textLabel.numberOfLines = 0
        container.addSubview(textLabel)

        NSLayoutConstraint.activate([
            bulletLabel.topAnchor.constraint(equalTo: container.topAnchor),
            bulletLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bulletLabel.widthAnchor.constraint(equalToConstant: 16),

            textLabel.topAnchor.constraint(equalTo: container.topAnchor),
            textLabel.leadingAnchor.constraint(equalTo: bulletLabel.trailingAnchor, constant: 4),
            textLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Actions

    @objc private func saveTapped() {
        guard let trip = associatedTrip, let itinerary = itinerary else { return }

        // Converti i piani giornalieri in Data
        let dailyPlansData: Data? = {
            let dataPlans = itinerary.dailyPlans.map { plan in
                DayPlanData(
                    dayNumber: plan.dayNumber,
                    theme: plan.theme,
                    morningActivity: plan.morningActivity,
                    lunchArea: plan.lunchArea,
                    afternoonActivity: plan.afternoonActivity,
                    dinnerArea: plan.dinnerArea,
                    eveningActivity: plan.eveningActivity,
                    transportNotes: plan.transportNotes
                )
            }
            return try? JSONEncoder().encode(dataPlans)
        }()

        let _ = CoreDataManager.shared.createItinerary(
            destination: itinerary.destination,
            totalDays: itinerary.totalDays,
            travelStyle: itinerary.travelStyle,
            dailyPlansData: dailyPlansData,
            generalTips: itinerary.generalTips,
            for: trip
        )

        // Notifica il salvataggio
        NotificationCenter.default.post(name: Constants.NotificationName.itineraryGenerated, object: nil)

        // Mostra conferma e torna indietro
        let alert = UIAlertController(
            title: "Salvato",
            message: "L'itinerario e stato salvato nel viaggio.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }

    @objc private func regenerateTapped() {
        let alert = UIAlertController(
            title: "Rigenera Itinerario",
            message: "Vuoi generare un nuovo itinerario? L'attuale non salvato verra perso.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Rigenera", style: .destructive) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })

        present(alert, animated: true)
    }
}
