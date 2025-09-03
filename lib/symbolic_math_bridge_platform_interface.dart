import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'symbolic_math_bridge_method_channel.dart';

abstract class SymbolicMathBridgePlatform extends PlatformInterface {
  /// Constructs a SymbolicMathBridgePlatform.
  SymbolicMathBridgePlatform() : super(token: _token);

  static final Object _token = Object();

  static SymbolicMathBridgePlatform _instance = MethodChannelSymbolicMathBridge();

  /// The default instance of [SymbolicMathBridgePlatform] to use.
  ///
  /// Defaults to [MethodChannelSymbolicMathBridge].
  static SymbolicMathBridgePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SymbolicMathBridgePlatform] when
  /// they register themselves.
  static set instance(SymbolicMathBridgePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
