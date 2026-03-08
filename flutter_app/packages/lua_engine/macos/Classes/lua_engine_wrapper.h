#ifndef LUA_ENGINE_WRAPPER_H
#define LUA_ENGINE_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// Forward-declare lua_State so Swift can treat it as OpaquePointer
typedef struct lua_State lua_State;

/// Create a new Lua state with all standard libraries open.
/// Returns NULL on allocation failure.
lua_State* lua_engine_init(void);

/// Close and free the Lua state. Safe to call with NULL.
void lua_engine_destroy(lua_State* L);

/// Execute [script] and return a JSON-encoded result string.
///
/// On success: JSON value (e.g. `42`, `"hello"`, `[1,2]`, `{"k":"v"}`)
/// On error:   string starting with "ERROR:" followed by the Lua error message
///
/// Caller must free() the returned string.
char* lua_engine_execute(lua_State* L, const char* script);

/// Load and execute [script] for its side effects (define globals/functions).
///
/// Returns NULL on success, or a malloc'd error string on failure.
/// Caller must free() the returned string if non-NULL.
char* lua_engine_load(lua_State* L, const char* script);

/// Call the named global Lua function with JSON-encoded arguments array.
///
/// [func]      — name of a global function
/// [args_json] — JSON array string, e.g. `[1, "hello", true]`
///
/// Returns JSON-encoded result (same format as lua_engine_execute).
/// Caller must free() the returned string.
char* lua_engine_call(lua_State* L, const char* func, const char* args_json);

#ifdef __cplusplus
}
#endif

#endif /* LUA_ENGINE_WRAPPER_H */
