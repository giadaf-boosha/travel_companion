//
//  UIColor+Extensions.swift
//  TravelCompanion
//
//  Created on 2025-12-07.
//

import UIKit

extension UIColor {

    // MARK: - App Theme Colors

    /// Primary app color - used for main actions and branding
    static let primaryColor = UIColor(hex: "#007AFF") ?? .systemBlue

    /// Secondary app color - used for secondary actions and accents
    static let secondaryColor = UIColor(hex: "#5856D6") ?? .systemPurple

    /// Accent color - used for highlights and important elements
    static let accentColor = UIColor(hex: "#FF9500") ?? .systemOrange

    // MARK: - Trip Type Colors

    /// Color for local trips (within the same city/area)
    static let localTripColor = UIColor(hex: "#34C759") ?? .systemGreen

    /// Color for day trips (single day excursions)
    static let dayTripColor = UIColor(hex: "#FF9500") ?? .systemOrange

    /// Color for multi-day trips (extended travel)
    static let multiDayTripColor = UIColor(hex: "#5856D6") ?? .systemPurple

    // MARK: - Chat Message Colors

    /// Background color for user messages in chat
    static let userMessageColor = UIColor(hex: "#007AFF") ?? .systemBlue

    /// Background color for assistant messages in chat
    static let assistantMessageColor = UIColor(hex: "#E5E5EA") ?? .systemGray5

    // MARK: - Additional Utility Colors

    /// Success color for positive actions and confirmations
    static let successColor = UIColor(hex: "#34C759") ?? .systemGreen

    /// Warning color for alerts and cautions
    static let warningColor = UIColor(hex: "#FF9500") ?? .systemOrange

    /// Error color for errors and destructive actions
    static let errorColor = UIColor(hex: "#FF3B30") ?? .systemRed

    /// Info color for informational messages
    static let infoColor = UIColor(hex: "#5856D6") ?? .systemPurple

    // MARK: - Hex Initializer

    /// Initializes a UIColor from a hexadecimal string
    /// - Parameter hex: A hex string (with or without #) like "#FF0000" or "FF0000"
    /// - Returns: A UIColor instance, or nil if the hex string is invalid
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        let r, g, b, a: CGFloat

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    /// Returns the hexadecimal string representation of the color
    /// - Parameter includeAlpha: Whether to include alpha channel in the hex string
    /// - Returns: A hex string like "#FF0000" or "#FF0000FF" (with alpha)
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

    /// Returns a lighter version of the color
    /// - Parameter percentage: The percentage to lighten (0.0 to 1.0)
    /// - Returns: A lighter UIColor
    func lighter(by percentage: CGFloat = 0.3) -> UIColor {
        return adjustBrightness(by: abs(percentage))
    }

    /// Returns a darker version of the color
    /// - Parameter percentage: The percentage to darken (0.0 to 1.0)
    /// - Returns: A darker UIColor
    func darker(by percentage: CGFloat = 0.3) -> UIColor {
        return adjustBrightness(by: -abs(percentage))
    }

    private func adjustBrightness(by percentage: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0

        if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return UIColor(hue: h, saturation: s, brightness: max(min(b + percentage, 1.0), 0.0), alpha: a)
        }

        return self
    }
}
