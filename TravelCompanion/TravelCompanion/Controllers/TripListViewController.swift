//
//  TripListViewController.swift
//  TravelCompanion
//
//  Created by Travel Companion Team on 07/12/2025.
//

import UIKit

class TripListViewController: UIViewController {

    // MARK: - UI Components
    private var searchBar: UISearchBar!
    private var filterSegment: UISegmentedControl!
    private var tableView: UITableView!
    private var emptyStateView: UIView!
    private var emptyStateLabel: UILabel!

    // MARK: - Properties
    private var allTrips: [Trip] = []
    private var filteredTrips: [Trip] = []
    private var searchText: String = ""
    private var selectedFilter: TripFilter = .all
    private let refreshControl = UIRefreshControl()

    private enum TripFilter: Int {
        case all = 0
        case local = 1
        case dayTrip = 2
        case multiDay = 3
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupSearchBar()
        setupNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTrips()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Create Search Bar
        searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        // Create Filter Segment
        filterSegment = UISegmentedControl(items: ["Tutti", "Locale", "Giornaliero", "Multi-giorno"])
        filterSegment.translatesAutoresizingMaskIntoConstraints = false
        filterSegment.selectedSegmentIndex = 0
        filterSegment.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        view.addSubview(filterSegment)

        // Create Table View
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // Create Empty State View
        emptyStateView = UIView()
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)

        // Create Empty State Label
        emptyStateLabel = UILabel()
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.text = "Nessun viaggio trovato"
        emptyStateLabel.font = .systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateView.addSubview(emptyStateLabel)

        // Setup Constraints
        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Search Bar - at the top
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Filter Segment - below search bar
            filterSegment.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            filterSegment.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterSegment.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Table View - fills the rest of the screen
            tableView.topAnchor.constraint(equalTo: filterSegment.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Empty State View - fills the same area as table view
            emptyStateView.topAnchor.constraint(equalTo: filterSegment.bottomAnchor, constant: 8),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Empty State Label - centered in empty state view
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: emptyStateView.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: emptyStateView.trailingAnchor, constant: -32)
        ])
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100

        // Register cell
        tableView.register(TripTableViewCell.self, forCellReuseIdentifier: "TripCell")

        // Setup refresh control
        refreshControl.addTarget(self, action: #selector(refreshTrips), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Cerca destinazione..."
        searchBar.showsCancelButton = false
    }

    private func setupNavigationBar() {
        title = "I Miei Viaggi"
        navigationController?.navigationBar.prefersLargeTitles = true

        // Add new trip button
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTripButtonTapped)
        )
        navigationItem.rightBarButtonItem = addButton
    }

    // MARK: - Data Loading
    private func loadTrips() {
        allTrips = CoreDataManager.shared.fetchAllTrips()
        applyFilters()
    }

    private func applyFilters() {
        var trips = allTrips

        // Apply type filter
        if selectedFilter != .all {
            trips = trips.filter { trip in
                let tripType = TripType(rawValue: trip.tripTypeRaw ?? "local") ?? .local
                switch selectedFilter {
                case .local:
                    return tripType == .local
                case .dayTrip:
                    return tripType == .dayTrip
                case .multiDay:
                    return tripType == .multiDay
                case .all:
                    return true
                }
            }
        }

        // Apply search filter
        if !searchText.isEmpty {
            trips = trips.filter { trip in
                trip.destination?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }

        // Sort by start date (most recent first)
        filteredTrips = trips.sorted { trip1, trip2 in
            let date1 = trip1.startDate ?? Date.distantPast
            let date2 = trip2.startDate ?? Date.distantPast
            return date1 > date2
        }

        updateUI()
    }

    private func updateUI() {
        tableView.reloadData()

        let isEmpty = filteredTrips.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty

        if isEmpty {
            if !searchText.isEmpty {
                emptyStateLabel.text = "Nessun viaggio trovato per '\(searchText)'"
            } else if selectedFilter != .all {
                emptyStateLabel.text = "Nessun viaggio in questa categoria"
            } else {
                emptyStateLabel.text = "Nessun viaggio ancora.\nTocca + per crearne uno!"
            }
        }
    }

    // MARK: - Actions
    @objc private func filterChanged() {
        selectedFilter = TripFilter(rawValue: filterSegment.selectedSegmentIndex) ?? .all
        applyFilters()
    }

    @objc private func refreshTrips() {
        loadTrips()
        refreshControl.endRefreshing()
    }

    @objc private func addTripButtonTapped() {
        let newTripVC = NewTripViewController()
        newTripVC.delegate = self
        let navController = UINavigationController(rootViewController: newTripVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    // MARK: - Navigation
    private func navigateToTripDetail(trip: Trip) {
        let detailVC = TripDetailViewController()
        detailVC.trip = trip
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - Delete Trip
    private func deleteTrip(at indexPath: IndexPath) {
        let trip = filteredTrips[indexPath.row]

        let alert = UIAlertController(
            title: "Elimina Viaggio",
            message: "Sei sicuro di voler eliminare il viaggio a \(trip.destination ?? "questa destinazione")? Questa azione non può essere annullata.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Elimina", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            CoreDataManager.shared.deleteTrip(trip)
            self.loadTrips()
        })

        present(alert, animated: true)
    }

    // MARK: - Alert Helper
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension TripListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTrips.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TripCell", for: indexPath) as? TripTableViewCell ?? TripTableViewCell(style: .subtitle, reuseIdentifier: "TripCell")

        let trip = filteredTrips[indexPath.row]
        cell.configure(with: trip)

        return cell
    }
}

// MARK: - UITableViewDelegate
extension TripListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let trip = filteredTrips[indexPath.row]
        navigateToTripDetail(trip: trip)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Elimina") { [weak self] _, _, completion in
            self?.deleteTrip(at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

// MARK: - UISearchBarDelegate
extension TripListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        applyFilters()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchText = ""
        searchBar.resignFirstResponder()
        applyFilters()
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
}

// MARK: - NewTripViewControllerDelegate
extension TripListViewController: NewTripViewControllerDelegate {
    func didCreateTrip(_ trip: Trip, shouldStartTracking: Bool) {
        loadTrips()
    }

    func didCancelTripCreation() {
        // Handle cancellation if needed
    }
}

// MARK: - TripTableViewCell
class TripTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        accessoryType = .disclosureIndicator
        textLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        detailTextLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        detailTextLabel?.textColor = .secondaryLabel
    }

    func configure(with trip: Trip) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        var detailText = ""
        if let startDate = trip.startDate {
            detailText += dateFormatter.string(from: startDate)
        }

        if let endDate = trip.endDate {
            detailText += " - " + dateFormatter.string(from: endDate)
        }

        if trip.isActive {
            detailText += " • In corso"
        }

        detailTextLabel?.text = detailText

        // Add badge for trip type
        let tripType = TripType(rawValue: trip.tripTypeRaw ?? "local") ?? .local
        let typeEmoji = tripType.emoji
        imageView?.image = nil
        textLabel?.text = "\(typeEmoji) \(trip.destination ?? "")"
    }
}
