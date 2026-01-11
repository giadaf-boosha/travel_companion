import UIKit

/// Controller per la visualizzazione e gestione della packing list generata dall'AI
final class PackingListViewController: UIViewController {

    // MARK: - Properties

    /// Trip associato (opzionale)
    var associatedTrip: Trip?

    /// Packing list salvata in Core Data (per visualizzazione esistente)
    var savedPackingList: PackingList?

    /// Parametri per la generazione
    var destination: String?
    var duration: Int = 3
    var tripType: String = "multi-giorno"
    var season: String = "primavera"

    private var items: [(category: String, items: [PackingItemModel])] = []
    private var isGenerating = false

    // MARK: - Model

    private struct PackingItemModel {
        let id: UUID
        let name: String
        var isChecked: Bool
        let isCustom: Bool
        var coreDataItem: PackingItem?
    }

    // MARK: - UI Components

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.accessibilityIdentifier = AccessibilityIdentifiers.PackingList.tableView
        return tv
    }()

    private let progressView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemBackground
        return v
    }()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.accessibilityIdentifier = AccessibilityIdentifiers.PackingList.progressLabel
        return label
    }()

    private let progressBar: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.trackTintColor = .systemGray5
        pv.progressTintColor = .systemGreen
        pv.layer.cornerRadius = 4
        pv.clipsToBounds = true
        return pv
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
        indicator.accessibilityIdentifier = AccessibilityIdentifiers.PackingList.loadingIndicator
        return indicator
    }()

    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Generazione lista in corso..."
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
        label.text = "Nessuna lista disponibile.\nTocca 'Genera' per creare una nuova lista."
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
        setupTableView()
        loadData()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(progressView)
        progressView.addSubview(progressLabel)
        progressView.addSubview(progressBar)

        view.addSubview(tableView)
        view.addSubview(loadingContainer)
        loadingContainer.addSubview(loadingIndicator)
        loadingContainer.addSubview(loadingLabel)

        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyStateLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Progress View
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 60),

            progressLabel.topAnchor.constraint(equalTo: progressView.topAnchor, constant: 8),
            progressLabel.centerXAnchor.constraint(equalTo: progressView.centerXAnchor),

            progressBar.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: progressView.leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: progressView.trailingAnchor, constant: -20),
            progressBar.heightAnchor.constraint(equalToConstant: 8),

            // Table View
            tableView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

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

            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -20),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }

    private func setupNavigationBar() {
        title = "Packing List"

        let generateButton = UIBarButtonItem(
            image: UIImage(systemName: "wand.and.stars"),
            style: .plain,
            target: self,
            action: #selector(generateTapped)
        )

        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addItemTapped)
        )
        addButton.accessibilityIdentifier = AccessibilityIdentifiers.PackingList.addItemButton

        navigationItem.rightBarButtonItems = [addButton, generateButton]
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PackingItemCell.self, forCellReuseIdentifier: "PackingItemCell")
        tableView.rowHeight = 50
    }

    // MARK: - Data Loading

    private func loadData() {
        if let savedList = savedPackingList {
            loadFromSaved(savedList)
        } else if let trip = associatedTrip {
            // Prova a caricare una lista esistente per il trip
            if let existingList = CoreDataManager.shared.fetchPackingList(for: trip) {
                savedPackingList = existingList
                loadFromSaved(existingList)
            } else {
                // Genera automaticamente se abbiamo tutti i parametri
                destination = trip.destination
                if let startDate = trip.startDate, let endDate = trip.endDate {
                    let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
                    duration = max(1, days + 1)
                }
                tripType = trip.tripTypeRaw ?? "multi-giorno"
                season = getCurrentSeason()

                if destination != nil {
                    generatePackingList()
                } else {
                    showEmptyState(true)
                }
            }
        } else if destination != nil {
            generatePackingList()
        } else {
            showEmptyState(true)
        }
    }

    private func loadFromSaved(_ packingList: PackingList) {
        let fetchedItems = CoreDataManager.shared.fetchPackingItems(for: packingList)

        // Raggruppa per categoria
        var grouped: [String: [PackingItemModel]] = [:]

        for item in fetchedItems {
            guard let category = item.category, let name = item.name else { continue }

            let model = PackingItemModel(
                id: item.id ?? UUID(),
                name: name,
                isChecked: item.isChecked,
                isCustom: item.isCustom,
                coreDataItem: item
            )

            if grouped[category] == nil {
                grouped[category] = []
            }
            grouped[category]?.append(model)
        }

        // Ordina le categorie
        items = Constants.AIAssistant.packingCategories.compactMap { category in
            guard let categoryItems = grouped[category], !categoryItems.isEmpty else { return nil }
            return (category: category, items: categoryItems)
        }

        updateUI()
    }

    private func loadFromGenerated(_ generated: GeneratedPackingListData) {
        items = [
            ("documents", generated.documents.map { PackingItemModel(id: UUID(), name: $0, isChecked: false, isCustom: false, coreDataItem: nil) }),
            ("clothing", generated.clothing.map { PackingItemModel(id: UUID(), name: $0, isChecked: false, isCustom: false, coreDataItem: nil) }),
            ("toiletries", generated.toiletries.map { PackingItemModel(id: UUID(), name: $0, isChecked: false, isCustom: false, coreDataItem: nil) }),
            ("electronics", generated.electronics.map { PackingItemModel(id: UUID(), name: $0, isChecked: false, isCustom: false, coreDataItem: nil) }),
            ("specialItems", generated.specialItems.map { PackingItemModel(id: UUID(), name: $0, isChecked: false, isCustom: false, coreDataItem: nil) }),
            ("healthKit", generated.healthKit.map { PackingItemModel(id: UUID(), name: $0, isChecked: false, isCustom: false, coreDataItem: nil) })
        ].filter { !$0.1.isEmpty }

        // Salva in Core Data se abbiamo un trip
        if let trip = associatedTrip {
            saveToTrip(trip)
        }

        updateUI()
    }

    private func saveToTrip(_ trip: Trip) {
        // Elimina eventuale lista esistente
        if let existingList = CoreDataManager.shared.fetchPackingList(for: trip) {
            CoreDataManager.shared.deletePackingList(existingList)
        }

        // Crea nuova lista
        let packingList = CoreDataManager.shared.createPackingList(
            destination: destination ?? trip.destination ?? "Unknown",
            duration: duration,
            for: trip
        )

        savedPackingList = packingList

        // Aggiungi tutti gli items
        var allItems: [(category: String, name: String)] = []
        for (category, categoryItems) in items {
            for item in categoryItems {
                allItems.append((category: category, name: item.name))
            }
        }

        CoreDataManager.shared.addGeneratedItems(to: packingList, items: allItems)

        // Ricarica dalla persistenza per avere i riferimenti Core Data
        loadFromSaved(packingList)

        // Notifica
        NotificationCenter.default.post(name: Constants.NotificationName.packingListGenerated, object: nil)
    }

    // MARK: - Generation

    private func generatePackingList() {
        guard let destination = destination else {
            showAlert(title: "Errore", message: "Destinazione non specificata")
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

        Task {
            do {
                let generated = try await FoundationModelService.shared.generatePackingList(
                    destination: destination,
                    duration: duration,
                    tripType: tripType,
                    season: season
                )

                await MainActor.run {
                    self.showLoading(false)
                    self.isGenerating = false
                    self.loadFromGenerated(generated)
                }
            } catch {
                await MainActor.run {
                    self.showLoading(false)
                    self.isGenerating = false
                    self.handleGenerationError(error)
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func generateTapped() {
        // Se non abbiamo una destinazione, chiedi all'utente
        if destination == nil && associatedTrip?.destination == nil {
            showDestinationInput()
            return
        }

        // Conferma rigenerazione se ci sono gia items
        if !items.isEmpty {
            let alert = UIAlertController(
                title: "Rigenera Lista",
                message: "Vuoi rigenerare la lista? Gli elementi attuali verranno sostituiti.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
            alert.addAction(UIAlertAction(title: "Rigenera", style: .destructive) { [weak self] _ in
                self?.generatePackingList()
            })

            present(alert, animated: true)
        } else {
            generatePackingList()
        }
    }

    @objc private func addItemTapped() {
        guard !items.isEmpty else {
            showAlert(title: "Lista Vuota", message: "Genera prima una lista per poter aggiungere elementi.")
            return
        }

        let alert = UIAlertController(title: "Aggiungi Elemento", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Nome elemento"
            textField.autocapitalizationType = .sentences
        }

        // Selettore categoria come action sheet nested
        let categories = Constants.AIAssistant.packingCategories
        let categoryNames = categories.map { Constants.AIAssistant.packingCategoryDisplayNames[$0] ?? $0 }

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))

        for (index, categoryName) in categoryNames.enumerated() {
            alert.addAction(UIAlertAction(title: "Aggiungi a \(categoryName)", style: .default) { [weak self] _ in
                guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !name.isEmpty else {
                    self?.showAlert(title: "Errore", message: "Inserisci un nome valido")
                    return
                }

                self?.addItem(name: name, to: categories[index])
            })
        }

        present(alert, animated: true)
    }

    private func addItem(name: String, to category: String) {
        let newItem = PackingItemModel(
            id: UUID(),
            name: name,
            isChecked: false,
            isCustom: true,
            coreDataItem: nil
        )

        // Trova o crea la categoria
        if let index = items.firstIndex(where: { $0.category == category }) {
            items[index].items.append(newItem)
        } else {
            items.append((category: category, items: [newItem]))
            // Riordina secondo l'ordine standard
            items.sort { cat1, cat2 in
                let idx1 = Constants.AIAssistant.packingCategories.firstIndex(of: cat1.category) ?? Int.max
                let idx2 = Constants.AIAssistant.packingCategories.firstIndex(of: cat2.category) ?? Int.max
                return idx1 < idx2
            }
        }

        // Salva in Core Data se abbiamo una packing list
        if let packingList = savedPackingList {
            let _ = CoreDataManager.shared.addPackingItem(
                to: packingList,
                category: category,
                name: name,
                isCustom: true
            )
        }

        tableView.reloadData()
        updateProgress()
    }

    private func showDestinationInput() {
        let alert = UIAlertController(title: "Destinazione", message: "Inserisci la destinazione per generare la lista.", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Es. Roma, Parigi, Tokyo"
            textField.autocapitalizationType = .words
        }

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Genera", style: .default) { [weak self] _ in
            guard let dest = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !dest.isEmpty else {
                return
            }
            self?.destination = dest
            self?.generatePackingList()
        })

        present(alert, animated: true)
    }

    // MARK: - UI Updates

    private func updateUI() {
        showEmptyState(items.isEmpty)
        tableView.reloadData()
        updateProgress()
    }

    private func updateProgress() {
        var total = 0
        var checked = 0

        for (_, categoryItems) in items {
            total += categoryItems.count
            checked += categoryItems.filter { $0.isChecked }.count
        }

        let progress = total > 0 ? Float(checked) / Float(total) : 0
        progressBar.setProgress(progress, animated: true)
        progressLabel.text = "\(checked)/\(total) elementi pronti"

        if progress == 1 {
            progressBar.progressTintColor = .systemGreen
        } else {
            progressBar.progressTintColor = .systemBlue
        }
    }

    private func showLoading(_ show: Bool) {
        loadingContainer.isHidden = !show
        if show {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    private func showEmptyState(_ show: Bool) {
        emptyStateView.isHidden = !show
        tableView.isHidden = show
        progressView.isHidden = show
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
                self?.generatePackingList()
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
                    self?.generatePackingList()
                })
            }
        }

        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Helpers

    private func getCurrentSeason() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:
            return "primavera"
        case 6...8:
            return "estate"
        case 9...11:
            return "autunno"
        default:
            return "inverno"
        }
    }
}

