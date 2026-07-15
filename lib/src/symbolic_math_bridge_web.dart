// Web implementation of the symbolic-math bridge via WASM + dart:js_interop.
//
// Two-phase loading:
//   1. Before the WASM module is ready, the constructor throws
//      SymbolicMathNotAvailableException — same as the old throw-only
//      stub. Consumers set their "native unavailable" flag and route to
//      pure-Dart fallbacks.
//   2. After `SymbolicMathBridge.tryLoadWasm()` succeeds, the constructor
//      works and every method delegates to SymEngine via JS ccall.
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
// JS interop bindings — typed wrappers around the Emscripten Module object
// ---------------------------------------------------------------------------

@JS('symEngineReady')
external bool get _jsReady;

@JS('symEngineInstance')
external JSObject? get _jsModule;

/// JS-level helper functions injected into the global scope.
/// We define thin JS wrappers via @JS rather than trying to call
/// Module.ccall from Dart (which requires dynamic dispatch that
/// dart:js_interop doesn't support on JSObject directly).

@JS('_symCcall0')
external JSString _jsCcall0(JSString fn);

@JS('_symCcall1')
external JSString _jsCcall1(JSString fn, JSString a);

@JS('_symCcall2')
external JSString _jsCcall2(JSString fn, JSString a, JSString b);

@JS('_symCcall3')
external JSString _jsCcall3(JSString fn, JSString a, JSString b, JSString c);

@JS('_symCcallInt')
external JSString _jsCcallInt(JSString fn, JSNumber a);

@JS('_symCcallIntStr')
external JSString _jsCcallIntStr(JSString fn, JSNumber a, JSString b);

@JS('_symCcallStrInt')
external JSString _jsCcallStrInt(JSString fn, JSString a, JSNumber b);

@JS('_symCcall3StrInt')
external JSString _jsCcall3StrInt(
    JSString fn, JSString a, JSString b, JSString c, JSNumber n);

@JS('_symHasExport')
external JSBoolean _jsHasExport(JSString name);

@JS('_symCcallVoidNum')
external void _jsCcallVoidNum(JSString fn, JSNumber a);

@JS('_symCcallNumSetElem')
external JSNumber _jsCcallNumSetElem(
  JSNumber ptr,
  JSNumber row,
  JSNumber col,
  JSString value,
);

@JS('_symCcallStrGetElem')
external JSString _jsCcallStrGetElem(JSNumber ptr, JSNumber row, JSNumber col);

@JS('_symCcallStrFromPtr')
external JSString _jsCcallStrFromPtr(JSString fn, JSNumber ptr);

@JS('_symCcallPtrFromPtr')
external JSNumber _jsCcallPtrFromPtr(JSString fn, JSNumber ptr);

@JS('_symCcallPtrFromPtrPtr')
external JSNumber _jsCcallPtrFromPtrPtr(JSString fn, JSNumber a, JSNumber b);

@JS('_symCcallPtrFromIntInt')
external JSNumber _jsCcallPtrFromIntInt(JSString fn, JSNumber a, JSNumber b);

/// Inject the JS helper functions that bridge Dart → Module.ccall.
/// Called once when the WASM module is ready.
@JS('eval')
external void _jsEval(JSString code);

bool _helpersInjected = false;

