import UIKit

/// Protocollo delegato per la generazione dell'itinerario
protocol ItineraryGeneratorDelegate: AnyObject {
    func didGenerateItinerary(destination: String, days: Int, tripType: String, travelStyle: String?)
    func didCancelItineraryGeneration()
}

/// Controller per la generazione di un nuovo itinerario AI
final class ItineraryGeneratorViewController: UIViewController {

    // MARK: - Delegate

    weak var delegate: ItineraryGeneratorDelegate?

    // MARK: - Properties

    /// Trip associato (opzionale, per pre-compilare i campi)
    var associatedTrip: Trip?

    private var isGenerating = false

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .interactive
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
        label.text = "Genera Itinerario"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "L'AI creerà un itinerario personalizzato per il tuo viaggio"
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // Destination
    private let destinationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Destinazione"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    private let destinationTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Es. Roma, Parigi, Tokyo"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .words
        tf.returnKeyType = .done
        tf.clearButtonMode = .whileEditing
        tf.accessibilityIdentifier = AccessibilityIdentifiers.ItineraryGenerator.destinationTextField
        return tf
    }()

    // Duration
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Durata (giorni)"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    private let durationValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "3 giorni"
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    private let durationStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.minimumValue = 1
        stepper.maximumValue = 30
        stepper.value = 3
        stepper.stepValue = 1
        return stepper
    }()

    // Trip Type
    private let tripTypeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Tipo di viaggio"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    private let tripTypeSegment: UISegmentedControl = {
        let items = ["Locale", "Giornaliero", "Multi-giorno"]
        let segment = UISegmentedControl(items: items)
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.selectedSegmentIndex = 2
        segment.accessibilityIdentifier = AccessibilityIdentifiers.ItineraryGenerator.tripTypeSegment
        return segment
    }()

    // Travel Style
    private let travelStyleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Stile di viaggio (opzionale)"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        return label
    }()

    private let travelStyleSegment: UISegmentedControl = {
        let items = TravelStyle.allCases.map { $0.displayName }
        let segment = UISegmentedControl(items: items)
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.selectedSegmentIndex = UISegmentedControl.noSegment
        segment.accessibilityIdentifier = AccessibilityIdentifiers.ItineraryGenerator.travelStylePicker
        return segment
    }()

    // Generate Button
    private let generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Genera Itinerario", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.accessibilityIdentifier = AccessibilityIdentifiers.ItineraryGenerator.generateButton
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
        indicator.accessibilityIdentifier = AccessibilityIdentifiers.ItineraryGenerator.loadingIndicator
        return indicator
    }()

    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Generazione itinerario in corso..."
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
        prefillFromTrip()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        scrollView.accessibilityIdentifier = AccessibilityIdentifiers.ItineraryGenerator.scrollView

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(destinationLabel)
        contentView.addSubview(destinationTextField)
        contentView.addSubview(durationLabel)
        contentView.addSubview(durationValueLabel)
        contentView.addSubview(durationStepper)
        contentView.addSubview(tripTypeLabel)
        contentView.addSubview(tripTypeSegment)
        contentView.addSubview(travelStyleLabel)
        contentView.addSubview(travelStyleSegment)
        contentView.addSubview(generateButton)

        view.addSubview(loadingContainer)
        loadingContainer.addSubview(loadingIndicator)
        loadingContainer.addSubview(loadingLabel)

        destinationTextField.delegate = self
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

            // Destination Label
            destinationLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            destinationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            // Destination TextField
            destinationTextField.topAnchor.constraint(equalTo: destinationLabel.bottomAnchor, constant: 8),
            destinationTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            destinationTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            destinationTextField.heightAnchor.constraint(equalToConstant: 44),

            // Duration Label
            durationLabel.topAnchor.constraint(equalTo: destinationTextField.bottomAnchor, constant: 24),
            durationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            // Duration Stepper
            durationStepper.centerYAnchor.constraint(equalTo: durationLabel.centerYAnchor),
            durationStepper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Duration Value
            durationValueLabel.centerYAnchor.constraint(equalTo: durationLabel.centerYAnchor),
            durationValueLabel.trailingAnchor.constraint(equalTo: durationStepper.leadingAnchor, constant: -12),

            // Trip Type Label
            tripTypeLabel.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 24),
            tripTypeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            // Trip Type Segment
            tripTypeSegment.topAnchor.constraint(equalTo: tripTypeLabel.bottomAnchor, constant: 8),
            tripTypeSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            tripTypeSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Travel Style Label
            travelStyleLabel.topAnchor.constraint(equalTo: tripTypeSegment.bottomAnchor, constant: 24),
            travelStyleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),

            // Travel Style Segment
            travelStyleSegment.topAnchor.constraint(equalTo: travelStyleLabel.bottomAnchor, constant: 8),
            travelStyleSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            travelStyleSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Generate Button
            generateButton.topAnchor.constraint(equalTo: travelStyleSegment.bottomAnchor, constant: 40),
            generateButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            generateButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            generateButton.heightAnchor.constraint(equalToConstant: 50),
            generateButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            // Loading Container
            loadingContainer.topAnchor.constraint(equalTo: view.topAnchor),
            loadingContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loadingContainer.centerYAnchor, constant: -20),

            // Loading Label
            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor)
        ])
    }

    private func setupNavigationBar() {
        title = "Nuovo Itinerario"

        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        cancelButton.accessibilityIdentifier = AccessibilityIdentifiers.ItineraryGenerator.cancelButton
        navigationItem.leftBarButtonItem = cancelButton
    }

    private func setupActions() {
        durationStepper.addTarget(self, action: #selector(durationChanged), for: .valueChanged)
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)

        // Tap gesture per nascondere la tastiera
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

    private func prefillFromTrip() {
        guard let trip = associatedTrip else { return }

        destinationTextField.text = trip.destination

        if let startDate = trip.startDate, let endDate = trip.endDate {
            let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
            durationStepper.value = Double(max(1, days + 1))
            updateDurationLabel()
        }

        if let tripTypeRaw = trip.tripTypeRaw {
            switch tripTypeRaw {
            case "local":
                tripTypeSegment.selectedSegmentIndex = 0
            case "dayTrip":
                tripTypeSegment.selectedSegmentIndex = 1
            case "multiDay":
                tripTypeSegment.selectedSegmentIndex = 2
            default:
                tripTypeSegment.selectedSegmentIndex = 2
            }
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.didCancelItineraryGeneration()
        dismiss(animated: true)
    }

    @objc private func durationChanged() {
        updateDurationLabel()
    }

    @objc private func generateTapped() {
        guard validateInput() else { return }

        let destination = destinationTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let days = Int(durationStepper.value)
        let tripType = getTripTypeString()
        let travelStyle = getSelectedTravelStyle()

        generateItinerary(destination: destination, days: days, tripType: tripType, travelStyle: travelStyle)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        let keyboardHeight = keyboardFrame.cgRectValue.height
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    // MARK: - Private Methods

    private func updateDurationLabel() {
        let days = Int(durationStepper.value)
        durationValueLabel.text = days == 1 ? "1 giorno" : "\(days) giorni"
    }

    private func getTripTypeString() -> String {
        switch tripTypeSegment.selectedSegmentIndex {
        case 0:
            return "locale"
        case 1:
            return "giornaliero"
        default:
            return "multi-giorno"
        }
    }

    private func getSelectedTravelStyle() -> String? {
        guard travelStyleSegment.selectedSegmentIndex != UISegmentedControl.noSegment else {
            return nil
        }
        return TravelStyle.allCases[travelStyleSegment.selectedSegmentIndex].rawValue
    }

    private func validateInput() -> Bool {
        guard let destination = destinationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !destination.isEmpty else {
            showAlert(title: "Errore", message: "Inserisci una destinazione")
            return false
        }

        guard destination.count >= 2 else {
            showAlert(title: "Errore", message: "La destinazione deve contenere almeno 2 caratteri")
            return false
        }

        return true
    }

    private func generateItinerary(destination: String, days: Int, tripType: String, travelStyle: String?) {
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
                let itinerary = try await FoundationModelService.shared.generateItinerary(
                    destination: destination,
                    days: days,
                    tripType: tripType,
                    travelStyle: travelStyle
                )

                await MainActor.run {
                    self.showLoading(false)
                    self.isGenerating = false
                    self.navigateToDetail(with: itinerary)
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

    private func navigateToDetail(with itinerary: TravelItineraryData) {
        let detailVC = ItineraryDetailViewController()
        detailVC.itinerary = itinerary
        detailVC.associatedTrip = associatedTrip
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func showLoading(_ show: Bool) {
        loadingContainer.isHidden = !show
        if show {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        generateButton.isEnabled = !show
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

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension ItineraryGeneratorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return updatedText.count <= 100
    }
}
