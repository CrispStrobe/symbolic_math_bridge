// windows/include/symbolic_math_bridge/symbolic_math_bridge_plugin_c_api.h
//
// Public C ABI of the Flutter Windows plugin module. Flutter's
// auto-generated plugin registrant calls these on plugin attach;
// the body lives in `windows/symbolic_math_bridge_plugin.cpp`.

#ifndef FLUTTER_PLUGIN_SYMBOLIC_MATH_BRIDGE_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_SYMBOLIC_MATH_BRIDGE_PLUGIN_C_API_H_

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void SymbolicMathBridgePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_SYMBOLIC_MATH_BRIDGE_PLUGIN_C_API_H_
