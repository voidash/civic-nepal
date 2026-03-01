import XCTest
@testable import CalendarCore

final class NagarikPatroTests: XCTestCase {
    func testTodayReturnsValidDate() {
        let today = BsDateConverter.today()
        XCTAssertGreaterThanOrEqual(today.year, 2080)
        XCTAssertLessThanOrEqual(today.year, 2250)
        XCTAssertGreaterThanOrEqual(today.month, 1)
        XCTAssertLessThanOrEqual(today.month, 12)
        XCTAssertGreaterThanOrEqual(today.day, 1)
        XCTAssertLessThanOrEqual(today.day, 32)
    }

    func testEventStoreLoads() {
        let store = CalendarEventStore.shared
        // 2081-01 should have events (Baisakh 1 = New Year)
        let events = store.eventsForMonth(year: 2081, month: 1)
        XCTAssertFalse(events.isEmpty, "Should have events for 2081-01")
    }

    func testAuspiciousDataLoads() {
        let store = CalendarEventStore.shared
        let ausp = store.auspiciousForMonth(year: 2081, month: 1)
        XCTAssertNotNil(ausp, "Should have auspicious data for 2081-01")
    }
}
