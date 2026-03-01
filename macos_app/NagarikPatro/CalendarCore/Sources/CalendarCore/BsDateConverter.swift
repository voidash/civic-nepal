import Foundation

/// Converts between AD (Gregorian) and BS (Bikram Sambat) calendar systems.
///
/// Ported from nepali_utils 3.0.8 `nepali_date_time.dart`.
/// Key difference from Dart: NO +1 day hack. Swift doesn't have the Dart VM
/// timezone bug with `DateTime(1986,1,2).difference(DateTime(1986,1,1))`.
/// We work in UTC throughout using Nepal's explicit TZ offset (UTC+5:45).
public enum BsDateConverter {
    private static let cal = BsCalendarData.shared

    /// Nepal timezone: UTC+5:45 = 20700 seconds
    public static let nepalTimeZone = TimeZone(secondsFromGMT: 20700)!

    // MARK: - AD → BS

    /// Convert a Gregorian (AD) date to BS.
    /// The input Date is interpreted in Nepal time (UTC+5:45).
    public static func adToBs(_ adDate: Date) -> BsDate {
        // Convert to Nepal time components
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = nepalTimeZone
        let comps = calendar.dateComponents([.year, .month, .day], from: adDate)
        return adToBs(year: comps.year!, month: comps.month!, day: comps.day!)
    }

    /// Convert AD year/month/day to BS date.
    /// Reference: AD 1913-04-13 = BS 1970/01/01
    public static func adToBs(year adYear: Int, month adMonth: Int, day adDay: Int) -> BsDate {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let adDate = calendar.date(from: DateComponents(year: adYear, month: adMonth, day: adDay))!
        let refDate = calendar.date(from: DateComponents(year: 1913, month: 4, day: 13))!

        var difference = calendar.dateComponents([.day], from: refDate, to: adDate).day!

        var bsYear = 1970
        var bsMonth = 1
        var bsDay = 1

        // Advance years
        var daysInYear = cal.daysInYear(year: bsYear) ?? 365
        while difference >= daysInYear {
            difference -= daysInYear
            bsYear += 1
            daysInYear = cal.daysInYear(year: bsYear) ?? 365
        }

        // Advance months
        var daysInMonth = cal.daysInMonth(year: bsYear, month: bsMonth) ?? 30
        while difference >= daysInMonth {
            difference -= daysInMonth
            bsMonth += 1
            daysInMonth = cal.daysInMonth(year: bsYear, month: bsMonth) ?? 30
        }

        bsDay += difference

        return BsDate(year: bsYear, month: bsMonth, day: bsDay)
    }

    // MARK: - BS → AD

    /// Convert a BS date to Gregorian (AD).
    /// Reference: BS 1969/09/18 = AD 1913/01/01
    /// Ported from `NepaliDateTime.toDateTime()` in nepali_date_time.dart:300-340.
    public static func bsToAd(_ bsDate: BsDate) -> Date {
        let refBs = BsDate(year: 1969, month: 9, day: 18)

        let totalTarget = countTotalNepaliDays(year: bsDate.year, month: bsDate.month, day: bsDate.day)
        let totalRef = countTotalNepaliDays(year: refBs.year, month: refBs.month, day: refBs.day)
        var difference = abs(totalTarget - totalRef)

        var adYear = 1913
        var adMonth = 1
        var adDay = 1

        // Advance years
        while difference >= (isLeapYear(adYear) ? 366 : 365) {
            difference -= isLeapYear(adYear) ? 366 : 365
            adYear += 1
        }

        // Advance months
        let monthDays = isLeapYear(adYear) ? englishLeapMonths : englishMonths
        var i = 0
        while i < monthDays.count && difference >= monthDays[i] {
            adMonth += 1
            difference -= monthDays[i]
            i += 1
        }

        adDay += difference

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: adYear, month: adMonth, day: adDay))!
    }

    // MARK: - Today

    /// Get today's date in BS (based on current Nepal time).
    public static func today() -> BsDate {
        adToBs(Date())
    }

    /// Get the weekday (1=Sunday, 7=Saturday) for a BS date.
    public static func weekday(for bsDate: BsDate) -> Int {
        let adDate = bsToAd(bsDate)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = nepalTimeZone
        return calendar.component(.weekday, from: adDate)  // 1=Sun, 7=Sat
    }

    /// Get the weekday for the first day of a BS month.
    public static func firstWeekday(year: Int, month: Int) -> Int {
        weekday(for: BsDate(year: year, month: month, day: 1))
    }

    // MARK: - Helpers

    /// Total number of BS days from BS 1969/01/01 to the given date.
    private static func countTotalNepaliDays(year: Int, month: Int, day: Int) -> Int {
        guard year >= 1969 else { return 0 }
        var total = day - 1

        // Add days for months before current month in current year
        if let yearData = cal.years[year] {
            for m in 1..<month {
                total += yearData[m]
            }
        }

        // Add days for all years before current year
        for y in 1969..<year {
            total += cal.daysInYear(year: y) ?? 365
        }

        return total
    }

    private static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0))
    }

    private static let englishMonths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    private static let englishLeapMonths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
}
