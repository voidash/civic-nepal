import AppKit
import SwiftUI
import CalendarCore

/// Manages the NSStatusItem (menu bar icon).
/// Left-click: toggle Flutter popup via HTTP (localhost:27182).
/// Right-click: context menu.
/// The macOS tray app no longer renders any calendar UI — Flutter owns the popup.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var midnightTimer: Timer?

    private let urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 3
        return URLSession(configuration: config)
    }()

    // MARK: - Settings Keys

    enum Settings {
        static let menuBarLanguageKey = "menuBarLanguage"
        static let showYearInMenuBarKey = "showYearInMenuBar"

        enum Language: String, CaseIterable {
            case nepali = "nepali"
            case english = "english"

            var displayName: String {
                switch self {
                case .nepali: return "नेपाली (Nepali)"
                case .english: return "English"
                }
            }
        }

        static var menuBarLanguage: Language {
            get {
                let raw = UserDefaults.standard.string(forKey: menuBarLanguageKey) ?? Language.nepali.rawValue
                return Language(rawValue: raw) ?? .nepali
            }
            set { UserDefaults.standard.set(newValue.rawValue, forKey: menuBarLanguageKey) }
        }

        static var showYearInMenuBar: Bool {
            get {
                if UserDefaults.standard.object(forKey: showYearInMenuBarKey) == nil { return false }
                return UserDefaults.standard.bool(forKey: showYearInMenuBarKey)
            }
            set { UserDefaults.standard.set(newValue, forKey: showYearInMenuBarKey) }
        }
    }

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        scheduleMidnightRefresh()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateStatusBarTitle(button)
            button.action = #selector(handleStatusItemClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
    }

    @objc private func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else {
            toggleFlutterPopup()
            return
        }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            toggleFlutterPopup()
        }
    }

    // MARK: - Flutter Popup via HTTP

    private func toggleFlutterPopup() {
        postToTrayServer(path: "/popup/toggle") { [weak self] success in
            if !success {
                // Flutter not running — launch it, then retry.
                self?.openFlutterApp()
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.postToTrayServer(path: "/popup/toggle") { _ in }
                }
            }
        }
    }

    private func postToTrayServer(path: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://127.0.0.1:27182\(path)") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        urlSession.dataTask(with: request) { _, response, error in
            let ok = error == nil && (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async { completion(ok) }
        }.resume()
    }

    private func updateStatusBarTitle(_ button: NSStatusBarButton) {
        let today = BsDateConverter.today()
        let lang = Settings.menuBarLanguage
        let showYear = Settings.showYearInMenuBar

        var title: String
        switch lang {
        case .nepali:
            title = NepaliDateFormatter.menuBarTitleNp(today)
            if showYear {
                title += " \(NepaliDateFormatter.toNepaliNumeral(today.year))"
            }
        case .english:
            title = NepaliDateFormatter.menuBarTitleEn(today)
            if showYear {
                title += " \(today.year)"
            }
        }
        button.title = title
    }

    // MARK: - Right-Click Context Menu

    private func showContextMenu() {
        closePopover()

        let menu = NSMenu()

        // Today's date display (non-interactive)
        let today = BsDateConverter.today()
        let todayItem = NSMenuItem(title: "आज: \(NepaliDateFormatter.formatNp(today))", action: nil, keyEquivalent: "")
        todayItem.isEnabled = false
        menu.addItem(todayItem)

        let todayAdItem = NSMenuItem(title: NepaliDateFormatter.formatAdDate(BsDateConverter.bsToAd(today)), action: nil, keyEquivalent: "")
        todayAdItem.isEnabled = false
        menu.addItem(todayAdItem)

        menu.addItem(.separator())

        // Language submenu
        let langMenu = NSMenu()
        for lang in Settings.Language.allCases {
            let item = NSMenuItem(title: lang.displayName, action: #selector(changeLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = lang.rawValue
            item.state = Settings.menuBarLanguage == lang ? .on : .off
            langMenu.addItem(item)
        }
        let langItem = NSMenuItem(title: "Menu Bar Language", action: nil, keyEquivalent: "")
        langItem.submenu = langMenu
        menu.addItem(langItem)

        // Show year toggle
        let yearItem = NSMenuItem(title: "Show Year in Menu Bar", action: #selector(toggleShowYear), keyEquivalent: "")
        yearItem.target = self
        yearItem.state = Settings.showYearInMenuBar ? .on : .off
        menu.addItem(yearItem)

        menu.addItem(.separator())

        // Open Flutter app (full-app mode)
        let openItem = NSMenuItem(title: "Open Nagarik Patro", action: #selector(openFullApp), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Clear the menu so left-click goes back to popover action
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    @objc private func changeLanguage(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let lang = Settings.Language(rawValue: rawValue) else { return }
        Settings.menuBarLanguage = lang
        if let button = statusItem.button {
            updateStatusBarTitle(button)
        }
    }

    @objc private func toggleShowYear() {
        Settings.showYearInMenuBar.toggle()
        if let button = statusItem.button {
            updateStatusBarTitle(button)
        }
    }

    @objc private func openFullApp() {
        // Ask Flutter to switch to full-app mode via the tray server.
        postToTrayServer(path: "/popup/open-app") { [weak self] success in
            if !success {
                // Flutter not running — launch it directly.
                self?.openFlutterApp()
            }
        }
    }

    private func openFlutterApp() {
        // 1. Try bundle ID (works if Flutter app has been launched at least once)
        let bundleID = "com.nepal.constitution.nepalCivic"
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.openApplication(
                at: appURL,
                configuration: NSWorkspace.OpenConfiguration()
            )
            return
        }

        // 2. Try known build output paths using compile-time source path
        if let repoRoot = Self.repoRoot {
            let paths = [
                (repoRoot as NSString).appendingPathComponent("flutter_app/build/macos/Build/Products/Release/nepal_civic.app"),
                (repoRoot as NSString).appendingPathComponent("flutter_app/build/macos/Build/Products/Debug/nepal_civic.app"),
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
    }

    /// Derive repo root from compile-time source file path.
    /// This file is at macos_app/NagarikPatro/NagarikPatro/App/AppDelegate.swift,
    /// so repo root is 5 levels up.
    private static let repoRoot: String? = {
        var path: String = (#filePath as NSString).deletingLastPathComponent
        for _ in 0..<4 {
            path = (path as NSString).deletingLastPathComponent
        }
        let flutterApp = (path as NSString).appendingPathComponent("flutter_app")
        guard FileManager.default.fileExists(atPath: flutterApp) else { return nil }
        return path
    }()

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Midnight Refresh

    private func scheduleMidnightRefresh() {
        midnightTimer?.invalidate()

        let now = Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = BsDateConverter.nepalTimeZone

        guard let todayStart = calendar.startOfDay(for: now) as Date?,
              let nextMidnight = calendar.date(byAdding: .day, value: 1, to: todayStart) else {
            return
        }

        let interval = nextMidnight.timeIntervalSince(now)
        guard interval > 0 else { return }

        midnightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.handleMidnight()
        }
    }

    private func handleMidnight() {
        if let button = statusItem.button {
            updateStatusBarTitle(button)
        }
        scheduleMidnightRefresh()
    }

    @objc private func handleWake() {
        if let button = statusItem.button {
            updateStatusBarTitle(button)
        }
        scheduleMidnightRefresh()
    }
}
