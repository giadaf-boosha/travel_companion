//
//  NewTripViewController.swift
//  TravelCompanion
//
//  Schermata per la creazione di un nuovo viaggio.
//  Raccoglie informazioni essenziali: destinazione, date, tipo viaggio.
//
//  Funzionalita:
//  - Campo testo per la destinazione con validazione
//  - Selettori data per inizio e fine viaggio
//  - Selezione tipo viaggio (locale, giornaliero, multi-giorno)
//  - Opzione per avviare automaticamente il tracking GPS
//  - Validazione input con messaggi di errore localizzati
//
//  Created by Travel Companion Team on 07/12/2025.
//

import UIKit

// MARK: - Protocollo Delegate

/// Protocollo delegate per comunicare gli eventi di creazione viaggio
protocol NewTripViewControllerDelegate: AnyObject {
    /// Chiamato quando un viaggio viene creato con successo
    /// - Parameters:
    ///   - trip: Il viaggio creato
    ///   - shouldStartTracking: Se avviare immediatamente il tracking GPS
    func didCreateTrip(_ trip: Trip, shouldStartTracking: Bool)

    /// Chiamato quando l'utente annulla la creazione del viaggio
    func didCancelTripCreation()
}

// MARK: - New Trip View Controller

/// Controller per la schermata di creazione nuovo viaggio.
///
/// Presenta un form con:
/// - Destinazione (obbligatoria, min 2 caratteri)
/// - Data inizio (default: oggi)
/// - Data fine (default: +7 giorni)
/// - Tipo viaggio (segmented control)
/// - Switch per tracking automatico
///
/// La validazione avviene al tap su "Crea Viaggio".
class NewTripViewController: UIViewController {

