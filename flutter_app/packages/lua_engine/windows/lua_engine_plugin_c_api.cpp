#include "include/lua_engine/lua_engine_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "lua_engine_plugin.h"

void LuaEnginePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
    lua_engine::LuaEnginePlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarManager::GetInstance()
            ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
