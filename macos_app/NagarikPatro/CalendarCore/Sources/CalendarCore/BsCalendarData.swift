import Foundation

/// Loads and provides access to the BS calendar month-length tables (282 years).
/// Thread-safe singleton. Shared between main app and WidgetKit extension.
public final class BsCalendarData: Sendable {
    public static let shared = BsCalendarData()

    public let meta: Meta
    public let monthNamesEn: [String]
    public let monthNamesNp: [String]
    public let weekdayNamesEn: [String]
    public let weekdayNamesNp: [String]
    public let weekdayNamesNpShort: [String]
    /// Key: BS year (Int). Value: [totalDays, month1..month12] — 13 elements.
    public let years: [Int: [Int]]

    public struct Meta: Sendable {
        public let source: String
        public let referenceAd: String  // "1913-04-13"
        public let referenceBsYear: Int
        public let referenceBsMonth: Int
        public let referenceBsDay: Int
        public let yearMin: Int
        public let yearMax: Int
        public let nepalTzOffsetSeconds: Int
    }

    private init() {
        guard let url = Bundle.module.url(forResource: "bs_calendar_data", withExtension: "json") else {
            fatalError("bs_calendar_data.json not found in CalendarCore bundle")
        }
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

            let metaJson = json["meta"] as! [String: Any]
            let refBs = metaJson["reference_bs"] as! [String: Any]
            let yearRange = metaJson["year_range"] as! [Int]

            self.meta = Meta(
                source: metaJson["source"] as! String,
                referenceAd: metaJson["reference_ad"] as! String,
                referenceBsYear: refBs["year"] as! Int,
                referenceBsMonth: refBs["month"] as! Int,
                referenceBsDay: refBs["day"] as! Int,
                yearMin: yearRange[0],
                yearMax: yearRange[1],
                nepalTzOffsetSeconds: metaJson["nepal_tz_offset_seconds"] as! Int
            )

            self.monthNamesEn = json["month_names_en"] as! [String]
            self.monthNamesNp = json["month_names_np"] as! [String]
            self.weekdayNamesEn = json["weekday_names_en"] as! [String]
            self.weekdayNamesNp = json["weekday_names_np"] as! [String]
            self.weekdayNamesNpShort = json["weekday_names_np_short"] as! [String]

            let yearsJson = json["years"] as! [String: [Int]]
            var parsed: [Int: [Int]] = [:]
            parsed.reserveCapacity(yearsJson.count)
            for (key, value) in yearsJson {
                guard let year = Int(key) else { continue }
                parsed[year] = value
            }
            self.years = parsed
        } catch {
            fatalError("Failed to load bs_calendar_data.json: \(error)")
        }
    }

    /// Days in a specific month of a BS year. Returns nil if year/month is out of range.
    public func daysInMonth(year: Int, month: Int) -> Int? {
        guard month >= 1, month <= 12,
              let yearData = years[year],
              yearData.count == 13 else {
            return nil
        }
        return yearData[month]
    }

    /// Total days in a BS year. Returns nil if year is out of range.
    public func daysInYear(year: Int) -> Int? {
        years[year]?.first
    }

    /// Whether a BS year is in the supported range.
    public func isYearSupported(_ year: Int) -> Bool {
        years[year] != nil
    }
}
