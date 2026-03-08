#include "lua_engine_wrapper.h"
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// ─── JSON serialisation ──────────────────────────────────────────────────────
// Minimal recursive Lua→JSON serialiser.
// Uses a growable buffer approach.

typedef struct {
    char*  buf;
    size_t len;
    size_t cap;
} StrBuf;

static void sb_init(StrBuf* b) {
    b->cap = 256;
    b->buf = (char*)malloc(b->cap);
    b->len = 0;
    if (b->buf) b->buf[0] = '\0';
}

static void sb_grow(StrBuf* b, size_t extra) {
    if (b->len + extra + 1 > b->cap) {
        while (b->len + extra + 1 > b->cap) b->cap *= 2;
        b->buf = (char*)realloc(b->buf, b->cap);
    }
}

static void sb_append(StrBuf* b, const char* s) {
    size_t n = strlen(s);
    sb_grow(b, n);
    memcpy(b->buf + b->len, s, n + 1);
    b->len += n;
}

static void sb_appendc(StrBuf* b, char c) {
    sb_grow(b, 1);
    b->buf[b->len++] = c;
    b->buf[b->len]   = '\0';
}

// Escape a string for JSON output
static void sb_append_json_string(StrBuf* b, const char* s, size_t len) {
    sb_appendc(b, '"');
    for (size_t i = 0; i < len; i++) {
        unsigned char c = (unsigned char)s[i];
        switch (c) {
            case '"':  sb_append(b, "\\\""); break;
            case '\\': sb_append(b, "\\\\"); break;
            case '\n': sb_append(b, "\\n");  break;
            case '\r': sb_append(b, "\\r");  break;
            case '\t': sb_append(b, "\\t");  break;
            default:
                if (c < 0x20) {
                    char esc[8];
                    snprintf(esc, sizeof(esc), "\\u%04x", c);
                    sb_append(b, esc);
                } else {
                    sb_appendc(b, (char)c);
                }
        }
    }
    sb_appendc(b, '"');
}

// Forward declaration
static void lua_value_to_json(lua_State* L, int idx, StrBuf* b, int depth);

static void lua_table_to_json(lua_State* L, int idx, StrBuf* b, int depth) {
    if (depth > 32) { sb_append(b, "null"); return; }
    idx = lua_absindex(L, idx);

    // Detect array: all keys 1..n integers
    lua_Integer n = (lua_Integer)lua_rawlen(L, idx);
    int is_array = (n > 0);
    for (lua_Integer i = 1; i <= n && is_array; i++) {
        lua_rawgeti(L, idx, i);
        if (lua_isnil(L, -1)) is_array = 0;
        lua_pop(L, 1);
    }

    if (is_array) {
        sb_appendc(b, '[');
        for (lua_Integer i = 1; i <= n; i++) {
            if (i > 1) sb_appendc(b, ',');
            lua_rawgeti(L, idx, i);
            lua_value_to_json(L, -1, b, depth + 1);
            lua_pop(L, 1);
        }
        sb_appendc(b, ']');
    } else {
        sb_appendc(b, '{');
        int first = 1;
        lua_pushnil(L);
        while (lua_next(L, idx) != 0) {
            if (!first) sb_appendc(b, ',');
            first = 0;
            // Key must be a string for valid JSON; convert numbers to strings
            if (lua_type(L, -2) == LUA_TSTRING) {
                size_t klen;
                const char* k = lua_tolstring(L, -2, &klen);
                sb_append_json_string(b, k, klen);
            } else if (lua_type(L, -2) == LUA_TNUMBER) {
                lua_pushvalue(L, -2);
                size_t klen;
                const char* k = lua_tolstring(L, -1, &klen);
                sb_append_json_string(b, k, klen);
                lua_pop(L, 1);
            } else {
                // Skip non-string/number keys
                lua_pop(L, 1);
                continue;
            }
            sb_appendc(b, ':');
            lua_value_to_json(L, -1, b, depth + 1);
            lua_pop(L, 1);
        }
        sb_appendc(b, '}');
    }
}

