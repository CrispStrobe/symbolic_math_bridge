// windows/symbolic_math_bridge_plugin.cpp
//
// Flutter Windows plugin glue. ffiPlugin: true keeps this minimal —
// the real work happens via `dart:ffi`
// `DynamicLibrary.open('symbolic_math_bridge_plugin.dll')` reaching
// the `flutter_symengine_*` C entry points compiled into the same DLL
// from `../src/flutter_symengine_wrapper.c`.

#include "include/symbolic_math_bridge/symbolic_math_bridge_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

extern "C" {
// Declared in force_link.c. Calling it from Register pins the wrapper
// symbol addresses so the linker can't dead-code-strip them when the
// only references are runtime dlsym/FFI lookups.
int symbolic_math_bridge_force_link_symbols(void);
}

namespace {

class SymbolicMathBridgePlugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar) {
    // No method channel — this is a pure FFI plugin. Calling the
    // force-link function here is the equivalent of iOS's
    // force_all_math_symbols_linking() in the Swift plugin's
    // register(with:) entry point.
    (void)symbolic_math_bridge_force_link_symbols();
  }
};

}  // namespace

void SymbolicMathBridgePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  SymbolicMathBridgePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
