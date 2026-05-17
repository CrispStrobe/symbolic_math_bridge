import Cocoa
import FlutterMacOS

// macOS counterpart of the iOS plugin class. Same name as the iOS class so
// `pluginClass: SwiftSymbolicMathBridgePlugin` in the bridge's pubspec.yaml
// resolves on both platforms. The class is mostly a placeholder — the real
// work is done over `dart:ffi`, which loads symbols from the linked native
// library directly.

public class SwiftSymbolicMathBridgePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "symbolic_math_bridge",
      binaryMessenger: registrar.messenger
    )
    let instance = SwiftSymbolicMathBridgePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