static void lua_value_to_json(lua_State* L, int idx, StrBuf* b, int depth) {
    idx = lua_absindex(L, idx);
    switch (lua_type(L, idx)) {
        case LUA_TNIL:
            sb_append(b, "null");
            break;
        case LUA_TBOOLEAN:
            sb_append(b, lua_toboolean(L, idx) ? "true" : "false");
            break;
        case LUA_TNUMBER: {
            char num[64];
            if (lua_isinteger(L, idx)) {
                snprintf(num, sizeof(num), "%lld", (long long)lua_tointeger(L, idx));
            } else {
                snprintf(num, sizeof(num), "%.17g", lua_tonumber(L, idx));
            }
            sb_append(b, num);
            break;
        }
        case LUA_TSTRING: {
            size_t len;
            const char* s = lua_tolstring(L, idx, &len);
            sb_append_json_string(b, s, len);
            break;
        }
        case LUA_TTABLE:
            lua_table_to_json(L, idx, b, depth);
            break;
        default:
            sb_append(b, "null");
            break;
    }
}

// Serialise top-of-stack value to a malloc'd JSON string.
// Returns NULL on malloc failure.
static char* stack_top_to_json(lua_State* L) {
    StrBuf b;
    sb_init(&b);
    if (!b.buf) return NULL;
    lua_value_to_json(L, -1, &b, 0);
    return b.buf; // caller must free()
}

// ─── JSON → Lua deserialiser (for call args) ────────────────────────────────
// Minimal JSON parser that pushes values onto the Lua stack.
// Only supports arrays at the top level (sufficient for call args).

typedef struct { const char* p; size_t rem; } JsonReader;

static void jr_skip_ws(JsonReader* r) {
    while (r->rem > 0 && (*r->p == ' ' || *r->p == '\t' ||
                           *r->p == '\n' || *r->p == '\r')) {
        r->p++; r->rem--;
    }
}

static void json_parse_value(lua_State* L, JsonReader* r);

static void json_parse_string(lua_State* L, JsonReader* r) {
    // consume opening "
    r->p++; r->rem--;
    char* out = (char*)malloc(r->rem + 1);
    size_t olen = 0;
    while (r->rem > 0 && *r->p != '"') {
        if (*r->p == '\\' && r->rem >= 2) {
            r->p++; r->rem--;
            switch (*r->p) {
                case '"':  out[olen++] = '"'; break;
                case '\\': out[olen++] = '\\'; break;
                case 'n':  out[olen++] = '\n'; break;
                case 'r':  out[olen++] = '\r'; break;
                case 't':  out[olen++] = '\t'; break;
                default:   out[olen++] = *r->p; break;
            }
        } else {
            out[olen++] = *r->p;
        }
        r->p++; r->rem--;
    }
    if (r->rem > 0) { r->p++; r->rem--; } // consume closing "
    out[olen] = '\0';
    lua_pushlstring(L, out, olen);
    free(out);
}

static void json_parse_array(lua_State* L, JsonReader* r) {
    r->p++; r->rem--; // consume '['
    lua_newtable(L);
    int idx = 1;
    jr_skip_ws(r);
    while (r->rem > 0 && *r->p != ']') {
        json_parse_value(L, r);
        lua_rawseti(L, -2, idx++);
        jr_skip_ws(r);
        if (r->rem > 0 && *r->p == ',') { r->p++; r->rem--; }
        jr_skip_ws(r);
    }
    if (r->rem > 0) { r->p++; r->rem--; } // consume ']'
}

static void json_parse_value(lua_State* L, JsonReader* r) {
    jr_skip_ws(r);
    if (r->rem == 0) { lua_pushnil(L); return; }
    char c = *r->p;
    if (c == '"') {
        json_parse_string(L, r);
    } else if (c == '[') {
        json_parse_array(L, r);
    } else if (c == 't') {
        lua_pushboolean(L, 1);
        r->p += 4; r->rem -= (r->rem >= 4 ? 4 : r->rem);
    } else if (c == 'f') {
        lua_pushboolean(L, 0);
        r->p += 5; r->rem -= (r->rem >= 5 ? 5 : r->rem);
    } else if (c == 'n') {
        lua_pushnil(L);
        r->p += 4; r->rem -= (r->rem >= 4 ? 4 : r->rem);
    } else if (c == '-' || (c >= '0' && c <= '9')) {
        char* end;
        long long iv = strtoll(r->p, &end, 10);
        if (end > r->p && (*end == ',' || *end == ']' ||
                           *end == '}' || *end == ' ' ||
                           *end == '\0' || *end == '\n')) {
            lua_pushinteger(L, (lua_Integer)iv);
        } else {
            double dv = strtod(r->p, &end);
            lua_pushnumber(L, (lua_Number)dv);
        }
        size_t consumed = (size_t)(end - r->p);
        r->p += consumed; r->rem -= consumed;
    } else {
        lua_pushnil(L);
    }
}