    // MARK: - Componenti UI
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let destinationTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Es. Roma, Parigi, Tokyo"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .words
        textField.returnKeyType = .done
        textField.clearButtonMode = .whileEditing
        textField.font = .systemFont(ofSize: 16)
        return textField
    }()

    private let destinationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Destinazione"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let startDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .date
        picker.minimumDate = Date()
        picker.date = Date()
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .wheels
        }
        return picker
    }()

    private let startDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Data Inizio"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let endDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .date
        picker.minimumDate = Date()
        picker.date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .wheels
        }
        return picker
    }()

    private let endDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Data Fine"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let tripTypeSegment: UISegmentedControl = {
        let items = ["Locale", "Giornaliero", "Multi-giorno"]
        let segment = UISegmentedControl(items: items)
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.selectedSegmentIndex = 0
        return segment
    }()

    private let tripTypeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Tipo Viaggio"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let startTrackingSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.isOn = true
        switchControl.onTintColor = .systemGreen
        return switchControl
    }()

    private let trackingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Inizia tracking automaticamente"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()

    private let trackingStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 12
        return stack
    }()

    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Crea Viaggio", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 12
        return button
    }()

    // MARK: - Properties
    weak var delegate: NewTripViewControllerDelegate?
    private var selectedTripType: TripType = .local

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupNavigationBar()
        setupActions()
        setupKeyboardHandling()
    }

    // MARK: - Setup Views
    private func setupViews() {
        view.backgroundColor = .systemBackground

        // Add scroll view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.accessibilityIdentifier = AccessibilityIdentifiers.NewTrip.scrollView

        // Add components to content view
        contentView.addSubview(destinationLabel)
        contentView.addSubview(destinationTextField)
        contentView.addSubview(startDateLabel)
        contentView.addSubview(startDatePicker)
        contentView.addSubview(endDateLabel)
        contentView.addSubview(endDatePicker)
        contentView.addSubview(tripTypeLabel)
        contentView.addSubview(tripTypeSegment)

        // Setup tracking stack
        trackingStackView.addArrangedSubview(trackingLabel)
        trackingStackView.addArrangedSubview(startTrackingSwitch)
        contentView.addSubview(trackingStackView)

        contentView.addSubview(createButton)

        // Setup delegates
        destinationTextField.delegate = self

        // Setup accessibility identifiers
        destinationTextField.accessibilityIdentifier = AccessibilityIdentifiers.NewTrip.destinationTextField
        startDatePicker.accessibilityIdentifier = AccessibilityIdentifiers.NewTrip.startDatePicker
        endDatePicker.accessibilityIdentifier = AccessibilityIdentifiers.NewTrip.endDatePicker
        tripTypeSegment.accessibilityIdentifier = AccessibilityIdentifiers.NewTrip.tripTypeSegment
        startTrackingSwitch.accessibilityIdentifier = AccessibilityIdentifiers.NewTrip.startTrackingSwitch
        createButton.accessibilityIdentifier = AccessibilityIdentifiers.NewTrip.createButton

        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismiss))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Destination label
            destinationLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            destinationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            destinationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Destination text field
            destinationTextField.topAnchor.constraint(equalTo: destinationLabel.bottomAnchor, constant: 8),
            destinationTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            destinationTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            destinationTextField.heightAnchor.constraint(equalToConstant: 44),

            // Start date label
            startDateLabel.topAnchor.constraint(equalTo: destinationTextField.bottomAnchor, constant: 24),
            startDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            startDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Start date picker
            startDatePicker.topAnchor.constraint(equalTo: startDateLabel.bottomAnchor, constant: 8),
            startDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            startDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // End date label
            endDateLabel.topAnchor.constraint(equalTo: startDatePicker.bottomAnchor, constant: 24),
            endDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            endDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // End date picker
            endDatePicker.topAnchor.constraint(equalTo: endDateLabel.bottomAnchor, constant: 8),
            endDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            endDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Trip type label
            tripTypeLabel.topAnchor.constraint(equalTo: endDatePicker.bottomAnchor, constant: 24),
            tripTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tripTypeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Trip type segment
            tripTypeSegment.topAnchor.constraint(equalTo: tripTypeLabel.bottomAnchor, constant: 8),
            tripTypeSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tripTypeSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tripTypeSegment.heightAnchor.constraint(equalToConstant: 32),

            // Tracking stack view
            trackingStackView.topAnchor.constraint(equalTo: tripTypeSegment.bottomAnchor, constant: 24),
            trackingStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            trackingStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Create button
            createButton.topAnchor.constraint(equalTo: trackingStackView.bottomAnchor, constant: 32),
            createButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            createButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            createButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    private func setupNavigationBar() {
        title = "Nuovo Viaggio"

        // Cancel button
        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        navigationItem.leftBarButtonItem = cancelButton
    }

    private func setupActions() {
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        startDatePicker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        tripTypeSegment.addTarget(self, action: #selector(tripTypeChanged), for: .valueChanged)
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

    // MARK: - Validation
    private func validateInput() -> (isValid: Bool, errorMessage: String?) {
        // Check destination
        guard let destination = destinationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !destination.isEmpty else {
            return (false, "Inserisci una destinazione")
        }

        guard destination.count >= 2 else {
            return (false, "La destinazione deve contenere almeno 2 caratteri")
        }

        // Check dates
        let startDate = startDatePicker.date
        let endDate = endDatePicker.date

        // Validate date range
        if endDate < startDate {
            return (false, "La data di fine deve essere successiva alla data di inizio")
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        if let days = components.day, days > 365 {
            return (false, "Il viaggio non può durare più di un anno")
        }

        return (true, nil)
    }

    // MARK: - Trip Creation
    private func createTrip() {
        // Validate input
        let validation = validateInput()
        guard validation.isValid else {
            showAlert(title: "Errore di Validazione", message: validation.errorMessage ?? "Dati non validi")
            return
        }

        // Get values
        guard let destination = destinationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }

        let startDate = startDatePicker.date
        let endDate = endDatePicker.date
        let shouldStartTracking = startTrackingSwitch.isOn

        // Create trip
        let trip = CoreDataManager.shared.createTrip(
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            type: selectedTripType,
            isActive: shouldStartTracking
        )

        if let trip = trip {
            // Notify delegate
            delegate?.didCreateTrip(trip, shouldStartTracking: shouldStartTracking)

            // Dismiss
            dismiss(animated: true)
        } else {
            showAlert(title: "Errore", message: "Impossibile creare il viaggio")
        }
    }

    // MARK: - Actions
    @objc private func createButtonTapped() {
        createTrip()
    }

    @objc private func startDateChanged() {
        // Update end date minimum to be after start date
        let startDate = startDatePicker.date
        endDatePicker.minimumDate = startDate

        // If end date is before new minimum, adjust it
        let endDate = endDatePicker.date
        if endDate < startDate {
            endDatePicker.date = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        }
    }

    @objc private func tripTypeChanged() {
        selectedTripType = TripType(segmentIndex: tripTypeSegment.selectedSegmentIndex)
    }

    @objc private func cancelButtonTapped() {
        // Confirm cancellation if data was entered
        if let destination = destinationTextField.text, !destination.isEmpty {
            let alert = UIAlertController(
                title: "Annulla Creazione",
                message: "Sei sicuro di voler annullare? I dati inseriti andranno persi.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Continua Modifica", style: .cancel))
            alert.addAction(UIAlertAction(title: "Annulla", style: .destructive) { [weak self] _ in
                self?.delegate?.didCancelTripCreation()
                self?.dismiss(animated: true)
            })
            present(alert, animated: true)
        } else {
            delegate?.didCancelTripCreation()
            dismiss(animated: true)
        }
    }

    @objc private func handleTapToDismiss() {
        view.endEditing(true)
    }

    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        let keyboardHeight = keyboardFrame.cgRectValue.height
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets

        // Scroll to text field if it's hidden by keyboard
        if destinationTextField.isFirstResponder {
            let rect = destinationTextField.convert(destinationTextField.bounds, to: scrollView)
            scrollView.scrollRectToVisible(rect, animated: true)
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    // MARK: - Alert Helper
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextFieldDelegate
extension NewTripViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Limit destination length
        if textField == destinationTextField {
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            return updatedText.count <= 100
        }
        return true
    }
}
