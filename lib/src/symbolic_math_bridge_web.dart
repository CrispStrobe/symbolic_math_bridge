// Web implementation of the symbolic-math bridge via WASM + dart:js_interop.
//
// Two-phase loading:
//   1. Before the WASM module is ready, the constructor throws
//      SymbolicMathNotAvailableException — same as the old throw-only
//      stub. Consumers set their "native unavailable" flag and route to
//      pure-Dart fallbacks.
//   2. After `SymbolicMathBridge.loadWasm()` completes, the constructor
//      succeeds and every method delegates to SymEngine via ccall.
//
// The Emscripten-generated symengine.js must be loaded via a <script> tag
// in web/index.html before Flutter boots. It defines SymEngineModule as a
// factory function that fetches + compiles symengine.wasm and resolves a
// promise with the module instance. The loader script in index.html calls
// the factory and sets window.symEngineInstance to the resolved module.
//
// Selected by the conditional export in `symbolic_math_bridge.dart` when
// `dart.library.io` is absent (dart2js and dart2wasm).

import 'dart:js_interop';

import 'symbolic_math_exceptions.dart';

// ---------------------------------------------------------------------------
// JS interop bindings
// ---------------------------------------------------------------------------

@JS('symEngineInstance')
external JSObject? get _jsModule;

@JS('symEngineReady')
external bool get _jsReady;

/// Call a WASM C function that returns a string.
/// Emscripten ccall with returnType='string' handles UTF8 decoding
/// and calls _free on the C-allocated result automatically.
String _ccall1(JSObject m, String fn, String arg) {
  final result = m.callMethod<JSString>(
    'ccall'.toJS,
    fn.toJS,
    'string'.toJS,
    ['string'].jsify(),
    [arg].jsify(),
  );
  return result.toDart;
}

String _ccall2(JSObject m, String fn, String a, String b) {
  final result = m.callMethod<JSString>(
    'ccall'.toJS,
    fn.toJS,
    'string'.toJS,
    ['string', 'string'].jsify(),
    [a, b].jsify(),
  );
  return result.toDart;
}

String _ccall3(JSObject m, String fn, String a, String b, String c) {
  final result = m.callMethod<JSString>(
    'ccall'.toJS,
    fn.toJS,
    'string'.toJS,
    ['string', 'string', 'string'].jsify(),
    [a, b, c].jsify(),
  );
  return result.toDart;
}

String _ccall0(JSObject m, String fn) {
  final result = m.callMethod<JSString>(
    'ccall'.toJS,
    fn.toJS,
    'string'.toJS,
    <String>[].jsify(),
    <String>[].jsify(),
  );
  return result.toDart;
}

String _ccallInt(JSObject m, String fn, int arg) {
  final result = m.callMethod<JSString>(
    'ccall'.toJS,
    fn.toJS,
    'string'.toJS,
    ['number'].jsify(),
    [arg].jsify(),
  );
  return result.toDart;
}

String _ccallIntStr(JSObject m, String fn, int a, String b) {
  final result = m.callMethod<JSString>(
    'ccall'.toJS,
    fn.toJS,
    'string'.toJS,
    ['number', 'string'].jsify(),
    [a, b].jsify(),
  );
  return result.toDart;
}

