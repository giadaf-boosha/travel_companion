import UIKit
import AVFoundation

/// Protocollo delegato per la nota vocale
protocol VoiceNoteDelegate: AnyObject {
    func voiceNote(_ controller: VoiceNoteViewController, didCaptureText text: String)
    func voiceNoteDidCancel(_ controller: VoiceNoteViewController)
}

/// Controller per la registrazione di note vocali con trascrizione
@available(iOS 26.0, *)
final class VoiceNoteViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: VoiceNoteDelegate?

    /// Trip associato (richiesto)
    var associatedTrip: Trip?

    private var isRecording = false
    private var capturedText = ""
    private var pulseAnimationLayer: CAShapeLayer?

    // MARK: - UI Components

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Nota Vocale"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Tieni premuto il pulsante per registrare.\nParla chiaramente e descrivi la tua esperienza."
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let microphoneButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 50
        button.accessibilityIdentifier = AccessibilityIdentifiers.VoiceNote.microphoneButton
        return button
    }()

    private let microphoneContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Pronto"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let transcriptionContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 12
        return v
    }()

    private let transcriptionTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Trascrizione"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let transcriptionTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = .systemFont(ofSize: 16, weight: .regular)
        tv.backgroundColor = .clear
        tv.isEditable = false
        tv.isScrollEnabled = true
        tv.text = "La trascrizione apparira qui..."
        tv.textColor = .tertiaryLabel
        tv.accessibilityIdentifier = AccessibilityIdentifiers.VoiceNote.transcriptionLabel
        return tv
    }()

    private let textFallbackContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 12
        return v
    }()

    private let textFallbackLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Oppure scrivi manualmente"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()

    private let textFallbackField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Scrivi qui la tua nota..."
        tf.borderStyle = .roundedRect
        tf.returnKeyType = .done
        tf.accessibilityIdentifier = AccessibilityIdentifiers.VoiceNote.textFallbackField
        return tf
    }()

    private let processButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Elabora con AI", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.isEnabled = false
        button.alpha = 0.5
        button.accessibilityIdentifier = AccessibilityIdentifiers.VoiceNote.processButton
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
        setupActions()
        checkPermissions()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isRecording {
            stopRecording()
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(headerLabel)
        view.addSubview(instructionLabel)
        view.addSubview(microphoneContainer)
        microphoneContainer.addSubview(microphoneButton)
        view.addSubview(statusLabel)
        view.addSubview(transcriptionContainerView)
        transcriptionContainerView.addSubview(transcriptionTitleLabel)
        transcriptionContainerView.addSubview(transcriptionTextView)
        view.addSubview(textFallbackContainerView)
        textFallbackContainerView.addSubview(textFallbackLabel)
        textFallbackContainerView.addSubview(textFallbackField)
        view.addSubview(processButton)

        textFallbackField.delegate = self

        // Setup pulse animation layer
        setupPulseAnimation()
    }

    private func setupConstraints() {
        let padding: CGFloat = 20

        NSLayoutConstraint.activate([
            // Header
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Instruction
            instructionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            // Microphone Container
            microphoneContainer.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 32),
            microphoneContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            microphoneContainer.widthAnchor.constraint(equalToConstant: 120),
            microphoneContainer.heightAnchor.constraint(equalToConstant: 120),

            // Microphone Button
            microphoneButton.centerXAnchor.constraint(equalTo: microphoneContainer.centerXAnchor),
            microphoneButton.centerYAnchor.constraint(equalTo: microphoneContainer.centerYAnchor),
            microphoneButton.widthAnchor.constraint(equalToConstant: 100),
            microphoneButton.heightAnchor.constraint(equalToConstant: 100),

            // Status Label
            statusLabel.topAnchor.constraint(equalTo: microphoneContainer.bottomAnchor, constant: 12),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Transcription Container
            transcriptionContainerView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 24),
            transcriptionContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            transcriptionContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            transcriptionContainerView.heightAnchor.constraint(equalToConstant: 120),

            transcriptionTitleLabel.topAnchor.constraint(equalTo: transcriptionContainerView.topAnchor, constant: 12),
            transcriptionTitleLabel.leadingAnchor.constraint(equalTo: transcriptionContainerView.leadingAnchor, constant: 12),

            transcriptionTextView.topAnchor.constraint(equalTo: transcriptionTitleLabel.bottomAnchor, constant: 8),
            transcriptionTextView.leadingAnchor.constraint(equalTo: transcriptionContainerView.leadingAnchor, constant: 8),
            transcriptionTextView.trailingAnchor.constraint(equalTo: transcriptionContainerView.trailingAnchor, constant: -8),
            transcriptionTextView.bottomAnchor.constraint(equalTo: transcriptionContainerView.bottomAnchor, constant: -8),

            // Text Fallback Container
            textFallbackContainerView.topAnchor.constraint(equalTo: transcriptionContainerView.bottomAnchor, constant: 16),
            textFallbackContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            textFallbackContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),

            textFallbackLabel.topAnchor.constraint(equalTo: textFallbackContainerView.topAnchor, constant: 12),
            textFallbackLabel.leadingAnchor.constraint(equalTo: textFallbackContainerView.leadingAnchor, constant: 12),

            textFallbackField.topAnchor.constraint(equalTo: textFallbackLabel.bottomAnchor, constant: 8),
            textFallbackField.leadingAnchor.constraint(equalTo: textFallbackContainerView.leadingAnchor, constant: 12),
            textFallbackField.trailingAnchor.constraint(equalTo: textFallbackContainerView.trailingAnchor, constant: -12),
            textFallbackField.bottomAnchor.constraint(equalTo: textFallbackContainerView.bottomAnchor, constant: -12),
            textFallbackField.heightAnchor.constraint(equalToConstant: 44),

            // Process Button
            processButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            processButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            processButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padding),
            processButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupNavigationBar() {
        title = "Nota Vocale"

        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        cancelButton.accessibilityIdentifier = AccessibilityIdentifiers.VoiceNote.cancelButton
        navigationItem.leftBarButtonItem = cancelButton
    }

    private func setupActions() {
        // Long press per registrare
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleMicrophoneLongPress))
        longPressGesture.minimumPressDuration = 0.2
        microphoneButton.addGestureRecognizer(longPressGesture)

        // Tap singolo per toggle
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMicrophoneTap))
        tapGesture.require(toFail: longPressGesture)
        microphoneButton.addGestureRecognizer(tapGesture)

        processButton.addTarget(self, action: #selector(processTapped), for: .touchUpInside)

        // Text field editing
        textFallbackField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        // Tap per nascondere tastiera
        let dismissTapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissTapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTapGesture)
    }

    private func setupPulseAnimation() {
        let pulseLayer = CAShapeLayer()
        pulseLayer.frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        pulseLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 100, height: 100)).cgPath
        pulseLayer.fillColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
        pulseLayer.opacity = 0
        microphoneContainer.layer.insertSublayer(pulseLayer, at: 0)
        self.pulseAnimationLayer = pulseLayer
    }

    // MARK: - Permissions

    private func checkPermissions() {
        SpeechRecognizerService.shared.requestAllPermissions { [weak self] granted, error in
            if !granted {
                self?.showPermissionAlert(error: error)
            }
        }
    }

    private func showPermissionAlert(error: SpeechRecognizerError?) {
        let alert = UIAlertController(
            title: "Permessi Necessari",
            message: error?.userMessage ?? "Per usare le note vocali, sono necessari i permessi per microfono e riconoscimento vocale.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Apri Impostazioni", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })

        alert.addAction(UIAlertAction(title: "Usa Testo", style: .cancel))

        present(alert, animated: true)
    }

    // MARK: - Recording

    private func startRecording() {
        guard !isRecording else { return }

        do {
            SpeechRecognizerService.shared.delegate = self
            try SpeechRecognizerService.shared.startListening()
            isRecording = true
            updateUIForRecordingState(true)
        } catch let error as SpeechRecognizerError {
            showError(error)
        } catch {
            showError(.unknown(error))
        }
    }

    private func stopRecording() {
        guard isRecording else { return }

        SpeechRecognizerService.shared.stopListening()
        isRecording = false
        updateUIForRecordingState(false)
    }

    private func updateUIForRecordingState(_ recording: Bool) {
        if recording {
            microphoneButton.backgroundColor = .systemRed
            statusLabel.text = "Ascoltando..."
            statusLabel.textColor = .systemRed
            startPulseAnimation()
        } else {
            microphoneButton.backgroundColor = .systemBlue
            statusLabel.text = "Pronto"
            statusLabel.textColor = .secondaryLabel
            stopPulseAnimation()
        }
    }

    private func startPulseAnimation() {
        guard let pulseLayer = pulseAnimationLayer else { return }

        pulseLayer.opacity = 1

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.3
        scaleAnimation.duration = 0.5
        scaleAnimation.autoreverses = true
        scaleAnimation.repeatCount = .infinity

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.6
        opacityAnimation.toValue = 0.2
        opacityAnimation.duration = 0.5
        opacityAnimation.autoreverses = true
        opacityAnimation.repeatCount = .infinity

        pulseLayer.add(scaleAnimation, forKey: "scale")
        pulseLayer.add(opacityAnimation, forKey: "opacity")
    }

    private func stopPulseAnimation() {
        pulseAnimationLayer?.removeAllAnimations()
        pulseAnimationLayer?.opacity = 0
    }

    private func updateProcessButton() {
        let hasText = !capturedText.isEmpty || !(textFallbackField.text?.isEmpty ?? true)
        processButton.isEnabled = hasText
        processButton.alpha = hasText ? 1.0 : 0.5
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        if isRecording {
            SpeechRecognizerService.shared.cancelListening()
        }
        delegate?.voiceNoteDidCancel(self)
        dismiss(animated: true)
    }

    @objc private func handleMicrophoneLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            startRecording()
        case .ended, .cancelled:
            stopRecording()
        default:
            break
        }
    }

    @objc private func handleMicrophoneTap() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    @objc private func processTapped() {
        // Usa il testo trascritto o quello manuale
        let textToProcess = capturedText.isEmpty
            ? (textFallbackField.text ?? "")
            : capturedText

        guard !textToProcess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Nessun Testo", message: "Registra una nota vocale o scrivi il testo manualmente.")
            return
        }

        // Naviga a StructuredNotePreviewViewController
        let previewVC = StructuredNotePreviewViewController()
        previewVC.rawText = textToProcess
        previewVC.associatedTrip = associatedTrip
        navigationController?.pushViewController(previewVC, animated: true)
    }

    @objc private func textFieldDidChange() {
        updateProcessButton()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Error Handling

    private func showError(_ error: SpeechRecognizerError) {
        let alert = UIAlertController(
            title: "Errore",
            message: error.userMessage,
            preferredStyle: .alert
        )

        if error == .notAuthorized || error == .noMicrophoneAccess {
            alert.addAction(UIAlertAction(title: "Apri Impostazioni", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
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

// MARK: - SpeechRecognizerDelegate

@available(iOS 26.0, *)
extension VoiceNoteViewController: SpeechRecognizerDelegate {
    func speechRecognizer(_ service: SpeechRecognizerService, didReceivePartialResult text: String) {
        transcriptionTextView.text = text
        transcriptionTextView.textColor = .label
    }

    func speechRecognizer(_ service: SpeechRecognizerService, didReceiveFinalResult text: String) {
        capturedText = text
        transcriptionTextView.text = text
        transcriptionTextView.textColor = .label
        updateProcessButton()
    }

    func speechRecognizer(_ service: SpeechRecognizerService, didFailWithError error: SpeechRecognizerError) {
        isRecording = false
        updateUIForRecordingState(false)
        showError(error)
    }

    func speechRecognizerDidStartListening(_ service: SpeechRecognizerService) {
        // UI already updated in startRecording
    }

    func speechRecognizerDidStopListening(_ service: SpeechRecognizerService) {
        // UI already updated in stopRecording
    }
}

// MARK: - UITextFieldDelegate

@available(iOS 26.0, *)
extension VoiceNoteViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - SpeechRecognizerError Equatable

extension SpeechRecognizerError: Equatable {
    static func == (lhs: SpeechRecognizerError, rhs: SpeechRecognizerError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthorized, .notAuthorized),
             (.notAvailable, .notAvailable),
             (.audioEngineError, .audioEngineError),
             (.recognitionFailed, .recognitionFailed),
             (.noMicrophoneAccess, .noMicrophoneAccess),
             (.alreadyRecording, .alreadyRecording),
             (.notRecording, .notRecording):
            return true
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}
