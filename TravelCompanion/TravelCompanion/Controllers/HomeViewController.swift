//
//  HomeViewController.swift
//  TravelCompanion
//
//  Created by Travel Companion Team on 07/12/2025.
//

import UIKit

class HomeViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel = UILabel()
    private let newTripButton = UIButton(type: .system)
    private let continueTripButton = UIButton(type: .system)

    private let statsCard = UIView()
    private let statsCardTitleLabel = UILabel()
    private let totalTripsLabel = UILabel()
    private let totalTripsDescriptionLabel = UILabel()
    private let totalDistanceLabel = UILabel()
    private let totalDistanceDescriptionLabel = UILabel()

    private let lastTripCard = UIView()
    private let lastTripCardTitleLabel = UILabel()
    private let lastTripDestinationLabel = UILabel()
    private let lastTripDateLabel = UILabel()

    private let emptyStateView = UIView()
    private let emptyStateImageView = UIImageView()
    private let emptyStateTitleLabel = UILabel()
    private let emptyStateMessageLabel = UILabel()

    // MARK: - Properties
    private var activeTrip: Trip?
    private var lastCompletedTrip: Trip?
    private var allTrips: [Trip] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupConstraints()
        setupGestureRecognizers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        updateUI()
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        title = "Travel Companion"
        navigationController?.navigationBar.prefersLargeTitles = true

        // Add settings button
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(settingsButtonTapped)
        )
        navigationItem.rightBarButtonItem = settingsButton
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        // Setup title label (optional, since we have navigation title)
        // We'll skip this since navigation bar has title

        // Setup new trip button
        setupNewTripButton()
        contentView.addSubview(newTripButton)

        // Setup continue trip button
        setupContinueTripButton()
        contentView.addSubview(continueTripButton)

        // Setup stats card
        setupStatsCard()
        contentView.addSubview(statsCard)

        // Setup last trip card
        setupLastTripCard()
        contentView.addSubview(lastTripCard)

        // Setup empty state
        setupEmptyState()
        contentView.addSubview(emptyStateView)
    }

    private func setupNewTripButton() {
        newTripButton.translatesAutoresizingMaskIntoConstraints = false
        newTripButton.setTitle("Nuovo Viaggio", for: .normal)
        newTripButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        newTripButton.setTitleColor(.white, for: .normal)
        newTripButton.backgroundColor = .systemBlue
        newTripButton.layer.cornerRadius = 12
        newTripButton.addTarget(self, action: #selector(newTripButtonTapped), for: .touchUpInside)

        // Add shadow
        newTripButton.layer.shadowColor = UIColor.black.cgColor
        newTripButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        newTripButton.layer.shadowRadius = 4
        newTripButton.layer.shadowOpacity = 0.1
    }

    private func setupContinueTripButton() {
        continueTripButton.translatesAutoresizingMaskIntoConstraints = false
        continueTripButton.setTitle("Continua Viaggio", for: .normal)
        continueTripButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueTripButton.setTitleColor(.white, for: .normal)
        continueTripButton.backgroundColor = .systemGreen
        continueTripButton.layer.cornerRadius = 12
        continueTripButton.addTarget(self, action: #selector(continueTripButtonTapped), for: .touchUpInside)
        continueTripButton.isHidden = true // Initially hidden

        // Add shadow
        continueTripButton.layer.shadowColor = UIColor.black.cgColor
        continueTripButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        continueTripButton.layer.shadowRadius = 4
        continueTripButton.layer.shadowOpacity = 0.1
    }

    private func setupStatsCard() {
        statsCard.translatesAutoresizingMaskIntoConstraints = false
        setupCard(statsCard)

        // Title
        statsCardTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        statsCardTitleLabel.text = "Statistiche"
        statsCardTitleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        statsCardTitleLabel.textColor = .label
        statsCard.addSubview(statsCardTitleLabel)

        // Total trips
        totalTripsLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTripsLabel.text = "0"
        totalTripsLabel.font = .systemFont(ofSize: 32, weight: .bold)
        totalTripsLabel.textColor = .label
        totalTripsLabel.textAlignment = .center
        statsCard.addSubview(totalTripsLabel)

        totalTripsDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTripsDescriptionLabel.text = "Viaggi totali"
        totalTripsDescriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        totalTripsDescriptionLabel.textColor = .secondaryLabel
        totalTripsDescriptionLabel.textAlignment = .center
        statsCard.addSubview(totalTripsDescriptionLabel)

        // Total distance
        totalDistanceLabel.translatesAutoresizingMaskIntoConstraints = false
        totalDistanceLabel.text = "0 km"
        totalDistanceLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        totalDistanceLabel.textColor = .systemBlue
        totalDistanceLabel.textAlignment = .center
        statsCard.addSubview(totalDistanceLabel)

        totalDistanceDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        totalDistanceDescriptionLabel.text = "Distanza totale"
        totalDistanceDescriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        totalDistanceDescriptionLabel.textColor = .secondaryLabel
        totalDistanceDescriptionLabel.textAlignment = .center
        statsCard.addSubview(totalDistanceDescriptionLabel)

        // Layout stats card content
        NSLayoutConstraint.activate([
            statsCardTitleLabel.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 16),
            statsCardTitleLabel.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 16),
            statsCardTitleLabel.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -16),

            totalTripsLabel.topAnchor.constraint(equalTo: statsCardTitleLabel.bottomAnchor, constant: 20),
            totalTripsLabel.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 16),
            totalTripsLabel.widthAnchor.constraint(equalTo: statsCard.widthAnchor, multiplier: 0.5, constant: -24),

            totalTripsDescriptionLabel.topAnchor.constraint(equalTo: totalTripsLabel.bottomAnchor, constant: 4),
            totalTripsDescriptionLabel.centerXAnchor.constraint(equalTo: totalTripsLabel.centerXAnchor),
            totalTripsDescriptionLabel.widthAnchor.constraint(equalTo: totalTripsLabel.widthAnchor),

            totalDistanceLabel.topAnchor.constraint(equalTo: statsCardTitleLabel.bottomAnchor, constant: 20),
            totalDistanceLabel.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -16),
            totalDistanceLabel.widthAnchor.constraint(equalTo: statsCard.widthAnchor, multiplier: 0.5, constant: -24),

            totalDistanceDescriptionLabel.topAnchor.constraint(equalTo: totalDistanceLabel.bottomAnchor, constant: 4),
            totalDistanceDescriptionLabel.centerXAnchor.constraint(equalTo: totalDistanceLabel.centerXAnchor),
            totalDistanceDescriptionLabel.widthAnchor.constraint(equalTo: totalDistanceLabel.widthAnchor),
            totalDistanceDescriptionLabel.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -16)
        ])
    }

    private func setupLastTripCard() {
        lastTripCard.translatesAutoresizingMaskIntoConstraints = false
        setupCard(lastTripCard)

        // Icon
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: "map.fill")
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        lastTripCard.addSubview(iconImageView)

        // Title
        lastTripCardTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        lastTripCardTitleLabel.text = "Ultimo Viaggio"
        lastTripCardTitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        lastTripCardTitleLabel.textColor = .secondaryLabel
        lastTripCard.addSubview(lastTripCardTitleLabel)

        // Destination
        lastTripDestinationLabel.translatesAutoresizingMaskIntoConstraints = false
        lastTripDestinationLabel.text = "Destinazione"
        lastTripDestinationLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        lastTripDestinationLabel.textColor = .label
        lastTripDestinationLabel.numberOfLines = 2
        lastTripCard.addSubview(lastTripDestinationLabel)

        // Date
        lastTripDateLabel.translatesAutoresizingMaskIntoConstraints = false
        lastTripDateLabel.text = "Data"
        lastTripDateLabel.font = .systemFont(ofSize: 14, weight: .regular)
        lastTripDateLabel.textColor = .secondaryLabel
        lastTripCard.addSubview(lastTripDateLabel)

        // Chevron
        let chevronImageView = UIImageView()
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .tertiaryLabel
        chevronImageView.contentMode = .scaleAspectFit
        lastTripCard.addSubview(chevronImageView)

        // Layout last trip card content
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: lastTripCard.leadingAnchor, constant: 16),
            iconImageView.topAnchor.constraint(equalTo: lastTripCard.topAnchor, constant: 16),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),

            lastTripCardTitleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            lastTripCardTitleLabel.topAnchor.constraint(equalTo: lastTripCard.topAnchor, constant: 16),
            lastTripCardTitleLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),

            lastTripDestinationLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            lastTripDestinationLabel.topAnchor.constraint(equalTo: lastTripCardTitleLabel.bottomAnchor, constant: 4),
            lastTripDestinationLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),

            lastTripDateLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            lastTripDateLabel.topAnchor.constraint(equalTo: lastTripDestinationLabel.bottomAnchor, constant: 4),
            lastTripDateLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            lastTripDateLabel.bottomAnchor.constraint(equalTo: lastTripCard.bottomAnchor, constant: -16),

            chevronImageView.trailingAnchor.constraint(equalTo: lastTripCard.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: lastTripCard.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 20),
            chevronImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true

        // Image
        emptyStateImageView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateImageView.image = UIImage(systemName: "airplane.circle")
        emptyStateImageView.tintColor = .tertiaryLabel
        emptyStateImageView.contentMode = .scaleAspectFit
        emptyStateView.addSubview(emptyStateImageView)

        // Title
        emptyStateTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateTitleLabel.text = "Nessun Viaggio"
        emptyStateTitleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        emptyStateTitleLabel.textColor = .secondaryLabel
        emptyStateTitleLabel.textAlignment = .center
        emptyStateView.addSubview(emptyStateTitleLabel)

        // Message
        emptyStateMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateMessageLabel.text = "Inizia il tuo primo viaggio\ntoccando il pulsante qui sopra"
        emptyStateMessageLabel.font = .systemFont(ofSize: 16, weight: .regular)
        emptyStateMessageLabel.textColor = .tertiaryLabel
        emptyStateMessageLabel.textAlignment = .center
        emptyStateMessageLabel.numberOfLines = 0
        emptyStateView.addSubview(emptyStateMessageLabel)

        // Layout empty state content
        NSLayoutConstraint.activate([
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor, constant: 40),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 100),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 100),

            emptyStateTitleLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 20),
            emptyStateTitleLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 20),
            emptyStateTitleLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -20),

            emptyStateMessageLabel.topAnchor.constraint(equalTo: emptyStateTitleLabel.bottomAnchor, constant: 12),
            emptyStateMessageLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 20),
            emptyStateMessageLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -20),
            emptyStateMessageLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor, constant: -40)
        ])
    }

    private func setupCard(_ card: UIView) {
        card.layer.cornerRadius = 16
        card.backgroundColor = .secondarySystemBackground
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4
        card.layer.shadowOpacity = 0.1
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // New trip button
            newTripButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            newTripButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            newTripButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            newTripButton.heightAnchor.constraint(equalToConstant: 56),

            // Continue trip button
            continueTripButton.topAnchor.constraint(equalTo: newTripButton.bottomAnchor, constant: 12),
            continueTripButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            continueTripButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            continueTripButton.heightAnchor.constraint(equalToConstant: 56),

            // Stats card
            statsCard.topAnchor.constraint(equalTo: continueTripButton.bottomAnchor, constant: 24),
            statsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Last trip card
            lastTripCard.topAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: 16),
            lastTripCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            lastTripCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Empty state
            emptyStateView.topAnchor.constraint(equalTo: continueTripButton.bottomAnchor, constant: 24),
            emptyStateView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emptyStateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            emptyStateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        // Make last trip card the last element when visible, or stats card when last trip is hidden
        lastTripCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20).isActive = true
    }

    private func setupGestureRecognizers() {
        // Add tap gesture to stats card
        let statsTapGesture = UITapGestureRecognizer(target: self, action: #selector(statsCardTapped))
        statsCard.addGestureRecognizer(statsTapGesture)
        statsCard.isUserInteractionEnabled = true

        // Add tap gesture to last trip card
        let lastTripTapGesture = UITapGestureRecognizer(target: self, action: #selector(lastTripCardTapped))
        lastTripCard.addGestureRecognizer(lastTripTapGesture)
        lastTripCard.isUserInteractionEnabled = true
    }

    // MARK: - Data Loading
    private func loadData() {
        // Load all trips
        allTrips = CoreDataManager.shared.fetchAllTrips()

        // Check for active trip
        activeTrip = allTrips.first(where: { $0.isActive })

        // Get last completed trip
        let completedTrips = allTrips.filter { !$0.isActive }
        lastCompletedTrip = completedTrips.max(by: { ($0.endDate ?? Date.distantPast) < ($1.endDate ?? Date.distantPast) })
    }

    private func updateUI() {
        // Update continue trip button visibility
        updateContinueTripButton()

        // Update statistics
        updateStatistics()

        // Update last trip card
        updateLastTripCard()

        // Show/hide empty state
        updateEmptyState()
    }

    private func updateContinueTripButton() {
        let hasActiveTrip = activeTrip != nil
        continueTripButton.isHidden = !hasActiveTrip

        if hasActiveTrip {
            continueTripButton.setTitle("Continua Viaggio", for: .normal)
        }
    }

    private func updateStatistics() {
        // Total trips
        totalTripsLabel.text = "\(allTrips.count)"

        // Calculate total distance
        let totalDistance = allTrips.reduce(0.0) { $0 + $1.totalDistance }
        let formattedDistance = formatDistance(totalDistance)
        totalDistanceLabel.text = formattedDistance
    }

    private func updateLastTripCard() {
        guard let lastTrip = lastCompletedTrip else {
            lastTripCard.isHidden = true
            return
        }

        lastTripCard.isHidden = false
        lastTripDestinationLabel.text = lastTrip.destination

        if let endDate = lastTrip.endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            lastTripDateLabel.text = "Completato il \(formatter.string(from: endDate))"
        }
    }

    private func updateEmptyState() {
        let isEmpty = allTrips.isEmpty
        emptyStateView.isHidden = !isEmpty
        statsCard.isHidden = isEmpty
        lastTripCard.isHidden = isEmpty || lastCompletedTrip == nil
    }

    // MARK: - Helper Methods
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }

    private func checkActiveTrip() -> Bool {
        loadData()
        return activeTrip != nil
    }

    // MARK: - Actions
    @objc private func newTripButtonTapped() {
        navigateToNewTrip()
    }

    @objc private func continueTripButtonTapped() {
        guard checkActiveTrip() else {
            showAlert(title: "Nessun Viaggio Attivo", message: "Non ci sono viaggi attivi al momento.")
            return
        }
        navigateToActiveTrip()
    }

    @objc private func lastTripCardTapped() {
        guard let trip = lastCompletedTrip else { return }
        navigateToTripDetail(trip: trip)
    }

    @objc private func statsCardTapped() {
        navigateToTripList()
    }

    @objc private func settingsButtonTapped() {
        // Navigate to settings
        let alert = UIAlertController(title: "Impostazioni", message: "Funzionalità in arrivo", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Navigation
    func navigateToNewTrip() {
        let newTripVC = NewTripViewController()
        newTripVC.delegate = self
        let navController = UINavigationController(rootViewController: newTripVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    private func navigateToActiveTrip() {
        guard let trip = activeTrip else { return }
        let activeTripVC = ActiveTripViewController()
        activeTripVC.trip = trip
        navigationController?.pushViewController(activeTripVC, animated: true)
    }

    private func navigateToTripList() {
        let tripListVC = TripListViewController()
        navigationController?.pushViewController(tripListVC, animated: true)
    }

    private func navigateToTripDetail(trip: Trip) {
        let detailVC = TripDetailViewController()
        detailVC.trip = trip
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - Alert Helper
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - NewTripViewControllerDelegate
extension HomeViewController: NewTripViewControllerDelegate {
    func didCreateTrip(_ trip: Trip, shouldStartTracking: Bool) {
        loadData()
        updateUI()

        if shouldStartTracking {
            // Navigate to active trip
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.navigateToActiveTrip()
            }
        }
    }

    func didCancelTripCreation() {
        // Handle cancellation if needed
    }
}
