import Flutter
import UIKit

// Declare the C function from SymEngineBridge.m
@_silgen_name("force_all_math_symbols_linking")
func force_all_math_symbols_linking()

public class SwiftSymbolicMathBridgePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Force all math library symbols to be linked and available for dlsym()
        // This calls the function that ensures SymEngineBridge +load method runs
        force_all_math_symbols_linking()
        
        // Set up method channel for Flutter-to-native communication
        let channel = FlutterMethodChannel(name: "symbolic_math_bridge", binaryMessenger: registrar.messenger())
        let instance = SwiftSymbolicMathBridgePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        print("[SYMBOLIC_MATH] Plugin registered and symbol linking forced")
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "testSymbolAccess":
            // Test if symbols are accessible for debugging
            testSymbolAccess(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func testSymbolAccess(result: @escaping FlutterResult) {
        // Test if we can find the key symbols that were failing
        let handle = dlopen(nil, RTLD_LAZY)
        
        // Test the problematic GMP symbol that was failing before
        let gmpSymbol = dlsym(handle, "__gmpz_init_set_str")
        let mpfrSymbol = dlsym(handle, "mpfr_init2")
        let mpcSymbol = dlsym(handle, "mpc_init2") 
        let flintSymbol = dlsym(handle, "fmpz_init")
        let symengineSymbol = dlsym(handle, "flutter_symengine_evaluate") // Corrected symbol name
        
        var symbolStatus: [String: Bool] = [:]
        symbolStatus["gmp_init_set_str"] = (gmpSymbol != nil)
        symbolStatus["mpfr_init2"] = (mpfrSymbol != nil)
        symbolStatus["mpc_init2"] = (mpcSymbol != nil)
        symbolStatus["fmpz_init"] = (flintSymbol != nil) 
        symbolStatus["flutter_symengine_evaluate"] = (symengineSymbol != nil) // Corrected key
        
        print("[SYMBOLIC_MATH] Symbol availability test:")
        for (symbol, available) in symbolStatus {
            print("  \(symbol): \(available ? "✅" : "❌")")
        }
        
        let allAvailable = symbolStatus.values.allSatisfy { $0 }
        print("[SYMBOLIC_MATH] Overall status: \(allAvailable ? "✅ ALL SYMBOLS AVAILABLE" : "❌ SOME SYMBOLS MISSING")")
        
        result(symbolStatus)
    }
}