// MARK: - UITableViewDataSource

extension PackingListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let category = items[section].category
        return Constants.AIAssistant.packingCategoryDisplayNames[category] ?? category.capitalized
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PackingItemCell", for: indexPath) as? PackingItemCell else {
            return UITableViewCell()
        }

        let item = items[indexPath.section].items[indexPath.row]
        cell.configure(with: item.name, isChecked: item.isChecked, isCustom: item.isCustom)
        cell.accessibilityIdentifier = "\(AccessibilityIdentifiers.PackingList.itemCell)_\(indexPath.section)_\(indexPath.row)"

        return cell
    }
}

// MARK: - UITableViewDelegate

extension PackingListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Toggle checked state
        items[indexPath.section].items[indexPath.row].isChecked.toggle()
        let item = items[indexPath.section].items[indexPath.row]

        // Aggiorna Core Data
        if let coreDataItem = item.coreDataItem {
            CoreDataManager.shared.togglePackingItem(coreDataItem)
        }

        // Aggiorna UI
        if let cell = tableView.cellForRow(at: indexPath) as? PackingItemCell {
            cell.setChecked(item.isChecked, animated: true)
        }

        updateProgress()
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Elimina") { [weak self] _, _, completion in
            self?.deleteItem(at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    private func deleteItem(at indexPath: IndexPath) {
        let item = items[indexPath.section].items[indexPath.row]

        // Elimina da Core Data
        if let coreDataItem = item.coreDataItem {
            CoreDataManager.shared.deletePackingItem(coreDataItem)
        }

        // Rimuovi dal modello
        items[indexPath.section].items.remove(at: indexPath.row)

        // Se la categoria e vuota, rimuovila
        if items[indexPath.section].items.isEmpty {
            items.remove(at: indexPath.section)
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
        } else {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }

        updateProgress()
    }
}

