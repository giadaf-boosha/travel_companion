//
//  TravelAIChatViewController.swift
//  TravelCompanion
//
//  Chat AI potenziata da Apple Foundation Models con Tool Calling.
//  Fornisce assistenza di viaggio intelligente e azioni nell'app.
//

import UIKit

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Controller per la chat AI con supporto Tool Calling
@available(iOS 26.0, *)
final class TravelAIChatViewController: UIViewController {

    // MARK: - Properties

    #if canImport(FoundationModels)
    private var chatSession: LanguageModelSession?
    #endif

    private var messages: [AIChatMessage] = []
    private var isGenerating = false

    // MARK: - UI Components

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorStyle = .none
        tv.keyboardDismissMode = .interactive
        tv.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        tv.backgroundColor = .systemBackground
        tv.accessibilityIdentifier = AccessibilityIdentifiers.TravelAIChat.tableView
        return tv
    }()

    private let startersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .systemBackground
        cv.showsVerticalScrollIndicator = false
        return cv
    }()

    private let startersHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Suggerimenti"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let startersSubtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Tocca per iniziare una conversazione"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()

    private let inputContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        return v
    }()

    private let inputTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Chiedi qualcosa sul tuo viaggio..."
        tf.layer.cornerRadius = 20
        tf.layer.borderWidth = 1
        tf.layer.borderColor = UIColor.systemGray4.cgColor
        tf.returnKeyType = .send
        tf.enablesReturnKeyAutomatically = true
        tf.backgroundColor = .systemBackground
        tf.accessibilityIdentifier = AccessibilityIdentifiers.TravelAIChat.inputTextField

        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 40))
        tf.leftView = paddingView
        tf.leftViewMode = .always
        return tf
    }()

    private let sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        btn.tintColor = .systemBlue
        btn.isEnabled = false
        btn.accessibilityIdentifier = AccessibilityIdentifiers.TravelAIChat.sendButton
        btn.contentHorizontalAlignment = .fill
        btn.contentVerticalAlignment = .fill
        return btn
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.hidesWhenStopped = true
        ai.accessibilityIdentifier = AccessibilityIdentifiers.TravelAIChat.loadingIndicator
        return ai
    }()

    private var inputContainerBottomConstraint: NSLayoutConstraint!
    private var showingStarters = true

    // Starters combinati
    private var allStarters: [ChatStarterItem] {
        TravelChatStarters.travelExpertStarters + TravelChatStarters.actionStarters
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupNavigationBar()
        setupSession()
        setupKeyboardObservers()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // TableView for messages
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AIChatUserCell.self, forCellReuseIdentifier: "AIChatUserCell")
        tableView.register(AIChatAssistantCell.self, forCellReuseIdentifier: "AIChatAssistantCell")
        tableView.register(AIChatTypingCell.self, forCellReuseIdentifier: "AIChatTypingCell")
        tableView.isHidden = true

        // Starters view
        view.addSubview(startersHeaderLabel)
        view.addSubview(startersSubtitleLabel)
        view.addSubview(startersCollectionView)
        startersCollectionView.delegate = self
        startersCollectionView.dataSource = self
        startersCollectionView.register(StarterCell.self, forCellWithReuseIdentifier: "StarterCell")

        // Input container
        view.addSubview(inputContainerView)
        inputContainerView.addSubview(inputTextField)
        inputContainerView.addSubview(sendButton)
        inputContainerView.addSubview(loadingIndicator)

        inputTextField.delegate = self
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        // Separator
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = .systemGray5
        inputContainerView.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: inputContainerView.topAnchor),
            separator.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        // Tap to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tap)
    }

    private func setupConstraints() {
        inputContainerBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            // Starters header
            startersHeaderLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            startersHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            startersSubtitleLabel.topAnchor.constraint(equalTo: startersHeaderLabel.bottomAnchor, constant: 4),
            startersSubtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            // Starters collection
            startersCollectionView.topAnchor.constraint(equalTo: startersSubtitleLabel.bottomAnchor, constant: 8),
            startersCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            startersCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            startersCollectionView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),

            // TableView
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),

            // Input container
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerBottomConstraint,
            inputContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

            // Input field
            inputTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 16),
            inputTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 10),
            inputTextField.bottomAnchor.constraint(equalTo: inputContainerView.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            inputTextField.heightAnchor.constraint(equalToConstant: 40),

            // Send button
            sendButton.leadingAnchor.constraint(equalTo: inputTextField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputTextField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),

            // Loading
            loadingIndicator.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor)
        ])
    }

    private func setupNavigationBar() {
        title = "Chat AI Viaggio"
        navigationController?.navigationBar.prefersLargeTitles = false

        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        closeButton.tintColor = .systemGray
        navigationItem.leftBarButtonItem = closeButton

        let clearButton = UIBarButtonItem(
            title: "Nuova",
            style: .plain,
            target: self,
            action: #selector(clearTapped)
        )
        navigationItem.rightBarButtonItem = clearButton
    }

    private func setupSession() {
        #if canImport(FoundationModels)
        let model = SystemLanguageModel.default
        guard model.availability == .available else {
            showUnavailableAlert()
            return
        }

        // Create session with tools and instructions
        let createTripTool = CreateTripTool()
        let addNoteTool = AddNoteTool()
        let getTripInfoTool = GetTripInfoTool()

        chatSession = LanguageModelSession(tools: [createTripTool, addNoteTool, getTripInfoTool]) {
            """
            Sei Travel Companion AI, un assistente di viaggio esperto e amichevole.

            IDENTITA:
            - Sei un esperto di viaggi con vasta conoscenza di destinazioni, culture e logistica
            - Rispondi SEMPRE in italiano
            - Sii conciso ma informativo, evita risposte troppo lunghe
            - Usa un tono professionale ma cordiale

            COMPETENZE:
            - Consigli su destinazioni, periodo migliore per visitare, cosa vedere
            - Informazioni culturali, gastronomiche, di sicurezza
            - Suggerimenti su budget, itinerari, trasporti
            - Frasi utili nelle lingue locali

            STRUMENTI DISPONIBILI:
            - createTrip: Crea un nuovo viaggio quando l'utente lo richiede
            - addNote: Aggiunge note al viaggio attivo
            - getTripInfo: Recupera informazioni sui viaggi dell'utente

            REGOLE:
            - Non inventare prezzi specifici o orari che potrebbero cambiare
            - Suggerisci sempre di verificare informazioni pratiche aggiornate
            - Quando crei viaggi o note, conferma l'azione completata
            - Se l'utente chiede di fare qualcosa nell'app, usa gli strumenti appropriati
            """
        }

        #if DEBUG
        print("TravelAIChatViewController: Session created with tools")
        #endif
        #endif
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // MARK: - Actions

    @objc private func sendTapped() {
        sendMessage()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func clearTapped() {
        let alert = UIAlertController(
            title: "Nuova Conversazione",
            message: "Vuoi iniziare una nuova conversazione?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Nuova", style: .default) { [weak self] _ in
            self?.resetConversation()
        })
        present(alert, animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        let keyboardHeight = keyboardFrame.height - view.safeAreaInsets.bottom

        UIView.animate(withDuration: duration) {
            self.inputContainerBottomConstraint.constant = -keyboardHeight
            self.view.layoutIfNeeded()
        }

        scrollToBottom(animated: true)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        UIView.animate(withDuration: duration) {
            self.inputContainerBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Chat Logic

    private func sendMessage() {
        guard let text = inputTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty,
              !isGenerating else {
            return
        }

        // Validate length
        guard text.count <= Constants.Validation.maxChatMessageLength else {
            showError("Il messaggio e troppo lungo. Massimo \(Constants.Validation.maxChatMessageLength) caratteri.")
            return
        }

        // Switch to chat view
        if showingStarters {
            showingStarters = false
            startersHeaderLabel.isHidden = true
            startersSubtitleLabel.isHidden = true
            startersCollectionView.isHidden = true
            tableView.isHidden = false
        }

        // Add user message
        let userMessage = AIChatMessage(role: .user, content: text)
        messages.append(userMessage)

        inputTextField.text = ""
        sendButton.isEnabled = false

        // Show typing indicator
        isGenerating = true
        tableView.reloadData()
        scrollToBottom(animated: true)

        sendButton.isHidden = true
        loadingIndicator.startAnimating()

        // Send to AI
        Task {
            await generateResponse(for: text)
        }
    }

    private func generateResponse(for prompt: String) async {
        #if canImport(FoundationModels)
        guard let session = chatSession else {
            await MainActor.run {
                handleError("Sessione AI non disponibile")
            }
            return
        }

        do {
            let response = try await session.respond(to: prompt)
            let content = response.content

            await MainActor.run {
                let assistantMessage = AIChatMessage(role: .assistant, content: content)
                self.messages.append(assistantMessage)
                self.finishGenerating()
            }
        } catch {
            await MainActor.run {
                #if DEBUG
                print("TravelAIChatViewController: Error - \(error)")
                #endif
                self.handleError("Si e verificato un errore. Riprova.")
            }
        }
        #else
        await MainActor.run {
            handleError("Funzionalita AI non disponibile")
        }
        #endif
    }

    private func finishGenerating() {
        isGenerating = false
        loadingIndicator.stopAnimating()
        sendButton.isHidden = false
        tableView.reloadData()
        scrollToBottom(animated: true)
    }

    private func handleError(_ message: String) {
        // Add error message
        let errorMessage = AIChatMessage(role: .assistant, content: "⚠️ \(message)")
        messages.append(errorMessage)
        finishGenerating()
    }

    private func resetConversation() {
        messages.removeAll()
        setupSession()

        showingStarters = true
        startersHeaderLabel.isHidden = false
        startersSubtitleLabel.isHidden = false
        startersCollectionView.isHidden = false
        tableView.isHidden = true
        tableView.reloadData()
    }

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }

        let row = messages.count - 1 + (isGenerating ? 1 : 0)
        guard row >= 0, row < tableView.numberOfRows(inSection: 0) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let indexPath = IndexPath(row: row, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }

    private func showUnavailableAlert() {
        let alert = UIAlertController(
            title: "AI Non Disponibile",
            message: "Apple Intelligence non e disponibile su questo dispositivo.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Errore", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

@available(iOS 26.0, *)
extension TravelAIChatViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count + (isGenerating ? 1 : 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Typing indicator
        if isGenerating && indexPath.row == messages.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AIChatTypingCell", for: indexPath) as! AIChatTypingCell
            cell.startAnimating()
            return cell
        }

        let message = messages[indexPath.row]

        if message.role == .user {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AIChatUserCell", for: indexPath) as! AIChatUserCell
            cell.configure(with: message.content)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AIChatAssistantCell", for: indexPath) as! AIChatAssistantCell
            cell.configure(with: message.content)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

@available(iOS 26.0, *)
extension TravelAIChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

// MARK: - UICollectionViewDataSource

@available(iOS 26.0, *)
extension TravelAIChatViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allStarters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StarterCell", for: indexPath) as! StarterCell
        cell.configure(with: allStarters[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

@available(iOS 26.0, *)
extension TravelAIChatViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let starter = allStarters[indexPath.item]
        inputTextField.text = starter.prompt
        sendButton.isEnabled = true
        sendMessage()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

@available(iOS 26.0, *)
extension TravelAIChatViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 32
        return CGSize(width: width, height: 60)
    }
}

// MARK: - UITextFieldDelegate

@available(iOS 26.0, *)
extension TravelAIChatViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

        sendButton.isEnabled = !updatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
        return true
    }
}

// MARK: - Support Types

/// Messaggio nella chat AI
struct AIChatMessage {
    enum Role {
        case user
        case assistant
    }

    let role: Role
    let content: String
    let timestamp = Date()
}

// MARK: - Custom Cells

/// Cella per messaggi utente
@available(iOS 26.0, *)
final class AIChatUserCell: UITableViewCell {

    private let bubbleView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBlue
        v.layer.cornerRadius = 16
        return v
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.numberOfLines = 0
        l.textColor = .white
        l.font = .systemFont(ofSize: 16)
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14)
        ])
    }

    func configure(with text: String) {
        messageLabel.text = text
    }
}

