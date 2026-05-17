import Cocoa
import FlutterMacOS

// macOS counterpart of the iOS plugin class. Same name as the iOS class so
// `pluginClass: SwiftSymbolicMathBridgePlugin` in the bridge's pubspec.yaml
// resolves on both platforms.
//
// The `force_all_math_symbols_linking()` call is the load-bearing line — it
// pulls in SymEngineBridge.m's translation unit so its `+load` method runs and
// the linker keeps every flutter_symengine_* C symbol. Without it, release
// builds drop the wrapper and dart:ffi calls fail. Mirrors the iOS plugin.

@_silgen_name("force_all_math_symbols_linking")
func force_all_math_symbols_linking()

public class SwiftSymbolicMathBridgePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    force_all_math_symbols_linking()

    let channel = FlutterMethodChannel(
      name: "symbolic_math_bridge",
      binaryMessenger: registrar.messenger
    )
    let instance = SwiftSymbolicMathBridgePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    print("[SYMBOLIC_MATH] Plugin registered and symbol linking forced")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "testSymbolAccess":
      testSymbolAccess(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func testSymbolAccess(result: @escaping FlutterResult) {
    let handle = dlopen(nil, RTLD_LAZY)

    let gmpSymbol = dlsym(handle, "__gmpz_init_set_str")
    let mpfrSymbol = dlsym(handle, "mpfr_init2")
    let mpcSymbol = dlsym(handle, "mpc_init2")
    let flintSymbol = dlsym(handle, "fmpz_init")
    let symengineSymbol = dlsym(handle, "flutter_symengine_evaluate")

    var symbolStatus: [String: Bool] = [:]
    symbolStatus["gmp_init_set_str"] = (gmpSymbol != nil)
    symbolStatus["mpfr_init2"] = (mpfrSymbol != nil)
    symbolStatus["mpc_init2"] = (mpcSymbol != nil)
    symbolStatus["fmpz_init"] = (flintSymbol != nil)
    symbolStatus["flutter_symengine_evaluate"] = (symengineSymbol != nil)

    print("[SYMBOLIC_MATH] Symbol availability test:")
    for (symbol, available) in symbolStatus {
      print("  \(symbol): \(available ? "OK" : "MISSING")")
    }

    result(symbolStatus)
  }
}
