import XCTest
@testable import CalendarCore

final class BsDateConverterTests: XCTestCase {

    // MARK: - AD → BS known pairs

    /// Reference date: AD 1913-04-13 = BS 1970-01-01
    func testReferenceDate() {
        let bs = BsDateConverter.adToBs(year: 1913, month: 4, day: 13)
        XCTAssertEqual(bs, BsDate(year: 1970, month: 1, day: 1))
    }

    /// New Year 2081: AD 2024-04-13 = BS 2081-01-01
    func testNewYear2081() {
        let bs = BsDateConverter.adToBs(year: 2024, month: 4, day: 13)
        XCTAssertEqual(bs, BsDate(year: 2081, month: 1, day: 1))
    }

    /// AD 2025-01-14 = BS 2081-10-01 (Magh 1)
    func testMagh1_2081() {
        let bs = BsDateConverter.adToBs(year: 2025, month: 1, day: 14)
        XCTAssertEqual(bs, BsDate(year: 2081, month: 10, day: 1))
    }

    /// AD 2000-01-01 = BS 2056-09-17
    func testY2K() {
        let bs = BsDateConverter.adToBs(year: 2000, month: 1, day: 1)
        XCTAssertEqual(bs, BsDate(year: 2056, month: 9, day: 17))
    }

    // MARK: - BS → AD known pairs

    func testBsToAd_Reference() {
        let ad = BsDateConverter.bsToAd(BsDate(year: 1970, month: 1, day: 1))
        let comps = utcComponents(from: ad)
        XCTAssertEqual(comps.year, 1913)
        XCTAssertEqual(comps.month, 4)
        XCTAssertEqual(comps.day, 13)
    }

    func testBsToAd_NewYear2081() {
        let ad = BsDateConverter.bsToAd(BsDate(year: 2081, month: 1, day: 1))
        let comps = utcComponents(from: ad)
        XCTAssertEqual(comps.year, 2024)
        XCTAssertEqual(comps.month, 4)
        XCTAssertEqual(comps.day, 13)
    }

    func testBsToAd_Y2K() {
        let ad = BsDateConverter.bsToAd(BsDate(year: 2056, month: 9, day: 17))
        let comps = utcComponents(from: ad)
        XCTAssertEqual(comps.year, 2000)
        XCTAssertEqual(comps.month, 1)
        XCTAssertEqual(comps.day, 1)
    }

    // MARK: - Round-trip

    func testRoundTrip_AdBsAd() {
        // Test a range of dates
        let testDates: [(Int, Int, Int)] = [
            (1913, 4, 13),
            (2000, 1, 1),
            (2024, 4, 13),
            (2025, 2, 18),
            (1970, 6, 15),
            (2050, 12, 31),
        ]
        for (y, m, d) in testDates {
            let bs = BsDateConverter.adToBs(year: y, month: m, day: d)
            let adBack = BsDateConverter.bsToAd(bs)
            let comps = utcComponents(from: adBack)
            XCTAssertEqual(comps.year, y, "Round-trip failed for AD \(y)-\(m)-\(d)")
            XCTAssertEqual(comps.month, m, "Round-trip failed for AD \(y)-\(m)-\(d)")
            XCTAssertEqual(comps.day, d, "Round-trip failed for AD \(y)-\(m)-\(d)")
        }
    }

    func testRoundTrip_BsAdBs() {
        let testDates: [BsDate] = [
            BsDate(year: 1970, month: 1, day: 1),
            BsDate(year: 2081, month: 1, day: 1),
            BsDate(year: 2056, month: 9, day: 17),
            BsDate(year: 2082, month: 6, day: 15),
            BsDate(year: 2000, month: 12, day: 29),
        ]
        for bs in testDates {
            let ad = BsDateConverter.bsToAd(bs)
            let bsBack = BsDateConverter.adToBs(ad)
            XCTAssertEqual(bsBack, bs, "Round-trip failed for BS \(bs.year)-\(bs.month)-\(bs.day)")
        }
    }

    // MARK: - Weekday

    func testWeekdayForKnownDate() {
        // 2081-01-01 (Apr 13, 2024) was a Saturday = 7
        let weekday = BsDateConverter.weekday(for: BsDate(year: 2081, month: 1, day: 1))
        XCTAssertEqual(weekday, 7) // Saturday
    }

    // MARK: - Formatter

    func testNepaliNumerals() {
        XCTAssertEqual(NepaliDateFormatter.toNepaliNumeral(0), "०")
        XCTAssertEqual(NepaliDateFormatter.toNepaliNumeral(123), "१२३")
        XCTAssertEqual(NepaliDateFormatter.toNepaliNumeral(2081), "२०८१")
    }

    func testMonthNames() {
        XCTAssertEqual(NepaliDateFormatter.monthNameNp(1), "बैशाख")
        XCTAssertEqual(NepaliDateFormatter.monthNameEn(1), "Baisakh")
        XCTAssertEqual(NepaliDateFormatter.monthNameNp(12), "चैत्र")
    }

    // MARK: - Calendar Data

    func testCalendarDataLoaded() {
        let data = BsCalendarData.shared
        XCTAssertEqual(data.years.count, 282)
        XCTAssertEqual(data.meta.yearMin, 1969)
        XCTAssertEqual(data.meta.yearMax, 2250)
    }

    func testDaysInMonth() {
        let data = BsCalendarData.shared
        // 2081 Baisakh should have 31 days
        XCTAssertEqual(data.daysInMonth(year: 2081, month: 1), 31)
        // 2081 has 366 total
        XCTAssertEqual(data.daysInYear(year: 2081), 366)
    }

    // MARK: - Helpers

    private func utcComponents(from date: Date) -> DateComponents {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.dateComponents([.year, .month, .day], from: date)
    }
}