void _injectHelpers() {
  if (_helpersInjected) return;
  _jsEval(
    '''
    window._symCcall0 = function(fn) {
      return symEngineInstance.ccall(fn, 'string', [], []);
    };
    window._symCcall1 = function(fn, a) {
      return symEngineInstance.ccall(fn, 'string', ['string'], [a]);
    };
    window._symCcall2 = function(fn, a, b) {
      return symEngineInstance.ccall(fn, 'string', ['string','string'], [a, b]);
    };
    window._symCcall3 = function(fn, a, b, c) {
      return symEngineInstance.ccall(fn, 'string', ['string','string','string'], [a, b, c]);
    };
    window._symCcallInt = function(fn, a) {
      return symEngineInstance.ccall(fn, 'string', ['number'], [a]);
    };
    window._symCcallIntStr = function(fn, a, b) {
      return symEngineInstance.ccall(fn, 'string', ['number','string'], [a, b]);
    };
    window._symCcallStrInt = function(fn, a, b) {
      return symEngineInstance.ccall(fn, 'string', ['string','number'], [a, b]);
    };
    window._symCcall3StrInt = function(fn, a, b, c, n) {
      return symEngineInstance.ccall(
        fn, 'string', ['string','string','string','number'], [a, b, c, n]);
    };
    window._symHasExport = function(name) {
      return typeof symEngineInstance['_' + name] === 'function';
    };
    window._symCcallVoidNum = function(fn, a) {
      symEngineInstance.ccall(fn, null, ['number'], [a]);
    };
    window._symCcallNumSetElem = function(ptr, row, col, value) {
      return symEngineInstance.ccall(
        'flutter_symengine_matrix_set_element', 'number',
        ['number','number','number','string'], [ptr, row, col, value]);
    };
    window._symCcallStrGetElem = function(ptr, row, col) {
      return symEngineInstance.ccall(
        'flutter_symengine_matrix_get_element', 'string',
        ['number','number','number'], [ptr, row, col]);
    };
    window._symCcallStrFromPtr = function(fn, ptr) {
      return symEngineInstance.ccall(fn, 'string', ['number'], [ptr]);
    };
    window._symCcallPtrFromPtr = function(fn, ptr) {
      return symEngineInstance.ccall(fn, 'number', ['number'], [ptr]);
    };
    window._symCcallPtrFromPtrPtr = function(fn, a, b) {
      return symEngineInstance.ccall(fn, 'number', ['number','number'], [a, b]);
    };
    window._symCcallPtrFromIntInt = function(fn, a, b) {
      return symEngineInstance.ccall(fn, 'number', ['number','number'], [a, b]);
    };
  '''
        .toJS,
  );
  _helpersInjected = true;
}

// ---------------------------------------------------------------------------
// Dart-level helpers
// ---------------------------------------------------------------------------

String _call0(String fn) => _jsCcall0(fn.toJS).toDart;

String _call1(String fn, String a) {
  final r = _jsCcall1(fn.toJS, a.toJS).toDart;
  _checkError(r, fn);
  return r;
}

String _call2(String fn, String a, String b) {
  final r = _jsCcall2(fn.toJS, a.toJS, b.toJS).toDart;
  _checkError(r, fn);
  return r;
}

String _call3(String fn, String a, String b, String c) {
  final r = _jsCcall3(fn.toJS, a.toJS, b.toJS, c.toJS).toDart;
  _checkError(r, fn);
  return r;
}

String _call3StrInt(String fn, String a, String b, String c, int n) {
  final r = _jsCcall3StrInt(fn.toJS, a.toJS, b.toJS, c.toJS, n.toJS).toDart;
  _checkError(r, fn);
  return r;
}

bool _hasExport(String name) => _jsHasExport(name.toJS).toDart;

String _callInt(String fn, int a) {
  final r = _jsCcallInt(fn.toJS, a.toJS).toDart;
  _checkError(r, fn);
  return r;
}

String _callIntStr(String fn, int a, String b) {
  final r = _jsCcallIntStr(fn.toJS, a.toJS, b.toJS).toDart;
  _checkError(r, fn);
  return r;
}

String _callStrInt(String fn, String a, int b) {
  final r = _jsCcallStrInt(fn.toJS, a.toJS, b.toJS).toDart;
  _checkError(r, fn);
  return r;
}

void _checkError(String result, String op) {
  if (result.startsWith('Error')) {
    throw SymbolicMathException(op, result);
  }
}

// ---------------------------------------------------------------------------
// Matrix (WASM-backed, uses opaque pointer-as-int handle)
// ---------------------------------------------------------------------------

/// A dense symbolic matrix backed by the SymEngine WASM build.
///
/// Elements are symbolic expressions passed and returned as strings; call
/// [dispose] when finished to free the native handle.
class SymEngineMatrix {
  final int _ptr;
  final int _rows;
  final int _cols;
  bool _disposed = false;

  SymEngineMatrix._(this._ptr, this._rows, this._cols);

  /// The number of rows in this matrix.
  int get rows => _rows;

  /// The number of columns in this matrix.
  int get cols => _cols;

  void _check() {
    if (_disposed) {
      throw SymbolicMathException('matrix', 'Matrix has been disposed');
    }
  }

  /// Frees the native matrix handle. Safe to call more than once.
  void dispose() {
    if (!_disposed) {
      _jsCcallVoidNum('flutter_symengine_matrix_free'.toJS, _ptr.toJS);
      _disposed = true;
    }
  }

  /// Sets the element at ([row], [col]) to the symbolic expression [value].
  void set(int row, int col, String value) {
    _check();
    final result = _jsCcallNumSetElem(
      _ptr.toJS,
      row.toJS,
      col.toJS,
      value.toJS,
    );
    if (result.toDartInt != 0) {
      throw SymbolicMathException(
        'matrix_set',
        'Failed to set element at ($row, $col)',
      );
    }
  }

