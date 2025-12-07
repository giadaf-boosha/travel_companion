//
//  String+Extensions.swift
//  TravelCompanion
//
//  Created on 2025-12-07.
//

import Foundation

extension String {

    /// Returns the string with leading and trailing whitespace removed
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Checks if the string is not empty after trimming whitespace
    var isNotEmpty: Bool {
        return !self.trimmed.isEmpty
    }

    /// Validates if the string is a valid destination name
    /// A valid destination should:
    /// - Not be empty after trimming
    /// - Have at least 2 characters
    /// - Not contain only numbers
    /// - Not contain special characters except spaces, commas, periods, hyphens, and apostrophes
    var isValidDestination: Bool {
        let trimmedString = self.trimmed

        // Check if empty or too short
        guard trimmedString.count >= 2 else { return false }

        // Check if contains only numbers
        if trimmedString.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil {
            return false
        }

        // Define allowed characters: letters, spaces, and common punctuation
        let allowedCharacters = CharacterSet.letters
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: ",.'-"))

        // Check if all characters are allowed
        let stringCharacters = CharacterSet(charactersIn: trimmedString)
        return allowedCharacters.isSuperset(of: stringCharacters)
    }

    /// Truncates the string to a specified length and adds an ellipsis if truncated
    /// - Parameter length: The maximum length of the returned string (including ellipsis)
    /// - Returns: The truncated string with "..." appended if it was truncated
    func truncated(to length: Int) -> String {
        guard length > 3 else { return self }

        if self.count > length {
            let truncatedLength = length - 3
            let index = self.index(self.startIndex, offsetBy: truncatedLength)
            return String(self[..<index]) + "..."
        }

        return self
    }

    /// Capitalizes the first letter of the string
    var capitalizedFirst: String {
        guard !self.isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }

    /// Checks if the string is a valid email address
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }

    /// Checks if the string contains only letters and spaces
    var isAlphabetic: Bool {
        let allowedCharacters = CharacterSet.letters.union(.whitespaces)
        let stringCharacters = CharacterSet(charactersIn: self)
        return allowedCharacters.isSuperset(of: stringCharacters) && !self.isEmpty
    }

    /// Checks if the string contains only numbers
    var isNumeric: Bool {
        return !self.isEmpty && self.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }

    /// Returns the string with all whitespace characters removed
    var withoutWhitespace: String {
        return self.components(separatedBy: .whitespaces).joined()
    }

    /// Converts the string to a URL-safe format
    var urlEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }

    /// Removes all HTML tags from the string
    var strippingHTML: String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    /// Converts the string to kebab-case (lowercase with hyphens)
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

    /// Returns the number of words in the string
    var wordCount: Int {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        let words = components.filter { !$0.isEmpty }
        return words.count
    }

    /// Safely subscript the string with an integer index
    subscript(safe index: Int) -> Character? {
        guard index >= 0 && index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }

    /// Safely subscript the string with a range
    subscript(safe range: Range<Int>) -> String? {
        guard range.lowerBound >= 0,
              range.upperBound <= count,
              range.lowerBound < range.upperBound else { return nil }

        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
        return String(self[startIndex..<endIndex])
    }
}
