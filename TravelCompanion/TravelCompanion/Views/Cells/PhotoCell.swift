import UIKit

/// Cella personalizzata per visualizzare una foto nella griglia
class PhotoCell: UICollectionViewCell {

    // MARK: - Properties

    static let identifier = Constants.Cell.photoCell

    private var imageView: UIImageView!
    private var timestampLabel: UILabel!
    private var gradientView: UIView!
    private var gradientLayer: CAGradientLayer?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupProgrammaticUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupProgrammaticUI()
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView?.image = nil
        timestampLabel?.text = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = gradientView?.bounds ?? bounds
    }

    // MARK: - Setup

    private func setupProgrammaticUI() {
        // Image view
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = 8
        image.backgroundColor = .secondarySystemBackground
        contentView.addSubview(image)
        self.imageView = image

        // Gradient view
        let gradient = UIView()
        gradient.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gradient)
        self.gradientView = gradient

        // Timestamp label
        let timestamp = UILabel()
        timestamp.translatesAutoresizingMaskIntoConstraints = false
        timestamp.font = .systemFont(ofSize: 11, weight: .medium)
        timestamp.textColor = .white
        contentView.addSubview(timestamp)
        self.timestampLabel = timestamp

        // Constraints
        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: contentView.topAnchor),
            image.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            image.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            image.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            gradient.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradient.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradient.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradient.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.4),

            timestamp.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            timestamp.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            timestamp.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])

        // Cell styling
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        setupGradient()
    }

    private func setupGradient() {
        guard gradientLayer == nil else { return }

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor
        ]
        gradient.locations = [0.5, 1.0]
        gradientView?.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
    }

    // MARK: - Configuration

    /// Configura la cella con i dati di una foto
    func configure(with photo: Photo) {
        // Carica l'immagine (thumbnail)
        if let imagePath = photo.imagePath {
            if let thumbnail = PhotoStorageManager.shared.loadThumbnail(at: imagePath) {
                imageView.image = thumbnail
            } else {
                // Fallback: carica l'immagine completa
                imageView.image = PhotoStorageManager.shared.loadPhoto(at: imagePath)
            }
        } else {
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .tertiaryLabel
        }

        // Timestamp
        if let timestamp = photo.timestamp {
            let formatter = DateFormatter()
            formatter.dateFormat = Constants.DateFormat.displayWithTime
            formatter.locale = Locale(identifier: "it_IT")
            timestampLabel.text = formatter.string(from: timestamp)
        } else {
            timestampLabel.text = nil
        }
    }

    /// Configura la cella con un'immagine diretta
    func configure(with image: UIImage?, timestamp: Date?) {
        imageView.image = image ?? UIImage(systemName: "photo")

        if let timestamp = timestamp {
            let formatter = DateFormatter()
            formatter.dateFormat = Constants.DateFormat.displayWithTime
            formatter.locale = Locale(identifier: "it_IT")
            timestampLabel.text = formatter.string(from: timestamp)
        } else {
            timestampLabel.text = nil
        }
    }

    // MARK: - Animation

    /// Anima la selezione della cella
    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.transform = self.isSelected ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.alpha = self.isHighlighted ? 0.7 : 1.0
            }
        }
    }
}