String _ccallStrInt(JSObject m, String fn, String a, int b) {
  final result = m.callMethod<JSString>(
    'ccall'.toJS,
    fn.toJS,
    'string'.toJS,
    ['string', 'number'].jsify(),
    [a, b].jsify(),
  );
  return result.toDart;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Never _unavailable(String op) =>
    throw SymbolicMathNotAvailableException(
      'SymEngine WASM not loaded: $op',
    );

void _checkError(String result, String op) {
  if (result.startsWith('Error in $op:') || result.startsWith('Error')) {
    throw SymbolicMathException(op, result);
  }
}

// ---------------------------------------------------------------------------
// Matrix (WASM-backed, uses opaque pointer-as-int handle)
// ---------------------------------------------------------------------------

class SymEngineMatrix {
  final int _ptr;
  final SymbolicMathBridge _bridge;
  final int _rows;
  final int _cols;
  bool _disposed = false;

  SymEngineMatrix._(this._ptr, this._bridge, this._rows, this._cols);

  int get rows => _rows;
  int get cols => _cols;

  void _check() {
    if (_disposed) {
      throw SymbolicMathException('matrix', 'Matrix has been disposed');
    }
  }

  void dispose() {
    if (!_disposed) {
      final m = _bridge._module;
      m.callMethod<JSAny?>(
        'ccall'.toJS,
        'flutter_symengine_matrix_free'.toJS,
        'null'.toJS, // void return
        ['number'].jsify(),
        [_ptr].jsify(),
      );
      _disposed = true;
    }
  }

  void set(int row, int col, String value) {
    _check();
    final m = _bridge._module;
    final result = m.callMethod<JSNumber>(
      'ccall'.toJS,
      'flutter_symengine_matrix_set_element'.toJS,
      'number'.toJS,
      ['number', 'number', 'number', 'string'].jsify(),
      [_ptr, row, col, value].jsify(),
    );
    if (result.toDartInt != 0) {
      throw SymbolicMathException(
        'matrix_set',
        'Failed to set element at ($row, $col)',
      );
    }
  }

  String get(int row, int col) {
    _check();
    final m = _bridge._module;
    final result = m.callMethod<JSString>(
      'ccall'.toJS,
      'flutter_symengine_matrix_get_element'.toJS,
      'string'.toJS,
      ['number', 'number', 'number'].jsify(),
      [_ptr, row, col].jsify(),
    );
    final s = result.toDart;
    _checkError(s, 'matrix_get');
    return s;
  }

  String getDeterminant() {
    _check();
    final m = _bridge._module;
    final result = m.callMethod<JSString>(
      'ccall'.toJS,
      'flutter_symengine_matrix_det'.toJS,
      'string'.toJS,
      ['number'].jsify(),
      [_ptr].jsify(),
    );
    final s = result.toDart;
    _checkError(s, 'matrix_det');
    return s;
  }

  SymEngineMatrix inverse() {
    _check();
    final m = _bridge._module;
    final resultPtr = m.callMethod<JSNumber>(
      'ccall'.toJS,
      'flutter_symengine_matrix_inv'.toJS,
      'number'.toJS,
      ['number'].jsify(),
      [_ptr].jsify(),
    );
    final p = resultPtr.toDartInt;
    if (p == 0) {
      throw SymbolicMathException('matrix_inv', 'Matrix inversion failed');
    }
    return SymEngineMatrix._(p, _bridge, _rows, _cols);
  }

  SymEngineMatrix operator +(SymEngineMatrix other) {
    _check();
    other._check();
    final m = _bridge._module;
    final resultPtr = m.callMethod<JSNumber>(
      'ccall'.toJS,
      'flutter_symengine_matrix_add'.toJS,
      'number'.toJS,
      ['number', 'number'].jsify(),
      [_ptr, other._ptr].jsify(),
    );
    final p = resultPtr.toDartInt;
    if (p == 0) {
      throw SymbolicMathException('matrix_add', 'Matrix addition failed');
    }
    return SymEngineMatrix._(p, _bridge, _rows, _cols);
  }

  SymEngineMatrix operator *(SymEngineMatrix other) {
    _check();
    other._check();
    final m = _bridge._module;
    final resultPtr = m.callMethod<JSNumber>(
      'ccall'.toJS,
      'flutter_symengine_matrix_mul'.toJS,
      'number'.toJS,
      ['number', 'number'].jsify(),
      [_ptr, other._ptr].jsify(),
    );
    final p = resultPtr.toDartInt;
    if (p == 0) {
      throw SymbolicMathException('matrix_mul', 'Matrix multiplication failed');
    }
    return SymEngineMatrix._(p, _bridge, _rows, other._cols);
  }

  @override
  String toString() {
    if (_disposed) return 'SymEngineMatrix(disposed)';
    final m = _bridge._module;
    final result = m.callMethod<JSString>(
      'ccall'.toJS,
      'flutter_symengine_matrix_to_string'.toJS,
      'string'.toJS,
      ['number'].jsify(),
      [_ptr].jsify(),
    );
    return result.toDart;
  }
}

// ---------------------------------------------------------------------------
// Main bridge class
// ---------------------------------------------------------------------------

class SymbolicMathBridge {
  static bool _wasmLoaded = false;

  /// The resolved Emscripten module instance. Non-null after [loadWasm].
  late final JSObject _module;

  SymbolicMathBridge() {
    if (!_wasmLoaded) {
      // WASM not ready yet — check if JS-side loaded it while we weren't
      // looking (e.g. the <script> in index.html resolved before Dart init).
      if (_jsReady && _jsModule != null) {
        _wasmLoaded = true;
      } else {
        throw SymbolicMathNotAvailableException('SymEngine (web build)');
      }
    }
    _module = _jsModule!;
  }

  /// Attempt to acquire the WASM module from the JS global.
  /// Call this after the Emscripten factory promise has resolved.
  /// Returns true if the module is ready, false otherwise.
  static bool tryLoadWasm() {
    if (_wasmLoaded) return true;
    if (_jsReady && _jsModule != null) {
      _wasmLoaded = true;
      return true;
    }
    return false;
  }

  /// Whether the WASM module has been loaded.
  static bool get isWasmLoaded => _wasmLoaded;

  // ---------- Helpers ----------

  String _call1(String fn, String arg) {
    final r = _ccall1(_module, fn, arg);
    _checkError(r, fn);
    return r;
  }

  String _call2(String fn, String a, String b) {
    final r = _ccall2(_module, fn, a, b);
    _checkError(r, fn);
    return r;
  }

  String _call3(String fn, String a, String b, String c) {
    final r = _ccall3(_module, fn, a, b, c);
    _checkError(r, fn);
    return r;
  }

  // ---------- Core symbolic operations ----------

  bool get hasIntegrate => true; // symbol exists (returns error, but callable)

  bool isValidExpression(String expression) {
    if (expression.trim().isEmpty) return false;
    int parenCount = 0;
    for (int i = 0; i < expression.length; i++) {
      if (expression[i] == '(') parenCount++;
      if (expression[i] == ')') parenCount--;
      if (parenCount < 0) return false;
    }
    return parenCount == 0;
  }

  String evaluate(String expression) =>
      _call1('flutter_symengine_evaluate', expression);

  String expand(String expression) =>
      _call1('flutter_symengine_expand', expression);

  String simplify(String expression) =>
      _call1('flutter_symengine_simplify', expression);

  String factor(String expression) =>
      _call1('flutter_symengine_factor', expression);

  String solve(String expression, String symbol) =>
      _call2('flutter_symengine_solve', expression, symbol);

  String differentiate(String expression, String symbol) =>
      _call2('flutter_symengine_differentiate', expression, symbol);

  String integrate(String expression, String symbol) =>
      _call2('flutter_symengine_integrate', expression, symbol);

  String substitute(String expression, String symbol, String value) =>
      _call3('flutter_symengine_substitute', expression, symbol, value);

  // ---------- Mathematical functions ----------

  static const _unaryFuncNames = [
    'abs', 'sin', 'cos', 'tan', 'asin', 'acos', 'atan',
    'sinh', 'cosh', 'tanh', 'asinh', 'acosh', 'atanh',
    'exp', 'log', 'sqrt', 'gamma',
  ];

  String callUnary(String funcName, String expression) {
    if (!_unaryFuncNames.contains(funcName)) {
      throw ArgumentError('Unknown unary function: $funcName');
    }
    return _call1('flutter_symengine_$funcName', expression);
  }

  String callBinary(String funcName, String expr1, String expr2) {
    throw ArgumentError('Unknown binary function: $funcName');
  }

  // ---------- Number theory ----------

  String gcd(String a, String b) =>
      _call2('flutter_symengine_gcd', a, b);

  String lcm(String a, String b) =>
      _call2('flutter_symengine_lcm', a, b);

  String factorial(int n) {
    final r = _ccallInt(_module, 'flutter_symengine_factorial', n);
    _checkError(r, 'factorial');
    return r;
  }

  String fibonacci(int n) {
    final r = _ccallInt(_module, 'flutter_symengine_fibonacci', n);
    _checkError(r, 'fibonacci');
    return r;
  }

  // ---------- Constants ----------

  String getPi() => _ccall0(_module, 'flutter_symengine_get_pi');
  String getE() => _ccall0(_module, 'flutter_symengine_get_e');
  String getEulerGamma() =>
      _ccall0(_module, 'flutter_symengine_get_euler_gamma');

  String getConstant(String name) {
    switch (name.toUpperCase()) {
      case 'PI':
        return getPi();
      case 'E':
        return getE();
      case 'GAMMA':
        return getEulerGamma();
      default:
        throw ArgumentError('Unknown constant: $name');
    }
  }

  // ---------- Matrix operations ----------

  SymEngineMatrix createMatrix(int rows, int cols) {
    if (rows <= 0 || cols <= 0) {
      throw SymbolicMathException(
        'matrix_create',
        'Dimensions must be positive',
      );
    }
    final ptr = _module.callMethod<JSNumber>(
      'ccall'.toJS,
      'flutter_symengine_matrix_new'.toJS,
      'number'.toJS,
      ['number', 'number'].jsify(),
      [rows, cols].jsify(),
    );
    final p = ptr.toDartInt;
    if (p == 0) {
      throw SymbolicMathException('matrix_create', 'allocation failed');
    }
    return SymEngineMatrix._(p, this, rows, cols);
  }

  // ---------- Utility ----------

  String getVersion() => _ccall0(_module, 'flutter_symengine_version');
  String testBasicOperations() =>
      _ccall0(_module, 'flutter_symengine_test_basic_operations');
  String testSymbolic() =>
      _ccall0(_module, 'flutter_symengine_test_symbolic');
  String getPreferredWrapperType() => 'SymEngine WASM (boostmp)';

  List<String> getAvailableUnaryFunctions() => List.of(_unaryFuncNames);
  List<String> getAvailableBinaryFunctions() => const [];
  List<String> getAvailableConstants() => const ['PI', 'E', 'GAMMA'];

  // ---------- High-precision (stubbed — no MPFR in WASM build) ----------

  String evaluateWithPrecision(String expression, int precision) =>
      throw SymbolicMathNotAvailableException(
        'High-precision evaluation (requires MPFR, not available in web build)',
      );

  String gmpPower(String base, int exponent) =>
      throw SymbolicMathNotAvailableException(
        'GMP power (not available in web build)',
      );

  String mpfrHighPrecisionPi(int precision) {
    final r = _ccallInt(_module, 'flutter_symengine_pi_with_precision', precision);
    _checkError(r, 'pi_with_precision');
    return r;
  }

  String mpfrHighPrecisionE(int precision) {
    final r = _ccallInt(_module, 'flutter_symengine_e_with_precision', precision);
    _checkError(r, 'e_with_precision');
    return r;
  }

  String mpfrHighPrecisionEulerGamma(int precision) {
    final r = _ccallInt(
      _module,
      'flutter_symengine_euler_gamma_with_precision',
      precision,
    );
    _checkError(r, 'euler_gamma_with_precision');
    return r;
  }

  String mpfrHighPrecisionSqrt2(int precision) {
    final r = _ccallInt(
      _module,
      'flutter_symengine_sqrt2_with_precision',
      precision,
    );
    _checkError(r, 'sqrt2_with_precision');
    return r;
  }

  String mpfrEvalf(String expression, int precision) {
    final r = _ccallStrInt(
      _module,
      'flutter_symengine_evalf_with_precision',
      expression,
      precision,
    );
    _checkError(r, 'evalf_with_precision');
    return r;
  }

  String mpfrCevalf(String expression, int precision) {
    final r = _ccallStrInt(
      _module,
      'flutter_symengine_cevalf_with_precision',
      expression,
      precision,
    );
    _checkError(r, 'cevalf_with_precision');
    return r;
  }

  String mpfrBesselJ(int order, String x) {
    final r = _ccallIntStr(
      _module,
      'flutter_symengine_besselj',
      order,
      x,
    );
    _checkError(r, 'besselj');
    return r;
  }

  String mpfrBesselY(int order, String x) {
    final r = _ccallIntStr(
      _module,
      'flutter_symengine_bessely',
      order,
      x,
    );
    _checkError(r, 'bessely');
    return r;
  }

  // ---------- Number-theory primitives (call WASM stubs — return errors) ----------

  bool ntheoryIsprime(String n) {
    final r = _call1('flutter_symengine_isprime', n);
    return r == 'true';
  }

  String ntheoryNextprime(String n) =>
      _call1('flutter_symengine_nextprime', n);

  String ntheoryPrevprime(String n) =>
      _call1('flutter_symengine_prevprime', n);

  String ntheoryFactorint(String n) =>
      _call1('flutter_symengine_factorint', n);

  String ntheoryModpow(String a, String e, String m) =>
      _call3('flutter_symengine_modpow', a, e, m);

  String ntheoryModinv(String a, String m) =>
      _call2('flutter_symengine_modinv', a, m);

  String ntheoryTotient(String n) =>
      _call1('flutter_symengine_totient', n);

  String ntheoryJacobi(String a, String n) =>
      _call2('flutter_symengine_jacobi', a, n);
}
