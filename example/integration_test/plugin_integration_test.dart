// Basic Flutter integration test for symbolic_math_bridge.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:symbolic_math_bridge/symbolic_math_bridge.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('evaluate basic expression', (WidgetTester tester) async {
    final bridge = SymbolicMathBridge();
    try {
      final result = bridge.evaluate('1 + 1');
      expect(result, '2');
    } on SymbolicMathNotAvailableException {
      // Expected on platforms without native library
    }
  });
}
