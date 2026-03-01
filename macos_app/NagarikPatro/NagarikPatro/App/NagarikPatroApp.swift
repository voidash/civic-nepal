import SwiftUI

@main
struct NagarikPatroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No window — this is a menu bar-only app.
        // LSUIElement = YES in Info.plist hides from Dock.
        Settings {
            EmptyView()
        }
    }
}
