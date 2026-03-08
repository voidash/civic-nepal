#include "lua_engine_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <variant>

extern "C" {
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

namespace lua_engine {

// ─── Registration ────────────────────────────────────────────────────────────

// static
void LuaEnginePlugin::RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
    auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(),
        "com.nagarikpatro/lua",
        &flutter::StandardMethodCodec::GetInstance()
    );

    auto plugin = std::make_unique<LuaEnginePlugin>();
    channel->SetMethodCallHandler(
        [plugin_ptr = plugin.get()](const auto& call, auto result) {
            plugin_ptr->HandleMethodCall(call, std::move(result));
        }
    );

    registrar->AddPlugin(std::move(plugin));
}

// ─── Constructor / Destructor ────────────────────────────────────────────────

LuaEnginePlugin::LuaEnginePlugin() {
    L_ = luaL_newstate();
    if (L_) luaL_openlibs(L_);
    StartLuaThread();
}

LuaEnginePlugin::~LuaEnginePlugin() {
    StopLuaThread();
    if (L_) {
        lua_close(L_);
        L_ = nullptr;
    }
}

// ─── Lua thread ──────────────────────────────────────────────────────────────

void LuaEnginePlugin::StartLuaThread() {
    lua_thread_ = std::thread([this]() {
        while (true) {
            Task task;
            {
                std::unique_lock<std::mutex> lock(queue_mutex_);
                queue_cv_.wait(lock, [this] { return stop_ || !task_queue_.empty(); });
                if (stop_ && task_queue_.empty()) break;
                task = std::move(task_queue_.front());
                task_queue_.pop();
            }
            task();
        }
    });
}

void LuaEnginePlugin::StopLuaThread() {
    {
        std::lock_guard<std::mutex> lock(queue_mutex_);
        stop_ = true;
    }
    queue_cv_.notify_all();
    if (lua_thread_.joinable()) lua_thread_.join();
}

void LuaEnginePlugin::PostTask(Task task) {
    {
        std::lock_guard<std::mutex> lock(queue_mutex_);
        task_queue_.push(std::move(task));
    }
    queue_cv_.notify_one();
}

// ─── Type conversions ────────────────────────────────────────────────────────

// static
void LuaEnginePlugin::PushEncodableValue(lua_State* L,
                                          const flutter::EncodableValue& val) {
    if (std::holds_alternative<std::monostate>(val)) {
        lua_pushnil(L);
    } else if (auto* b = std::get_if<bool>(&val)) {
        lua_pushboolean(L, *b ? 1 : 0);
    } else if (auto* i = std::get_if<int32_t>(&val)) {
        lua_pushinteger(L, (lua_Integer)*i);
    } else if (auto* i64 = std::get_if<int64_t>(&val)) {
        lua_pushinteger(L, (lua_Integer)*i64);
    } else if (auto* d = std::get_if<double>(&val)) {
        lua_pushnumber(L, (lua_Number)*d);
    } else if (auto* s = std::get_if<std::string>(&val)) {
        lua_pushlstring(L, s->data(), s->size());
    } else if (auto* list = std::get_if<flutter::EncodableList>(&val)) {
        lua_createtable(L, (int)list->size(), 0);
        for (size_t i = 0; i < list->size(); i++) {
            PushEncodableValue(L, (*list)[i]);
            lua_rawseti(L, -2, (lua_Integer)(i + 1));
        }
    } else if (auto* map = std::get_if<flutter::EncodableMap>(&val)) {
        lua_createtable(L, 0, (int)map->size());
        for (const auto& kv : *map) {
            PushEncodableValue(L, kv.first);
            PushEncodableValue(L, kv.second);
            lua_rawset(L, -3);
        }
    } else {
        lua_pushnil(L);
    }
}

// static
flutter::EncodableValue LuaEnginePlugin::PopValue(lua_State* L, int idx) {
    idx = lua_absindex(L, idx);
    int t = lua_type(L, idx);
    switch (t) {
        case LUA_TNIL:
        case LUA_TNONE:
            return flutter::EncodableValue();  // monostate = null

        case LUA_TBOOLEAN:
            return flutter::EncodableValue(lua_toboolean(L, idx) != 0);

        case LUA_TNUMBER:
            if (lua_isinteger(L, idx)) {
                return flutter::EncodableValue((int64_t)lua_tointeger(L, idx));
            }
            return flutter::EncodableValue(lua_tonumber(L, idx));

        case LUA_TSTRING: {
            size_t len;
            const char* s = lua_tolstring(L, idx, &len);
            return flutter::EncodableValue(std::string(s, len));
        }

        case LUA_TTABLE: {
            lua_Integer n = (lua_Integer)lua_rawlen(L, idx);
            bool is_array = (n > 0);
            for (lua_Integer i = 1; i <= n && is_array; i++) {
                lua_rawgeti(L, idx, i);
                if (lua_isnil(L, -1)) is_array = false;
                lua_pop(L, 1);
            }

            if (is_array) {
                flutter::EncodableList list;
                list.reserve((size_t)n);
                for (lua_Integer i = 1; i <= n; i++) {
                    lua_rawgeti(L, idx, i);
                    list.push_back(PopValue(L, -1));
                    lua_pop(L, 1);
                }
                return flutter::EncodableValue(list);
            } else {
                flutter::EncodableMap map;
                lua_pushnil(L);
                while (lua_next(L, idx) != 0) {
                    auto key = PopValue(L, -2);
                    auto val = PopValue(L, -1);
                    map[key] = val;
                    lua_pop(L, 1);
                }
                return flutter::EncodableValue(map);
            }
        }

        default:
            return flutter::EncodableValue();
    }
}

