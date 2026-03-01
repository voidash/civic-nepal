import Cocoa
import FlutterMacOS
import ServiceManagement

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Register as login item on first launch
    if #available(macOS 13.0, *) {
      let hasRegistered = UserDefaults.standard.bool(forKey: "hasRegisteredLoginItem")
      if !hasRegistered {
        try? SMAppService.mainApp.register()
        UserDefaults.standard.set(true, forKey: "hasRegisteredLoginItem")
      }
    }

    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.nagarikpatro/launch_at_login",
                                       binaryMessenger: controller.engine.binaryMessenger)
    channel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "isEnabled":
        if #available(macOS 13.0, *) {
          let status = SMAppService.mainApp.status
          result(status == .enabled)
        } else {
          result(false)
        }
      case "setEnabled":
        guard let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
          return
        }
        if #available(macOS 13.0, *) {
          do {
            if enabled {
              try SMAppService.mainApp.register()
            } else {
              try SMAppService.mainApp.unregister()
            }
            result(true)
          } catch {
            result(FlutterError(code: "SM_ERROR", message: error.localizedDescription, details: nil))
          }
        } else {
          result(FlutterError(code: "UNSUPPORTED", message: "Requires macOS 13+", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
