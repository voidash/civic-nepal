import SwiftUI
import CalendarCore

/// Shows upcoming Google Calendar events (read from the Flutter app's cache) in the menu bar popover.
struct UpcomingEventsView: View {
    let events: [SystemCalendarEvent]
    let isAuthorized: Bool
    let onRequestAccess: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Upcoming")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            if !isAuthorized {
                Button(action: onRequestAccess) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 12))
                        Text("Sign in via Nagarik Patro")
                            .font(.system(size: 11))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            } else if events.isEmpty {
                Text("No upcoming events")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            } else {
                VStack(spacing: 2) {
                    ForEach(events.prefix(5)) { event in
                        eventRow(event)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
    }

    private func eventRow(_ event: SystemCalendarEvent) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(red: event.colorRed, green: event.colorGreen, blue: event.colorBlue))
                .frame(width: 3, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)

                if event.isAllDay {
                    Text("All day")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                } else {
                    Text(event.formattedTimeRange)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: event.colorRed, green: event.colorGreen, blue: event.colorBlue).opacity(0.08))
        )
    }
}
