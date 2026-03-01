import EventKit
import Foundation

/// Reads system calendar events via EventKit.
/// Works with all calendars configured in macOS System Settings (Google, iCloud, Exchange, etc.).
public final class EventKitService: @unchecked Sendable {
    public static let shared = EventKitService()

    private let store = EKEventStore()

    private init() {}

    // MARK: - Authorization

    /// Current authorization status.
    public var isAuthorized: Bool {
        if #available(macOS 14.0, *) {
            return EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            return EKEventStore.authorizationStatus(for: .event) == .authorized
        }
    }

    /// Request calendar access. Returns true if granted.
    @MainActor
    public func requestAccess() async -> Bool {
        if #available(macOS 14.0, *) {
            do {
                return try await store.requestFullAccessToEvents()
            } catch {
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                store.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Fetching Events

    /// Fetch events in a date range from all calendars.
    public func events(from startDate: Date, to endDate: Date) -> [SystemCalendarEvent] {
        guard isAuthorized else { return [] }

        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let ekEvents = store.events(matching: predicate)

        return ekEvents.map { event in
            let (r, g, b) = cgColorToRGB(event.calendar.cgColor)
            return SystemCalendarEvent(
                id: event.eventIdentifier,
                title: event.title ?? "Untitled",
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                calendarTitle: event.calendar.title,
                colorRed: r,
                colorGreen: g,
                colorBlue: b,
                location: event.location
            )
        }.sorted { $0.startDate < $1.startDate }
    }

    /// Fetch today's events (Nepal timezone).
    public func todayEvents() -> [SystemCalendarEvent] {
        let (start, end) = dayBounds(daysFromNow: 0)
        return events(from: start, to: end)
    }

    /// Fetch tomorrow's events (Nepal timezone).
    public func tomorrowEvents() -> [SystemCalendarEvent] {
        let (start, end) = dayBounds(daysFromNow: 1)
        return events(from: start, to: end)
    }

    /// Fetch upcoming timed events within the next N hours.
    public func upcomingEvents(hours: Int = 24) -> [SystemCalendarEvent] {
        guard isAuthorized else { return [] }
        let now = Date()
        let end = now.addingTimeInterval(TimeInterval(hours * 3600))
        return events(from: now, to: end).filter { !$0.isAllDay }
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

    private func cgColorToRGB(_ cgColor: CGColor?) -> (Double, Double, Double) {
        guard let cgColor = cgColor,
              let srgb = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = cgColor.converted(to: srgb, intent: .defaultIntent, options: nil),
              let c = converted.components, c.count >= 3 else {
            return (0.26, 0.52, 0.96) // Default blue
        }
        return (Double(c[0]), Double(c[1]), Double(c[2]))
    }
}
