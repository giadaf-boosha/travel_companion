//
//  UIViewController+Extensions.swift
//  TravelCompanion
//
//  Created on 2025-12-07.
//

import UIKit

extension UIViewController {

    /// Shows a simple alert with title, message, and OK button
    /// - Parameters:
    ///   - title: The alert title
    ///   - message: The alert message
    ///   - completion: Optional completion handler called when alert is dismissed
    func showSimpleAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        }
        alertController.addAction(okAction)

        DispatchQueue.main.async { [weak self] in
            self?.present(alertController, animated: true)
        }
    }

    /// Shows a confirmation alert with custom buttons
    /// - Parameters:
    ///   - title: The alert title
    ///   - message: The alert message
    ///   - confirmTitle: The title for the confirm button (default: "Confirm")
    ///   - cancelTitle: The title for the cancel button (default: "Cancel")
    ///   - confirmAction: The action to perform when confirm is tapped
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

        alertController.addAction(cancelBtn)
        alertController.addAction(confirmBtn)

        DispatchQueue.main.async { [weak self] in
            self?.present(alertController, animated: true)
        }
    }

    /// Shows an error alert with a formatted error message
    /// - Parameter error: The error to display
    func showErrorAlert(_ error: Error) {
        let title = "Errore"
        let message = error.localizedDescription
        showSimpleAlert(title: title, message: message)
    }

    /// Adds a tap gesture recognizer to dismiss the keyboard when tapping outside text fields
    func setupKeyboardDismissOnTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleKeyboardDismissTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func handleKeyboardDismissTap() {
        view.endEditing(true)
    }

    // MARK: - Loading Indicator

    private static var loadingViewTag = 999999
    private static var activityIndicatorTag = 999998

    /// Shows a loading indicator overlay on the view controller
    /// - Parameter message: Optional message to display below the spinner
    func showLoadingIndicator(message: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Remove any existing loading view
            self.hideLoadingIndicator()

            // Create overlay view
            let loadingView = UIView(frame: self.view.bounds)
            loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            loadingView.tag = UIViewController.loadingViewTag
            loadingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            // Create container for spinner and text
            let containerView = UIView()
            containerView.backgroundColor = UIColor.systemBackground
            containerView.layer.cornerRadius = 12
            containerView.translatesAutoresizingMaskIntoConstraints = false

            // Create activity indicator
            let activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.tag = UIViewController.activityIndicatorTag
            activityIndicator.color = .label
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.startAnimating()

            containerView.addSubview(activityIndicator)

            var constraints = [
                activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                activityIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20)
            ]

            // Add message label if provided
            if let message = message {
                let messageLabel = UILabel()
                messageLabel.text = message
                messageLabel.textColor = .label
                messageLabel.font = .systemFont(ofSize: 16, weight: .medium)
                messageLabel.textAlignment = .center
                messageLabel.numberOfLines = 0
                messageLabel.translatesAutoresizingMaskIntoConstraints = false

                containerView.addSubview(messageLabel)

                constraints.append(contentsOf: [
                    messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
                    messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                    messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
                    messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
                ])
            } else {
                constraints.append(
                    activityIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
                )
            }

            loadingView.addSubview(containerView)

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

    /// Hides the loading indicator overlay
    func hideLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let loadingView = self.view.viewWithTag(UIViewController.loadingViewTag) {
                UIView.animate(withDuration: 0.2, animations: {
                    loadingView.alpha = 0
                }, completion: { _ in
                    loadingView.removeFromSuperview()
                })
            }
        }
    }
}
