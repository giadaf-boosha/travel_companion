import UIKit

/// ViewController per le impostazioni dell'app
final class SettingsViewController: UIViewController {

    // MARK: - UI Components

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        table.backgroundColor = .systemGroupedBackground
        return table
    }()

    // MARK: - Properties

    private let notificationManager = NotificationManager.shared

    // Sezioni della tabella
    private enum Section: Int, CaseIterable {
        case notifications
        case geofence
        case account
        case about

        var title: String {
            switch self {
            case .notifications: return "Notifiche"
            case .geofence: return "Geofencing"
            case .account: return "Account"
            case .about: return "Informazioni"
            }
        }
    }

    private enum NotificationRow: Int, CaseIterable {
        case poiNotifications
        case reminderNotifications
        case reminderInterval
        case openSettings

        var title: String {
            switch self {
            case .poiNotifications: return "Notifiche POI"
            case .reminderNotifications: return "Promemoria Viaggi"
            case .reminderInterval: return "Intervallo Promemoria"
            case .openSettings: return "Apri Impostazioni Sistema"
            }
        }

        var subtitle: String? {
            switch self {
            case .poiNotifications: return "Ricevi notifiche per punti di interesse nelle vicinanze"
            case .reminderNotifications: return "Promemoria per registrare nuovi viaggi"
            case .reminderInterval: return nil
            case .openSettings: return "Gestisci permessi e notifiche"
            }
        }
    }

    private enum AccountRow: Int, CaseIterable {
        case profile
        case privacy
        case dataManagement

        var title: String {
            switch self {
            case .profile: return "Profilo"
            case .privacy: return "Privacy"
            case .dataManagement: return "Gestione Dati"
            }
        }

        var subtitle: String? {
            switch self {
            case .profile: return "Modifica informazioni personali"
            case .privacy: return "Controlla le tue impostazioni di privacy"
            case .dataManagement: return "Esporta o elimina i tuoi dati"
            }
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupConstraints()
        loadSettings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Ricarica lo stato delle autorizzazioni
        notificationManager.checkAuthorizationStatus { [weak self] _ in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Impostazioni"
        view.backgroundColor = .systemGroupedBackground

        // Aggiungi la tableView alla view
        view.addSubview(tableView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadSettings() {
        // Carica le impostazioni dai UserDefaults
        if !UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.notificationsEnabled) {
            // Imposta valori di default al primo avvio
            UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.poiNotificationsEnabled)
            UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.reminderNotificationsEnabled)
            UserDefaults.standard.set(Constants.Defaults.reminderIntervalDays, forKey: Constants.UserDefaultsKeys.reminderIntervalDays)
            UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.notificationsEnabled)
        }
    }

    // MARK: - Settings Management

    private func togglePOINotifications(_ isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: Constants.UserDefaultsKeys.poiNotificationsEnabled)

        if !notificationManager.isAuthorized && isOn {
            requestNotificationPermission()
        }
    }

    private func toggleReminderNotifications(_ isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: Constants.UserDefaultsKeys.reminderNotificationsEnabled)

        if isOn {
            let interval = UserDefaults.standard.integer(forKey: Constants.UserDefaultsKeys.reminderIntervalDays)
            notificationManager.scheduleLoggingReminder(daysInterval: interval)
        } else {
            notificationManager.cancelLoggingReminder()
        }

        if !notificationManager.isAuthorized && isOn {
            requestNotificationPermission()
        }
    }

    private func updateReminderInterval(_ days: Int) {
        UserDefaults.standard.set(days, forKey: Constants.UserDefaultsKeys.reminderIntervalDays)

        // Riprogramma il reminder se è abilitato
        if UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.reminderNotificationsEnabled) {
            notificationManager.scheduleLoggingReminder(daysInterval: days)
        }

        tableView.reloadData()
    }

    private func requestNotificationPermission() {
        notificationManager.requestAuthorization { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.tableView.reloadData()
                } else {
                    self?.showPermissionDeniedAlert()
                }
            }
        }
    }

    private func openSystemSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }

    // MARK: - Alerts

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Permesso Negato",
            message: "Le notifiche sono disabilitate. Puoi abilitarle dalle Impostazioni di sistema.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Impostazioni", style: .default) { [weak self] _ in
            self?.openSystemSettings()
        })

        present(alert, animated: true)
    }

    private func showReminderIntervalPicker() {
        let alert = UIAlertController(
            title: "Intervallo Promemoria",
            message: "Ogni quanti giorni vuoi ricevere un promemoria?",
            preferredStyle: .alert
        )

        // Opzioni predefinite
        let intervals = [3, 7, 14, 30]
        let currentInterval = UserDefaults.standard.integer(forKey: Constants.UserDefaultsKeys.reminderIntervalDays)

        for interval in intervals {
            let action = UIAlertAction(title: "\(interval) giorni", style: .default) { [weak self] _ in
                self?.updateReminderInterval(interval)
            }
            if interval == currentInterval {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))

        present(alert, animated: true)
    }

    private func showAccountFeatureAlert(feature: String) {
        let alert = UIAlertController(
            title: feature,
            message: "Questa funzionalità sarà disponibile in una versione futura dell'app.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Helper Methods

    private func getAppVersion() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }

        switch sectionType {
        case .notifications:
            return NotificationRow.allCases.count
        case .geofence:
            return 1
        case .account:
            return AccountRow.allCases.count
        case .about:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        cell.selectionStyle = .default

        guard let sectionType = Section(rawValue: indexPath.section) else { return cell }

        var content = cell.defaultContentConfiguration()

        switch sectionType {
        case .notifications:
            configureNotificationCell(cell, content: &content, row: indexPath.row)

        case .geofence:
            content.text = "Gestisci Zone Geofence"
            content.secondaryText = "Configura le zone di monitoraggio"
            cell.accessoryType = .disclosureIndicator
            cell.contentConfiguration = content

        case .account:
            configureAccountCell(cell, content: &content, row: indexPath.row)

        case .about:
            content.text = "Versione App"
            content.secondaryText = getAppVersion()
            cell.selectionStyle = .none
            cell.accessoryType = .none
            cell.contentConfiguration = content
        }

        return cell
    }

    private func configureNotificationCell(_ cell: UITableViewCell, content: inout UIListContentConfiguration, row: Int) {
        guard let notificationRow = NotificationRow(rawValue: row) else { return }

        content.text = notificationRow.title
        content.secondaryText = notificationRow.subtitle

        switch notificationRow {
        case .poiNotifications:
            let toggle = UISwitch()
            toggle.isOn = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.poiNotificationsEnabled)
            toggle.addTarget(self, action: #selector(poiNotificationsToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none

        case .reminderNotifications:
            let toggle = UISwitch()
            toggle.isOn = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.reminderNotificationsEnabled)
            toggle.addTarget(self, action: #selector(reminderNotificationsToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none

        case .reminderInterval:
            let days = UserDefaults.standard.integer(forKey: Constants.UserDefaultsKeys.reminderIntervalDays)
            content.secondaryText = "Ogni \(days) giorni"
            cell.accessoryType = .disclosureIndicator
            cell.accessoryView = nil
            cell.selectionStyle = .default

        case .openSettings:
            cell.accessoryType = .disclosureIndicator
            cell.accessoryView = nil
            cell.selectionStyle = .default
        }

        cell.contentConfiguration = content
    }

    private func configureAccountCell(_ cell: UITableViewCell, content: inout UIListContentConfiguration, row: Int) {
        guard let accountRow = AccountRow(rawValue: row) else { return }

        content.text = accountRow.title
        content.secondaryText = accountRow.subtitle
        cell.accessoryType = .disclosureIndicator
        cell.accessoryView = nil
        cell.selectionStyle = .default
        cell.contentConfiguration = content
    }

    // MARK: - Actions

    @objc private func poiNotificationsToggled(_ sender: UISwitch) {
        togglePOINotifications(sender.isOn)
    }

    @objc private func reminderNotificationsToggled(_ sender: UISwitch) {
        toggleReminderNotifications(sender.isOn)
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let sectionType = Section(rawValue: indexPath.section) else { return }

        switch sectionType {
        case .notifications:
            guard let notificationRow = NotificationRow(rawValue: indexPath.row) else { return }

            switch notificationRow {
            case .reminderInterval:
                showReminderIntervalPicker()

            case .openSettings:
                openSystemSettings()

            default:
                break
            }

        case .geofence:
            // Naviga al GeofenceViewController
            performSegue(withIdentifier: Constants.Segue.showGeofence, sender: nil)

        case .account:
            guard let accountRow = AccountRow(rawValue: indexPath.row) else { return }
            showAccountFeatureAlert(feature: accountRow.title)

        case .about:
            break
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }

        switch sectionType {
        case .notifications:
            if !notificationManager.isAuthorized {
                return "Le notifiche sono disabilitate. Abilita le notifiche dalle Impostazioni di sistema per ricevere aggiornamenti."
            }
            return nil

        case .geofence:
            return "Le zone geofence ti avvisano quando entri o esci da luoghi specifici. Richiede l'autorizzazione alla posizione 'Sempre'."

        case .account:
            return "Gestisci le tue informazioni personali e le preferenze dell'account."

        case .about:
            return "\(Config.appName) - La tua app per registrare e condividere i tuoi viaggi."
        }
    }
}
