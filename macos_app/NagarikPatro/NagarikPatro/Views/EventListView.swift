import SwiftUI
import CalendarCore

/// Shows events and auspicious info for a selected day.
struct EventListView: View {
    let year: Int
    let month: Int
    let day: Int

    private let eventStore = CalendarEventStore.shared

    private var dayEvent: CalendarEventStore.DayEventInfo? {
        eventStore.events(year: year, month: month, day: day)
    }

    private var isAuspiciousWedding: Bool {
        eventStore.isAuspiciousWedding(year: year, month: month, day: day)
    }

    private var isAuspiciousBratabandha: Bool {
        eventStore.isAuspiciousBratabandha(year: year, month: month, day: day)
    }

    private var isAuspiciousPasni: Bool {
        eventStore.isAuspiciousPasni(year: year, month: month, day: day)
    }

    private var hasContent: Bool {
        dayEvent != nil || isAuspiciousWedding || isAuspiciousBratabandha || isAuspiciousPasni
    }

    var body: some View {
        if hasContent {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    // Date header
                    Text("\(NepaliDateFormatter.toNepaliNumeral(day)) \(NepaliDateFormatter.monthNameNp(month))")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.bottom, 2)

                    // Events
                    if let info = dayEvent {
                        ForEach(Array(zip(info.eventsNp, info.events)), id: \.0) { npEvent, enEvent in
                            HStack(alignment: .top, spacing: 6) {
                                Circle()
                                    .fill(info.isHoliday ? .red : .orange)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 4)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(npEvent)
                                        .font(.system(size: 12))
                                    Text(enEvent)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Auspicious tags
                    if isAuspiciousWedding || isAuspiciousBratabandha || isAuspiciousPasni {
                        HStack(spacing: 4) {
                            if isAuspiciousWedding {
                                auspiciousTag("बिबाह", color: .green)
                            }
                            if isAuspiciousBratabandha {
                                auspiciousTag("ब्रतबन्ध", color: .green)
                            }
                            if isAuspiciousPasni {
                                auspiciousTag("पास्नी", color: .green)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 120)
        } else {
            EmptyView()
        }
    }

    private func auspiciousTag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.1))
                    .stroke(color.opacity(0.3), lineWidth: 0.5)
            )
    }
}
