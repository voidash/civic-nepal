import AppKit
import ServiceManagement
import CalendarCore

/// Manages the NSStatusItem (menu bar icon).
/// Left-click: toggle Flutter popup via HTTP (localhost:27182).
/// Right-click: minimal context menu (date + Open + Quit).
///
/// Tray widget settings (language, year, launch-at-login, visibility) are
/// managed from the Flutter app and delivered via tray_settings.json.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var midnightTimer: Timer?

    private let urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 3
        return URLSession(configuration: config)
    }()

    // MARK: - Tray Settings (from tray_settings.json)

    private struct TraySettingsData {
        var menuBarLanguage: MenuBarLanguage = .nepali
        var showYearInTray  = false
        var launchAtLogin   = false
        var showTrayWidget  = true
    }

    enum MenuBarLanguage: String { case nepali, english }

    private var traySettings = TraySettingsData()
    private var traySettingsSource: DispatchSourceFileSystemObject?
    private var trayRetryTimer: Timer?

    private var traySettingsPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Application Support/NagarikPatro/tray_settings.json"
    }

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        loadTraySettings()
        applyTraySettings()
        startTraySettingsWatcher()
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

    // MARK: - Status Bar Title

    private func updateStatusBarTitle(_ button: NSStatusBarButton) {
        let today = BsDateConverter.today()

        var title: String
        switch traySettings.menuBarLanguage {
        case .nepali:
            title = NepaliDateFormatter.menuBarTitleNp(today)
            if traySettings.showYearInTray {
                title += " \(NepaliDateFormatter.toNepaliNumeral(today.year))"
            }
        case .english:
            title = NepaliDateFormatter.menuBarTitleEn(today)
            if traySettings.showYearInTray {
                title += " \(today.year)"
            }
        }
        button.title = title
    }

    // MARK: - Right-Click Context Menu

    private func showContextMenu() {
        let menu = NSMenu()

        // Today's date display (non-interactive)
        let today = BsDateConverter.today()
        let todayItem = NSMenuItem(
            title: "आज: \(NepaliDateFormatter.formatNp(today))",
            action: nil, keyEquivalent: "")
        todayItem.isEnabled = false
        menu.addItem(todayItem)

        let todayAdItem = NSMenuItem(
            title: NepaliDateFormatter.formatAdDate(BsDateConverter.bsToAd(today)),
            action: nil, keyEquivalent: "")
        todayAdItem.isEnabled = false
        menu.addItem(todayAdItem)

        menu.addItem(.separator())

        // Open Flutter app (settings are managed there)
        let openItem = NSMenuItem(
            title: "Open Nagarik Patro",
            action: #selector(openFullApp), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Clear menu so next left-click returns to popup toggle behaviour.
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    @objc private func openFullApp() {
        postToTrayServer(path: "/popup/open-app") { [weak self] success in
            if !success { self?.openFlutterApp() }
        }
    }

    private func openFlutterApp() {
        let bundleID = "com.nepal.constitution.nepalCivic"
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.openApplication(
                at: appURL, configuration: NSWorkspace.OpenConfiguration())
            return
        }

        if let repoRoot = Self.repoRoot {
            let paths = [
                (repoRoot as NSString).appendingPathComponent(
                    "flutter_app/build/macos/Build/Products/Release/nepal_civic.app"),
                (repoRoot as NSString).appendingPathComponent(
                    "flutter_app/build/macos/Build/Products/Debug/nepal_civic.app"),
            ]
            for path in paths where FileManager.default.fileExists(atPath: path) {
                NSWorkspace.shared.openApplication(
                    at: URL(fileURLWithPath: path),
                    configuration: NSWorkspace.OpenConfiguration())
                return
            }
        }
    }

    private static let repoRoot: String? = {
        var path: String = (#filePath as NSString).deletingLastPathComponent
        for _ in 0..<4 { path = (path as NSString).deletingLastPathComponent }
        let flutterApp = (path as NSString).appendingPathComponent("flutter_app")
        guard FileManager.default.fileExists(atPath: flutterApp) else { return nil }
        return path
    }()

    @objc private func quitApp() { NSApp.terminate(nil) }

    // MARK: - Tray Settings File Loading + Watching

    private func loadTraySettings() {
        guard let data = FileManager.default.contents(atPath: traySettingsPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        traySettings = TraySettingsData(
            menuBarLanguage: (json["menuBarLanguage"] as? String) == "english" ? .english : .nepali,
            showYearInTray: (json["showYearInTray"] as? Bool) ?? false,
            launchAtLogin:  (json["launchAtLogin"]  as? Bool) ?? false,
            showTrayWidget: (json["showTrayWidget"]  as? Bool) ?? true
        )
    }

    private func applyTraySettings() {
        guard traySettings.showTrayWidget else {
            NSApp.terminate(nil)
            return
        }

        if let button = statusItem?.button {
            updateStatusBarTitle(button)
        }

        syncLaunchAtLogin(traySettings.launchAtLogin)
    }

    private func syncLaunchAtLogin(_ desired: Bool) {
        guard #available(macOS 13.0, *) else { return }
        let service = SMAppService.mainApp
        let current = service.status == .enabled
        guard current != desired else { return }
        do {
            if desired { try service.register() }
            else       { try service.unregister() }
        } catch {
            // Non-fatal — user can control this via System Settings
        }
    }

    /// Start a DispatchSource file-system watcher for tray_settings.json.
    /// Falls back to a 30-second polling timer if the file doesn't exist yet.
    private func startTraySettingsWatcher() {
        trayRetryTimer?.invalidate()
        trayRetryTimer = nil

        let fd = open(traySettingsPath, O_EVTONLY)
        guard fd >= 0 else {
            // File doesn't exist yet — Flutter hasn't run. Retry in 30 s.
            trayRetryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
                self?.startTraySettingsWatcher()
            }
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename],
            queue: .main)

        source.setEventHandler { [weak self] in
            guard let self else { return }
            let mask = source.data
            if mask.contains(.delete) || mask.contains(.rename) {
                // File was removed — stop watching and retry later.
                source.cancel()
                self.traySettingsSource = nil
                self.startTraySettingsWatcher()
            } else {
                self.loadTraySettings()
                self.applyTraySettings()
            }
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        traySettingsSource = source
    }

    // MARK: - Midnight Refresh

    private func scheduleMidnightRefresh() {
        midnightTimer?.invalidate()

        let now = Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = BsDateConverter.nepalTimeZone

        guard let todayStart = calendar.startOfDay(for: now) as Date?,
              let nextMidnight = calendar.date(byAdding: .day, value: 1, to: todayStart)
        else { return }

        let interval = nextMidnight.timeIntervalSince(now)
        guard interval > 0 else { return }

        midnightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.handleMidnight()
        }
    }

    private func handleMidnight() {
        if let button = statusItem.button { updateStatusBarTitle(button) }
        scheduleMidnightRefresh()
    }

    @objc private func handleWake() {
        if let button = statusItem.button { updateStatusBarTitle(button) }
        scheduleMidnightRefresh()
    }
}
