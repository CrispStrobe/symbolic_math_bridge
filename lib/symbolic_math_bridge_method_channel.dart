import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'symbolic_math_bridge_platform_interface.dart';

/// An implementation of [SymbolicMathBridgePlatform] that uses method channels.
class MethodChannelSymbolicMathBridge extends SymbolicMathBridgePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('symbolic_math_bridge');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