  /// Returns the symbolic expression stored at ([row], [col]).
  String get(int row, int col) {
    _check();
    final result = _jsCcallStrGetElem(_ptr.toJS, row.toJS, col.toJS);
    final s = result.toDart;
    _checkError(s, 'matrix_get');
    return s;
  }

  /// Returns the symbolic determinant of this (square) matrix.
  String getDeterminant() {
    _check();
    final s = _jsCcallStrFromPtr(
      'flutter_symengine_matrix_det'.toJS,
      _ptr.toJS,
    ).toDart;
    _checkError(s, 'matrix_det');
    return s;
  }

  /// Returns a new matrix that is the symbolic inverse of this one.
  SymEngineMatrix inverse() {
    _check();
    final p = _jsCcallPtrFromPtr(
      'flutter_symengine_matrix_inv'.toJS,
      _ptr.toJS,
    ).toDartInt;
    if (p == 0) {
      throw SymbolicMathException('matrix_inv', 'Matrix inversion failed');
    }
    return SymEngineMatrix._(p, _rows, _cols);
  }

  /// Returns the element-wise sum of this matrix and [other].
  SymEngineMatrix operator +(SymEngineMatrix other) {
    _check();
    other._check();
    final p = _jsCcallPtrFromPtrPtr(
      'flutter_symengine_matrix_add'.toJS,
      _ptr.toJS,
      other._ptr.toJS,
    ).toDartInt;
    if (p == 0) {
      throw SymbolicMathException('matrix_add', 'Matrix addition failed');
    }
    return SymEngineMatrix._(p, _rows, _cols);
  }

  /// Returns the matrix product of this matrix and [other].
  SymEngineMatrix operator *(SymEngineMatrix other) {
    _check();
    other._check();
    final p = _jsCcallPtrFromPtrPtr(
      'flutter_symengine_matrix_mul'.toJS,
      _ptr.toJS,
      other._ptr.toJS,
    ).toDartInt;
    if (p == 0) {
      throw SymbolicMathException('matrix_mul', 'Matrix multiplication failed');
    }
    return SymEngineMatrix._(p, _rows, other._cols);
  }

  @override
  String toString() {
    if (_disposed) return 'SymEngineMatrix(disposed)';
    return _jsCcallStrFromPtr(
      'flutter_symengine_matrix_to_string'.toJS,
      _ptr.toJS,
    ).toDart;
  }
}

// ---------------------------------------------------------------------------
// Main bridge class
// ---------------------------------------------------------------------------

/// The symbolic-math engine on the web: a thin wrapper over the SymEngine
/// WASM build. Mirrors the native (`dart:ffi`) API so the same code runs on
/// every platform; throws [SymbolicMathNotAvailableException] if the WASM
/// module is not loaded.
class SymbolicMathBridge {
  static bool _wasmLoaded = false;

  SymbolicMathBridge() {
    if (!_wasmLoaded) {
      if (_jsReady && _jsModule != null) {
        _injectHelpers();
        _wasmLoaded = true;
      } else {
        throw SymbolicMathNotAvailableException('SymEngine (web build)');
      }
    }
  }

  /// Attempt to acquire the WASM module from the JS global.
  static bool tryLoadWasm() {
    if (_wasmLoaded) return true;
    if (_jsReady && _jsModule != null) {
      _injectHelpers();
      _wasmLoaded = true;
      return true;
    }
    return false;
  }

  /// Whether the WASM module has been loaded.
  static bool get isWasmLoaded => _wasmLoaded;

  // ---------- Core symbolic operations ----------

  /// Whether the build supports [integrate] (always true on the web build).
  bool get hasIntegrate => true;

  /// Returns whether [expression] has balanced parentheses and is non-empty.
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

  /// Numerically/symbolically evaluates [expression].
  String evaluate(String expression) =>
      _call1('flutter_symengine_evaluate', expression);

  /// Expands products and powers in [expression].
  String expand(String expression) =>
      _call1('flutter_symengine_expand', expression);

  /// Simplifies [expression] to a reduced form.
  String simplify(String expression) =>
      _call1('flutter_symengine_simplify', expression);

  /// Factors [expression] into a product of terms where possible.
  String factor(String expression) =>
      _call1('flutter_symengine_factor', expression);

  /// Solves [expression] for [symbol].
  String solve(String expression, String symbol) =>
      _call2('flutter_symengine_solve', expression, symbol);

  /// Differentiates [expression] with respect to [symbol].
  String differentiate(String expression, String symbol) =>
      _call2('flutter_symengine_differentiate', expression, symbol);

