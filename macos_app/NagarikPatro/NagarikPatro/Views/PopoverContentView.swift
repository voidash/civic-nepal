import SwiftUI
import CalendarCore

/// Root SwiftUI view displayed in the menu bar popover (340x460+).
struct PopoverContentView: View {
    @State private var currentYear: Int
    @State private var currentMonth: Int
    @State private var selectedDay: Int?
    @State private var upcomingEvents: [SystemCalendarEvent] = []
    @State private var hasCachedData: Bool

    private let today: BsDate
    private let todayAd: Date
    private let cache = GoogleCalendarCache.shared

    init() {
        let t = BsDateConverter.today()
        self.today = t
        self.todayAd = BsDateConverter.bsToAd(t)
        _currentYear = State(initialValue: t.year)
        _currentMonth = State(initialValue: t.month)
        _selectedDay = State(initialValue: nil)
        _hasCachedData = State(initialValue: GoogleCalendarCache.shared.hasCachedData)
    }

    var body: some View {
        VStack(spacing: 0) {
            MonthNavigationView(
                year: currentYear,
                month: currentMonth,
                onPrevious: previousMonth,
                onNext: nextMonth
            )

            Divider()

            TodayCardView(today: today, todayAd: todayAd)

            Divider()

            // Upcoming Google Calendar events (from Flutter app's cache)
            UpcomingEventsView(
                events: upcomingEvents,
                isAuthorized: hasCachedData,
                onRequestAccess: openFlutterApp
            )

            Divider()

            MiniCalendarView(
                year: currentYear,
                month: currentMonth,
                today: today,
                selectedDay: $selectedDay
            )

            if let day = selectedDay {
                Divider()
                EventListView(year: currentYear, month: currentMonth, day: day)
            }

            Divider()

            openAppButton
        }
        .frame(width: 340)
        .onAppear {
            loadUpcomingEvents()
        }
    }

    // MARK: - Event Loading

    private func loadUpcomingEvents() {
        hasCachedData = cache.hasCachedData
        // Show remaining events today + all-day events
        let todayRemaining = cache.upcomingEvents(hours: 24)
        let allDay = cache.todayEvents().filter { $0.isAllDay }
        var merged: [SystemCalendarEvent] = []
        for e in allDay where !merged.contains(where: { $0.id == e.id }) {
            merged.append(e)
        }
        for e in todayRemaining where !merged.contains(where: { $0.id == e.id }) {
            merged.append(e)
        }
        upcomingEvents = Array(merged.prefix(5))
    }

    // MARK: - Navigation

    private func previousMonth() {
        selectedDay = nil
        if currentMonth == 1 {
            currentMonth = 12
            currentYear -= 1
        } else {
            currentMonth -= 1
        }
    }

    private func nextMonth() {
        selectedDay = nil
        if currentMonth == 12 {
            currentMonth = 1
            currentYear += 1
        } else {
            currentMonth += 1
        }
    }

    // MARK: - Open App Button

    private var openAppButton: some View {
        Button(action: openFlutterApp) {
            HStack {
                Image(systemName: "arrow.up.forward.app")
                Text("Open Nagarik Patro")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .padding(8)
    }

    private func openFlutterApp() {
        // 1. Try local build paths first (most up-to-date during development)
        if let repoRoot = Self.repoRoot {
            let paths = [
                (repoRoot as NSString).appendingPathComponent("flutter_app/build/macos/Build/Products/Debug/nepal_civic.app"),
                (repoRoot as NSString).appendingPathComponent("flutter_app/build/macos/Build/Products/Release/nepal_civic.app"),
            ]
            for path in paths {
                if FileManager.default.fileExists(atPath: path) {
                    NSWorkspace.shared.openApplication(
                        at: URL(fileURLWithPath: path),
                        configuration: NSWorkspace.OpenConfiguration()
                    )
                    return
                }
            }
        }

        // 2. Fall back to bundle ID (LaunchServices cache — may be stale)
        let bundleID = "com.nepal.constitution.nepalCivic"
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.openApplication(
                at: appURL,
                configuration: NSWorkspace.OpenConfiguration()
            )
        }
    }

    /// Derive repo root from compile-time source file path.
    /// This file is at macos_app/NagarikPatro/NagarikPatro/Views/PopoverContentView.swift,
    /// so repo root is 4 levels up.
    private static let repoRoot: String? = {
        var path: String = (#filePath as NSString).deletingLastPathComponent
        for _ in 0..<3 {
            path = (path as NSString).deletingLastPathComponent
        }
        let flutterApp = (path as NSString).appendingPathComponent("flutter_app")
        guard FileManager.default.fileExists(atPath: flutterApp) else { return nil }
        return path
    }()
}
