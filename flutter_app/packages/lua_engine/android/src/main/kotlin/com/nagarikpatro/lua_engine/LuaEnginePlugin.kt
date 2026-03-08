package com.nagarikpatro.lua_engine

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

class LuaEnginePlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel

    // Single-threaded executor: Lua is not thread-safe, one thread = no mutex needed
    private val executor = Executors.newSingleThreadExecutor()

    // Lua state pointer (opaque jlong from C)
    private var statePtr: Long = 0L

    companion object {
        init {
            System.loadLibrary("lua_engine")
        }

        @JvmStatic private external fun nativeInit(): Long
        @JvmStatic private external fun nativeDestroy(statePtr: Long)
        @JvmStatic private external fun nativeExecute(statePtr: Long, script: String): Any?
        @JvmStatic private external fun nativeLoad(statePtr: Long, script: String): String?
        @JvmStatic private external fun nativeCall(statePtr: Long, funcName: String, args: Array<Any?>): Any?
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.nagarikpatro/lua")
        channel.setMethodCallHandler(this)
        executor.submit { statePtr = nativeInit() }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        executor.submit {
            if (statePtr != 0L) {
                nativeDestroy(statePtr)
                statePtr = 0L
            }
        }
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "execute" -> {
                val script = call.argument<String>("script")
                    ?: return result.error("INVALID_ARGS", "script is required", null)
                executor.submit {
                    try {
                        val ret = nativeExecute(statePtr, script)
                        if (ret is String && ret.startsWith("ERROR:")) {
                            result.error("LUA_ERROR", ret.removePrefix("ERROR:"), null)
                        } else {
                            result.success(ret)
                        }
                    } catch (e: Exception) {
                        result.error("NATIVE_ERROR", e.message, null)
                    }
                }
            }

            "load" -> {
                val script = call.argument<String>("script")
                    ?: return result.error("INVALID_ARGS", "script is required", null)
                executor.submit {
                    try {
                        val err = nativeLoad(statePtr, script)
                        if (err != null) {
                            result.error("LUA_ERROR", err, null)
                        } else {
                            result.success(null)
                        }
                    } catch (e: Exception) {
                        result.error("NATIVE_ERROR", e.message, null)
                    }
                }
            }

            "call" -> {
                val fn = call.argument<String>("function")
                    ?: return result.error("INVALID_ARGS", "function is required", null)
                val args = call.argument<List<Any?>>("args") ?: emptyList()
                executor.submit {
                    try {
                        val ret = nativeCall(statePtr, fn, args.toTypedArray())
                        if (ret is String && ret.startsWith("ERROR:")) {
                            result.error("LUA_ERROR", ret.removePrefix("ERROR:"), null)
                        } else {
                            result.success(ret)
                        }
                    } catch (e: Exception) {
                        result.error("NATIVE_ERROR", e.message, null)
                    }
                }
            }

            "reset" -> {
                executor.submit {
                    try {
                        if (statePtr != 0L) nativeDestroy(statePtr)
                        statePtr = nativeInit()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("NATIVE_ERROR", e.message, null)
                    }
                }
            }

            else -> result.notImplemented()
        }
    }
}