  /// Integrates [expression] with respect to [symbol].
  String integrate(String expression, String symbol) =>
      _call2('flutter_symengine_integrate', expression, symbol);

  // series/linsolve exist only in WASM binaries built with the C2-arc
  // wasm_exports.json — probe the module so an older cached binary
  // degrades gracefully instead of throwing from inside ccall.
  bool get hasSeries => _hasExport('flutter_symengine_series');
  bool get hasLinsolve => _hasExport('flutter_symengine_linsolve');

  String series(
    String expression,
    String symbol, {
    String point = '0',
    int order = 6,
  }) {
    if (!hasSeries) {
      throw SymbolicMathNotAvailableException('SymEngine series (web build)');
    }
    return _call3StrInt(
        'flutter_symengine_series', expression, symbol, point, order);
  }

  String linsolve(List<String> equations, List<String> symbols) {
    if (!hasLinsolve) {
      throw SymbolicMathNotAvailableException('SymEngine linsolve (web build)');
    }
    return _call2(
        'flutter_symengine_linsolve', equations.join('; '), symbols.join(', '));
  }

  String substitute(String expression, String symbol, String value) =>
      _call3('flutter_symengine_substitute', expression, symbol, value);

  // ---------- Mathematical functions ----------

  static const _unaryFuncNames = [
    'abs',
    'sin',
    'cos',
    'tan',
    'asin',
    'acos',
    'atan',
    'sinh',
    'cosh',
    'tanh',
    'asinh',
    'acosh',
    'atanh',
    'exp',
    'log',
    'sqrt',
    'gamma',
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

  String gcd(String a, String b) => _call2('flutter_symengine_gcd', a, b);

  String lcm(String a, String b) => _call2('flutter_symengine_lcm', a, b);

  String factorial(int n) => _callInt('flutter_symengine_factorial', n);

  String fibonacci(int n) => _callInt('flutter_symengine_fibonacci', n);

  // ---------- Constants ----------

  String getPi() => _call0('flutter_symengine_get_pi');
  String getE() => _call0('flutter_symengine_get_e');
  String getEulerGamma() => _call0('flutter_symengine_get_euler_gamma');

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
    final p = _jsCcallPtrFromIntInt(
      'flutter_symengine_matrix_new'.toJS,
      rows.toJS,
      cols.toJS,
    ).toDartInt;
    if (p == 0) {
      throw SymbolicMathException('matrix_create', 'allocation failed');
    }
    return SymEngineMatrix._(p, rows, cols);
  }

  // ---------- Utility ----------

  String getVersion() => _call0('flutter_symengine_version');
  String testBasicOperations() =>
      _call0('flutter_symengine_test_basic_operations');
  String testSymbolic() => _call0('flutter_symengine_test_symbolic');
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

  String mpfrHighPrecisionPi(int precision) =>
      _callInt('flutter_symengine_pi_with_precision', precision);

  String mpfrHighPrecisionE(int precision) =>
      _callInt('flutter_symengine_e_with_precision', precision);

  String mpfrHighPrecisionEulerGamma(int precision) =>
      _callInt('flutter_symengine_euler_gamma_with_precision', precision);

  String mpfrHighPrecisionSqrt2(int precision) =>
      _callInt('flutter_symengine_sqrt2_with_precision', precision);

  String mpfrEvalf(String expression, int precision) => _callStrInt(
        'flutter_symengine_evalf_with_precision',
        expression,
        precision,
      );

  String mpfrCevalf(String expression, int precision) => _callStrInt(
        'flutter_symengine_cevalf_with_precision',
        expression,
        precision,
      );

  String mpfrBesselJ(int order, String x) =>
      _callIntStr('flutter_symengine_besselj', order, x);

  String mpfrBesselY(int order, String x) =>
      _callIntStr('flutter_symengine_bessely', order, x);

  // ---------- Number-theory primitives ----------

  bool ntheoryIsprime(String n) =>
      _call1('flutter_symengine_isprime', n) == 'true';

  String ntheoryNextprime(String n) => _call1('flutter_symengine_nextprime', n);

  String ntheoryPrevprime(String n) => _call1('flutter_symengine_prevprime', n);

  String ntheoryFactorint(String n) => _call1('flutter_symengine_factorint', n);

  String ntheoryModpow(String a, String e, String m) =>
      _call3('flutter_symengine_modpow', a, e, m);

  String ntheoryModinv(String a, String m) =>
      _call2('flutter_symengine_modinv', a, m);

  String ntheoryTotient(String n) => _call1('flutter_symengine_totient', n);

  String ntheoryJacobi(String a, String n) =>
      _call2('flutter_symengine_jacobi', a, n);
}
