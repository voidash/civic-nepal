import FlutterMacOS
import Foundation

public class LuaEnginePlugin: NSObject, FlutterPlugin {

    // Dedicated serial queue — Lua is not thread-safe
    private let queue = DispatchQueue(label: "com.nagarikpatro.lua_engine",
                                      qos: .userInitiated)

    // Opaque Lua state pointer
    private var L: OpaquePointer?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.nagarikpatro/lua",
                                           binaryMessenger: registrar.messenger)
        let instance = LuaEnginePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    override public init() {
        super.init()
        L = lua_engine_init()
    }

    deinit {
        if let state = L {
            lua_engine_destroy(state)
        }
    }

    // MARK: – FlutterPlugin

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        switch call.method {
        case "execute":
            guard let script = args?["script"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "script required", details: nil))
                return
            }
            queue.async { [weak self] in
                guard let self = self, let L = self.L else {
                    result(FlutterError(code: "NO_STATE", message: "Lua state not initialised", details: nil))
                    return
                }
                guard let raw = lua_engine_execute(L, script) else {
                    result(nil)
                    return
                }
                let str = String(cString: raw)
                free(raw)
                if str.hasPrefix("ERROR:") {
                    let msg = String(str.dropFirst("ERROR:".count))
                    result(FlutterError(code: "LUA_ERROR", message: msg, details: nil))
                } else {
                    result(self.decodeJSON(str))
                }
            }

        case "load":
            guard let script = args?["script"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "script required", details: nil))
                return
            }
            queue.async { [weak self] in
                guard let self = self, let L = self.L else { return }
                let errPtr = lua_engine_load(L, script)
                if let errPtr = errPtr {
                    let msg = String(cString: errPtr)
                    free(errPtr)
                    result(FlutterError(code: "LUA_ERROR", message: msg, details: nil))
                } else {
                    result(nil)
                }
            }

        case "call":
            guard let fn = args?["function"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "function required", details: nil))
                return
            }
            let callArgs = args?["args"] as? [Any?] ?? []
            queue.async { [weak self] in
                guard let self = self, let L = self.L else { return }
                // Encode callArgs as JSON for the C bridge
                let argsJSON = self.encodeJSON(callArgs)
                guard let raw = lua_engine_call(L, fn, argsJSON) else {
                    result(nil)
                    return
                }
                let str = String(cString: raw)
                free(raw)
                if str.hasPrefix("ERROR:") {
                    let msg = String(str.dropFirst("ERROR:".count))
                    result(FlutterError(code: "LUA_ERROR", message: msg, details: nil))
                } else {
                    result(self.decodeJSON(str))
                }
            }

        case "reset":
            queue.async { [weak self] in
                guard let self = self else { return }
                if let L = self.L { lua_engine_destroy(L) }
                self.L = lua_engine_init()
                result(nil)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: – JSON ↔ Swift helpers

    /// Decode a JSON string into a Flutter-compatible Swift value.
    private func decodeJSON(_ json: String) -> Any? {
        guard let data = json.data(using: .utf8) else { return nil }
        guard let value = try? JSONSerialization.jsonObject(
            with: data,
            options: [.allowFragments]
        ) else { return nil }
        return value is NSNull ? nil : value
    }

    /// Encode a Swift array to a compact JSON string for the C bridge.
    private func encodeJSON(_ value: Any?) -> String {
        guard let value = value else { return "null" }
        guard let data = try? JSONSerialization.data(withJSONObject: value) else {
            return "null"
        }
        return String(data: data, encoding: .utf8) ?? "null"
    }
}