/// Cella per messaggi assistente
@available(iOS 26.0, *)
final class AIChatAssistantCell: UITableViewCell {

    private let bubbleView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 16
        return v
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.numberOfLines = 0
        l.textColor = .label
        l.font = .systemFont(ofSize: 16)
        return l
    }()

    private let aiIconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "sparkles")
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(aiIconView)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            aiIconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            aiIconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            aiIconView.widthAnchor.constraint(equalToConstant: 20),
            aiIconView.heightAnchor.constraint(equalToConstant: 20),

            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.leadingAnchor.constraint(equalTo: aiIconView.trailingAnchor, constant: 8),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14)
        ])
    }

    func configure(with text: String) {
        messageLabel.text = text
    }
}

/// Cella indicatore di digitazione
@available(iOS 26.0, *)
final class AIChatTypingCell: UITableViewCell {

    private let bubbleView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 16
        return v
    }()

    private let dot1 = UIView()
    private let dot2 = UIView()
    private let dot3 = UIView()

    private let aiIconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "sparkles")
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(aiIconView)
        contentView.addSubview(bubbleView)

        [dot1, dot2, dot3].forEach { dot in
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = .systemGray3
            dot.layer.cornerRadius = 4
            bubbleView.addSubview(dot)
        }

        NSLayoutConstraint.activate([
            aiIconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            aiIconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            aiIconView.widthAnchor.constraint(equalToConstant: 20),
            aiIconView.heightAnchor.constraint(equalToConstant: 20),

            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.leadingAnchor.constraint(equalTo: aiIconView.trailingAnchor, constant: 8),
            bubbleView.widthAnchor.constraint(equalToConstant: 60),
            bubbleView.heightAnchor.constraint(equalToConstant: 36),

            dot1.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            dot1.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            dot1.widthAnchor.constraint(equalToConstant: 8),
            dot1.heightAnchor.constraint(equalToConstant: 8),

            dot2.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            dot2.leadingAnchor.constraint(equalTo: dot1.trailingAnchor, constant: 6),
            dot2.widthAnchor.constraint(equalToConstant: 8),
            dot2.heightAnchor.constraint(equalToConstant: 8),

            dot3.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            dot3.leadingAnchor.constraint(equalTo: dot2.trailingAnchor, constant: 6),
            dot3.widthAnchor.constraint(equalToConstant: 8),
            dot3.heightAnchor.constraint(equalToConstant: 8)
        ])
    }

    func startAnimating() {
        let dots = [dot1, dot2, dot3]

        for (index, dot) in dots.enumerated() {
            let animation = CAKeyframeAnimation(keyPath: "transform.scale")
            animation.values = [1.0, 1.4, 1.0]
            animation.keyTimes = [0, 0.5, 1]
            animation.duration = 0.6
            animation.repeatCount = .infinity
            animation.beginTime = CACurrentMediaTime() + Double(index) * 0.15
            dot.layer.add(animation, forKey: "bounce")
        }
    }
}

/// Cella per starter di conversazione
@available(iOS 26.0, *)
final class StarterCell: UICollectionViewCell {

    private let containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 1
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = .label
        return l
    }()

    private let arrowView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
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
        contentView.addSubview(containerView)
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(arrowView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: arrowView.leadingAnchor, constant: -8),

            arrowView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            arrowView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            arrowView.widthAnchor.constraint(equalToConstant: 12),
            arrowView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    func configure(with starter: ChatStarterItem) {
        iconView.image = UIImage(systemName: starter.icon)
        titleLabel.text = starter.title

        if starter.isAction {
            containerView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
            containerView.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.3).cgColor
            iconView.tintColor = .systemGreen
        } else {
            containerView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
            containerView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
            iconView.tintColor = .systemBlue
        }
    }
}
