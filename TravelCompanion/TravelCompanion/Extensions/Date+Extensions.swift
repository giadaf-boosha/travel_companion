//
//  Date+Extensions.swift
//  TravelCompanion
//
//  Created on 2025-12-07.
//

import Foundation

extension Date {

    /// Formats the date with a specified style
    /// - Parameter style: The date formatter style to use
    /// - Returns: A formatted string representation of the date
    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }

    /// Formats the date with both date and time
    /// - Returns: A formatted string with date and time (e.g., "Dec 7, 2025 at 10:30 AM")
    func formattedWithTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }

    /// Returns a human-readable string representing how long ago the date was
    /// - Returns: A string like "Just now", "5 minutes ago", "2 hours ago", etc.
    func timeAgo() -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute, .second], from: self, to: now)

        if let years = components.year, years > 0 {
            return years == 1 ? "1 year ago" : "\(years) years ago"
        }

        if let months = components.month, months > 0 {
            return months == 1 ? "1 month ago" : "\(months) months ago"
        }

        if let weeks = components.weekOfYear, weeks > 0 {
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        }

        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        }

        if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }

        if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        }

        return "Just now"
    }

    /// Returns the start of the day (00:00:00)
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    /// Returns the end of the day (23:59:59)
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Returns the start of the month (first day at 00:00:00)
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    /// Returns the end of the month (last day at 23:59:59)
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    /// Checks if this date is on the same day as another date
    /// - Parameter date: The date to compare with
    /// - Returns: True if both dates are on the same day
    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }

    /// Calculates the number of days between this date and another date
    /// - Parameter date: The date to calculate the difference from
    /// - Returns: The number of days between the two dates (can be negative)
    func daysBetween(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: self.startOfDay, to: date.startOfDay)
        return components.day ?? 0
    }

    /// Calculates the number of months between this date and another date
    /// - Parameter date: The date to calculate the difference from
    /// - Returns: The number of months between the two dates (can be negative)
    func monthsBetween(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.month], from: self.startOfMonth, to: date.startOfMonth)
        return components.month ?? 0
    }
}
