import 'package:flutter/material.dart';
import 'package:symbolic_math_bridge/symbolic_math_bridge.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _result = 'Tap button to evaluate';
  final _bridge = SymbolicMathBridge();

  Future<void> _evaluate() async {
    String result;
    try {
      result = _bridge.evaluate('2**10 + 1');
    } on SymbolicMathNotAvailableException {
      result = 'Native library not available on this platform.';
    } on SymbolicMathException catch (e) {
      result = 'Error: ${e.message}';
    }

    if (!mounted) return;
    setState(() {
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Symbolic Math Bridge Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Result: $_result'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _evaluate,
                child: const Text('Evaluate 2^10 + 1'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
