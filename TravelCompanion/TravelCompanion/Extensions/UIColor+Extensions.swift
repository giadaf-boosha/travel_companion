//
//  UIColor+Extensions.swift
//  TravelCompanion
//
//  Estensioni per UIColor con colori tema dell'app e conversione hex.
//  Created on 2025-12-07.
//

import UIKit

// MARK: - UIColor Extensions

/// Estensione di UIColor con colori personalizzati dell'app e metodi di conversione hex
extension UIColor {

    // MARK: - Colori Tema Principali

    /// Colore primario dell'app - usato per azioni principali e branding
    /// - Note: Blu iOS standard (#007AFF)
    static let primaryColor = UIColor(hex: "#007AFF") ?? .systemBlue

    /// Colore secondario dell'app - usato per azioni secondarie e accenti
    /// - Note: Viola iOS standard (#5856D6)
    static let secondaryColor = UIColor(hex: "#5856D6") ?? .systemPurple

    /// Colore di accento - usato per evidenziazioni ed elementi importanti
    /// - Note: Arancione iOS standard (#FF9500)
    static let accentColor = UIColor(hex: "#FF9500") ?? .systemOrange

    // MARK: - Colori per Tipi di Viaggio

    /// Colore per viaggi locali (nella stessa citta/area)
    /// - Note: Verde per indicare familiarita e vicinanza
    static let localTripColor = UIColor(hex: "#34C759") ?? .systemGreen

    /// Colore per gite giornaliere (escursioni di un solo giorno)
    /// - Note: Arancione per indicare attivita e dinamismo
    static let dayTripColor = UIColor(hex: "#FF9500") ?? .systemOrange

    /// Colore per viaggi multi-giorno (viaggi estesi)
    /// - Note: Viola per indicare avventura e esplorazione
    static let multiDayTripColor = UIColor(hex: "#5856D6") ?? .systemPurple

    // MARK: - Colori Messaggi Chat

    /// Colore di sfondo per i messaggi dell'utente nella chat
    /// - Note: Blu per distinguere visivamente i messaggi inviati
    static let userMessageColor = UIColor(hex: "#007AFF") ?? .systemBlue

    /// Colore di sfondo per i messaggi dell'assistente nella chat
    /// - Note: Grigio chiaro per i messaggi ricevuti
    static let assistantMessageColor = UIColor(hex: "#E5E5EA") ?? .systemGray5

    // MARK: - Colori di Utilita Semantici

    /// Colore successo per azioni positive e conferme
    /// - Note: Verde per feedback positivo
    static let successColor = UIColor(hex: "#34C759") ?? .systemGreen

    /// Colore avviso per alert e cautele
    /// - Note: Arancione per attirare attenzione senza allarmare
    static let warningColor = UIColor(hex: "#FF9500") ?? .systemOrange

    /// Colore errore per errori e azioni distruttive
    /// - Note: Rosso per segnalare problemi o pericoli
    static let errorColor = UIColor(hex: "#FF3B30") ?? .systemRed

    /// Colore informativo per messaggi informativi
    /// - Note: Viola per informazioni neutrali
    static let infoColor = UIColor(hex: "#5856D6") ?? .systemPurple

    // MARK: - Inizializzatore Hex

    /// Inizializza un UIColor da una stringa esadecimale
    /// - Parameter hex: Stringa hex (con o senza #) come "#FF0000" o "FF0000"
    /// - Returns: Istanza UIColor, o nil se la stringa hex non e valida
    ///
    /// Supporta formati:
    /// - 6 caratteri (RGB): "#FF0000" per rosso
    /// - 8 caratteri (RGBA): "#FF0000FF" per rosso opaco
    ///
    /// - Example: UIColor(hex: "#007AFF") -> Blu iOS
    convenience init?(hex: String) {
        // Rimuove spazi e simbolo #
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        // Tenta di parsare il valore esadecimale
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        let r, g, b, a: CGFloat

        if length == 6 {
            // Formato RGB (6 caratteri)
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            // Formato RGBA (8 caratteri)
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    // MARK: - Conversione a Hex

    /// Restituisce la rappresentazione esadecimale del colore
    /// - Parameter includeAlpha: Se includere il canale alpha nella stringa hex
    /// - Returns: Stringa hex come "#FF0000" o "#FF0000FF" (con alpha)
    /// - Example: UIColor.red.toHex() -> "#FF0000"
    func toHex(includeAlpha: Bool = false) -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if includeAlpha {
            return String(format: "#%02lX%02lX%02lX%02lX",
                         lroundf(r * 255),
                         lroundf(g * 255),
                         lroundf(b * 255),
                         lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX",
                         lroundf(r * 255),
                         lroundf(g * 255),
                         lroundf(b * 255))
        }
    }

    // MARK: - Varianti di Luminosita

    /// Restituisce una versione piu chiara del colore
    /// - Parameter percentage: Percentuale di schiarimento (0.0 a 1.0)
    /// - Returns: UIColor piu chiaro
    /// - Note: Default 30% piu chiaro
    func lighter(by percentage: CGFloat = 0.3) -> UIColor {
        return adjustBrightness(by: abs(percentage))
    }

    /// Restituisce una versione piu scura del colore
    /// - Parameter percentage: Percentuale di scurimento (0.0 a 1.0)
    /// - Returns: UIColor piu scuro
    /// - Note: Default 30% piu scuro
    func darker(by percentage: CGFloat = 0.3) -> UIColor {
        return adjustBrightness(by: -abs(percentage))
    }

    /// Metodo privato per regolare la luminosita del colore
    /// - Parameter percentage: Valore di regolazione (positivo = piu chiaro, negativo = piu scuro)
    /// - Returns: UIColor con luminosita modificata
    private func adjustBrightness(by percentage: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0

        // Converte in HSB per modificare la luminosita
        if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return UIColor(hue: h, saturation: s, brightness: max(min(b + percentage, 1.0), 0.0), alpha: a)
        }

        return self
    }
}
