import Foundation

/// Formats BS dates with Nepali numerals and localized strings.
public enum NepaliDateFormatter {
    private static let cal = BsCalendarData.shared
    private static let nepaliDigits: [Character] = ["०", "१", "२", "३", "४", "५", "६", "७", "८", "९"]

    /// Convert an integer to Nepali (Devanagari) numeral string.
    public static func toNepaliNumeral(_ number: Int) -> String {
        String(number).map { char in
            if let digit = char.wholeNumberValue, digit >= 0 && digit <= 9 {
                return String(nepaliDigits[digit])
            }
            return String(char)
        }.joined()
    }

    /// Month name in Nepali for a 1-based month index.
    public static func monthNameNp(_ month: Int) -> String {
        guard month >= 1, month <= 12 else { return "" }
        return cal.monthNamesNp[month - 1]
    }

    /// Month name in English for a 1-based month index.
    public static func monthNameEn(_ month: Int) -> String {
        guard month >= 1, month <= 12 else { return "" }
        return cal.monthNamesEn[month - 1]
    }

    /// Weekday name in Nepali (1=Sunday, 7=Saturday).
    public static func weekdayNameNp(_ weekday: Int) -> String {
        guard weekday >= 1, weekday <= 7 else { return "" }
        return cal.weekdayNamesNp[weekday - 1]
    }

    /// Weekday name in English (1=Sunday, 7=Saturday).
    public static func weekdayNameEn(_ weekday: Int) -> String {
        guard weekday >= 1, weekday <= 7 else { return "" }
        return cal.weekdayNamesEn[weekday - 1]
    }

    /// Short weekday name in Nepali (1=Sunday, 7=Saturday).
    public static func weekdayNameNpShort(_ weekday: Int) -> String {
        guard weekday >= 1, weekday <= 7 else { return "" }
        return cal.weekdayNamesNpShort[weekday - 1]
    }

    /// Format: "१५ बैशाख २०८१"
    public static func formatNp(_ date: BsDate) -> String {
        "\(toNepaliNumeral(date.day)) \(monthNameNp(date.month)) \(toNepaliNumeral(date.year))"
    }

    /// Format: "15 Baisakh 2081"
    public static func formatEn(_ date: BsDate) -> String {
        "\(date.day) \(monthNameEn(date.month)) \(date.year)"
    }

    /// Format the AD equivalent: "Apr 13, 2024"
    public static func formatAdDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.timeZone = BsDateConverter.nepalTimeZone
        return formatter.string(from: date)
    }

    /// Format for the menu bar title in Nepali: "फागुन ७"
    public static func menuBarTitleNp(_ date: BsDate) -> String {
        "\(monthNameNp(date.month)) \(toNepaliNumeral(date.day))"
    }

    /// Format for the menu bar title in English: "Falgun 7"
    public static func menuBarTitleEn(_ date: BsDate) -> String {
        "\(monthNameEn(date.month)) \(date.day)"
    }
}
