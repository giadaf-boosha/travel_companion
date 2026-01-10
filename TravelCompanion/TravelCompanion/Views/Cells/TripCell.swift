//
//  TripCell.swift
//  TravelCompanion
//
//  Cella personalizzata per visualizzare un viaggio nella lista viaggi.
//  Mostra destinazione, date, tipo viaggio, distanza e conteggio foto.
//
//  Caratteristiche:
//  - Supporta sia Storyboard (IBOutlet) che creazione programmatica
//  - Indicatore colorato del tipo di viaggio
//  - Bordo verde per viaggi attivi
//  - Animazione di feedback al tap
//  - Formattazione date localizzata (italiano)
//

import UIKit

// MARK: - Trip Cell

/// Cella UITableViewCell personalizzata per visualizzare un viaggio nella lista.
///
/// La cella mostra:
/// - Indicatore colorato del tipo di viaggio
/// - Nome della destinazione
/// - Range di date (formattato in italiano)
/// - Badge tipo viaggio (Locale, Giornaliero, Multi-giorno)
/// - Distanza percorsa (se disponibile)
/// - Conteggio foto (se disponibile)
/// - Bordo verde se il viaggio e attualmente attivo
///
/// Supporta due modalita di inizializzazione:
/// - Storyboard con IBOutlet collegati
/// - Creazione programmatica con `createProgrammatically()`
class TripCell: UITableViewCell {

    // MARK: - IBOutlets (Storyboard)

    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var tripTypeLabel: UILabel!
    @IBOutlet weak var tripTypeIndicator: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var photoCountLabel: UILabel!
    @IBOutlet weak var containerView: UIView!

    // MARK: - Properties

    static let identifier = Constants.Cell.tripCell
    static let estimatedHeight: CGFloat = 100

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        destinationLabel.text = nil
        dateLabel.text = nil
        tripTypeLabel.text = nil
        distanceLabel.text = nil
        photoCountLabel.text = nil
        tripTypeIndicator.backgroundColor = .systemGray
    }

    // MARK: - Setup

    private func setupUI() {
        // Container view styling
        containerView?.layer.cornerRadius = 12
        containerView?.layer.shadowColor = UIColor.black.cgColor
        containerView?.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView?.layer.shadowRadius = 4
        containerView?.layer.shadowOpacity = 0.1
        containerView?.backgroundColor = .systemBackground

        // Trip type indicator
        tripTypeIndicator?.layer.cornerRadius = 4

        // Selection style
        selectionStyle = .none
    }

    // MARK: - Configuration

    /// Configura la cella con i dati di un viaggio
    func configure(with trip: Trip, photoCount: Int = 0) {
        // Destinazione
        destinationLabel.text = trip.destination ?? "Destinazione sconosciuta"

        // Date
        configureDateLabel(trip: trip)

        // Tipo di viaggio
        if let tripTypeRaw = trip.tripTypeRaw, let tripType = TripType(rawValue: tripTypeRaw) {
            tripTypeLabel.text = tripType.displayName
            tripTypeIndicator.backgroundColor = tripType.color
        } else {
            tripTypeLabel.text = "Tipo sconosciuto"
            tripTypeIndicator.backgroundColor = .systemGray
        }

        // Distanza (solo per multi-day o se > 0)
        if trip.totalDistance > 0 {
            distanceLabel.text = DistanceCalculator.formatDistance(trip.totalDistance)
            distanceLabel.isHidden = false
        } else {
            distanceLabel.isHidden = true
        }

        // Conteggio foto
        if photoCount > 0 {
            photoCountLabel.text = "\(photoCount) foto"
            photoCountLabel.isHidden = false
        } else {
            photoCountLabel.isHidden = true
        }

        // Indica se il viaggio è attivo
        if trip.isActive {
            containerView?.layer.borderWidth = 2
            containerView?.layer.borderColor = UIColor.systemGreen.cgColor
        } else {
            containerView?.layer.borderWidth = 0
        }
    }

    /// Configura il label delle date
    private func configureDateLabel(trip: Trip) {
        guard let startDate = trip.startDate else {
            dateLabel.text = "Data non disponibile"
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "it_IT")

        if let endDate = trip.endDate {
            // Viaggio con data di fine
            if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
                // Stesso giorno
                dateFormatter.dateFormat = Constants.DateFormat.display
                dateLabel.text = dateFormatter.string(from: startDate)
            } else {
                // Giorni diversi
                dateFormatter.dateFormat = Constants.DateFormat.dayMonth
                let startString = dateFormatter.string(from: startDate)
                let endString = dateFormatter.string(from: endDate)
                dateLabel.text = "\(startString) - \(endString)"
            }
        } else {
            // Solo data di inizio
            dateFormatter.dateFormat = Constants.DateFormat.display
            dateLabel.text = dateFormatter.string(from: startDate)
        }
    }

    // MARK: - Animation

    /// Anima la selezione della cella
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            UIView.animate(withDuration: 0.1) {
                self.containerView?.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                self.containerView?.transform = .identity
            }
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        if highlighted {
            UIView.animate(withDuration: 0.1) {
                self.containerView?.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
                self.containerView?.backgroundColor = .secondarySystemBackground
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                self.containerView?.transform = .identity
                self.containerView?.backgroundColor = .systemBackground
            }
        }
    }
}

