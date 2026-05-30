import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbolic_math_bridge/symbolic_math_bridge_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelSymbolicMathBridge();
  const channel = MethodChannel('symbolic_math_bridge');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion returns mocked value', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
