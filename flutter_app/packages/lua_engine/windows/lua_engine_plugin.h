#ifndef FLUTTER_PLUGIN_LUA_ENGINE_PLUGIN_H_
#define FLUTTER_PLUGIN_LUA_ENGINE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <condition_variable>
#include <functional>
#include <memory>
#include <mutex>
#include <queue>
#include <thread>

extern "C" {
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

namespace lua_engine {

class LuaEnginePlugin : public flutter::Plugin {
public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

    LuaEnginePlugin();
    ~LuaEnginePlugin() override;

    // Disallow copy and assign
    LuaEnginePlugin(const LuaEnginePlugin&) = delete;
    LuaEnginePlugin& operator=(const LuaEnginePlugin&) = delete;

private:
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    // ─── Lua thread management ───────────────────────────────────────────────
    using Task = std::function<void()>;

    void StartLuaThread();
    void StopLuaThread();
    void PostTask(Task task);

    lua_State* L_ = nullptr;

    std::thread lua_thread_;
    std::queue<Task> task_queue_;
    std::mutex queue_mutex_;
    std::condition_variable queue_cv_;
    bool stop_ = false;

    // ─── Type conversion helpers ─────────────────────────────────────────────
    static void PushEncodableValue(lua_State* L, const flutter::EncodableValue& val);
    static flutter::EncodableValue PopValue(lua_State* L, int idx);
};

}  // namespace lua_engine

#endif  // FLUTTER_PLUGIN_LUA_ENGINE_PLUGIN_H_
