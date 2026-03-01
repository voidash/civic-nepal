import SwiftUI
import WidgetKit
import CalendarCore

/// Small widget — "Up Next" style: weekday, large date, event count, event list with colored dots.
struct NagarikPatroSmallWidget: Widget {
    let kind = "NagarikPatroSmall"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarTimelineProvider()) { entry in
            SmallWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("आजको पात्रो")
        .description("Today's date and upcoming events")
        .supportedFamilies([.systemSmall])
    }
}

struct SmallWidgetView: View {
    let entry: CalendarEntry

    private var timedEvents: [SystemCalendarEvent] {
        entry.systemEvents.filter { !$0.isAllDay && $0.endDate > Date() }
    }

    private var totalEventCount: Int {
        entry.systemEvents.count + entry.events.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Weekday + month (top line)
            Text("\(weekdayShort) \u{2022} \(NepaliDateFormatter.monthNameNp(entry.bsDate.month))")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.red)
                .textCase(.uppercase)

            // Large day number
            Text(NepaliDateFormatter.toNepaliNumeral(entry.bsDate.day))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .padding(.bottom, 2)

            // Event count
            if totalEventCount > 0 {
                Text(eventCountLabel)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
            }

            Spacer(minLength: 0)

            // Up to 3 events
            if !timedEvents.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(timedEvents.prefix(3)) { event in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(red: event.colorRed, green: event.colorGreen, blue: event.colorBlue))
                                .frame(width: 5, height: 5)
                            Text(event.title)
                                .font(.system(size: 10))
                                .lineLimit(1)
                        }
                    }
                }
            } else if !entry.events.isEmpty {
                // Show Nepali events if no system events
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(entry.events.prefix(3), id: \.day) { event in
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(2)
    }

    private var weekdayShort: String {
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let idx = (entry.weekday - 1).clamped(to: 0...6)
        return names[idx]
    }

    private var eventCountLabel: String {
        if totalEventCount == 1 { return "1 event" }
        return "\(totalEventCount) events"
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
