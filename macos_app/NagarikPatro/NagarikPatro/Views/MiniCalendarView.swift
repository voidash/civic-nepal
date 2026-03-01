import SwiftUI
import CalendarCore

/// 7-column calendar grid for a BS month.
struct MiniCalendarView: View {
    let year: Int
    let month: Int
    let today: BsDate
    @Binding var selectedDay: Int?

    private let cal = BsCalendarData.shared
    private let eventStore = CalendarEventStore.shared

    private var daysInMonth: Int {
        cal.daysInMonth(year: year, month: month) ?? 30
    }

    /// Weekday of first day (1=Sun, 7=Sat)
    private var firstWeekday: Int {
        BsDateConverter.firstWeekday(year: year, month: month)
    }

    /// Number of blank cells before day 1 (Sun=0 offset since grid starts with Sun)
    private var startOffset: Int {
        firstWeekday - 1
    }

    private var totalCells: Int {
        startOffset + daysInMonth
    }

    private var rows: Int {
        (totalCells + 6) / 7
    }

    private var monthEvents: [Int: CalendarEventStore.DayEventInfo] {
        let events = eventStore.eventsForMonth(year: year, month: month)
        return Dictionary(uniqueKeysWithValues: events.map { ($0.day, $0) })
    }

    private var auspiciousMonth: CalendarEventStore.AuspiciousMonth? {
        eventStore.auspiciousForMonth(year: year, month: month)
    }

    var body: some View {
        VStack(spacing: 0) {
            weekdayHeaders
            calendarGrid
        }
    }

    // MARK: - Weekday Headers

    private var weekdayHeaders: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                VStack(spacing: 1) {
                    Text(cal.weekdayNamesNpShort[index])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(index == 6 ? .red : .primary)
                    Text(["S", "M", "T", "W", "T", "F", "S"][index])
                        .font(.system(size: 9))
                        .foregroundStyle(index == 6 ? .red.opacity(0.7) : .secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let events = monthEvents
        let ausp = auspiciousMonth

        return VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        let dayNumber = index - startOffset + 1

                        if dayNumber >= 1 && dayNumber <= daysInMonth {
                            let isToday = today.year == year && today.month == month && today.day == dayNumber
                            let isSaturday = col == 6
                            let dayEvent = events[dayNumber]
                            let isHoliday = dayEvent?.isHoliday ?? false
                            let hasEvents = dayEvent != nil && !dayEvent!.events.isEmpty
                            let hasAuspicious = ausp?.bibahaLagan.contains(dayNumber) == true
                                || ausp?.bratabandha.contains(dayNumber) == true
                                || ausp?.pasni.contains(dayNumber) == true

                            DayCellView(
                                day: dayNumber,
                                isToday: isToday,
                                isSaturday: isSaturday,
                                isHoliday: isHoliday,
                                hasEvents: hasEvents,
                                hasAuspicious: hasAuspicious,
                                isSelected: selectedDay == dayNumber
                            )
                            .onTapGesture {
                                if selectedDay == dayNumber {
                                    selectedDay = nil
                                } else {
                                    selectedDay = dayNumber
                                }
                            }
                        } else {
                            // Empty cell
                            Color.clear
                                .frame(height: 36)
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                )
                        }
                    }
                }
            }
        }
    }
}
