import Foundation

/// Loads and queries event and auspicious day data from JSON files.
public final class CalendarEventStore: Sendable {
    public static let shared = CalendarEventStore()

    /// Key: "YYYY-MM" (e.g., "2081-01"). Value: array of day event info.
    private let events: [String: [DayEventInfo]]
    /// Key: "YYYY-MM". Value: auspicious day info.
    private let auspicious: [String: AuspiciousMonth]

    private init() {
        self.events = Self.loadEvents()
        self.auspicious = Self.loadAuspicious()
    }

    // MARK: - Public API

    /// Get events for a specific day. Returns empty array if no data.
    public func events(year: Int, month: Int, day: Int) -> DayEventInfo? {
        let key = Self.monthKey(year: year, month: month)
        return events[key]?.first(where: { $0.day == day })
    }

    /// Get all events for a month.
    public func eventsForMonth(year: Int, month: Int) -> [DayEventInfo] {
        let key = Self.monthKey(year: year, month: month)
        return events[key] ?? []
    }

    /// Get auspicious data for a month.
    public func auspiciousForMonth(year: Int, month: Int) -> AuspiciousMonth? {
        let key = Self.monthKey(year: year, month: month)
        return auspicious[key]
    }

    /// Check if a specific day is auspicious for weddings.
    public func isAuspiciousWedding(year: Int, month: Int, day: Int) -> Bool {
        auspiciousForMonth(year: year, month: month)?.bibahaLagan.contains(day) ?? false
    }

    /// Check if a specific day is auspicious for bratabandha.
    public func isAuspiciousBratabandha(year: Int, month: Int, day: Int) -> Bool {
        auspiciousForMonth(year: year, month: month)?.bratabandha.contains(day) ?? false
    }

    /// Check if a specific day is auspicious for pasni.
    public func isAuspiciousPasni(year: Int, month: Int, day: Int) -> Bool {
        auspiciousForMonth(year: year, month: month)?.pasni.contains(day) ?? false
    }

    // MARK: - Models

    public struct DayEventInfo: Sendable {
        public let day: Int
        public let events: [String]
        public let eventsNp: [String]
        public let isHoliday: Bool
    }

    public struct AuspiciousMonth: Sendable {
        public let year: Int
        public let month: Int
        public let bibahaLagan: [Int]
        public let bratabandha: [Int]
        public let pasni: [Int]
    }

    // MARK: - Loading

    private static func monthKey(year: Int, month: Int) -> String {
        String(format: "%d-%02d", year, month)
    }

    private static func loadEvents() -> [String: [DayEventInfo]] {
        guard let url = Bundle.module.url(forResource: "nepali_calendar_events", withExtension: "json") else {
            print("WARNING: nepali_calendar_events.json not found")
            return [:]
        }
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            var result: [String: [DayEventInfo]] = [:]
            result.reserveCapacity(json.count)

            for (key, value) in json {
                guard let monthData = value as? [String: Any],
                      let days = monthData["days"] as? [[String: Any]] else {
                    continue
                }
                result[key] = days.compactMap { dayJson -> DayEventInfo? in
                    guard let day = dayJson["day"] as? Int else { return nil }
                    return DayEventInfo(
                        day: day,
                        events: dayJson["events"] as? [String] ?? [],
                        eventsNp: dayJson["events_np"] as? [String] ?? [],
                        isHoliday: dayJson["is_holiday"] as? Bool ?? false
                    )
                }
            }
            return result
        } catch {
            print("ERROR: Failed to load events: \(error)")
            return [:]
        }
    }

    private static func loadAuspicious() -> [String: AuspiciousMonth] {
        guard let url = Bundle.module.url(forResource: "nepali_calendar_auspicious", withExtension: "json") else {
            print("WARNING: nepali_calendar_auspicious.json not found")
            return [:]
        }
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            var result: [String: AuspiciousMonth] = [:]
            result.reserveCapacity(json.count)

            for (key, value) in json {
                guard let monthData = value as? [String: Any],
                      let year = monthData["year"] as? Int,
                      let month = monthData["month"] as? Int else {
                    continue
                }
                result[key] = AuspiciousMonth(
                    year: year,
                    month: month,
                    bibahaLagan: monthData["bibaha_lagan"] as? [Int] ?? [],
                    bratabandha: monthData["bratabandha"] as? [Int] ?? [],
                    pasni: monthData["pasni"] as? [Int] ?? []
                )
            }
            return result
        } catch {
            print("ERROR: Failed to load auspicious data: \(error)")
            return [:]
        }
    }
}
