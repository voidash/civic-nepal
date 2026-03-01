import Foundation

/// Reads Google Calendar events from a shared JSON cache written by the Flutter app.
/// Cache path: ~/Library/Application Support/NagarikPatro/google_calendar_cache.json
public final class GoogleCalendarCache: @unchecked Sendable {
    public static let shared = GoogleCalendarCache()

    /// Possible cache file locations — the Flutter app may be sandboxed or not.
    private static let possiblePaths: [String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            // Sandboxed Flutter app (most common)
            "\(home)/Library/Containers/com.nepal.constitution.nepalCivic/Data/Library/Application Support/NagarikPatro/google_calendar_cache.json",
            // Non-sandboxed / direct path
            "\(home)/Library/Application Support/NagarikPatro/google_calendar_cache.json",
        ]
    }()

    /// Resolved cache path (first existing file, or first path as default).
    private var cachePath: String {
        Self.possiblePaths.first { FileManager.default.fileExists(atPath: $0) }
            ?? Self.possiblePaths[0]
    }

    private init() {}

    // MARK: - Cache reading

    /// Read cached events. Returns empty if no cache or parse failure.
    public func readCache() -> CachedGoogleData? {
        guard FileManager.default.fileExists(atPath: cachePath) else { return nil }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: cachePath))
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let json = json else { return nil }

            let lastSynced = (json["lastSynced"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) }
            let userEmail = json["userEmail"] as? String
            let rawEvents = json["events"] as? [[String: Any]] ?? []

            let events = rawEvents.compactMap { parseEvent($0) }

            return CachedGoogleData(
                lastSynced: lastSynced,
                userEmail: userEmail,
                events: events
            )
        } catch {
            return nil
        }
    }

    /// Today's Google Calendar events (Nepal timezone).
    public func todayEvents() -> [SystemCalendarEvent] {
        guard let cache = readCache() else { return [] }
        let (start, end) = dayBounds(daysFromNow: 0)
        return cache.events.filter { $0.startDate >= start && $0.startDate < end }
    }

    /// Tomorrow's Google Calendar events (Nepal timezone).
    public func tomorrowEvents() -> [SystemCalendarEvent] {
        guard let cache = readCache() else { return [] }
        let (start, end) = dayBounds(daysFromNow: 1)
        return cache.events.filter { $0.startDate >= start && $0.startDate < end }
    }

    /// Upcoming timed events from now.
    public func upcomingEvents(hours: Int = 24) -> [SystemCalendarEvent] {
        guard let cache = readCache() else { return [] }
        let now = Date()
        let end = now.addingTimeInterval(TimeInterval(hours * 3600))
        return cache.events.filter { !$0.isAllDay && $0.endDate > now && $0.startDate < end }
    }

    /// Whether the cache exists and has data.
    public var hasCachedData: Bool {
        readCache() != nil
    }

    /// User email from the cache (for display).
    public var userEmail: String? {
        readCache()?.userEmail
    }

    // MARK: - Helpers

    private func dayBounds(daysFromNow offset: Int) -> (Date, Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = BsDateConverter.nepalTimeZone
        let todayStart = calendar.startOfDay(for: Date())
        let dayStart = calendar.date(byAdding: .day, value: offset, to: todayStart)!
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return (dayStart, dayEnd)
    }

    private func parseEvent(_ json: [String: Any]) -> SystemCalendarEvent? {
        guard let id = json["id"] as? String,
              let title = json["title"] as? String,
              let startStr = json["startTime"] as? String,
              let startDate = ISO8601DateFormatter().date(from: startStr) else {
            return nil
        }

        let endDate: Date
        if let endStr = json["endTime"] as? String,
           let parsed = ISO8601DateFormatter().date(from: endStr) {
            endDate = parsed
        } else {
            endDate = startDate.addingTimeInterval(3600) // Default 1 hour
        }

        let isAllDay = json["isAllDay"] as? Bool ?? false
        let calendarId = json["calendarId"] as? String ?? "primary"
        let colorHex = json["colorHex"] as? String ?? "#4285F4"
        let location = json["location"] as? String

        let (r, g, b) = hexToRGB(colorHex)

        return SystemCalendarEvent(
            id: id,
            title: title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            calendarTitle: calendarId,
            colorRed: r,
            colorGreen: g,
            colorBlue: b,
            location: location
        )
    }

    private func hexToRGB(_ hex: String) -> (Double, Double, Double) {
        var hexStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexStr.hasPrefix("#") { hexStr.removeFirst() }
        guard hexStr.count == 6, let val = UInt64(hexStr, radix: 16) else {
            return (0.26, 0.52, 0.96) // Default blue
        }
        let r = Double((val >> 16) & 0xFF) / 255.0
        let g = Double((val >> 8) & 0xFF) / 255.0
        let b = Double(val & 0xFF) / 255.0
        return (r, g, b)
    }
}

/// Parsed cache data.
public struct CachedGoogleData: Sendable {
    public let lastSynced: Date?
    public let userEmail: String?
    public let events: [SystemCalendarEvent]
}
