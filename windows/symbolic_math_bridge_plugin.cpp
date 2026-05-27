// windows/symbolic_math_bridge_plugin.cpp
//
// Flutter Windows plugin glue. `ffiPlugin: true` keeps this minimal —
// the real `flutter_symengine_*` symbols live either in this same DLL
// (CI standalone build) or in a side-loaded `libsymbolic_math_bridge.dll`
// (consumer build with bundled prebuilt), and are reached from Dart via
// `DynamicLibrary.open(...)` rather than a method channel.

#include "include/symbolic_math_bridge/symbolic_math_bridge_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

// SYMBOLIC_MATH_BRIDGE_HAS_FORCE_LINK is defined by CMakeLists in the
// build modes that compile force_link.c alongside this file. The
// force-link function takes the address of every flutter_symengine_*
// symbol so the linker can't dead-code-strip them when the only
// references are runtime dlsym/FFI lookups. In consumer-prebuilt mode
// force_link.c is NOT compiled (the wrapper symbols live in the
// bundled DLL, separately loaded by Dart) so the call would be
// unresolved at link time. Compile the call out in that mode.
#ifdef SYMBOLIC_MATH_BRIDGE_HAS_FORCE_LINK
extern "C" {
int symbolic_math_bridge_force_link_symbols(void);
}
#endif

namespace {

class SymbolicMathBridgePlugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
#ifdef SYMBOLIC_MATH_BRIDGE_HAS_FORCE_LINK
    (void)symbolic_math_bridge_force_link_symbols();
#endif
    // No method channel registration — pure FFI plugin.
  }
};

}  // namespace

void SymbolicMathBridgePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  SymbolicMathBridgePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
