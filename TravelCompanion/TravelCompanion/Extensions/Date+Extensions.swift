//
//  Date+Extensions.swift
//  TravelCompanion
//
//  Estensioni per la classe Date con utility di formattazione e calcolo intervalli.
//  Created on 2025-12-07.
//

import Foundation

// MARK: - Date Extensions

/// Estensione di Date con metodi di utilita per formattazione, confronto e calcolo differenze temporali
extension Date {

    // MARK: - Formattazione

    /// Formatta la data con uno stile specificato
    /// - Parameter style: Lo stile del DateFormatter da usare (.short, .medium, .long, .full)
    /// - Returns: Rappresentazione stringa formattata della data
    /// - Note: Usa il locale corrente del dispositivo
    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }

    /// Formatta la data includendo sia data che ora
    /// - Returns: Stringa formattata con data e ora (es. "7 dic 2025, 10:30")
    /// - Note: Stile data: medio, stile ora: breve
    func formattedWithTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }

    // MARK: - Tempo Relativo

    /// Restituisce una stringa leggibile che rappresenta quanto tempo fa era questa data
    /// - Returns: Stringa come "Adesso", "5 minuti fa", "2 ore fa", "1 settimana fa", ecc.
    /// - Note: Utile per mostrare timestamp relativi nell'interfaccia utente
    func timeAgo() -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute, .second], from: self, to: now)

        // Controlla in ordine decrescente di grandezza
        if let years = components.year, years > 0 {
            return years == 1 ? "1 anno fa" : "\(years) anni fa"
        }

        if let months = components.month, months > 0 {
            return months == 1 ? "1 mese fa" : "\(months) mesi fa"
        }

        if let weeks = components.weekOfYear, weeks > 0 {
            return weeks == 1 ? "1 settimana fa" : "\(weeks) settimane fa"
        }

        if let days = components.day, days > 0 {
            return days == 1 ? "1 giorno fa" : "\(days) giorni fa"
        }

        if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 ora fa" : "\(hours) ore fa"
        }

        if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minuto fa" : "\(minutes) minuti fa"
        }

        return "Adesso"
    }

    // MARK: - Limiti Temporali del Giorno

    /// Restituisce l'inizio del giorno (00:00:00)
    /// - Returns: Data con ora impostata a mezzanotte
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    /// Restituisce la fine del giorno (23:59:59)
    /// - Returns: Data con ora impostata all'ultimo secondo del giorno
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    // MARK: - Limiti Temporali del Mese

    /// Restituisce l'inizio del mese (primo giorno alle 00:00:00)
    /// - Returns: Data del primo giorno del mese corrente
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// Restituisce la fine del mese (ultimo giorno alle 23:59:59)
    /// - Returns: Data dell'ultimo giorno del mese corrente
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    // MARK: - Confronti

    /// Verifica se questa data e nello stesso giorno di un'altra data
    /// - Parameter date: La data da confrontare
    /// - Returns: `true` se entrambe le date sono nello stesso giorno calendario
    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }

    // MARK: - Calcolo Differenze

    /// Calcola il numero di giorni tra questa data e un'altra
    /// - Parameter date: La data da cui calcolare la differenza
    /// - Returns: Numero di giorni (puo essere negativo se la data e nel passato)
    /// - Note: Il calcolo e basato sull'inizio dei rispettivi giorni
    func daysBetween(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: self.startOfDay, to: date.startOfDay)
        return components.day ?? 0
    }

    /// Calcola il numero di mesi tra questa data e un'altra
    /// - Parameter date: La data da cui calcolare la differenza
    /// - Returns: Numero di mesi (puo essere negativo se la data e nel passato)
    /// - Note: Il calcolo e basato sull'inizio dei rispettivi mesi
    func monthsBetween(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.month], from: self.startOfMonth, to: date.startOfMonth)
        return components.month ?? 0
    }
}