// Push elements of a JSON array [v0, v1, ...] onto the Lua stack.
// Returns number of elements pushed, or -1 on error.
static int json_array_to_lua_stack(lua_State* L, const char* json) {
    if (!json) { lua_pushnil(L); return 1; }
    JsonReader r = { json, strlen(json) };
    jr_skip_ws(&r);
    if (r.rem == 0 || *r.p != '[') {
        // Treat as single value wrapped in array
        json_parse_value(L, &r);
        return 1;
    }
    r.p++; r.rem--; // consume '['
    int count = 0;
    jr_skip_ws(&r);
    while (r.rem > 0 && *r.p != ']') {
        json_parse_value(L, &r);
        count++;
        jr_skip_ws(&r);
        if (r.rem > 0 && *r.p == ',') { r.p++; r.rem--; }
        jr_skip_ws(&r);
    }
    return count;
}

// ─── Public API ─────────────────────────────────────────────────────────────

lua_State* lua_engine_init(void) {
    lua_State* L = luaL_newstate();
    if (!L) return NULL;
    luaL_openlibs(L);
    return L;
}

void lua_engine_destroy(lua_State* L) {
    if (L) lua_close(L);
}

char* lua_engine_execute(lua_State* L, const char* script) {
    int top = lua_gettop(L);

    if (luaL_loadstring(L, script) != LUA_OK) {
        const char* err = lua_tostring(L, -1);
        size_t n = strlen("ERROR:") + strlen(err) + 1;
        char* out = (char*)malloc(n);
        snprintf(out, n, "ERROR:%s", err);
        lua_settop(L, top);
        return out;
    }

    int top_after_load = lua_gettop(L);
    if (lua_pcall(L, 0, LUA_MULTRET, 0) != LUA_OK) {
        const char* err = lua_tostring(L, -1);
        size_t n = strlen("ERROR:") + strlen(err) + 1;
        char* out = (char*)malloc(n);
        snprintf(out, n, "ERROR:%s", err);
        lua_settop(L, top);
        return out;
    }

    int nret = lua_gettop(L) - (top_after_load - 1);
    char* json;
    if (nret > 0) {
        json = stack_top_to_json(L);
    } else {
        json = strdup("null");
    }
    lua_settop(L, top);
    return json;
}

char* lua_engine_load(lua_State* L, const char* script) {
    int top = lua_gettop(L);

    if (luaL_loadstring(L, script) != LUA_OK) {
        const char* err = lua_tostring(L, -1);
        char* out = strdup(err ? err : "compile error");
        lua_settop(L, top);
        return out;
    }

    if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
        const char* err = lua_tostring(L, -1);
        char* out = strdup(err ? err : "runtime error");
        lua_settop(L, top);
        return out;
    }

    return NULL; // success
}

char* lua_engine_call(lua_State* L, const char* func, const char* args_json) {
    int top = lua_gettop(L);

    lua_getglobal(L, func);
    if (!lua_isfunction(L, -1)) {
        lua_settop(L, top);
        const char* msg = "ERROR:function not found";
        return strdup(msg);
    }

    int argc = json_array_to_lua_stack(L, args_json);

    int top_after_args = lua_gettop(L);
    if (lua_pcall(L, argc, LUA_MULTRET, 0) != LUA_OK) {
        const char* err = lua_tostring(L, -1);
        size_t n = strlen("ERROR:") + strlen(err) + 1;
        char* out = (char*)malloc(n);
        snprintf(out, n, "ERROR:%s", err);
        lua_settop(L, top);
        return out;
    }

    int nret = lua_gettop(L) - (top_after_args - argc - 1);
    char* json;
    if (nret > 0) {
        json = stack_top_to_json(L);
    } else {
        json = strdup("null");
    }
    lua_settop(L, top);
    return json;
}
