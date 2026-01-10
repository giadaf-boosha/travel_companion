//
//  TripDetailViewController.swift
//  TravelCompanion
//
//  Created by Travel Companion Team on 07/12/2025.
//

import UIKit
import CoreLocation

class TripDetailViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Header Section
    private let headerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let destinationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let tripTypeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusBadge: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Photos Section
    private let photosSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Foto"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let photosCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private var photosHeightConstraint: NSLayoutConstraint!

    // Notes Section
    private let notesSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Note"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let notesTableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .singleLine
        tv.isScrollEnabled = false
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 60
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private var notesHeightConstraint: NSLayoutConstraint!

    // Map Button
    private let mapButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 12
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitle("Visualizza Mappa", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // AI Section
    private let aiSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "AI Assistente"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let aiButtonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let itineraryAIButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 10
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = AccessibilityIdentifiers.TripDetail.aiItineraryButton
        return button
    }()

    private let packingListAIButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 10
        button.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        button.setTitleColor(.systemOrange, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = AccessibilityIdentifiers.TripDetail.aiPackingListButton
        return button
    }()

    private let briefingAIButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 10
        button.backgroundColor = .systemPurple.withAlphaComponent(0.1)
        button.setTitleColor(.systemPurple, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = AccessibilityIdentifiers.TripDetail.aiBriefingButton
        return button
    }()

    private let summaryAIButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 10
        button.backgroundColor = .systemTeal.withAlphaComponent(0.1)
        button.setTitleColor(.systemTeal, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = AccessibilityIdentifiers.TripDetail.aiSummaryButton
        return button
    }()

    // MARK: - Properties
    var trip: Trip!
    private var photos: [Photo] = []
    private var notes: [Note] = []
    private var routes: [Route] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        guard trip != nil else {
            navigationController?.popViewController(animated: true)
            return
        }

        setupUI()
        setupNavigationBar()
        setupCollectionView()
        setupTableView()
        setupActions()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Add scroll view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Add header components to stack
        headerStackView.addArrangedSubview(destinationLabel)
        headerStackView.addArrangedSubview(dateLabel)

        // Setup info row (trip type + status badge)
        statusBadge.addSubview(statusLabel)
        infoStackView.addArrangedSubview(tripTypeLabel)
        infoStackView.addArrangedSubview(statusBadge)
        infoStackView.addArrangedSubview(UIView()) // Spacer

        headerStackView.addArrangedSubview(infoStackView)
        headerStackView.addArrangedSubview(distanceLabel)

        // Add separators
        let separator1 = createSeparator()
        let separator2 = createSeparator()
        let separator3 = createSeparator()
        let separator4 = createSeparator()

        // Add all components to content view
        contentView.addSubview(headerStackView)
        contentView.addSubview(separator1)
        contentView.addSubview(photosSectionLabel)
        contentView.addSubview(photosCollectionView)
        contentView.addSubview(separator2)
        contentView.addSubview(notesSectionLabel)
        contentView.addSubview(notesTableView)
        contentView.addSubview(separator3)

        // AI Section (only on iOS 26+)
        if #available(iOS 26.0, *) {
            contentView.addSubview(aiSectionLabel)
            contentView.addSubview(aiButtonsStackView)
            aiButtonsStackView.addArrangedSubview(itineraryAIButton)
            aiButtonsStackView.addArrangedSubview(packingListAIButton)
            aiButtonsStackView.addArrangedSubview(briefingAIButton)
            aiButtonsStackView.addArrangedSubview(summaryAIButton)
            contentView.addSubview(separator4)
        }

        contentView.addSubview(mapButton)

        // Setup accessibility identifiers
        scrollView.accessibilityIdentifier = AccessibilityIdentifiers.TripDetail.scrollView
        destinationLabel.accessibilityIdentifier = AccessibilityIdentifiers.TripDetail.destinationLabel
        dateLabel.accessibilityIdentifier = AccessibilityIdentifiers.TripDetail.dateLabel
        tripTypeLabel.accessibilityIdentifier = AccessibilityIdentifiers.TripDetail.tripTypeLabel
        statusLabel.accessibilityIdentifier = AccessibilityIdentifiers.TripDetail.statusLabel
        distanceLabel.accessibilityIdentifier = AccessibilityIdentifiers.TripDetail.distanceLabel
        photosCollectionView.accessibilityIdentifier = AccessibilityIdentifiers.TripDetail.photosCollectionView
        notesTableView.accessibilityIdentifier = AccessibilityIdentifiers.TripDetail.notesTableView
        mapButton.accessibilityIdentifier = AccessibilityIdentifiers.TripDetail.mapButton

        // Setup constraints
        setupConstraints()

        // Update trip info
        updateTripInfo()
    }

    private func setupConstraints() {
        // ScrollView constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // ContentView constraints
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Status label inside badge
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: statusBadge.topAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: statusBadge.leadingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: statusBadge.trailingAnchor, constant: -8),
            statusLabel.bottomAnchor.constraint(equalTo: statusBadge.bottomAnchor, constant: -4)
        ])

        // Header stack
        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        NSLayoutConstraint.activate([
            infoStackView.leadingAnchor.constraint(equalTo: headerStackView.leadingAnchor),
            infoStackView.trailingAnchor.constraint(equalTo: headerStackView.trailingAnchor)
        ])

        // Photos section
        guard let separator1 = contentView.subviews.first(where: { $0.backgroundColor == .separator && $0.frame.origin.y == 0 }) as? UIView else { return }
        NSLayoutConstraint.activate([
            separator1.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 24),
            separator1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator1.heightAnchor.constraint(equalToConstant: 1)
        ])

        NSLayoutConstraint.activate([
            photosSectionLabel.topAnchor.constraint(equalTo: separator1.bottomAnchor, constant: 24),
            photosSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            photosSectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        photosHeightConstraint = photosCollectionView.heightAnchor.constraint(equalToConstant: 150)
        NSLayoutConstraint.activate([
            photosCollectionView.topAnchor.constraint(equalTo: photosSectionLabel.bottomAnchor, constant: 12),
            photosCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            photosCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            photosHeightConstraint
        ])

        // Notes section
        guard let separator2 = contentView.subviews.filter({ $0.backgroundColor == .separator }).dropFirst().first as? UIView else { return }
        NSLayoutConstraint.activate([
            separator2.topAnchor.constraint(equalTo: photosCollectionView.bottomAnchor, constant: 24),
            separator2.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator2.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator2.heightAnchor.constraint(equalToConstant: 1)
        ])

        NSLayoutConstraint.activate([
            notesSectionLabel.topAnchor.constraint(equalTo: separator2.bottomAnchor, constant: 24),
            notesSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            notesSectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        notesHeightConstraint = notesTableView.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            notesTableView.topAnchor.constraint(equalTo: notesSectionLabel.bottomAnchor, constant: 12),
            notesTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            notesTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            notesHeightConstraint
        ])

        // Separator after notes
        guard let separator3 = contentView.subviews.filter({ $0.backgroundColor == .separator }).dropFirst(2).first as? UIView else { return }
        NSLayoutConstraint.activate([
            separator3.topAnchor.constraint(equalTo: notesTableView.bottomAnchor, constant: 24),
            separator3.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separator3.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator3.heightAnchor.constraint(equalToConstant: 1)
        ])

        // AI Section (only on iOS 26+)
        if #available(iOS 26.0, *) {
            NSLayoutConstraint.activate([
                aiSectionLabel.topAnchor.constraint(equalTo: separator3.bottomAnchor, constant: 24),
                aiSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                aiSectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])

            NSLayoutConstraint.activate([
                aiButtonsStackView.topAnchor.constraint(equalTo: aiSectionLabel.bottomAnchor, constant: 12),
                aiButtonsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                aiButtonsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])

            // Height constraints for AI buttons
            [itineraryAIButton, packingListAIButton, briefingAIButton, summaryAIButton].forEach { button in
                button.heightAnchor.constraint(equalToConstant: 48).isActive = true
            }

            // Separator after AI section
            guard let separator4 = contentView.subviews.filter({ $0.backgroundColor == .separator }).dropFirst(3).first as? UIView else { return }
            NSLayoutConstraint.activate([
                separator4.topAnchor.constraint(equalTo: aiButtonsStackView.bottomAnchor, constant: 24),
                separator4.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                separator4.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                separator4.heightAnchor.constraint(equalToConstant: 1)
            ])

            // Map button after AI section
            NSLayoutConstraint.activate([
                mapButton.topAnchor.constraint(equalTo: separator4.bottomAnchor, constant: 24),
                mapButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                mapButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                mapButton.heightAnchor.constraint(equalToConstant: 50),
                mapButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
            ])
        } else {
            // Map button directly after notes (iOS < 26)
            NSLayoutConstraint.activate([
                mapButton.topAnchor.constraint(equalTo: separator3.bottomAnchor, constant: 24),
                mapButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                mapButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                mapButton.heightAnchor.constraint(equalToConstant: 50),
                mapButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
            ])
        }
    }

    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }

    private func setupNavigationBar() {
        title = "Dettagli Viaggio"

        // Share and delete buttons
        let shareButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareButtonTapped)
        )

        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(deleteButtonTapped)
        )
        deleteButton.tintColor = .systemRed

        navigationItem.rightBarButtonItems = [shareButton, deleteButton]
    }

    private func setupCollectionView() {
        photosCollectionView.delegate = self
        photosCollectionView.dataSource = self
        photosCollectionView.register(PhotoDetailCell.self, forCellWithReuseIdentifier: "PhotoDetailCell")
    }

    private func setupTableView() {
        notesTableView.delegate = self
        notesTableView.dataSource = self
        notesTableView.register(NoteDetailCell.self, forCellReuseIdentifier: "NoteDetailCell")
    }

    private func setupActions() {
        mapButton.addTarget(self, action: #selector(mapButtonTapped), for: .touchUpInside)

        // AI button actions (iOS 26+)
        if #available(iOS 26.0, *) {
            itineraryAIButton.addTarget(self, action: #selector(itineraryAIButtonTapped), for: .touchUpInside)
            packingListAIButton.addTarget(self, action: #selector(packingListAIButtonTapped), for: .touchUpInside)
            briefingAIButton.addTarget(self, action: #selector(briefingAIButtonTapped), for: .touchUpInside)
            summaryAIButton.addTarget(self, action: #selector(summaryAIButtonTapped), for: .touchUpInside)
        }
    }

    // MARK: - Data Loading
    private func loadData() {
        // Load photos
        photos = CoreDataManager.shared.fetchPhotos(for: trip)
        photosCollectionView.reloadData()
        updatePhotosHeight()

        // Load notes
        notes = CoreDataManager.shared.fetchNotes(for: trip)
        notesTableView.reloadData()
        updateNotesHeight()

        // Load routes for map
        routes = CoreDataManager.shared.fetchRoutes(for: trip)

        // Update map button visibility
        mapButton.isHidden = routes.isEmpty

        // Update AI button states (iOS 26+)
        if #available(iOS 26.0, *) {
            updateAIButtonStates()
        }
    }

    @available(iOS 26.0, *)
    private func updateAIButtonStates() {
        // Check if itinerary exists
        let hasItinerary = CoreDataManager.shared.fetchItinerary(for: trip) != nil
        itineraryAIButton.setTitle(hasItinerary ? "Vedi Itinerario" : "Genera Itinerario", for: .normal)

        // Check if packing list exists
        let hasPackingList = CoreDataManager.shared.fetchPackingList(for: trip) != nil
        packingListAIButton.setTitle(hasPackingList ? "Vedi Packing List" : "Genera Packing List", for: .normal)

        // Check if briefing exists
        let hasBriefing = CoreDataManager.shared.fetchBriefing(for: trip) != nil
        briefingAIButton.setTitle(hasBriefing ? "Vedi Briefing" : "Genera Briefing", for: .normal)

        // Summary only available for completed trips
        let isCompleted = !trip.isActive
        summaryAIButton.isHidden = trip.isActive
        if isCompleted {
            let hasSummary = CoreDataManager.shared.fetchSummary(for: trip) != nil
            summaryAIButton.setTitle(hasSummary ? "Vedi Riassunto" : "Genera Riassunto", for: .normal)
        }
    }

    private func updateTripInfo() {
        // Destination
        let tripType = TripType(rawValue: trip.tripTypeRaw ?? "local") ?? .local
        let typeEmoji = tripType.emoji
        destinationLabel.text = "\(typeEmoji) \(trip.destination ?? "Destinazione sconosciuta")"

        // Dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none

        var dateText = ""
        if let startDate = trip.startDate {
            dateText = "Dal \(dateFormatter.string(from: startDate))"
        }
        if let endDate = trip.endDate {
            dateText += "\nAl \(dateFormatter.string(from: endDate))"
        }
        dateLabel.text = dateText

        // Trip type
        tripTypeLabel.text = tripType.displayName.uppercased()

        // Distance
        let distance = trip.totalDistance
        distanceLabel.text = "Distanza: \(formatDistance(distance))"

        // Status
        if trip.isActive {
            statusBadge.backgroundColor = .systemGreen
            statusLabel.text = "IN CORSO"
        } else {
            statusBadge.backgroundColor = .systemGray
            statusLabel.text = "COMPLETATO"
        }
    }

    private func updatePhotosHeight() {
        if photos.isEmpty {
            photosHeightConstraint.constant = 0
            photosCollectionView.isHidden = true
            photosSectionLabel.isHidden = true
        } else {
            photosHeightConstraint.constant = 150
            photosCollectionView.isHidden = false
            photosSectionLabel.isHidden = false
        }
    }

    private func updateNotesHeight() {
        if notes.isEmpty {
            notesHeightConstraint.constant = 0
            notesTableView.isHidden = true
            notesSectionLabel.isHidden = true
        } else {
            notesTableView.layoutIfNeeded()
            notesHeightConstraint.constant = notesTableView.contentSize.height
            notesTableView.isHidden = false
            notesSectionLabel.isHidden = false
        }
    }

    // MARK: - Helper Methods
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }

    // MARK: - Actions
    @objc private func mapButtonTapped() {
        navigateToMap()
    }

    @objc private func shareButtonTapped() {
        guard let destination = trip.destination else { return }

        var shareText = "Ho visitato \(destination)!"

        if trip.totalDistance > 0 {
            shareText += "\nDistanza percorsa: \(formatDistance(trip.totalDistance))"
        }

        if photos.count > 0 {
            shareText += "\nFoto scattate: \(photos.count)"
        }

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first
        }

        present(activityVC, animated: true)
    }

    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(
            title: "Elimina Viaggio",
            message: "Sei sicuro di voler eliminare questo viaggio? Questa azione eliminerà anche tutte le foto, note e posizioni associate. Questa azione non può essere annullata.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Elimina", style: .destructive) { [weak self] _ in
            self?.deleteTrip()
        })

        present(alert, animated: true)
    }

    // MARK: - Delete Trip
    private func deleteTrip() {
        CoreDataManager.shared.deleteTrip(trip)
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Navigation
    private func navigateToMap() {
        let mapVC = MapViewController()
        mapVC.trip = trip
        navigationController?.pushViewController(mapVC, animated: true)
    }

    // MARK: - Alert Helper
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - AI Actions

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    @objc private func itineraryAIButtonTapped() {
        // Check if itinerary already exists
        if let existingItinerary = CoreDataManager.shared.fetchItinerary(for: trip) {
            // Show existing itinerary
            let detailVC = ItineraryDetailViewController()
            detailVC.existingItinerary = existingItinerary
            detailVC.associatedTrip = trip
            navigationController?.pushViewController(detailVC, animated: true)
        } else {
            // Generate new itinerary
            let generatorVC = ItineraryGeneratorViewController()
            generatorVC.associatedTrip = trip
            let nav = UINavigationController(rootViewController: generatorVC)
            present(nav, animated: true)
        }
    }

    @available(iOS 26.0, *)
    @objc private func packingListAIButtonTapped() {
        let packingVC = PackingListViewController()
        packingVC.associatedTrip = trip

        // Check if packing list already exists
        if let existingList = CoreDataManager.shared.fetchPackingList(for: trip) {
            packingVC.existingPackingList = existingList
        }

        let nav = UINavigationController(rootViewController: packingVC)
        present(nav, animated: true)
    }

    @available(iOS 26.0, *)
    @objc private func briefingAIButtonTapped() {
        let briefingVC = BriefingDetailViewController()
        briefingVC.destination = trip.destination ?? ""
        briefingVC.associatedTrip = trip

        // Check if briefing already exists
        if let existingBriefing = CoreDataManager.shared.fetchBriefing(for: trip) {
            briefingVC.existingBriefing = existingBriefing
        }

        let nav = UINavigationController(rootViewController: briefingVC)
        present(nav, animated: true)
    }

    @available(iOS 26.0, *)
    @objc private func summaryAIButtonTapped() {
        guard !trip.isActive else {
            showAlert(title: "Viaggio in Corso", message: "Completa il viaggio per generare il riassunto.")
            return
        }

        let summaryVC = TripSummaryViewController()
        summaryVC.associatedTrip = trip

        // Check if summary already exists
        if let existingSummary = CoreDataManager.shared.fetchSummary(for: trip) {
            summaryVC.existingSummary = existingSummary
        }

        let nav = UINavigationController(rootViewController: summaryVC)
        present(nav, animated: true)
    }
    #else
    // Fallback per iOS < 26 o SDK non disponibile
    @objc private func itineraryAIButtonTapped() {
        showAlert(title: "Non Disponibile", message: "Le funzionalita AI richiedono iOS 26 o successivo.")
    }

    @objc private func packingListAIButtonTapped() {
        showAlert(title: "Non Disponibile", message: "Le funzionalita AI richiedono iOS 26 o successivo.")
    }

    @objc private func briefingAIButtonTapped() {
        showAlert(title: "Non Disponibile", message: "Le funzionalita AI richiedono iOS 26 o successivo.")
    }

    @objc private func summaryAIButtonTapped() {
        showAlert(title: "Non Disponibile", message: "Le funzionalita AI richiedono iOS 26 o successivo.")
    }
    #endif
}

// MARK: - UICollectionViewDataSource
extension TripDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoDetailCell", for: indexPath) as! PhotoDetailCell
        let photo = photos[indexPath.item]
        cell.configure(with: photo)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension TripDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = photos[indexPath.item]
        print("Selected photo: \(photo)")
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension TripDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height
        return CGSize(width: height, height: height)
    }
}

// MARK: - UITableViewDataSource
extension TripDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteDetailCell", for: indexPath) as! NoteDetailCell
        let note = notes[indexPath.row]
        cell.configure(with: note)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TripDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - PhotoDetailCell
class PhotoDetailCell: UICollectionViewCell {

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with photo: Photo) {
        if let imagePath = photo.imagePath {
            imageView.image = PhotoStorageManager.shared.loadPhoto(at: imagePath)
        } else {
            imageView.image = UIImage(systemName: "photo")
        }
    }
}

// MARK: - NoteDetailCell
class NoteDetailCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none
        textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        textLabel?.numberOfLines = 0
        detailTextLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        detailTextLabel?.textColor = .secondaryLabel
    }

    func configure(with note: Note) {
        textLabel?.text = note.content

        if let timestamp = note.timestamp {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            detailTextLabel?.text = formatter.string(from: timestamp)
        }
    }
}
