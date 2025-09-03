
import 'symbolic_math_bridge_platform_interface.dart';

class SymbolicMathBridge {
  Future<String?> getPlatformVersion() {
    return SymbolicMathBridgePlatform.instance.getPlatformVersion();
  }
}
