import UIKit

/// Cella personalizzata per visualizzare un messaggio nella chat
class ChatMessageCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var timestampLabel: UILabel!

    // Constraints per allineamento dinamico
    @IBOutlet weak var bubbleLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bubbleTrailingConstraint: NSLayoutConstraint!

    // MARK: - Properties

    static let userIdentifier = Constants.Cell.chatUserCell
    static let assistantIdentifier = Constants.Cell.chatAssistantCell

    private var isUserMessage: Bool = false

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        timestampLabel.text = nil
    }

    // MARK: - Setup

    private func setupUI() {
        // Bubble view styling
        bubbleView?.layer.cornerRadius = 16

        // Message label
        messageLabel?.font = .systemFont(ofSize: 15)
        messageLabel?.numberOfLines = 0

        // Timestamp label
        timestampLabel?.font = .systemFont(ofSize: 11)
        timestampLabel?.textColor = .tertiaryLabel

        // No selection
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    // MARK: - Configuration

    /// Configura la cella con i dati di un messaggio
    func configure(with message: ChatMessage) {
        messageLabel.text = message.content
        isUserMessage = message.role.isUser

        // Configura aspetto in base al ruolo
        if message.role.isUser {
            configureAsUserMessage()
        } else {
            configureAsAssistantMessage()
        }

        // Timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.DateFormat.time
        timestampLabel.text = formatter.string(from: message.timestamp)
    }

    /// Configura come messaggio dell'utente
    private func configureAsUserMessage() {
        bubbleView.backgroundColor = UIColor.systemBlue
        messageLabel.textColor = .white

        // Allineamento a destra
        bubbleLeadingConstraint?.isActive = false
        bubbleTrailingConstraint?.isActive = true

        // Corner radius asimmetrico
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
    }

    /// Configura come messaggio dell'assistente
    private func configureAsAssistantMessage() {
        bubbleView.backgroundColor = UIColor.secondarySystemBackground
        messageLabel.textColor = .label

        // Allineamento a sinistra
        bubbleLeadingConstraint?.isActive = true
        bubbleTrailingConstraint?.isActive = false

        // Corner radius asimmetrico
        bubbleView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
    }
}

// MARK: - Programmatic Initialization

extension ChatMessageCell {

    /// Crea una cella per messaggio utente programmaticamente
    static func createUserCell() -> ChatMessageCell {
        let cell = ChatMessageCell(style: .default, reuseIdentifier: userIdentifier)
        cell.setupProgrammaticUI(isUser: true)
        return cell
    }

    /// Crea una cella per messaggio assistente programmaticamente
    static func createAssistantCell() -> ChatMessageCell {
        let cell = ChatMessageCell(style: .default, reuseIdentifier: assistantIdentifier)
        cell.setupProgrammaticUI(isUser: false)
        return cell
    }

    private func setupProgrammaticUI(isUser: Bool) {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        // Bubble view
        let bubble = UIView()
        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.layer.cornerRadius = 16
        contentView.addSubview(bubble)
        self.bubbleView = bubble

        // Message label
        let message = UILabel()
        message.translatesAutoresizingMaskIntoConstraints = false
        message.font = .systemFont(ofSize: 15)
        message.numberOfLines = 0
        bubble.addSubview(message)
        self.messageLabel = message

        // Timestamp label
        let timestamp = UILabel()
        timestamp.translatesAutoresizingMaskIntoConstraints = false
        timestamp.font = .systemFont(ofSize: 11)
        timestamp.textColor = .tertiaryLabel
        contentView.addSubview(timestamp)
        self.timestampLabel = timestamp

        // Constraints comuni
        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),

            message.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
            message.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 14),
            message.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -14),
            message.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10),

            timestamp.topAnchor.constraint(equalTo: bubble.bottomAnchor, constant: 4),
            timestamp.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])

        // Constraints specifici per allineamento
        if isUser {
            let trailing = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            trailing.isActive = true
            self.bubbleTrailingConstraint = trailing

            let leading = bubble.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60)
            leading.isActive = true

            timestamp.trailingAnchor.constraint(equalTo: bubble.trailingAnchor).isActive = true

            bubble.backgroundColor = .systemBlue
            message.textColor = .white
            bubble.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
        } else {
            let leading = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
            leading.isActive = true
            self.bubbleLeadingConstraint = leading

            let trailing = bubble.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60)
            trailing.isActive = true

            timestamp.leadingAnchor.constraint(equalTo: bubble.leadingAnchor).isActive = true

            bubble.backgroundColor = .secondarySystemBackground
            message.textColor = .label
            bubble.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
        }

        isUserMessage = isUser
    }
}

// MARK: - Typing Indicator Cell

/// Cella che mostra l'indicatore di digitazione dell'assistente
class TypingIndicatorCell: UITableViewCell {

    static let identifier = "TypingIndicatorCell"

    private var dots: [UIView] = []
    private var animating = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        // Bubble
        let bubble = UIView()
        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.backgroundColor = .secondarySystemBackground
        bubble.layer.cornerRadius = 16
        bubble.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner]
        contentView.addSubview(bubble)

        // Stack per i dots
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        bubble.addSubview(stack)

        // Crea 3 dots
        for _ in 0..<3 {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = .tertiaryLabel
            dot.layer.cornerRadius = 4
            dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
            stack.addArrangedSubview(dot)
            dots.append(dot)
        }

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            stack.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -14)
        ])
    }

    func startAnimating() {
        guard !animating else { return }
        animating = true

        for (index, dot) in dots.enumerated() {
            let delay = Double(index) * 0.15
            UIView.animate(
                withDuration: 0.4,
                delay: delay,
                options: [.repeat, .autoreverse],
                animations: {
                    dot.alpha = 0.3
                    dot.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }
            )
        }
    }

    func stopAnimating() {
        animating = false
        for dot in dots {
            dot.layer.removeAllAnimations()
            dot.alpha = 1
            dot.transform = .identity
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopAnimating()
    }
}
