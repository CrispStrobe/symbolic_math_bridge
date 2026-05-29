// Web stub for the symbolic-math bridge.
//
// The browser has no `dart:ffi` and no shared-library loader, so the
// native SymEngine / MPFR / FLINT wrapper cannot run. This file mirrors
// the public surface of the native implementation
// (`symbolic_math_bridge_io.dart`) so consumers compile unchanged on
// web, but every entry point is unavailable:
//
//   * `SymbolicMathBridge()` throws `SymbolicMathNotAvailableException`,
//     which is exactly what consumers already catch on any host where
//     the native library failed to load (e.g. `flutter test`). They set
//     their "native unavailable" flag and route to pure-Dart fallbacks.
//   * Every method also throws, defensively — none is reachable once the
//     constructor has thrown, but the bodies keep the contract honest.
//
// Selected by the conditional export in `symbolic_math_bridge.dart` when
// `dart.library.io` is absent (dart2js and dart2wasm).

import 'symbolic_math_exceptions.dart';

Never _unavailable(String op) =>
    throw SymbolicMathNotAvailableException('SymEngine (web build): $op');

/// Web stub for [SymEngineMatrix]. Never instantiated — `createMatrix`
/// throws before one could be returned — but its members must exist so
/// matrix-handling consumer code type-checks on web.
class SymEngineMatrix {
  SymEngineMatrix._();

  int get rows => _unavailable('matrix.rows');
  int get cols => _unavailable('matrix.cols');

  void dispose() {}

  void set(int row, int col, String value) => _unavailable('matrix.set');
  String get(int row, int col) => _unavailable('matrix.get');
  String getDeterminant() => _unavailable('matrix.det');
  SymEngineMatrix inverse() => _unavailable('matrix.inverse');
  SymEngineMatrix operator +(SymEngineMatrix other) => _unavailable('matrix.+');
  SymEngineMatrix operator *(SymEngineMatrix other) => _unavailable('matrix.*');

  @override
  String toString() => 'SymEngineMatrix(unavailable on web)';
}

/// Web stub for [SymbolicMathBridge]. The constructor throws so a
/// consumer's `try { SymbolicMathBridge() }` lands on the same
/// "native library unavailable" branch it already has for headless
/// hosts. Methods below are unreachable but preserve the API contract.
class SymbolicMathBridge {
  SymbolicMathBridge() {
    throw SymbolicMathNotAvailableException('SymEngine (web build)');
  }

  /// Native `integrate` availability probe — always false on web.
  bool get hasIntegrate => false;

  bool isValidExpression(String expression) => _unavailable('isValidExpression');

  String evaluate(String expression) => _unavailable('evaluate');
  String expand(String expression) => _unavailable('expand');
  String simplify(String expression) => _unavailable('simplify');
  String factor(String expression) => _unavailable('factor');
  String solve(String expression, String symbol) => _unavailable('solve');
  String differentiate(String expression, String symbol) =>
      _unavailable('differentiate');
  String integrate(String expression, String symbol) =>
      _unavailable('integrate');
  String substitute(String expression, String symbol, String value) =>
      _unavailable('substitute');
  String callUnary(String funcName, String expression) =>
      _unavailable('callUnary');
  String callBinary(String funcName, String expr1, String expr2) =>
      _unavailable('callBinary');
  String gcd(String a, String b) => _unavailable('gcd');
  String lcm(String a, String b) => _unavailable('lcm');
  String factorial(int n) => _unavailable('factorial');
  String fibonacci(int n) => _unavailable('fibonacci');

  String getPi() => _unavailable('getPi');
  String getE() => _unavailable('getE');
  String getEulerGamma() => _unavailable('getEulerGamma');
  String getConstant(String name) => _unavailable('getConstant');

  SymEngineMatrix createMatrix(int rows, int cols) =>
      _unavailable('createMatrix');

  String getVersion() => _unavailable('getVersion');
  String testBasicOperations() => _unavailable('testBasicOperations');
  String testSymbolic() => _unavailable('testSymbolic');
  String getPreferredWrapperType() => _unavailable('getPreferredWrapperType');

  List<String> getAvailableUnaryFunctions() => const [];
  List<String> getAvailableBinaryFunctions() => const [];
  List<String> getAvailableConstants() => const [];

  String evaluateWithPrecision(String expression, int precision) =>
      _unavailable('evaluateWithPrecision');
  String gmpPower(String base, int exponent) => _unavailable('gmpPower');

  String mpfrHighPrecisionPi(int precision) =>
      _unavailable('mpfrHighPrecisionPi');
  String mpfrHighPrecisionE(int precision) =>
      _unavailable('mpfrHighPrecisionE');
  String mpfrHighPrecisionEulerGamma(int precision) =>
      _unavailable('mpfrHighPrecisionEulerGamma');
  String mpfrHighPrecisionSqrt2(int precision) =>
      _unavailable('mpfrHighPrecisionSqrt2');
  String mpfrEvalf(String expression, int precision) =>
      _unavailable('mpfrEvalf');
  String mpfrCevalf(String expression, int precision) =>
      _unavailable('mpfrCevalf');
  String mpfrBesselJ(int order, String x) => _unavailable('mpfrBesselJ');
  String mpfrBesselY(int order, String x) => _unavailable('mpfrBesselY');

  bool ntheoryIsprime(String n) => _unavailable('ntheoryIsprime');
  String ntheoryNextprime(String n) => _unavailable('ntheoryNextprime');
  String ntheoryPrevprime(String n) => _unavailable('ntheoryPrevprime');
  String ntheoryFactorint(String n) => _unavailable('ntheoryFactorint');
  String ntheoryModpow(String a, String e, String m) =>
      _unavailable('ntheoryModpow');
  String ntheoryModinv(String a, String m) => _unavailable('ntheoryModinv');
  String ntheoryTotient(String n) => _unavailable('ntheoryTotient');
  String ntheoryJacobi(String a, String n) => _unavailable('ntheoryJacobi');
}
