import UIKit

/// ViewController per la chat con l'assistente AI
final class ChatViewController: UIViewController {

    // MARK: - UI Components

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        tableView.backgroundColor = .systemBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private let inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Scrivi un messaggio..."
        textField.layer.cornerRadius = 20
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.returnKeyType = .send
        textField.enablesReturnKeyAutomatically = true
        textField.backgroundColor = .systemBackground
        textField.translatesAutoresizingMaskIntoConstraints = false

        // Padding per il textfield
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 40))
        textField.leftView = paddingView
        textField.leftViewMode = .always

        return textField
    }()

    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Invia", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 20
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private var inputContainerBottomConstraint: NSLayoutConstraint!

    // MARK: - Properties

    private let chatService = ChatService()
    private var messages: [ChatMessage] = []
    private var isTyping = false

    // Suggerimenti iniziali
    private let suggestions = [
        "Suggeriscimi una destinazione",
        "Consigli per un viaggio a Roma",
        "Crea un itinerario di 3 giorni a Venezia"
    ]
    private var showingSuggestions = true

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupConstraints()
        setupUI()
        setupTableView()
        setupKeyboardObservers()
        loadMessages()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupViews() {
        view.backgroundColor = .systemBackground

        // Aggiungi le views alla gerarchia
        view.addSubview(tableView)
        view.addSubview(inputContainerView)

        inputContainerView.addSubview(inputTextField)
        inputContainerView.addSubview(sendButton)
        inputContainerView.addSubview(loadingIndicator)
    }

    private func setupConstraints() {
        // TableView constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor)
        ])

        // Input container constraints
        inputContainerBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerBottomConstraint,
            inputContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])

        // Input text field constraints
        NSLayoutConstraint.activate([
            inputTextField.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 16),
            inputTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 10),
            inputTextField.bottomAnchor.constraint(equalTo: inputContainerView.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            inputTextField.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Send button constraints
        NSLayoutConstraint.activate([
            sendButton.leadingAnchor.constraint(equalTo: inputTextField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputTextField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 70),
            sendButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Loading indicator constraints
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor)
        ])
    }

    private func setupUI() {
        title = "Assistente Viaggio"

        // Configura campo di input
        inputTextField.delegate = self

        // Configura bottone invio
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)

        // Pulsante per cancellare conversazione
        let clearButton = UIBarButtonItem(
            title: "Cancella",
            style: .plain,
            target: self,
            action: #selector(clearConversationTapped)
        )
        navigationItem.rightBarButtonItem = clearButton

        // Aggiungi separatore superiore al container input
        let separatorLine = UIView()
        separatorLine.backgroundColor = .systemGray5
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        inputContainerView.addSubview(separatorLine)

        NSLayoutConstraint.activate([
            separatorLine.topAnchor.constraint(equalTo: inputContainerView.topAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        // Registra celle custom
        tableView.register(ChatUserCell.self, forCellReuseIdentifier: Constants.Cell.chatUserCell)
        tableView.register(ChatAssistantCell.self, forCellReuseIdentifier: Constants.Cell.chatAssistantCell)
        tableView.register(TypingIndicatorCell.self, forCellReuseIdentifier: "TypingIndicatorCell")
        tableView.register(SuggestionCell.self, forCellReuseIdentifier: "SuggestionCell")

        // Gestione tap per nascondere tastiera
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleChatKeyboardDismiss))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
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

    // MARK: - Data Loading

    private func loadMessages() {
        messages = chatService.getVisibleMessages()
        showingSuggestions = messages.isEmpty
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func sendButtonTapped() {
        sendMessage()
    }

    @objc private func clearConversationTapped() {
        let alert = UIAlertController(
            title: "Cancella Conversazione",
            message: "Vuoi cancellare tutta la conversazione?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Cancella", style: .destructive) { [weak self] _ in
            self?.clearConversation()
        })

        present(alert, animated: true)
    }

    @objc private func handleChatKeyboardDismiss() {
        view.endEditing(true)
    }

    // MARK: - Keyboard Handling

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
              !text.isEmpty else {
            return
        }

        // Valida lunghezza messaggio
        guard text.count <= Constants.Validation.maxChatMessageLength else {
            showError("Il messaggio è troppo lungo. Massimo \(Constants.Validation.maxChatMessageLength) caratteri.")
            return
        }

        // Pulisci il campo di input
        inputTextField.text = ""
        sendButton.isEnabled = false

        // Nascondi suggerimenti
        if showingSuggestions {
            showingSuggestions = false
            tableView.reloadData()
        }

        // Mostra indicatore di caricamento
        isTyping = true
        tableView.beginUpdates()
        let indexPath = IndexPath(row: messages.count, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
        scrollToBottom(animated: true)

        loadingIndicator.startAnimating()

        // Invia il messaggio
        chatService.sendMessage(text) { [weak self] result in
            guard let self = self else { return }

            self.loadingIndicator.stopAnimating()
            self.isTyping = false

            switch result {
            case .success(_):
                // Ricarica i messaggi
                self.messages = self.chatService.getVisibleMessages()
                self.tableView.reloadData()
                self.scrollToBottom(animated: true)

            case .failure(let error):
                // Rimuovi l'indicatore di typing
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.showError(error.localizedDescription)
            }
        }
    }

    private func clearConversation() {
        chatService.clearConversation()
        messages = []
        showingSuggestions = true
        tableView.reloadData()
    }

    private func scrollToBottom(animated: Bool) {
        guard tableView.numberOfRows(inSection: 0) > 0 else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let lastRow = self.tableView.numberOfRows(inSection: 0) - 1
            let indexPath = IndexPath(row: lastRow, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }

    // MARK: - Error Handling

    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Errore",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showingSuggestions {
            return suggestions.count
        }
        return messages.count + (isTyping ? 1 : 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Mostra suggerimenti se la chat è vuota
        if showingSuggestions {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath) as! SuggestionCell
            cell.configure(with: suggestions[indexPath.row])
            return cell
        }

        // Mostra indicatore typing
        if isTyping && indexPath.row == messages.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TypingIndicatorCell", for: indexPath) as! TypingIndicatorCell
            cell.startAnimating()
            return cell
        }

        let message = messages[indexPath.row]

        if message.role.isUser {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cell.chatUserCell, for: indexPath) as! ChatUserCell
            cell.configure(with: message)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cell.chatAssistantCell, for: indexPath) as! ChatAssistantCell
            cell.configure(with: message)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension ChatViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Gestisci tap su suggerimenti
        if showingSuggestions {
            inputTextField.text = suggestions[indexPath.row]
            sendButton.isEnabled = true
            inputTextField.becomeFirstResponder()
        }
    }
}

