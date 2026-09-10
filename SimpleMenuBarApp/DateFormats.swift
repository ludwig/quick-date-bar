//
//  DateFormats.swift
//  SimpleMenuBarApp
//

import Foundation

/// Date-to-string rendering for every menu item.
///
/// Deliberately free of AppKit so it can be compiled and exercised with plain
/// `swiftc` (see `just test`). All calls happen on the main thread.
enum DateFormats {
    static let date = "yyyy-MM-dd"
    /// Week-based year plus ISO week, e.g. 2025-12-29 -> 2026-W01.
    static let week = "YYYY-'W'ww"
    static let filename = "yyyy_MM_dd__HH_mm_ss"
    // See https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Format_Patterns
    static let journalPrefix = "yyyy-MM-dd: EEEE... "

    /// ISO 8601 calendar so `ww` and `YYYY` follow Monday-start weeks with the
    /// four-day rule instead of the locale's Sunday-start Gregorian weeks.
    static let calendar = Calendar(identifier: .iso8601)

    private static var formatters: [String: DateFormatter] = [:]

    /// Forget cached formatters, e.g. after the system time zone changes.
    static func resetCache() {
        formatters.removeAll()
        iso8601Formatter.timeZone = .current
    }

    static func formatter(for pattern: String) -> DateFormatter {
        if let cached = formatters[pattern] {
            return cached
        }
        let formatter = DateFormatter()
        // Fixed locale so digits and separators stay ASCII regardless of the
        // system locale; these strings feed filenames, front matter, and logs.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.dateFormat = pattern
        formatters[pattern] = formatter
        return formatter
    }

    static func string(_ pattern: String, from date: Date = Date()) -> String {
        formatter(for: pattern).string(from: date)
    }

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withDashSeparatorInDate,
            .withColonSeparatorInTime,
            .withColonSeparatorInTimeZone,
        ]
        formatter.timeZone = .current
        return formatter
    }()

    /// Local time with offset, e.g. 2026-09-10T00:15:30-07:00.
    static func iso8601(from date: Date = Date()) -> String {
        iso8601Formatter.string(from: date)
    }

    static func hugoFrontMatter(from date: Date = Date()) -> String {
        """
        ---
        title: "Your title here"
        date: \(iso8601(from: date))
        tags: []
        draft: false
        ---
        """
    }
}
