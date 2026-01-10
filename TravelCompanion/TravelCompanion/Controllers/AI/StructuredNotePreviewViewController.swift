import UIKit
import CoreLocation

/// Controller per la preview e modifica di una nota strutturata dall'AI
final class StructuredNotePreviewViewController: UIViewController {

    // MARK: - Properties

    /// Testo grezzo da strutturare
    var rawText: String = ""

    /// Trip associato (richiesto per salvare)
    var associatedTrip: Trip?

    /// Nota strutturata generata
    private var structuredNote: StructuredNoteData?

    private var isProcessing = false

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .interactive
        sv.accessibilityIdentifier = AccessibilityIdentifiers.StructuredNotePreview.scrollView
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
        label.text = "Anteprima Nota"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()

    private let originalTextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Testo originale"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let originalTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = .systemFont(ofSize: 14, weight: .regular)
        tv.backgroundColor = .tertiarySystemBackground
        tv.layer.cornerRadius = 8
        tv.isEditable = false
        tv.isScrollEnabled = false
        return tv
    }()

    // Category
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Categoria"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    private let categorySegment: UISegmentedControl = {
        let items = NoteCategory.allCases.map { $0.displayName }
        let segment = UISegmentedControl(items: items)
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.selectedSegmentIndex = 0
        segment.accessibilityIdentifier = AccessibilityIdentifiers.StructuredNotePreview.categoryPicker
        return segment
    }()

    // Place Name
    private let placeNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Nome Luogo (opzionale)"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    private let placeNameTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Es. Trattoria Da Mario"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .words
        tf.returnKeyType = .done
        tf.accessibilityIdentifier = AccessibilityIdentifiers.StructuredNotePreview.placeNameTextField
        return tf
    }()

    // Rating
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Valutazione"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    private let ratingStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.spacing = 8
        sv.distribution = .fillEqually
        sv.accessibilityIdentifier = AccessibilityIdentifiers.StructuredNotePreview.ratingPicker
        return sv
    }()

    private var ratingButtons: [UIButton] = []
    private var selectedRating: Int = 0

    // Cost
    private let costLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Costo (opzionale)"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    private let costTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Es. €25 a persona"
        tf.borderStyle = .roundedRect
        tf.returnKeyType = .done
        tf.accessibilityIdentifier = AccessibilityIdentifiers.StructuredNotePreview.costTextField
        return tf
    }()

    // Summary
    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Riepilogo"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    private let summaryTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = .systemFont(ofSize: 16, weight: .regular)
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 8
        tv.isScrollEnabled = false
        tv.accessibilityIdentifier = AccessibilityIdentifiers.StructuredNotePreview.summaryTextView
        return tv
    }()

    // Tags
    private let tagsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Tag"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    private let tagsContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 8
        v.accessibilityIdentifier = AccessibilityIdentifiers.StructuredNotePreview.tagsView
        return v
    }()

    private let tagsStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        return sv
    }()

    // Buttons
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Salva Nota", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.accessibilityIdentifier = AccessibilityIdentifiers.StructuredNotePreview.saveButton
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
        return indicator
    }()

    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Elaborazione in corso..."
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
        setupKeyboardHandling()
        displayOriginalText()
        processWithAI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerLabel)
        contentView.addSubview(originalTextLabel)
        contentView.addSubview(originalTextView)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(categorySegment)
        contentView.addSubview(placeNameLabel)
        contentView.addSubview(placeNameTextField)
        contentView.addSubview(ratingLabel)
        contentView.addSubview(ratingStackView)
        contentView.addSubview(costLabel)
        contentView.addSubview(costTextField)
        contentView.addSubview(summaryLabel)
        contentView.addSubview(summaryTextView)
        contentView.addSubview(tagsLabel)
        contentView.addSubview(tagsContainerView)
        tagsContainerView.addSubview(tagsStackView)
        contentView.addSubview(saveButton)

        view.addSubview(loadingContainer)
        loadingContainer.addSubview(loadingIndicator)
        loadingContainer.addSubview(loadingLabel)

        placeNameTextField.delegate = self
        costTextField.delegate = self

        setupRatingButtons()
    }

    private func setupRatingButtons() {
        for i in 1...5 {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "star"), for: .normal)
            button.tintColor = .systemYellow
            button.tag = i
            button.addTarget(self, action: #selector(ratingTapped(_:)), for: .touchUpInside)
            ratingButtons.append(button)
            ratingStackView.addArrangedSubview(button)
        }
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

            // Original Text
            originalTextLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            originalTextLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            originalTextView.topAnchor.constraint(equalTo: originalTextLabel.bottomAnchor, constant: 8),
            originalTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            originalTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Category
            categoryLabel.topAnchor.constraint(equalTo: originalTextView.bottomAnchor, constant: 24),
            categoryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            categorySegment.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 8),
            categorySegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            categorySegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Place Name
            placeNameLabel.topAnchor.constraint(equalTo: categorySegment.bottomAnchor, constant: 24),
            placeNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            placeNameTextField.topAnchor.constraint(equalTo: placeNameLabel.bottomAnchor, constant: 8),
            placeNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            placeNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            placeNameTextField.heightAnchor.constraint(equalToConstant: 44),

            // Rating
            ratingLabel.topAnchor.constraint(equalTo: placeNameTextField.bottomAnchor, constant: 24),
            ratingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            ratingStackView.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 8),
            ratingStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            ratingStackView.heightAnchor.constraint(equalToConstant: 44),

            // Cost
            costLabel.topAnchor.constraint(equalTo: ratingStackView.bottomAnchor, constant: 24),
            costLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            costTextField.topAnchor.constraint(equalTo: costLabel.bottomAnchor, constant: 8),
            costTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            costTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            costTextField.heightAnchor.constraint(equalToConstant: 44),

            // Summary
            summaryLabel.topAnchor.constraint(equalTo: costTextField.bottomAnchor, constant: 24),
            summaryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            summaryTextView.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 8),
            summaryTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            summaryTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            summaryTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            // Tags
            tagsLabel.topAnchor.constraint(equalTo: summaryTextView.bottomAnchor, constant: 24),
            tagsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            tagsContainerView.topAnchor.constraint(equalTo: tagsLabel.bottomAnchor, constant: 8),
            tagsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            tagsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            tagsContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            tagsStackView.topAnchor.constraint(equalTo: tagsContainerView.topAnchor, constant: 8),
            tagsStackView.leadingAnchor.constraint(equalTo: tagsContainerView.leadingAnchor, constant: 8),
            tagsStackView.trailingAnchor.constraint(lessThanOrEqualTo: tagsContainerView.trailingAnchor, constant: -8),
            tagsStackView.bottomAnchor.constraint(equalTo: tagsContainerView.bottomAnchor, constant: -8),

            // Save Button
            saveButton.topAnchor.constraint(equalTo: tagsContainerView.bottomAnchor, constant: 32),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),

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
        title = "Struttura Nota"

        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        cancelButton.accessibilityIdentifier = AccessibilityIdentifiers.StructuredNotePreview.cancelButton
        navigationItem.leftBarButtonItem = cancelButton
    }

    private func setupActions() {
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // MARK: - Data Display

    private func displayOriginalText() {
        originalTextView.text = rawText
    }

    private func populateFromStructuredNote(_ note: StructuredNoteData) {
        // Category
        if let category = NoteCategory(rawValue: note.category) {
            if let index = NoteCategory.allCases.firstIndex(of: category) {
                categorySegment.selectedSegmentIndex = index
            }
        }

        // Place name
        placeNameTextField.text = note.placeName

        // Rating
        if let rating = note.rating {
            setRating(rating)
        }

        // Cost
        costTextField.text = note.cost

        // Summary
        summaryTextView.text = note.summary

        // Tags
        updateTagsDisplay(note.tags)
    }

    private func updateTagsDisplay(_ tags: [String]) {
        // Remove existing tag views
        tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for tag in tags {
            let tagView = createTagView(tag)
            tagsStackView.addArrangedSubview(tagView)
        }

        if tags.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "Nessun tag"
            emptyLabel.font = .systemFont(ofSize: 14, weight: .regular)
            emptyLabel.textColor = .tertiaryLabel
            tagsStackView.addArrangedSubview(emptyLabel)
        }
    }

    private func createTagView(_ tag: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBlue.withAlphaComponent(0.15)
        container.layer.cornerRadius = 12

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "#\(tag)"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .systemBlue
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])

        return container
    }

    private func setRating(_ rating: Int) {
        selectedRating = rating
        for (index, button) in ratingButtons.enumerated() {
            let imageName = index < rating ? "star.fill" : "star"
            button.setImage(UIImage(systemName: imageName), for: .normal)
        }
    }

    // MARK: - AI Processing

    private func processWithAI() {
        guard !rawText.isEmpty else {
            showAlert(title: "Errore", message: "Nessun testo da elaborare")
            return
        }

        // Check availability
        let availabilityResult = FoundationModelService.shared.checkAvailability()
        switch availabilityResult {
        case .available:
            break
        case .unavailable(let title, let message, _):
            // Usa un fallback manuale
            showAlert(title: title, message: message)
            populateWithDefaults()
            return
        }

        showLoading(true)
        isProcessing = true

        #if canImport(FoundationModels)
        Task {
            do {
                let structured = try await FoundationModelService.shared.structureNote(rawText: rawText)

                // Convert to Data structure
                let structuredData = StructuredNoteData(
                    category: structured.category,
                    placeName: structured.placeName,
                    rating: structured.rating,
                    cost: structured.cost,
                    summary: structured.summary,
                    tags: structured.tags
                )

                await MainActor.run {
                    self.showLoading(false)
                    self.isProcessing = false
                    self.structuredNote = structuredData
                    self.populateFromStructuredNote(structuredData)
                }
            } catch {
                await MainActor.run {
                    self.showLoading(false)
                    self.isProcessing = false
                    self.handleGenerationError(error)
                    self.populateWithDefaults()
                }
            }
        }
        #else
        showLoading(false)
        isProcessing = false
        populateWithDefaults()
        #endif
    }

    private func populateWithDefaults() {
        // Popola con valori di default
        categorySegment.selectedSegmentIndex = NoteCategory.allCases.count - 1 // "altro"
        summaryTextView.text = rawText
        updateTagsDisplay([])
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func ratingTapped(_ sender: UIButton) {
        setRating(sender.tag)
    }

    @objc private func saveTapped() {
        guard let trip = associatedTrip else {
            showAlert(title: "Errore", message: "Nessun viaggio associato")
            return
        }

        let category = NoteCategory.allCases[categorySegment.selectedSegmentIndex].rawValue
        let placeName = placeNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let rating = selectedRating > 0 ? selectedRating : nil
        let cost = costTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = summaryTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Estrai i tag dalla UI
        var tags: [String] = []
        if let note = structuredNote {
            tags = note.tags
        }

        // Costruisci il contenuto completo
        var content = summary
        if let place = placeName, !place.isEmpty {
            content = "[\(place)] " + content
        }

        // Ottieni posizione corrente se disponibile
        let location = LocationManager.shared.currentLocation

        // Salva in Core Data
        let _ = CoreDataManager.shared.createStructuredNote(
            for: trip,
            content: content,
            category: category,
            placeName: placeName,
            rating: rating,
            cost: cost,
            tags: tags,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude
        )

        // Notifica il salvataggio
        NotificationCenter.default.post(name: Constants.NotificationName.noteAdded, object: nil)

        // Mostra conferma e torna indietro
        let alert = UIAlertController(
            title: "Salvato",
            message: "La nota e stata salvata con successo.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            // Torna alla home o alla lista note
            self?.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    // MARK: - UI State

    private func showLoading(_ show: Bool) {
        loadingContainer.isHidden = !show
        if show {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        saveButton.isEnabled = !show
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
                self?.processWithAI()
            })
        }

        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension StructuredNotePreviewViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
