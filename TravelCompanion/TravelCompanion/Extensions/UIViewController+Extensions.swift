//
//  UIViewController+Extensions.swift
//  TravelCompanion
//
//  Estensioni per UIViewController con utility per alert, tastiera e indicatori di caricamento.
//  Created on 2025-12-07.
//

import UIKit

// MARK: - UIViewController Extensions

/// Estensione di UIViewController con metodi di utilita per la gestione di alert,
/// tastiera e indicatori di caricamento usati in tutta l'applicazione
extension UIViewController {

    // MARK: - Alert Semplici

    /// Mostra un alert semplice con titolo, messaggio e pulsante OK
    /// - Parameters:
    ///   - title: Titolo dell'alert
    ///   - message: Messaggio dell'alert
    ///   - completion: Handler opzionale chiamato quando l'alert viene chiuso
    /// - Note: L'alert viene presentato sul main thread per sicurezza
    func showSimpleAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        }
        alertController.addAction(okAction)

        // Presenta sul main thread per evitare problemi di concorrenza
        DispatchQueue.main.async { [weak self] in
            self?.present(alertController, animated: true)
        }
    }

    // MARK: - Alert di Conferma

    /// Mostra un alert di conferma con pulsanti personalizzabili
    /// - Parameters:
    ///   - title: Titolo dell'alert
    ///   - message: Messaggio dell'alert
    ///   - confirmTitle: Titolo del pulsante di conferma (default: "Conferma")
    ///   - cancelTitle: Titolo del pulsante di annullamento (default: "Annulla")
    ///   - confirmAction: Azione da eseguire quando si conferma
    /// - Note: Il pulsante cancel viene aggiunto prima per essere a sinistra
    func showConfirmationAlert(
        title: String,
        message: String,
        confirmTitle: String = "Conferma",
        cancelTitle: String = "Annulla",
        confirmAction: @escaping () -> Void
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let confirmBtn = UIAlertAction(title: confirmTitle, style: .default) { _ in
            confirmAction()
        }

        let cancelBtn = UIAlertAction(title: cancelTitle, style: .cancel)

        // Ordine: prima cancel (sinistra), poi conferma (destra)
        alertController.addAction(cancelBtn)
        alertController.addAction(confirmBtn)

        DispatchQueue.main.async { [weak self] in
            self?.present(alertController, animated: true)
        }
    }

    // MARK: - Alert Errori

    /// Mostra un alert per errori con messaggio formattato
    /// - Parameter error: L'errore da visualizzare
    /// - Note: Usa localizedDescription per il messaggio
    func showErrorAlert(_ error: Error) {
        let title = "Errore"
        let message = error.localizedDescription
        showSimpleAlert(title: title, message: message)
    }

    // MARK: - Gestione Tastiera

    /// Aggiunge un riconoscitore di tap per chiudere la tastiera toccando fuori dai campi di testo
    /// - Note: cancelsTouchesInView = false permette che i tap raggiungano altri controlli
    func setupKeyboardDismissOnTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleKeyboardDismissTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    /// Handler privato per chiudere la tastiera
    @objc private func handleKeyboardDismissTap() {
        view.endEditing(true)
    }

    // MARK: - Indicatore di Caricamento

    /// Tag per identificare la view di overlay del loading
    private static var loadingViewTag = 999999

    /// Tag per identificare l'activity indicator
    private static var activityIndicatorTag = 999998

    /// Mostra un indicatore di caricamento overlay sul view controller
    /// - Parameter message: Messaggio opzionale da mostrare sotto lo spinner
    /// - Note: Crea un overlay semi-trasparente con spinner centrato
    func showLoadingIndicator(message: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Rimuove eventuali loading view esistenti prima di crearne una nuova
            self.hideLoadingIndicator()

            // Crea la view di overlay con sfondo semi-trasparente
            let loadingView = UIView(frame: self.view.bounds)
            loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            loadingView.tag = UIViewController.loadingViewTag
            loadingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            // Crea il container centrale per spinner e testo
            let containerView = UIView()
            containerView.backgroundColor = UIColor.systemBackground
            containerView.layer.cornerRadius = 12
            containerView.translatesAutoresizingMaskIntoConstraints = false

            // Crea l'activity indicator (spinner)
            let activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.tag = UIViewController.activityIndicatorTag
            activityIndicator.color = .label
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.startAnimating()

            containerView.addSubview(activityIndicator)

            // Imposta i constraint base per lo spinner
            var constraints = [
                activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                activityIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20)
            ]

            // Aggiunge la label del messaggio se fornito
            if let message = message {
                let messageLabel = UILabel()
                messageLabel.text = message
                messageLabel.textColor = .label
                messageLabel.font = .systemFont(ofSize: 16, weight: .medium)
                messageLabel.textAlignment = .center
                messageLabel.numberOfLines = 0
                messageLabel.translatesAutoresizingMaskIntoConstraints = false

                containerView.addSubview(messageLabel)

                // Constraint aggiuntivi per la label del messaggio
                constraints.append(contentsOf: [
                    messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
                    messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                    messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
                    messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
                ])
            } else {
                // Senza messaggio, lo spinner e al centro verticale
                constraints.append(
                    activityIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
                )
            }

            loadingView.addSubview(containerView)

            // Constraint per centrare il container nell'overlay
            constraints.append(contentsOf: [
                containerView.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
                containerView.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor),
                containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
                containerView.leadingAnchor.constraint(greaterThanOrEqualTo: loadingView.leadingAnchor, constant: 40),
                containerView.trailingAnchor.constraint(lessThanOrEqualTo: loadingView.trailingAnchor, constant: -40)
            ])

            NSLayoutConstraint.activate(constraints)

            self.view.addSubview(loadingView)
        }
    }

    /// Nasconde l'indicatore di caricamento overlay con animazione fade-out
    /// - Note: Viene eseguito sul main thread per sicurezza
    func hideLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Cerca la loading view tramite il suo tag
            if let loadingView = self.view.viewWithTag(UIViewController.loadingViewTag) {
                // Animazione di fade-out prima della rimozione
                UIView.animate(withDuration: 0.2, animations: {
                    loadingView.alpha = 0
                }, completion: { _ in
                    loadingView.removeFromSuperview()
                })
            }
        }
    }
}