// ─── Method dispatch ─────────────────────────────────────────────────────────

void LuaEnginePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

    auto shared_result = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(
        std::move(result));

    const auto& method = method_call.method_name();
    const auto* args_map = std::get_if<flutter::EncodableMap>(method_call.arguments());

    if (method == "execute") {
        if (!args_map) {
            shared_result->Error("INVALID_ARGS", "arguments must be a map");
            return;
        }
        auto it = args_map->find(flutter::EncodableValue("script"));
        if (it == args_map->end()) {
            shared_result->Error("INVALID_ARGS", "script required");
            return;
        }
        std::string script = std::get<std::string>(it->second);

        PostTask([this, script, shared_result]() {
            int top = lua_gettop(L_);
            if (luaL_loadstring(L_, script.c_str()) != LUA_OK) {
                std::string err = lua_tostring(L_, -1);
                lua_settop(L_, top);
                shared_result->Error("LUA_ERROR", err);
                return;
            }
            int top_after = lua_gettop(L_);
            if (lua_pcall(L_, 0, LUA_MULTRET, 0) != LUA_OK) {
                std::string err = lua_tostring(L_, -1);
                lua_settop(L_, top);
                shared_result->Error("LUA_ERROR", err);
                return;
            }
            int nret = lua_gettop(L_) - (top_after - 1);
            if (nret > 0) {
                auto val = PopValue(L_, -1);
                lua_settop(L_, top);
                shared_result->Success(val);
            } else {
                lua_settop(L_, top);
                shared_result->Success(flutter::EncodableValue());
            }
        });

    } else if (method == "load") {
        if (!args_map) {
            shared_result->Error("INVALID_ARGS", "arguments must be a map");
            return;
        }
        auto it = args_map->find(flutter::EncodableValue("script"));
        if (it == args_map->end()) {
            shared_result->Error("INVALID_ARGS", "script required");
            return;
        }
        std::string script = std::get<std::string>(it->second);

        PostTask([this, script, shared_result]() {
            int top = lua_gettop(L_);
            if (luaL_loadstring(L_, script.c_str()) != LUA_OK) {
                std::string err = lua_tostring(L_, -1);
                lua_settop(L_, top);
                shared_result->Error("LUA_ERROR", err);
                return;
            }
            if (lua_pcall(L_, 0, 0, 0) != LUA_OK) {
                std::string err = lua_tostring(L_, -1);
                lua_settop(L_, top);
                shared_result->Error("LUA_ERROR", err);
                return;
            }
            shared_result->Success(flutter::EncodableValue());
        });

    } else if (method == "call") {
        if (!args_map) {
            shared_result->Error("INVALID_ARGS", "arguments must be a map");
            return;
        }
        auto fn_it = args_map->find(flutter::EncodableValue("function"));
        if (fn_it == args_map->end()) {
            shared_result->Error("INVALID_ARGS", "function required");
            return;
        }
        std::string fn_name = std::get<std::string>(fn_it->second);

        flutter::EncodableList call_args;
        auto args_it = args_map->find(flutter::EncodableValue("args"));
        if (args_it != args_map->end()) {
            if (auto* l = std::get_if<flutter::EncodableList>(&args_it->second)) {
                call_args = *l;
            }
        }

        PostTask([this, fn_name, call_args, shared_result]() {
            int top = lua_gettop(L_);
            lua_getglobal(L_, fn_name.c_str());
            if (!lua_isfunction(L_, -1)) {
                lua_settop(L_, top);
                shared_result->Error("LUA_ERROR", "function not found: " + fn_name);
                return;
            }
            for (const auto& arg : call_args) {
                PushEncodableValue(L_, arg);
            }
            int argc = (int)call_args.size();
            int top_after = lua_gettop(L_);
            if (lua_pcall(L_, argc, LUA_MULTRET, 0) != LUA_OK) {
                std::string err = lua_tostring(L_, -1);
                lua_settop(L_, top);
                shared_result->Error("LUA_ERROR", err);
                return;
            }
            int nret = lua_gettop(L_) - (top_after - argc - 1);
            if (nret > 0) {
                auto val = PopValue(L_, -1);
                lua_settop(L_, top);
                shared_result->Success(val);
            } else {
                lua_settop(L_, top);
                shared_result->Success(flutter::EncodableValue());
            }
        });

    } else if (method == "reset") {
        PostTask([this, shared_result]() {
            if (L_) { lua_close(L_); }
            L_ = luaL_newstate();
            if (L_) luaL_openlibs(L_);
            shared_result->Success(flutter::EncodableValue());
        });

    } else {
        shared_result->NotImplemented();
    }
}

}  // namespace lua_engine
