import UIKit

/// Cella personalizzata per visualizzare una nota nella lista
class NoteCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationIcon: UIImageView!
    @IBOutlet weak var containerView: UIView!

    // MARK: - Properties

    static let identifier = Constants.Cell.noteCell
    static let estimatedHeight: CGFloat = 80

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentLabel.text = nil
        timestampLabel.text = nil
        locationLabel.text = nil
        locationLabel.isHidden = true
        locationIcon.isHidden = true
    }

    // MARK: - Setup

    private func setupUI() {
        // Container view styling
        containerView?.backgroundColor = .secondarySystemBackground
        containerView?.layer.cornerRadius = 10

        // Content label
        contentLabel?.font = .systemFont(ofSize: 15)
        contentLabel?.textColor = .label
        contentLabel?.numberOfLines = 3

        // Timestamp label
        timestampLabel?.font = .systemFont(ofSize: 12)
        timestampLabel?.textColor = .secondaryLabel

        // Location
        locationLabel?.font = .systemFont(ofSize: 12)
        locationLabel?.textColor = .tertiaryLabel
        locationIcon?.tintColor = .tertiaryLabel

        // Selection style
        selectionStyle = .none
    }

    // MARK: - Configuration

    /// Configura la cella con i dati di una nota
    func configure(with note: Note) {
        // Contenuto
        contentLabel.text = note.content ?? ""

        // Timestamp
        if let timestamp = note.timestamp {
            let formatter = DateFormatter()
            formatter.dateFormat = Constants.DateFormat.displayWithTime
            formatter.locale = Locale(identifier: "it_IT")
            timestampLabel.text = formatter.string(from: timestamp)
        } else {
            timestampLabel.text = nil
        }

        // Posizione
        if note.latitude != 0 && note.longitude != 0 {
            let latString = String(format: "%.4f", note.latitude)
            let lonString = String(format: "%.4f", note.longitude)
            locationLabel.text = "\(latString), \(lonString)"
            locationLabel.isHidden = false
            locationIcon.isHidden = false
        } else {
            locationLabel.isHidden = true
            locationIcon.isHidden = true
        }
    }

    // MARK: - Animation

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        UIView.animate(withDuration: 0.1) {
            self.containerView?.backgroundColor = highlighted ?
                .tertiarySystemBackground : .secondarySystemBackground
        }
    }
}

// MARK: - Programmatic Initialization

extension NoteCell {

    /// Crea e configura la cella programmaticamente
    static func createProgrammatically() -> NoteCell {
        let cell = NoteCell(style: .default, reuseIdentifier: identifier)
        cell.setupProgrammaticUI()
        return cell
    }

    private func setupProgrammaticUI() {
        // Container view
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 10
        contentView.addSubview(container)
        self.containerView = container

        // Content label
        let content = UILabel()
        content.translatesAutoresizingMaskIntoConstraints = false
        content.font = .systemFont(ofSize: 15)
        content.textColor = .label
        content.numberOfLines = 3
        container.addSubview(content)
        self.contentLabel = content

        // Timestamp label
        let timestamp = UILabel()
        timestamp.translatesAutoresizingMaskIntoConstraints = false
        timestamp.font = .systemFont(ofSize: 12)
        timestamp.textColor = .secondaryLabel
        container.addSubview(timestamp)
        self.timestampLabel = timestamp

        // Location icon
        let locIcon = UIImageView(image: UIImage(systemName: "location.fill"))
        locIcon.translatesAutoresizingMaskIntoConstraints = false
        locIcon.tintColor = .tertiaryLabel
        locIcon.contentMode = .scaleAspectFit
        container.addSubview(locIcon)
        self.locationIcon = locIcon

        // Location label
        let location = UILabel()
        location.translatesAutoresizingMaskIntoConstraints = false
        location.font = .systemFont(ofSize: 12)
        location.textColor = .tertiaryLabel
        container.addSubview(location)
        self.locationLabel = location

        // Constraints
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            content.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),

            timestamp.topAnchor.constraint(equalTo: content.bottomAnchor, constant: 8),
            timestamp.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            timestamp.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),

            locIcon.centerYAnchor.constraint(equalTo: timestamp.centerYAnchor),
            locIcon.leadingAnchor.constraint(equalTo: timestamp.trailingAnchor, constant: 12),
            locIcon.widthAnchor.constraint(equalToConstant: 12),
            locIcon.heightAnchor.constraint(equalToConstant: 12),

            location.centerYAnchor.constraint(equalTo: timestamp.centerYAnchor),
            location.leadingAnchor.constraint(equalTo: locIcon.trailingAnchor, constant: 4),
            location.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -12)
        ])

        selectionStyle = .none
    }
}