// MARK: - UITextFieldDelegate

extension ChatViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

        sendButton.isEnabled = !updatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return true
    }
}

// MARK: - Custom Cells

/// Cella per messaggi utente
class ChatUserCell: UITableViewCell {

    private let bubbleView = UIView()
    private let messageLabel = UILabel()

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

        bubbleView.backgroundColor = .systemBlue
        bubbleView.layer.cornerRadius = 16
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)

        messageLabel.numberOfLines = 0
        messageLabel.textColor = .white
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12)
        ])
    }

    func configure(with message: ChatMessage) {
        messageLabel.text = message.content
    }
}

/// Cella per messaggi assistente
class ChatAssistantCell: UITableViewCell {

    private let bubbleView = UIView()
    private let messageLabel = UILabel()

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

        bubbleView.backgroundColor = .systemGray5
        bubbleView.layer.cornerRadius = 16
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)

        messageLabel.numberOfLines = 0
        messageLabel.textColor = .label
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12)
        ])
    }

    func configure(with message: ChatMessage) {
        messageLabel.text = message.content
    }
}

/// Cella per suggerimenti
class SuggestionCell: UITableViewCell {

    private let containerView = UIView()
    private let suggestionLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        selectionStyle = .default
        backgroundColor = .clear

        containerView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        suggestionLabel.numberOfLines = 0
        suggestionLabel.textColor = .systemBlue
        suggestionLabel.font = UIFont.systemFont(ofSize: 15)
        suggestionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(suggestionLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            suggestionLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            suggestionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            suggestionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            suggestionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
    }

    func configure(with suggestion: String) {
        suggestionLabel.text = suggestion
    }
}
