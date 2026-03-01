import Foundation

/// A system calendar event fetched via EventKit.
/// Stores all data needed for display so we don't hold onto EKEvent references.
public struct SystemCalendarEvent: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let calendarTitle: String
    /// RGB components (0.0–1.0) of the source calendar's color.
    public let colorRed: Double
    public let colorGreen: Double
    public let colorBlue: Double
    public let location: String?

    public init(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        calendarTitle: String,
        colorRed: Double,
        colorGreen: Double,
        colorBlue: Double,
        location: String?
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.calendarTitle = calendarTitle
        self.colorRed = colorRed
        self.colorGreen = colorGreen
        self.colorBlue = colorBlue
        self.location = location
    }

    /// Format start time as "9:00 AM" (Nepal timezone).
    public var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeZone = BsDateConverter.nepalTimeZone
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startDate)
    }

    /// Format time range as "9:00 AM – 10:00 AM" (Nepal timezone).
    public var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeZone = BsDateConverter.nepalTimeZone
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }

    /// Duration in minutes.
    public var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }
}
