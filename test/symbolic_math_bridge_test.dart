import 'package:flutter_test/flutter_test.dart';
import 'package:symbolic_math_bridge/symbolic_math_bridge.dart';
import 'package:symbolic_math_bridge/symbolic_math_bridge_platform_interface.dart';
import 'package:symbolic_math_bridge/symbolic_math_bridge_method_channel.dart';

void main() {
  final SymbolicMathBridgePlatform initialPlatform =
      SymbolicMathBridgePlatform.instance;

  test('MethodChannelSymbolicMathBridge is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSymbolicMathBridge>());
  });

  test('SymbolicMathBridge singleton returns same instance', () {
    try {
      final a = SymbolicMathBridge();
      final b = SymbolicMathBridge();
      expect(identical(a, b), isTrue);
    } on ArgumentError {
      // Expected on CI: native library not available
    }
  });

  test('SymbolicMathException stores operation and message', () {
    final e = SymbolicMathException('evaluate', 'parse error');
    expect(e.operation, 'evaluate');
    expect(e.message, 'parse error');
    expect(e.toString(), contains('evaluate'));
    expect(e.toString(), contains('parse error'));
  });

  test('SymbolicMathParseException is a SymbolicMathException', () {
    final e = SymbolicMathParseException('evaluate', 'bad input');
    expect(e, isA<SymbolicMathException>());
    expect(e.operation, 'evaluate');
  });

  test('SymbolicMathMemoryException is a SymbolicMathException', () {
    final e = SymbolicMathMemoryException('matrix');
    expect(e, isA<SymbolicMathException>());
    expect(e.message, contains('Memory'));
  });

  test('SymbolicMathNotAvailableException is a SymbolicMathException', () {
    final e = SymbolicMathNotAvailableException('symengine');
    expect(e, isA<SymbolicMathException>());
    expect(e.message, contains('not available'));
  });
}
