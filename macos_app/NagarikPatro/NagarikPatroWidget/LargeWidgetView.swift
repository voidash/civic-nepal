import SwiftUI
import WidgetKit
import CalendarCore

/// Large widget — Left: date + hourly timeline with event blocks + now indicator,
/// Right: tomorrow's events.
struct NagarikPatroLargeWidget: Widget {
    let kind = "NagarikPatroLarge"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarTimelineProvider()) { entry in
            LargeWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("नेपाली पात्रो")
        .description("Timeline view with upcoming events")
        .supportedFamilies([.systemLarge])
    }
}

struct LargeWidgetView: View {
    let entry: CalendarEntry

    /// Hours to display in the timeline (6-hour window centered on now or next event).
    private var timelineHours: [Int] {
        let now = currentNepalHour
        // Show 7 hours starting 1 hour before now
        let startHour = max(0, min(18, now - 1))
        return Array(startHour..<min(24, startHour + 7))
    }

    private var currentNepalHour: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = BsDateConverter.nepalTimeZone
        return cal.component(.hour, from: Date())
    }

    private var currentNepalMinute: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = BsDateConverter.nepalTimeZone
        return cal.component(.minute, from: Date())
    }

    private var todayTimedEvents: [SystemCalendarEvent] {
        entry.systemEvents.filter { !$0.isAllDay }
    }

    private var tomorrowTimedEvents: [SystemCalendarEvent] {
        entry.tomorrowSystemEvents.filter { !$0.isAllDay }
    }

    private var tomorrowAllDay: [SystemCalendarEvent] {
        entry.tomorrowSystemEvents.filter { $0.isAllDay }
    }

    // Tomorrow's BS date
    private var tomorrowBs: BsDate {
        let tomorrowAd = Calendar.current.date(byAdding: .day, value: 1, to: entry.date)!
        return BsDateConverter.adToBs(tomorrowAd)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: date header + timeline
            VStack(alignment: .leading, spacing: 0) {
                dateHeader
                    .padding(.bottom, 6)

                timelineView
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.trailing, 6)

            // Vertical divider
            Rectangle()
                .fill(.quaternary)
                .frame(width: 1)
                .padding(.vertical, 4)

            // Right: tomorrow's events
            VStack(alignment: .leading, spacing: 0) {
                tomorrowSection
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.leading, 8)
        }
        .padding(6)
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack(spacing: 8) {
            // Large day box
            Text(NepaliDateFormatter.toNepaliNumeral(entry.bsDate.day))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 6).fill(.blue))

            VStack(alignment: .leading, spacing: 1) {
                Text(weekdayLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.red)
                    .textCase(.uppercase)
                Text("\(NepaliDateFormatter.monthNameNp(entry.bsDate.month)) \(NepaliDateFormatter.toNepaliNumeral(entry.bsDate.year))")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Timeline

    private let hourHeight: CGFloat = 26

    private var timelineView: some View {
        let hours = timelineHours
        let totalHeight = CGFloat(hours.count) * hourHeight

        return ZStack(alignment: .topLeading) {
            // Hour grid lines + labels
            VStack(spacing: 0) {
                ForEach(hours, id: \.self) { hour in
                    HStack(spacing: 4) {
                        Text(hourLabel(hour))
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .trailing)
                        Rectangle()
                            .fill(.quaternary)
                            .frame(height: 0.5)
                    }
                    .frame(height: hourHeight)
                }
            }

            // Event blocks
            ForEach(todayTimedEvents) { event in
                eventBlock(event, hours: hours)
            }

            // Current time indicator
            if let firstHour = hours.first, let lastHour = hours.last {
                let nowMinutes = currentNepalHour * 60 + currentNepalMinute
                let rangeStart = firstHour * 60
                let rangeEnd = (lastHour + 1) * 60
                if nowMinutes >= rangeStart && nowMinutes <= rangeEnd {
                    let offset = CGFloat(nowMinutes - rangeStart) / CGFloat(rangeEnd - rangeStart) * totalHeight
                    HStack(spacing: 0) {
                        Circle()
                            .fill(.red)
                            .frame(width: 6, height: 6)
                        Rectangle()
                            .fill(.red)
                            .frame(height: 1)
                    }
                    .offset(x: 26, y: offset - 3)
                }
            }
        }
        .frame(height: totalHeight)
        .clipped()
    }

    private func eventBlock(_ event: SystemCalendarEvent, hours: [Int]) -> some View {
        let layout = eventBlockLayout(event, hours: hours)
        let color = Color(red: event.colorRed, green: event.colorGreen, blue: event.colorBlue)

        return Group {
            if layout.visible {
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.15))
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color)
                                .frame(width: 2)
                        }
                        .overlay(alignment: .topLeading) {
                            Text(event.title)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(color)
                                .lineLimit(1)
                                .padding(.leading, 5)
                                .padding(.top, 2)
                        }
                }
                .frame(height: max(layout.height, 14))
                .padding(.leading, 34)
                .padding(.trailing, 2)
                .offset(y: layout.topOffset)
            }
        }
    }

    private struct EventBlockLayout {
        let topOffset: CGFloat
        let height: CGFloat
        let visible: Bool
    }

    private func eventBlockLayout(_ event: SystemCalendarEvent, hours: [Int]) -> EventBlockLayout {
        let firstHour = hours.first ?? 0
        let totalMinutes = hours.count * 60

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = BsDateConverter.nepalTimeZone

        let startComps = cal.dateComponents([.hour, .minute], from: event.startDate)
        let endComps = cal.dateComponents([.hour, .minute], from: event.endDate)

        let startMin = (startComps.hour ?? 0) * 60 + (startComps.minute ?? 0)
        let endMin = (endComps.hour ?? 0) * 60 + (endComps.minute ?? 0)
        let rangeStart = firstHour * 60

        let clampedStart = max(startMin - rangeStart, 0)
        let clampedEnd = min(endMin - rangeStart, totalMinutes)
        let duration = max(clampedEnd - clampedStart, 15)

        let totalHeight = CGFloat(hours.count) * hourHeight
        let topOffset = CGFloat(clampedStart) / CGFloat(totalMinutes) * totalHeight
        let blockHeight = CGFloat(duration) / CGFloat(totalMinutes) * totalHeight

        return EventBlockLayout(
            topOffset: topOffset,
            height: blockHeight,
            visible: clampedEnd > 0 && clampedStart < totalMinutes
        )
    }

    // MARK: - Tomorrow Section

    private var tomorrowSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tomorrow header
            HStack(spacing: 4) {
                Text("Tomorrow")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(NepaliDateFormatter.toNepaliNumeral(tomorrowBs.day))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)

            if !tomorrowAllDay.isEmpty {
                ForEach(tomorrowAllDay.prefix(2)) { event in
                    allDayEventRow(event)
                        .padding(.bottom, 4)
                }
            }

            if !tomorrowTimedEvents.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(tomorrowTimedEvents.prefix(6)) { event in
                        tomorrowEventRow(event)
                    }
                }
            } else if tomorrowAllDay.isEmpty {
                // No events at all — show Nepali events for tomorrow if available
                let tBs = tomorrowBs
                let nepaliEvents = CalendarEventStore.shared.eventsForMonth(year: tBs.year, month: tBs.month)
                    .filter { $0.day == tBs.day }
                if !nepaliEvents.isEmpty {
                    ForEach(Array(nepaliEvents.prefix(4).enumerated()), id: \.offset) { _, event in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(event.isHoliday ? .red : .orange)
                                .frame(width: 4, height: 4)
                            if let np = event.eventsNp.first {
                                Text(np)
                                    .font(.system(size: 9))
                                    .lineLimit(1)
                            }
                        }
                    }
                } else {
                    Text("No events")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func tomorrowEventRow(_ event: SystemCalendarEvent) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(red: event.colorRed, green: event.colorGreen, blue: event.colorBlue))
                .frame(width: 2, height: 24)
            VStack(alignment: .leading, spacing: 0) {
                Text(event.formattedStartTime)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                Text(event.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
            }
        }
    }

    private func allDayEventRow(_ event: SystemCalendarEvent) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(red: event.colorRed, green: event.colorGreen, blue: event.colorBlue))
                .frame(width: 5, height: 5)
            Text(event.title)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
            Text("All day")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func hourLabel(_ hour: Int) -> String {
        if hour == 0 { return "12a" }
        if hour < 12 { return "\(hour)a" }
        if hour == 12 { return "12p" }
        return "\(hour - 12)p"
    }

    private var weekdayLabel: String {
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let idx = max(0, min(6, entry.weekday - 1))
        return names[idx]
    }
}
