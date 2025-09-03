import 'package:flutter_test/flutter_test.dart';
import 'package:symbolic_math_bridge/symbolic_math_bridge.dart';
import 'package:symbolic_math_bridge/symbolic_math_bridge_platform_interface.dart';
import 'package:symbolic_math_bridge/symbolic_math_bridge_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSymbolicMathBridgePlatform
    with MockPlatformInterfaceMixin
    implements SymbolicMathBridgePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SymbolicMathBridgePlatform initialPlatform = SymbolicMathBridgePlatform.instance;

  test('$MethodChannelSymbolicMathBridge is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSymbolicMathBridge>());
  });

  test('getPlatformVersion', () async {
    SymbolicMathBridge symbolicMathBridgePlugin = SymbolicMathBridge();
    MockSymbolicMathBridgePlatform fakePlatform = MockSymbolicMathBridgePlatform();
    SymbolicMathBridgePlatform.instance = fakePlatform;

    expect(await symbolicMathBridgePlugin.getPlatformVersion(), '42');
  });
}
