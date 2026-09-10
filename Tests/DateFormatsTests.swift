// Boundary-date checks for DateFormats, compiled with plain swiftc.
// Run with `just test`.

import Foundation

@main
struct DateFormatsTests {
    static var failures = 0

    static func expect(_ actual: String, _ expected: String, _ label: String) {
        if actual == expected {
            print("  ok   \(label): \(actual)")
        } else {
            failures += 1
            print("  FAIL \(label): got \(actual), expected \(expected)")
        }
    }

    static func localDate(_ year: Int, _ month: Int, _ day: Int,
                          _ hour: Int = 12, _ minute: Int = 0, _ second: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute, second: second
        ))!
    }

    static func main() {
        print("ISO 8601 weeks")
        let weeks: [(Int, Int, Int, String)] = [
            (2025, 12, 28, "2025-W52"), // Sunday, still last week of 2025
            (2025, 12, 29, "2026-W01"), // Monday, first ISO week of 2026
            (2026, 1, 1, "2026-W01"),
            (2026, 1, 4, "2026-W01"),   // Sunday closes week 1
            (2026, 1, 5, "2026-W02"),
            (2026, 9, 13, "2026-W37"),  // Sunday
            (2026, 9, 14, "2026-W38"),  // Monday
            (2027, 1, 1, "2026-W53"),   // 2026 has 53 ISO weeks
            (2027, 1, 3, "2026-W53"),
            (2027, 1, 4, "2027-W01"),
        ]
        for (y, m, d, expected) in weeks {
            expect(DateFormats.string(DateFormats.week, from: localDate(y, m, d)), expected, "\(y)-\(m)-\(d)")
        }

        print("Fixed patterns")
        let sample = localDate(2026, 9, 10, 14, 5, 9)
        expect(DateFormats.string(DateFormats.date, from: sample), "2026-09-10", "date")
        expect(DateFormats.string(DateFormats.filename, from: sample), "2026_09_10__14_05_09", "filename")
        let journal = DateFormats.string(DateFormats.journalPrefix, from: sample)
        expect(String(journal.prefix(12)), "2026-09-10: ", "journal prefix start")
        expect(String(journal.suffix(4)), "... ", "journal prefix end")

        print("ISO 8601 timestamp")
        let iso = DateFormats.iso8601(from: sample)
        let pattern = #"^2026-09-10T14:05:09([+-]\d{2}:\d{2}|Z)$"#
        expect(iso.range(of: pattern, options: .regularExpression) != nil ? "matches" : iso, "matches", "iso8601 shape")

        print("Hugo front matter")
        let hugo = DateFormats.hugoFrontMatter(from: sample)
        expect(hugo.contains("date: \(iso)") ? "contains iso date" : hugo, "contains iso date", "hugo date line")
        expect(hugo.hasPrefix("---\n") && hugo.hasSuffix("\n---") ? "fenced" : hugo, "fenced", "hugo fences")

        print("Formatter cache")
        expect(DateFormats.formatter(for: DateFormats.date) === DateFormats.formatter(for: DateFormats.date) ? "same" : "different", "same", "cached instance")
        DateFormats.resetCache()
        expect(DateFormats.string(DateFormats.date, from: sample), "2026-09-10", "works after reset")

        if failures > 0 {
            print("\n\(failures) failure(s)")
            exit(1)
        }
        print("\nAll checks passed")
    }
}