// MARK: - PackingItemCell

private class PackingItemCell: UITableViewCell {

    private let checkmarkImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemGreen
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .regular)
        return label
    }()

    private let customBadge: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemOrange.withAlphaComponent(0.15)
        v.layer.cornerRadius = 4
        v.isHidden = true
        return v
    }()

    private let customLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Aggiunto"
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .systemOrange
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(checkmarkImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(customBadge)
        customBadge.addSubview(customLabel)

        NSLayoutConstraint.activate([
            checkmarkImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24),

            nameLabel.leadingAnchor.constraint(equalTo: checkmarkImageView.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            customBadge.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            customBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            customBadge.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),

            customLabel.topAnchor.constraint(equalTo: customBadge.topAnchor, constant: 2),
            customLabel.leadingAnchor.constraint(equalTo: customBadge.leadingAnchor, constant: 6),
            customLabel.trailingAnchor.constraint(equalTo: customBadge.trailingAnchor, constant: -6),
            customLabel.bottomAnchor.constraint(equalTo: customBadge.bottomAnchor, constant: -2)
        ])
    }

    func configure(with name: String, isChecked: Bool, isCustom: Bool) {
        nameLabel.text = name
        customBadge.isHidden = !isCustom
        setChecked(isChecked, animated: false)
    }

    func setChecked(_ checked: Bool, animated: Bool) {
        let imageName = checked ? "checkmark.circle.fill" : "circle"
        let duration = animated ? 0.2 : 0

        UIView.transition(with: checkmarkImageView, duration: duration, options: .transitionCrossDissolve) {
            self.checkmarkImageView.image = UIImage(systemName: imageName)
            self.checkmarkImageView.tintColor = checked ? .systemGreen : .systemGray3
        }

        UIView.animate(withDuration: duration) {
            self.nameLabel.alpha = checked ? 0.6 : 1.0
        }
    }
}
