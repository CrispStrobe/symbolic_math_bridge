// android/src/main/kotlin/be/crispstro/symbolic_math_bridge/SymbolicMathBridgePlugin.kt
//
// R132 scaffold — Flutter plugin glue for Android.
//
// The Dart side reaches the native symbols via dart:ffi
// `DynamicLibrary.open("libsymbolic_math_bridge.so")`. This Kotlin class
// does two jobs:
//
//   1. System.loadLibrary triggers the .so load *before* dart:ffi tries.
//      Without this, the first FFI call would race the load and
//      sometimes report "symbol not found" on a cold launch.
//
//   2. Calls forceLinkSymbols() — an external C function whose only
//      purpose is to take addresses of every flutter_symengine_*
//      entry point so the static linker keeps them around. Same trick
//      as iOS's `force_all_math_symbols_linking()`; without it the
//      linker would happily drop wrapper symbols that are only ever
//      reached via dlsym.

package be.crispstro.symbolic_math_bridge

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin

class SymbolicMathBridgePlugin : FlutterPlugin {

    private external fun forceLinkSymbols(): Int

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        try {
            System.loadLibrary("symbolic_math_bridge")
            val ret = forceLinkSymbols()
            android.util.Log.i(
                "symbolic_math_bridge",
                "Native library loaded, force-link returned $ret"
            )
        } catch (t: Throwable) {
            // Don't crash the host app — the bridge falls through to its
            // "unavailable" path the same way Linux / Windows builds do
            // today. The Dart side already handles missing symbols.
            android.util.Log.w(
                "symbolic_math_bridge",
                "Native library load failed; FFI calls will return errors",
                t
            )
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // No-op. The .so stays loaded for the process lifetime.
    }
}
