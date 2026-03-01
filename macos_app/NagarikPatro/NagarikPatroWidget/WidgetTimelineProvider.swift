import WidgetKit
import CalendarCore

struct CalendarEntry: TimelineEntry {
    let date: Date
    let bsDate: BsDate
    let weekday: Int  // 1=Sun, 7=Sat
    let events: [CalendarEventStore.DayEventInfo]
    /// Google Calendar events for today (from Flutter app's cache)
    let systemEvents: [SystemCalendarEvent]
    /// Google Calendar events for tomorrow
    let tomorrowSystemEvents: [SystemCalendarEvent]
}

struct CalendarTimelineProvider: TimelineProvider {
    private let cache = GoogleCalendarCache.shared

    func placeholder(in context: Context) -> CalendarEntry {
        let today = BsDateConverter.today()
        return CalendarEntry(
            date: Date(),
            bsDate: today,
            weekday: BsDateConverter.weekday(for: today),
            events: [],
            systemEvents: [],
            tomorrowSystemEvents: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let entry = makeEntry()

        // Refresh at next Nepal midnight (UTC+5:45) or in 15 minutes for event updates
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = BsDateConverter.nepalTimeZone
        let todayStart = calendar.startOfDay(for: Date())
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? Date().addingTimeInterval(86400)

        // If we have cached events, refresh more frequently (every 15 min) to pick up cache updates
        let refreshDate: Date
        if cache.hasCachedData {
            let fifteenMin = Date().addingTimeInterval(15 * 60)
            refreshDate = min(fifteenMin, nextMidnight)
        } else {
            refreshDate = nextMidnight
        }

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func makeEntry() -> CalendarEntry {
        let today = BsDateConverter.today()
        let nepaliEvents = CalendarEventStore.shared.eventsForMonth(year: today.year, month: today.month)
        let todayNepaliEvents = nepaliEvents.filter { $0.day == today.day }

        // Read Google Calendar events from Flutter app's cache
        let sysToday = cache.todayEvents()
        let sysTomorrow = cache.tomorrowEvents()

        return CalendarEntry(
            date: Date(),
            bsDate: today,
            weekday: BsDateConverter.weekday(for: today),
            events: todayNepaliEvents,
            systemEvents: sysToday,
            tomorrowSystemEvents: sysTomorrow
        )
    }
}
