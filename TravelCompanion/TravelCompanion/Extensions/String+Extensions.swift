//
//  String+Extensions.swift
//  TravelCompanion
//
//  Estensioni per la classe String con utility di validazione e formattazione.
//  Created on 2025-12-07.
//

import Foundation

// MARK: - String Extensions

/// Estensione di String con metodi di utilita per validazione, formattazione e manipolazione testo
extension String {

    // MARK: - Proprieta di Trimming e Validazione Base

    /// Restituisce la stringa senza spazi bianchi iniziali e finali
    /// - Note: Rimuove sia spazi che newline
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Verifica se la stringa non e vuota dopo il trimming
    /// - Returns: `true` se la stringa contiene almeno un carattere non-whitespace
    var isNotEmpty: Bool {
        return !self.trimmed.isEmpty
    }

    // MARK: - Validazione Destinazioni di Viaggio

    /// Valida se la stringa e un nome di destinazione valido
    ///
    /// Una destinazione valida deve:
    /// - Non essere vuota dopo il trimming
    /// - Avere almeno 2 caratteri
    /// - Non contenere solo numeri
    /// - Contenere solo lettere, spazi e punteggiatura comune (virgole, punti, trattini, apostrofi)
    ///
    /// - Returns: `true` se la destinazione e valida
    /// - Example: "Roma" -> true, "123" -> false, "P@ris!" -> false
    var isValidDestination: Bool {
        let trimmedString = self.trimmed

        // Verifica se vuota o troppo corta
        guard trimmedString.count >= 2 else { return false }

        // Verifica se contiene solo numeri
        if trimmedString.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil {
            return false
        }

        // Definisce i caratteri consentiti: lettere, spazi e punteggiatura comune
        let allowedCharacters = CharacterSet.letters
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: ",.'-"))

        // Verifica che tutti i caratteri siano consentiti
        let stringCharacters = CharacterSet(charactersIn: trimmedString)
        return allowedCharacters.isSuperset(of: stringCharacters)
    }

    // MARK: - Troncamento e Formattazione

    /// Tronca la stringa a una lunghezza specificata aggiungendo ellissi se necessario
    /// - Parameter length: Lunghezza massima della stringa risultante (inclusa ellissi)
    /// - Returns: La stringa troncata con "..." se era piu lunga del limite
    /// - Example: "Ciao mondo".truncated(to: 8) -> "Ciao..."
    func truncated(to length: Int) -> String {
        guard length > 3 else { return self }

        if self.count > length {
            let truncatedLength = length - 3
            let index = self.index(self.startIndex, offsetBy: truncatedLength)
            return String(self[..<index]) + "..."
        }

        return self
    }

    /// Rende maiuscola solo la prima lettera della stringa
    /// - Returns: Stringa con prima lettera maiuscola e resto invariato
    /// - Example: "ciao" -> "Ciao", "CIAO" -> "CIAO"
    var capitalizedFirst: String {
        guard !self.isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }

    // MARK: - Validazione Formati Specifici

    /// Verifica se la stringa e un indirizzo email valido
    /// - Returns: `true` se il formato email e corretto
    /// - Note: Usa una regex standard per la validazione
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }

    /// Verifica se la stringa contiene solo lettere e spazi
    /// - Returns: `true` se non ci sono numeri o caratteri speciali
    var isAlphabetic: Bool {
        let allowedCharacters = CharacterSet.letters.union(.whitespaces)
        let stringCharacters = CharacterSet(charactersIn: self)
        return allowedCharacters.isSuperset(of: stringCharacters) && !self.isEmpty
    }

    /// Verifica se la stringa contiene solo numeri
    /// - Returns: `true` se la stringa e composta esclusivamente da cifre
    var isNumeric: Bool {
        return !self.isEmpty && self.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }

    // MARK: - Manipolazione Whitespace

    /// Restituisce la stringa senza alcun carattere di spazio
    /// - Returns: Stringa con tutti gli spazi rimossi
    /// - Example: "Ciao mondo" -> "Ciaomondo"
    var withoutWhitespace: String {
        return self.components(separatedBy: .whitespaces).joined()
    }

    // MARK: - Encoding e Sanitizzazione

    /// Converte la stringa in un formato URL-safe
    /// - Returns: Stringa con caratteri speciali codificati per uso in URL
    var urlEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }

    /// Rimuove tutti i tag HTML dalla stringa
    /// - Returns: Stringa senza markup HTML
    /// - Example: "<p>Ciao</p>" -> "Ciao"
    var strippingHTML: String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    // MARK: - Conversione Case

    /// Converte la stringa in kebab-case (minuscolo con trattini)
    /// - Returns: Stringa in formato kebab-case
    /// - Example: "CiaoMondo" -> "ciao-mondo"
    var kebabCased: String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: self.count)
        let kebabCase = regex?.stringByReplacingMatches(
            in: self,
            range: range,
            withTemplate: "$1-$2"
        )
        return kebabCase?.lowercased().replacingOccurrences(of: " ", with: "-") ?? self.lowercased()
    }

    // MARK: - Conteggio e Analisi

    /// Restituisce il numero di parole nella stringa
    /// - Returns: Conteggio delle parole separate da spazi
    var wordCount: Int {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        let words = components.filter { !$0.isEmpty }
        return words.count
    }

    // MARK: - Subscript Sicuri

    /// Accede in modo sicuro a un carattere tramite indice intero
    /// - Parameter index: L'indice del carattere da ottenere
    /// - Returns: Il carattere all'indice specificato, o `nil` se fuori range
    /// - Example: "Ciao"[safe: 1] -> "i"
    subscript(safe index: Int) -> Character? {
        guard index >= 0 && index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }

    /// Accede in modo sicuro a una sottostringa tramite range
    /// - Parameter range: Il range di indici da estrarre
    /// - Returns: La sottostringa nel range, o `nil` se fuori limiti
    /// - Example: "Ciao"[safe: 0..<2] -> "Ci"
    subscript(safe range: Range<Int>) -> String? {
        guard range.lowerBound >= 0,
              range.upperBound <= count,
              range.lowerBound < range.upperBound else { return nil }

        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
        return String(self[startIndex..<endIndex])
    }
}
