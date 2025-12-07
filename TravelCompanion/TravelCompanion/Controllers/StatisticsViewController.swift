import UIKit

/// ViewController per la visualizzazione delle statistiche dei viaggi
final class StatisticsViewController: UIViewController {

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let yearSegment: UISegmentedControl = {
        let segment = UISegmentedControl()
        segment.translatesAutoresizingMaskIntoConstraints = false
        return segment
    }()

    // Cards container
    private let statsCardsContainer: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.distribution = .fill
        return stack
    }()

    // Total statistics cards
    private let totalTripsCard = StatCardView(title: "Totale Viaggi", icon: "airplane")
    private let totalDistanceCard = StatCardView(title: "Distanza Totale", icon: "map")
    private let totalPhotosCard = StatCardView(title: "Foto Totali", icon: "photo.on.rectangle")
    private let totalNotesCard = StatCardView(title: "Note Totali", icon: "note.text")

    // Chart containers
    private let tripsChartView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()

    private let distanceChartView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()

    // MARK: - Properties

    private let coreDataManager = CoreDataManager.shared
    private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    private var availableYears: [Int] = []

    // Chart colors
    private let chartBarColor = UIColor.systemBlue
    private let chartLabelColor = UIColor.label
    private let chartGridColor = UIColor.separator

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        loadAvailableYears()
        setupYearSegment()
        loadStatistics()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadStatistics()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Statistiche"
        view.backgroundColor = .systemGroupedBackground

        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(yearSegment)
        contentView.addSubview(statsCardsContainer)
        contentView.addSubview(tripsChartView)
        contentView.addSubview(distanceChartView)

        // Configure cards
        configureCardView(tripsChartView)
        configureCardView(distanceChartView)

        // Setup stats cards
        setupStatsCards()

        // Setup constraints
        setupConstraints()

        // Add target for segment control
        yearSegment.addTarget(self, action: #selector(yearSegmentChanged), for: .valueChanged)
    }

    private func setupStatsCards() {
        // Create horizontal stack for first row (trips and distance)
        let firstRowStack = UIStackView(arrangedSubviews: [totalTripsCard, totalDistanceCard])
        firstRowStack.axis = .horizontal
        firstRowStack.spacing = 12
        firstRowStack.distribution = .fillEqually

        // Create horizontal stack for second row (photos and notes)
        let secondRowStack = UIStackView(arrangedSubviews: [totalPhotosCard, totalNotesCard])
        secondRowStack.axis = .horizontal
        secondRowStack.spacing = 12
        secondRowStack.distribution = .fillEqually

        // Add to container
        statsCardsContainer.addArrangedSubview(firstRowStack)
        statsCardsContainer.addArrangedSubview(secondRowStack)
    }

    private func setupConstraints() {
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

            // Year Segment
            yearSegment.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            yearSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            yearSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Stats Cards Container
            statsCardsContainer.topAnchor.constraint(equalTo: yearSegment.bottomAnchor, constant: 20),
            statsCardsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsCardsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // First row height
            totalTripsCard.heightAnchor.constraint(equalToConstant: 100),

            // Second row height
            totalPhotosCard.heightAnchor.constraint(equalToConstant: 100),

            // Trips Chart
            tripsChartView.topAnchor.constraint(equalTo: statsCardsContainer.bottomAnchor, constant: 24),
            tripsChartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tripsChartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tripsChartView.heightAnchor.constraint(equalToConstant: 250),

            // Distance Chart
            distanceChartView.topAnchor.constraint(equalTo: tripsChartView.bottomAnchor, constant: 20),
            distanceChartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            distanceChartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            distanceChartView.heightAnchor.constraint(equalToConstant: 250),
            distanceChartView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func configureCardView(_ view: UIView) {
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.backgroundColor = .systemBackground
    }

    private func loadAvailableYears() {
        let trips = coreDataManager.fetchAllTrips()
        let calendar = Calendar.current

        var yearsSet = Set<Int>()
        for trip in trips {
            if let startDate = trip.startDate {
                let year = calendar.component(.year, from: startDate)
                yearsSet.insert(year)
            }
        }

        availableYears = Array(yearsSet).sorted(by: >)

        // Se non ci sono anni, usa l'anno corrente
        if availableYears.isEmpty {
            availableYears = [selectedYear]
        }
    }

    private func setupYearSegment() {
        yearSegment.removeAllSegments()

        // Mostra fino a 5 anni più recenti
        let yearsToShow = Array(availableYears.prefix(5))

        for (index, year) in yearsToShow.enumerated() {
            yearSegment.insertSegment(withTitle: "\(year)", at: index, animated: false)

            if year == selectedYear {
                yearSegment.selectedSegmentIndex = index
            }
        }

        // Se l'anno corrente non è selezionato, seleziona il primo
        if yearSegment.selectedSegmentIndex == UISegmentedControl.noSegment {
            yearSegment.selectedSegmentIndex = 0
            if let firstYear = yearsToShow.first {
                selectedYear = firstYear
            }
        }
    }

    // MARK: - Data Loading

    private func loadStatistics() {
        loadTotalStatistics()
        loadYearlyStatistics()
    }

    private func loadTotalStatistics() {
        // Totale viaggi
        let totalTrips = coreDataManager.getTotalTripsCount()
        totalTripsCard.setValue("\(totalTrips)")

        // Distanza totale
        let totalDistance = coreDataManager.getTotalDistance()
        totalDistanceCard.setValue(formatDistance(totalDistance))

        // Totale foto
        let totalPhotos = coreDataManager.getTotalPhotosCount()
        totalPhotosCard.setValue("\(totalPhotos)")

        // Totale note
        let totalNotes = coreDataManager.getTotalNotesCount()
        totalNotesCard.setValue("\(totalNotes)")
    }

    private func loadYearlyStatistics() {
        // Dati per l'anno selezionato
        let tripsCountByMonth = coreDataManager.getTripsCountByMonth(year: selectedYear)
        let distanceByMonth = coreDataManager.getDistanceByMonth(year: selectedYear)

        // Disegna i grafici con animazione
        drawTripsChart(data: tripsCountByMonth)
        drawDistanceChart(data: distanceByMonth)
    }

    // MARK: - Charts Drawing

    private func drawTripsChart(data: [Int: Int]) {
        // Rimuovi layer precedenti
        tripsChartView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let chartLayer = CALayer()
        chartLayer.frame = tripsChartView.bounds
        tripsChartView.layer.addSublayer(chartLayer)

        // Padding
        let padding: CGFloat = 40
        let availableWidth = tripsChartView.bounds.width - (padding * 2)
        let availableHeight = tripsChartView.bounds.height - (padding * 2)

        // Trova il valore massimo
        let maxValue = data.values.max() ?? 1
        let barWidth = availableWidth / 12

        // Disegna griglia e label
        drawGrid(in: chartLayer, frame: CGRect(x: padding, y: padding, width: availableWidth, height: availableHeight), maxValue: CGFloat(maxValue))

        // Disegna le barre
        for month in 1...12 {
            let value = data[month] ?? 0
            let barHeight = (CGFloat(value) / CGFloat(maxValue)) * availableHeight

            let x = padding + (CGFloat(month - 1) * barWidth) + (barWidth * 0.2)
            let y = padding + availableHeight - barHeight
            let width = barWidth * 0.6

            // Crea la barra con animazione
            let barLayer = CAShapeLayer()
            let barPath = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: width, height: barHeight),
                                      cornerRadius: 4)
            barLayer.path = barPath.cgPath
            barLayer.fillColor = chartBarColor.cgColor

            // Animazione
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = 0.5
            animation.beginTime = CACurrentMediaTime() + (Double(month - 1) * 0.05)
            animation.fillMode = .backwards
            barLayer.add(animation, forKey: "fadeIn")

            chartLayer.addSublayer(barLayer)

            // Label del mese
            let monthLabel = CATextLayer()
            monthLabel.string = getMonthAbbreviation(month)
            monthLabel.fontSize = 10
            monthLabel.foregroundColor = chartLabelColor.cgColor
            monthLabel.alignmentMode = .center
            monthLabel.frame = CGRect(x: x, y: padding + availableHeight + 5, width: width, height: 15)
            monthLabel.contentsScale = UIScreen.main.scale
            chartLayer.addSublayer(monthLabel)
        }

        // Titolo
        let titleLabel = CATextLayer()
        titleLabel.string = "Viaggi per Mese"
        titleLabel.fontSize = 14
        titleLabel.foregroundColor = chartLabelColor.cgColor
        titleLabel.alignmentMode = .center
        titleLabel.frame = CGRect(x: 0, y: 10, width: tripsChartView.bounds.width, height: 20)
        titleLabel.contentsScale = UIScreen.main.scale
        chartLayer.addSublayer(titleLabel)
    }

    private func drawDistanceChart(data: [Int: Double]) {
        // Rimuovi layer precedenti
        distanceChartView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let chartLayer = CALayer()
        chartLayer.frame = distanceChartView.bounds
        distanceChartView.layer.addSublayer(chartLayer)

        // Padding
        let padding: CGFloat = 40
        let availableWidth = distanceChartView.bounds.width - (padding * 2)
        let availableHeight = distanceChartView.bounds.height - (padding * 2)

        // Trova il valore massimo
        let maxValue = data.values.max() ?? 1000
        let barWidth = availableWidth / 12

        // Disegna griglia
        drawGrid(in: chartLayer, frame: CGRect(x: padding, y: padding, width: availableWidth, height: availableHeight), maxValue: CGFloat(maxValue))

        // Disegna le barre
        for month in 1...12 {
            let value = data[month] ?? 0
            let barHeight = (CGFloat(value) / CGFloat(maxValue)) * availableHeight

            let x = padding + (CGFloat(month - 1) * barWidth) + (barWidth * 0.2)
            let y = padding + availableHeight - barHeight
            let width = barWidth * 0.6

            // Crea la barra con animazione
            let barLayer = CAShapeLayer()
            let barPath = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: width, height: barHeight),
                                      cornerRadius: 4)
            barLayer.path = barPath.cgPath
            barLayer.fillColor = UIColor.systemGreen.cgColor

            // Animazione
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = 0.5
            animation.beginTime = CACurrentMediaTime() + (Double(month - 1) * 0.05)
            animation.fillMode = .backwards
            barLayer.add(animation, forKey: "fadeIn")

            chartLayer.addSublayer(barLayer)

            // Label del mese
            let monthLabel = CATextLayer()
            monthLabel.string = getMonthAbbreviation(month)
            monthLabel.fontSize = 10
            monthLabel.foregroundColor = chartLabelColor.cgColor
            monthLabel.alignmentMode = .center
            monthLabel.frame = CGRect(x: x, y: padding + availableHeight + 5, width: width, height: 15)
            monthLabel.contentsScale = UIScreen.main.scale
            chartLayer.addSublayer(monthLabel)
        }

        // Titolo
        let titleLabel = CATextLayer()
        titleLabel.string = "Distanza per Mese (km)"
        titleLabel.fontSize = 14
        titleLabel.foregroundColor = chartLabelColor.cgColor
        titleLabel.alignmentMode = .center
        titleLabel.frame = CGRect(x: 0, y: 10, width: distanceChartView.bounds.width, height: 20)
        titleLabel.contentsScale = UIScreen.main.scale
        chartLayer.addSublayer(titleLabel)
    }

    private func drawGrid(in layer: CALayer, frame: CGRect, maxValue: CGFloat) {
        let gridLines = 5
        let lineHeight = frame.height / CGFloat(gridLines)

        for i in 0...gridLines {
            let y = frame.minY + (CGFloat(i) * lineHeight)

            // Linea griglia
            let gridPath = UIBezierPath()
            gridPath.move(to: CGPoint(x: frame.minX, y: y))
            gridPath.addLine(to: CGPoint(x: frame.maxX, y: y))

            let gridLayer = CAShapeLayer()
            gridLayer.path = gridPath.cgPath
            gridLayer.strokeColor = chartGridColor.cgColor
            gridLayer.lineWidth = 0.5
            layer.addSublayer(gridLayer)
        }
    }

    // MARK: - Actions

    @objc private func yearSegmentChanged(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        if selectedIndex < availableYears.count {
            selectedYear = availableYears[selectedIndex]
            loadYearlyStatistics()
        }
    }

    // MARK: - Helper Methods

    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }

    private func getMonthAbbreviation(_ month: Int) -> String {
        let months = ["Gen", "Feb", "Mar", "Apr", "Mag", "Giu", "Lug", "Ago", "Set", "Ott", "Nov", "Dic"]
        guard month > 0 && month <= 12 else { return "" }
        return months[month - 1]
    }
}

// MARK: - StatCardView

/// Card view per visualizzare una singola statistica
private class StatCardView: UIView {

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    init(title: String, icon: String) {
        super.init(frame: .zero)

        self.titleLabel.text = title
        self.iconImageView.image = UIImage(systemName: icon)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(valueLabel)

        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            valueLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8)
        ])
    }

    func setValue(_ value: String) {
        valueLabel.text = value
    }
}
