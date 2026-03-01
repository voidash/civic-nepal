import Foundation

/// A day in the calendar with associated metadata (events, holidays, auspicious flags).
public struct CalendarDay: Identifiable, Sendable {
    public var id: Int { day }
    public let day: Int
    public let isToday: Bool
    public let isSaturday: Bool
    public let isHoliday: Bool
    public let events: [String]
    public let eventsNp: [String]
    public let isAuspiciousWedding: Bool
    public let isAuspiciousBratabandha: Bool
    public let isAuspiciousPasni: Bool

    public init(
        day: Int,
        isToday: Bool = false,
        isSaturday: Bool = false,
        isHoliday: Bool = false,
        events: [String] = [],
        eventsNp: [String] = [],
        isAuspiciousWedding: Bool = false,
        isAuspiciousBratabandha: Bool = false,
        isAuspiciousPasni: Bool = false
    ) {
        self.day = day
        self.isToday = isToday
        self.isSaturday = isSaturday
        self.isHoliday = isHoliday
        self.events = events
        self.eventsNp = eventsNp
        self.isAuspiciousWedding = isAuspiciousWedding
        self.isAuspiciousBratabandha = isAuspiciousBratabandha
        self.isAuspiciousPasni = isAuspiciousPasni
    }

    public var hasEvents: Bool { !events.isEmpty }
    public var hasAuspicious: Bool { isAuspiciousWedding || isAuspiciousBratabandha || isAuspiciousPasni }
}
