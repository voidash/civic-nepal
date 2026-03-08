#include <jni.h>
#include <android/log.h>
#include <string>

extern "C" {
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

#define LOG_TAG "LuaEngine"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// ─── Type conversion helpers ────────────────────────────────────────────────

static jobject lua_to_java(JNIEnv* env, lua_State* L, int idx);
static void java_to_lua(JNIEnv* env, lua_State* L, jobject value);

static jobject lua_to_java(JNIEnv* env, lua_State* L, int idx) {
    idx = lua_absindex(L, idx);
    int t = lua_type(L, idx);

    switch (t) {
        case LUA_TNIL:
        case LUA_TNONE:
            return nullptr;

        case LUA_TBOOLEAN: {
            jclass cls = env->FindClass("java/lang/Boolean");
            jmethodID ctor = env->GetStaticMethodID(cls, "valueOf", "(Z)Ljava/lang/Boolean;");
            return env->CallStaticObjectMethod(cls, ctor, (jboolean)lua_toboolean(L, idx));
        }

        case LUA_TNUMBER: {
            if (lua_isinteger(L, idx)) {
                jclass cls = env->FindClass("java/lang/Long");
                jmethodID ctor = env->GetStaticMethodID(cls, "valueOf", "(J)Ljava/lang/Long;");
                return env->CallStaticObjectMethod(cls, ctor, (jlong)lua_tointeger(L, idx));
            } else {
                jclass cls = env->FindClass("java/lang/Double");
                jmethodID ctor = env->GetStaticMethodID(cls, "valueOf", "(D)Ljava/lang/Double;");
                return env->CallStaticObjectMethod(cls, ctor, (jdouble)lua_tonumber(L, idx));
            }
        }

        case LUA_TSTRING: {
            size_t len;
            const char* s = lua_tolstring(L, idx, &len);
            return env->NewStringUTF(s);
        }

        case LUA_TTABLE: {
            // Detect array vs map: check if it's a sequence (keys 1..n with no holes)
            lua_Integer n = (lua_Integer)lua_rawlen(L, idx);
            bool is_array = (n > 0);
            if (is_array) {
                // Verify all integer keys 1..n exist
                for (lua_Integer i = 1; i <= n && is_array; i++) {
                    lua_rawgeti(L, idx, i);
                    if (lua_isnil(L, -1)) is_array = false;
                    lua_pop(L, 1);
                }
            }

            if (is_array) {
                jclass list_cls = env->FindClass("java/util/ArrayList");
                jmethodID list_ctor = env->GetMethodID(list_cls, "<init>", "(I)V");
                jmethodID list_add = env->GetMethodID(list_cls, "add", "(Ljava/lang/Object;)Z");
                jobject list = env->NewObject(list_cls, list_ctor, (jint)n);
                for (lua_Integer i = 1; i <= n; i++) {
                    lua_rawgeti(L, idx, i);
                    jobject elem = lua_to_java(env, L, -1);
                    env->CallBooleanMethod(list, list_add, elem);
                    if (elem) env->DeleteLocalRef(elem);
                    lua_pop(L, 1);
                }
                return list;
            } else {
                jclass map_cls = env->FindClass("java/util/HashMap");
                jmethodID map_ctor = env->GetMethodID(map_cls, "<init>", "()V");
                jmethodID map_put = env->GetMethodID(map_cls, "put",
                    "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
                jobject map = env->NewObject(map_cls, map_ctor);
                lua_pushnil(L);
                while (lua_next(L, idx) != 0) {
                    jobject k = lua_to_java(env, L, -2);
                    jobject v = lua_to_java(env, L, -1);
                    if (k) {
                        env->CallObjectMethod(map, map_put, k, v);
                        env->DeleteLocalRef(k);
                    }
                    if (v) env->DeleteLocalRef(v);
                    lua_pop(L, 1); // pop value, keep key for next
                }
                return map;
            }
        }

        default:
            // functions, userdata, threads → null
            return nullptr;
    }
}

static void java_to_lua(JNIEnv* env, lua_State* L, jobject value) {
    if (value == nullptr) {
        lua_pushnil(L);
        return;
    }

    // Boolean
    jclass bool_cls = env->FindClass("java/lang/Boolean");
    if (env->IsInstanceOf(value, bool_cls)) {
        jmethodID bval = env->GetMethodID(bool_cls, "booleanValue", "()Z");
        lua_pushboolean(L, (int)env->CallBooleanMethod(value, bval));
        return;
    }

    // Integer / Long
    jclass int_cls = env->FindClass("java/lang/Integer");
    jclass long_cls = env->FindClass("java/lang/Long");
    if (env->IsInstanceOf(value, long_cls)) {
        jmethodID lval = env->GetMethodID(long_cls, "longValue", "()J");
        lua_pushinteger(L, (lua_Integer)env->CallLongMethod(value, lval));
        return;
    }
    if (env->IsInstanceOf(value, int_cls)) {
        jmethodID ival = env->GetMethodID(int_cls, "intValue", "()I");
        lua_pushinteger(L, (lua_Integer)env->CallIntMethod(value, ival));
        return;
    }

    // Double / Float
    jclass double_cls = env->FindClass("java/lang/Double");
    jclass float_cls = env->FindClass("java/lang/Float");
    if (env->IsInstanceOf(value, double_cls)) {
        jmethodID dval = env->GetMethodID(double_cls, "doubleValue", "()D");
        lua_pushnumber(L, (lua_Number)env->CallDoubleMethod(value, dval));
        return;
    }
    if (env->IsInstanceOf(value, float_cls)) {
        jmethodID fval = env->GetMethodID(float_cls, "floatValue", "()F");
        lua_pushnumber(L, (lua_Number)env->CallFloatMethod(value, fval));
        return;
    }

    // String
    jclass str_cls = env->FindClass("java/lang/String");
    if (env->IsInstanceOf(value, str_cls)) {
        const char* s = env->GetStringUTFChars((jstring)value, nullptr);
        lua_pushstring(L, s);
        env->ReleaseStringUTFChars((jstring)value, s);
        return;
    }

    // List → array table
    jclass list_cls = env->FindClass("java/util/List");
    if (env->IsInstanceOf(value, list_cls)) {
        jmethodID size_m = env->GetMethodID(list_cls, "size", "()I");
        jmethodID get_m = env->GetMethodID(list_cls, "get", "(I)Ljava/lang/Object;");
        jint sz = env->CallIntMethod(value, size_m);
        lua_createtable(L, (int)sz, 0);
        for (jint i = 0; i < sz; i++) {
            jobject elem = env->CallObjectMethod(value, get_m, i);
            java_to_lua(env, L, elem);
            lua_rawseti(L, -2, i + 1);
            if (elem) env->DeleteLocalRef(elem);
        }
        return;
    }

    // Map → dict table
    jclass map_cls = env->FindClass("java/util/Map");
    if (env->IsInstanceOf(value, map_cls)) {
        jmethodID entryset_m = env->GetMethodID(map_cls, "entrySet", "()Ljava/util/Set;");
        jclass set_cls = env->FindClass("java/util/Set");
        jmethodID iter_m = env->GetMethodID(set_cls, "iterator", "()Ljava/util/Iterator;");
        jclass iter_cls = env->FindClass("java/util/Iterator");
        jmethodID has_next_m = env->GetMethodID(iter_cls, "hasNext", "()Z");
        jmethodID next_m = env->GetMethodID(iter_cls, "next", "()Ljava/lang/Object;");
        jclass entry_cls = env->FindClass("java/util/Map$Entry");
        jmethodID get_key_m = env->GetMethodID(entry_cls, "getKey", "()Ljava/lang/Object;");
        jmethodID get_val_m = env->GetMethodID(entry_cls, "getValue", "()Ljava/lang/Object;");

        lua_createtable(L, 0, 8);
        jobject entry_set = env->CallObjectMethod(value, entryset_m);
        jobject iter = env->CallObjectMethod(entry_set, iter_m);
        while (env->CallBooleanMethod(iter, has_next_m)) {
            jobject entry = env->CallObjectMethod(iter, next_m);
            jobject k = env->CallObjectMethod(entry, get_key_m);
            jobject v = env->CallObjectMethod(entry, get_val_m);
            java_to_lua(env, L, k);
            java_to_lua(env, L, v);
            lua_rawset(L, -3);
            if (k) env->DeleteLocalRef(k);
            if (v) env->DeleteLocalRef(v);
            env->DeleteLocalRef(entry);
        }
        env->DeleteLocalRef(iter);
        env->DeleteLocalRef(entry_set);
        return;
    }

    // Fallback
    lua_pushnil(L);
}

// ─── JNI exports ────────────────────────────────────────────────────────────

extern "C" {

JNIEXPORT jlong JNICALL
Java_com_nagarikpatro_lua_1engine_LuaEnginePlugin_nativeInit(JNIEnv* env, jclass cls) {
    lua_State* L = luaL_newstate();
    if (!L) return 0;
    luaL_openlibs(L);
    LOGD("Lua state created: %p", (void*)L);
    return (jlong)(intptr_t)L;
}

JNIEXPORT void JNICALL
Java_com_nagarikpatro_lua_1engine_LuaEnginePlugin_nativeDestroy(JNIEnv* env, jclass cls, jlong statePtr) {
    lua_State* L = (lua_State*)(intptr_t)statePtr;
    if (L) {
        lua_close(L);
        LOGD("Lua state closed");
    }
}

JNIEXPORT jobject JNICALL
Java_com_nagarikpatro_lua_1engine_LuaEnginePlugin_nativeExecute(JNIEnv* env, jclass cls,
                                                                  jlong statePtr, jstring script) {
    lua_State* L = (lua_State*)(intptr_t)statePtr;
    const char* code = env->GetStringUTFChars(script, nullptr);

    int load_status = luaL_loadstring(L, code);
    env->ReleaseStringUTFChars(script, code);

    if (load_status != LUA_OK) {
        const char* err = lua_tostring(L, -1);
        std::string msg = err ? err : "Unknown compile error";
        lua_pop(L, 1);
        // Signal error by returning a special marker — handled in Kotlin
        // Actually throw via setting a flag. Use a workaround: return jstring with "ERROR:" prefix
        std::string error_str = "ERROR:" + msg;
        return env->NewStringUTF(error_str.c_str());
    }

    int top_before = lua_gettop(L) - 1; // -1 for the function we just pushed
    int call_status = lua_pcall(L, 0, LUA_MULTRET, 0);

    if (call_status != LUA_OK) {
        const char* err = lua_tostring(L, -1);
        std::string msg = err ? err : "Unknown runtime error";
        lua_settop(L, top_before);
        std::string error_str = "ERROR:" + msg;
        return env->NewStringUTF(error_str.c_str());
    }

    int nresults = lua_gettop(L) - top_before;
    jobject result = nullptr;
    if (nresults > 0) {
        result = lua_to_java(env, L, -1);
        lua_settop(L, top_before);
    }
    return result;
}

JNIEXPORT jstring JNICALL
Java_com_nagarikpatro_lua_1engine_LuaEnginePlugin_nativeLoad(JNIEnv* env, jclass cls,
                                                               jlong statePtr, jstring script) {
    lua_State* L = (lua_State*)(intptr_t)statePtr;
    const char* code = env->GetStringUTFChars(script, nullptr);

    int load_status = luaL_loadstring(L, code);
    env->ReleaseStringUTFChars(script, code);

    if (load_status != LUA_OK) {
        const char* err = lua_tostring(L, -1);
        std::string msg = err ? err : "Unknown compile error";
        lua_pop(L, 1);
        return env->NewStringUTF(msg.c_str());
    }

    int call_status = lua_pcall(L, 0, 0, 0);
    if (call_status != LUA_OK) {
        const char* err = lua_tostring(L, -1);
        std::string msg = err ? err : "Unknown runtime error";
        lua_pop(L, 1);
        return env->NewStringUTF(msg.c_str());
    }

    return nullptr; // null = success
}

JNIEXPORT jobject JNICALL
Java_com_nagarikpatro_lua_1engine_LuaEnginePlugin_nativeCall(JNIEnv* env, jclass cls,
                                                               jlong statePtr,
                                                               jstring funcName,
                                                               jobjectArray args) {
    lua_State* L = (lua_State*)(intptr_t)statePtr;
    const char* fn = env->GetStringUTFChars(funcName, nullptr);

    lua_getglobal(L, fn);
    env->ReleaseStringUTFChars(funcName, fn);

    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 1);
        std::string error_str = "ERROR:function not found";
        return env->NewStringUTF(error_str.c_str());
    }

    jint argc = args ? env->GetArrayLength(args) : 0;
    for (jint i = 0; i < argc; i++) {
        jobject arg = env->GetObjectArrayElement(args, i);
        java_to_lua(env, L, arg);
        if (arg) env->DeleteLocalRef(arg);
    }

    int top_before = lua_gettop(L) - 1 - argc; // base before function + args
    int call_status = lua_pcall(L, argc, LUA_MULTRET, 0);
    if (call_status != LUA_OK) {
        const char* err = lua_tostring(L, -1);
        std::string msg = err ? err : "Unknown runtime error";
        lua_settop(L, top_before);
        std::string error_str = "ERROR:" + msg;
        return env->NewStringUTF(error_str.c_str());
    }

    int nresults = lua_gettop(L) - top_before;
    jobject result = nullptr;
    if (nresults > 0) {
        result = lua_to_java(env, L, -1);
        lua_settop(L, top_before);
    }
    return result;
}

} // extern "C"
