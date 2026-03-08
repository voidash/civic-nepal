cmake_minimum_required(VERSION 3.14)
set(PLUGIN_NAME "lua_engine_plugin")
project(${PLUGIN_NAME} LANGUAGES C CXX)

# Lua sources live in ../src/lua54 relative to this CMakeLists.txt
set(LUA_SRC "${CMAKE_CURRENT_SOURCE_DIR}/../src/lua54")

file(GLOB LUA_C "${LUA_SRC}/*.c")
# Exclude standalone executables that define main()
list(FILTER LUA_C EXCLUDE REGEX ".*[/\\\\](lua|luac)\\.c$")

add_library(${PLUGIN_NAME} SHARED
    lua_engine_plugin.cpp
    lua_engine_plugin_c_api.cpp
    ${LUA_C}
)

target_include_directories(${PLUGIN_NAME} PRIVATE
    ${LUA_SRC}
    include
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE
    FLUTTER_PLUGIN_IMPL
    # Required to export Lua symbols from a DLL on Windows
    LUA_BUILD_AS_DLL
)

set_target_properties(${PLUGIN_NAME} PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
)

target_link_libraries(${PLUGIN_NAME} PRIVATE
    flutter
    flutter_wrapper_plugin
)
