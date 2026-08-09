cmake_minimum_required(VERSION 3.22.1)
project(lua_engine LANGUAGES C CXX)

set(LUA_SRC "${CMAKE_CURRENT_SOURCE_DIR}/../src/lua54")

# The Lua sources are fetched rather than vendored. Say so plainly here — the
# failure without this is a bare "'lua.h' file not found" a hundred lines deep
# in a ninja log.
if(NOT EXISTS "${LUA_SRC}/lua.h")
    message(FATAL_ERROR
        "Lua 5.4 sources are missing from ${LUA_SRC}.\n"
        "Run scripts/fetch_lua.sh from the repository root, then build again.")
endif()

file(GLOB LUA_C "${LUA_SRC}/*.c")
# Exclude standalone executables that define main()
list(FILTER LUA_C EXCLUDE REGEX ".*[/\\\\](lua|luac)\\.c$")

add_library(lua_engine SHARED
    src/main/cpp/lua_engine_jni.cpp
    ${LUA_C}
)

target_include_directories(lua_engine PRIVATE ${LUA_SRC})

target_compile_definitions(lua_engine PRIVATE
    LUA_USE_POSIX
)

find_library(log-lib log)
target_link_libraries(lua_engine PRIVATE ${log-lib})