// MARK: - Programmatic Initialization

extension TripCell {

    /// Crea e configura la cella programmaticamente (per uso senza storyboard)
    static func createProgrammatically() -> TripCell {
        let cell = TripCell(style: .default, reuseIdentifier: identifier)
        cell.setupProgrammaticUI()
        return cell
    }

    private func setupProgrammaticUI() {
        // Container view
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        container.layer.shadowOpacity = 0.1
        contentView.addSubview(container)
        self.containerView = container

        // Trip type indicator
        let indicator = UIView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.layer.cornerRadius = 4
        indicator.backgroundColor = .systemGray
        container.addSubview(indicator)
        self.tripTypeIndicator = indicator

        // Destination label
        let destination = UILabel()
        destination.translatesAutoresizingMaskIntoConstraints = false
        destination.font = .systemFont(ofSize: 17, weight: .semibold)
        destination.textColor = .label
        container.addSubview(destination)
        self.destinationLabel = destination

        // Date label
        let date = UILabel()
        date.translatesAutoresizingMaskIntoConstraints = false
        date.font = .systemFont(ofSize: 14)
        date.textColor = .secondaryLabel
        container.addSubview(date)
        self.dateLabel = date

        // Trip type label
        let tripType = UILabel()
        tripType.translatesAutoresizingMaskIntoConstraints = false
        tripType.font = .systemFont(ofSize: 12)
        tripType.textColor = .secondaryLabel
        container.addSubview(tripType)
        self.tripTypeLabel = tripType

        // Distance label
        let distance = UILabel()
        distance.translatesAutoresizingMaskIntoConstraints = false
        distance.font = .systemFont(ofSize: 12)
        distance.textColor = .tertiaryLabel
        container.addSubview(distance)
        self.distanceLabel = distance

        // Photo count label
        let photoCount = UILabel()
        photoCount.translatesAutoresizingMaskIntoConstraints = false
        photoCount.font = .systemFont(ofSize: 12)
        photoCount.textColor = .tertiaryLabel
        container.addSubview(photoCount)
        self.photoCountLabel = photoCount

        // Constraints
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            indicator.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            indicator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            indicator.widthAnchor.constraint(equalToConstant: 8),
            indicator.heightAnchor.constraint(equalToConstant: 8),

            destination.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            destination.leadingAnchor.constraint(equalTo: indicator.trailingAnchor, constant: 12),
            destination.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            date.topAnchor.constraint(equalTo: destination.bottomAnchor, constant: 4),
            date.leadingAnchor.constraint(equalTo: destination.leadingAnchor),
            date.trailingAnchor.constraint(equalTo: destination.trailingAnchor),

            tripType.topAnchor.constraint(equalTo: date.bottomAnchor, constant: 8),
            tripType.leadingAnchor.constraint(equalTo: destination.leadingAnchor),
            tripType.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),

            distance.centerYAnchor.constraint(equalTo: tripType.centerYAnchor),
            distance.leadingAnchor.constraint(equalTo: tripType.trailingAnchor, constant: 16),

            photoCount.centerYAnchor.constraint(equalTo: tripType.centerYAnchor),
            photoCount.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])

        selectionStyle = .none
    }
}
