import SwiftUI
import WidgetKit
import CalendarCore

/// Medium widget — Left: date + today's events, Right: tomorrow's events with times.
struct NagarikPatroMediumWidget: Widget {
    let kind = "NagarikPatroMedium"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarTimelineProvider()) { entry in
            MediumWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("आजको पात्रो")
        .description("Today's events and tomorrow's schedule")
        .supportedFamilies([.systemMedium])
    }
}

struct MediumWidgetView: View {
    let entry: CalendarEntry

    private var todayTimedEvents: [SystemCalendarEvent] {
        entry.systemEvents.filter { !$0.isAllDay && $0.endDate > Date() }
    }

    private var todayAllDayEvents: [SystemCalendarEvent] {
        entry.systemEvents.filter { $0.isAllDay }
    }

    private var tomorrowTimedEvents: [SystemCalendarEvent] {
        entry.tomorrowSystemEvents.filter { !$0.isAllDay }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left column: date + today's events
            VStack(alignment: .leading, spacing: 0) {
                // Date header
                Text(weekdayLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.red)
                    .textCase(.uppercase)

                Text(NepaliDateFormatter.toNepaliNumeral(entry.bsDate.day))
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text(NepaliDateFormatter.monthNameNp(entry.bsDate.month))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)

                Spacer(minLength: 0)

                // Today's events
                if !todayTimedEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(todayTimedEvents.prefix(3)) { event in
                            systemEventRow(event, showTime: true)
                        }
                    }
                } else if !todayAllDayEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(todayAllDayEvents.prefix(2)) { event in
                            systemEventRow(event, showTime: false)
                        }
                    }
                } else if !entry.events.isEmpty {
                    nepaliEventRows(entry.events, limit: 2)
                } else {
                    Text("No events")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.trailing, 8)

            // Divider
            Rectangle()
                .fill(.quaternary)
                .frame(width: 1)
                .padding(.vertical, 4)

            // Right column: tomorrow
            VStack(alignment: .leading, spacing: 0) {
                Text("Tomorrow")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)

                if !tomorrowTimedEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(tomorrowTimedEvents.prefix(4)) { event in
                            tomorrowEventRow(event)
                        }
                    }
                } else if !entry.tomorrowSystemEvents.isEmpty {
                    // All-day events tomorrow
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(entry.tomorrowSystemEvents.prefix(3)) { event in
                            systemEventRow(event, showTime: false)
                        }
                    }
                } else {
                    Text("No events")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.leading, 8)
        }
        .padding(4)
    }

    private func systemEventRow(_ event: SystemCalendarEvent, showTime: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(red: event.colorRed, green: event.colorGreen, blue: event.colorBlue))
                .frame(width: 5, height: 5)
            VStack(alignment: .leading, spacing: 0) {
                Text(event.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                if showTime {
                    Text(event.formattedStartTime)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func tomorrowEventRow(_ event: SystemCalendarEvent) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(red: event.colorRed, green: event.colorGreen, blue: event.colorBlue))
                .frame(width: 2, height: 22)
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

    private func nepaliEventRows(_ events: [CalendarEventStore.DayEventInfo], limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(events.prefix(limit).enumerated()), id: \.offset) { _, event in
                HStack(spacing: 4) {
                    Circle()
                        .fill(event.isHoliday ? .red : .orange)
                        .frame(width: 5, height: 5)
                    if let np = event.eventsNp.first {
                        Text(np)
                            .font(.system(size: 10))
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var weekdayLabel: String {
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let idx = max(0, min(6, entry.weekday - 1))
        return names[idx]
    }
}
