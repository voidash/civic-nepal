import Foundation

/// A date in the Bikram Sambat (BS) calendar system used in Nepal.
public struct BsDate: Equatable, Hashable, Comparable, Sendable {
    public let year: Int
    public let month: Int  // 1-12
    public let day: Int    // 1-32

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public static func < (lhs: BsDate, rhs: BsDate) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }
}
