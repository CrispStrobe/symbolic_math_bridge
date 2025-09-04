import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// --- C Function Signatures (Native) ---
// These typedefs use dart:ffi types (Int32, Pointer, etc.) to match the C source code exactly.

// Core
typedef _EvaluateC = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _SolveC = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _SubstituteC = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef _FreeStringC = Void Function(Pointer<Utf8>);
// Unary
typedef _UnaryFuncC = Pointer<Utf8> Function(Pointer<Utf8>);
// Number Theory
typedef _GcdLcmC = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _FactorialC = Pointer<Utf8> Function(Int32);
typedef _FibonacciC = Pointer<Utf8> Function(Int32);
// Constants
typedef _GetConstantC = Pointer<Utf8> Function();
// Matrix
typedef _MatrixNewC = Pointer<Void> Function(Int32, Int32);
typedef _MatrixFreeC = Void Function(Pointer<Void>);
typedef _MatrixSetElementC = Int32 Function(Pointer<Void>, Int32, Int32, Pointer<Utf8>);
typedef _MatrixGetElementC = Pointer<Utf8> Function(Pointer<Void>, Int32, Int32);
typedef _MatrixToStringC = Pointer<Utf8> Function(Pointer<Void>);
typedef _MatrixUnaryOpC = Pointer<Utf8> Function(Pointer<Void>);
typedef _MatrixUnaryOpReturnsMatrixC = Pointer<Void> Function(Pointer<Void>);
typedef _MatrixBinaryOpC = Pointer<Void> Function(Pointer<Void>, Pointer<Void>);

// --- Dart Function Signatures (Dart-side) ---
// These typedefs use standard Dart types (int, String, etc.) for the public API.

// Core
typedef _EvaluateDart = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _SolveDart = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _SubstituteDart = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);
// Unary
typedef _UnaryFuncDart = Pointer<Utf8> Function(Pointer<Utf8>);
// Number Theory
typedef _GcdLcmDart = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _FactorialDart = Pointer<Utf8> Function(int);
typedef _FibonacciDart = Pointer<Utf8> Function(int);
// Constants
typedef _GetConstantDart = Pointer<Utf8> Function();
// Matrix
typedef _MatrixNewDart = Pointer<Void> Function(int, int);
typedef _MatrixFreeDart = void Function(Pointer<Void>);
typedef _MatrixSetElementDart = int Function(Pointer<Void>, int, int, Pointer<Utf8>);
typedef _MatrixGetElementDart = Pointer<Utf8> Function(Pointer<Void>, int, int);
typedef _MatrixToStringDart = Pointer<Utf8> Function(Pointer<Void>);
typedef _MatrixUnaryOpDart = Pointer<Utf8> Function(Pointer<Void>);
typedef _MatrixUnaryOpReturnsMatrixDart = Pointer<Void> Function(Pointer<Void>);
typedef _MatrixBinaryOpDart = Pointer<Void> Function(Pointer<Void>, Pointer<Void>);


class SymbolicMathBridge {
  static final SymbolicMathBridge _instance = SymbolicMathBridge._internal();
  factory SymbolicMathBridge() => _instance;

  late final DynamicLibrary _dylib;

  // --- Dart Function Lookups ---
  late final _EvaluateDart _evaluate;
  late final _SolveDart _solve;
  late final _UnaryFuncDart _expand;
  late final _SolveDart _differentiate;
  late final _SubstituteDart _substitute;
  late final _FreeStringDart _freeString;
  late final Map<String, _UnaryFuncDart> _unaryFunctions;
  late final _GcdLcmDart _gcd;
  late final _GcdLcmDart _lcm;
  late final _FactorialDart _factorial;
  late final _FibonacciDart _fibonacci;
  late final _GetConstantDart _getPi;
  late final _GetConstantDart _getE;
  late final _GetConstantDart _getEulerGamma;
  late final _MatrixNewDart _matrixNew;
  late final _MatrixFreeDart _matrixFree;
  late final _MatrixSetElementDart _matrixSetElement;
  late final _MatrixGetElementDart _matrixGetElement;
  late final _MatrixToStringDart _matrixToString;
  late final _MatrixUnaryOpDart _matrixDet;
  late final _MatrixUnaryOpReturnsMatrixDart _matrixInv;
  late final _MatrixBinaryOpDart _matrixAdd;
  late final _MatrixBinaryOpDart _matrixMul;

  SymbolicMathBridge._internal() {
    _dylib = Platform.isIOS || Platform.isMacOS
        ? DynamicLibrary.process()
        : DynamicLibrary.open('libSymEngineFlutterWrapper.so');

    _evaluate = _dylib.lookupFunction<_EvaluateC, _EvaluateDart>('flutter_symengine_evaluate');
    _solve = _dylib.lookupFunction<_SolveC, _SolveDart>('flutter_symengine_solve');
    _expand = _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_expand');
    _differentiate = _dylib.lookupFunction<_SolveC, _SolveDart>('flutter_symengine_differentiate');
    _substitute = _dylib.lookupFunction<_SubstituteC, _SubstituteDart>('flutter_symengine_substitute');
    _freeString = _dylib.lookupFunction<_FreeStringC, _FreeStringDart>('flutter_symengine_free_string');

    _unaryFunctions = {
      'abs': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_abs'),
      'sin': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_sin'),
      'cos': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_cos'),
      'tan': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_tan'),
      'asin': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_asin'),
      'acos': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_acos'),
      'atan': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_atan'),
      'sinh': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_sinh'),
      'cosh': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_cosh'),
      'tanh': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_tanh'),
      'asinh': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_asinh'),
      'acosh': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_acosh'),
      'atanh': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_atanh'),
      'exp': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_exp'),
      'log': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_log'),
      'sqrt': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_sqrt'),
      'gamma': _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_gamma'),
    };

    _gcd = _dylib.lookupFunction<_GcdLcmC, _GcdLcmDart>('flutter_symengine_gcd');
    _lcm = _dylib.lookupFunction<_GcdLcmC, _GcdLcmDart>('flutter_symengine_lcm');
    _factorial = _dylib.lookupFunction<_FactorialC, _FactorialDart>('flutter_symengine_factorial');
    _fibonacci = _dylib.lookupFunction<_FibonacciC, _FibonacciDart>('flutter_symengine_fibonacci');

    _getPi = _dylib.lookupFunction<_GetConstantC, _GetConstantDart>('flutter_symengine_get_pi');
    _getE = _dylib.lookupFunction<_GetConstantC, _GetConstantDart>('flutter_symengine_get_e');
    _getEulerGamma = _dylib.lookupFunction<_GetConstantC, _GetConstantDart>('flutter_symengine_get_euler_gamma');
    
    _matrixNew = _dylib.lookupFunction<_MatrixNewC, _MatrixNewDart>('flutter_symengine_matrix_new');
    _matrixFree = _dylib.lookupFunction<_MatrixFreeC, _MatrixFreeDart>('flutter_symengine_matrix_free');
    _matrixSetElement = _dylib.lookupFunction<_MatrixSetElementC, _MatrixSetElementDart>('flutter_symengine_matrix_set_element');
    _matrixGetElement = _dylib.lookupFunction<_MatrixGetElementC, _MatrixGetElementDart>('flutter_symengine_matrix_get_element');
    _matrixToString = _dylib.lookupFunction<_MatrixToStringC, _MatrixToStringDart>('flutter_symengine_matrix_to_string');
    _matrixDet = _dylib.lookupFunction<_MatrixUnaryOpC, _MatrixUnaryOpDart>('flutter_symengine_matrix_det');
    _matrixInv = _dylib.lookupFunction<_MatrixUnaryOpReturnsMatrixC, _MatrixUnaryOpReturnsMatrixDart>('flutter_symengine_matrix_inv');
    _matrixAdd = _dylib.lookupFunction<_MatrixBinaryOpC, _MatrixBinaryOpDart>('flutter_symengine_matrix_add');
    _matrixMul = _dylib.lookupFunction<_MatrixBinaryOpC, _MatrixBinaryOpDart>('flutter_symengine_matrix_mul');
  }

  String _performStringOperation(_UnaryFuncDart op, String input) {
    final inputC = input.toNativeUtf8();
    final resultC = op(inputC);
    final result = resultC.toDartString();
    _freeString(resultC);
    malloc.free(inputC);
    return result;
  }

  // --- Public Dart API ---

  String evaluate(String expression) => _performStringOperation(_evaluate, expression);
  String expand(String expression) => _performStringOperation(_expand, expression);

  String solve(String expression, String symbol) {
    final exprC = expression.toNativeUtf8();
    final symC = symbol.toNativeUtf8();
    final resultC = _solve(exprC, symC);
    final result = resultC.toDartString();
    _freeString(resultC);
    malloc.free(exprC);
    malloc.free(symC);
    return result;
  }
  
  String differentiate(String expression, String symbol) {
    final exprC = expression.toNativeUtf8();
    final symC = symbol.toNativeUtf8();
    final resultC = _differentiate(exprC, symC);
    final result = resultC.toDartString();
    _freeString(resultC);
    malloc.free(exprC);
    malloc.free(symC);
    return result;
  }
  
  String substitute(String expression, String symbol, String value) {
    final exprC = expression.toNativeUtf8();
    final symC = symbol.toNativeUtf8();
    final valC = value.toNativeUtf8();
    final resultC = _substitute(exprC, symC, valC);
    final result = resultC.toDartString();
    _freeString(resultC);
    malloc.free(exprC);
    malloc.free(symC);
    malloc.free(valC);
    return result;
  }
  
  String callUnary(String funcName, String expression) {
      final func = _unaryFunctions[funcName];
      if (func == null) {
          throw ArgumentError('Unknown unary function: $funcName');
      }
      return _performStringOperation(func, expression);
  }

  String gcd(String a, String b) {
    final aC = a.toNativeUtf8();
    final bC = b.toNativeUtf8();
    final resultC = _gcd(aC, bC);
    final result = resultC.toDartString();
    _freeString(resultC);
    malloc.free(aC);
    malloc.free(bC);
    return result;
  }

  String lcm(String a, String b) {
    final aC = a.toNativeUtf8();
    final bC = b.toNativeUtf8();
    final resultC = _lcm(aC, bC);
    final result = resultC.toDartString();
    _freeString(resultC);
    malloc.free(aC);
    malloc.free(bC);
    return result;
  }
  
  String factorial(int n) {
      final resultC = _factorial(n);
      final result = resultC.toDartString();
      _freeString(resultC);
      return result;
  }
  
  String fibonacci(int n) {
      final resultC = _fibonacci(n);
      final result = resultC.toDartString();
      _freeString(resultC);
      return result;
  }
  
  String getPi() {
      final resultC = _getPi();
      final result = resultC.toDartString();
      _freeString(resultC);
      return result;
  }

  String getE() {
      final resultC = _getE();
      final result = resultC.toDartString();
      _freeString(resultC);
      return result;
  }
  
  String getEulerGamma() {
      final resultC = _getEulerGamma();
      final result = resultC.toDartString();
      _freeString(resultC);
      return result;
  }

  SymEngineMatrix createMatrix(int rows, int cols) {
    final ptr = _matrixNew(rows, cols);
    if (ptr == nullptr) {
        throw Exception('Failed to create matrix in native code.');
    }
    return SymEngineMatrix._fromPointer(ptr, this);
  }
}

// --- Matrix Class with Opaque Pointer and Finalizer ---

// **FIX:** Look up the function pointer directly for the finalizer.
final _finalizer = NativeFinalizer(
  SymbolicMathBridge()._dylib.lookup<NativeFunction<_MatrixFreeC>>('flutter_symengine_matrix_free')
);

// **FIX:** Implement Finalizable to be used with NativeFinalizer.
class SymEngineMatrix implements Finalizable {
    late final Pointer<Void> _ptr;
    final SymbolicMathBridge _bridge;

    SymEngineMatrix._fromPointer(this._ptr, this._bridge) {
        _finalizer.attach(this, _ptr, detach: this);
    }

    void dispose() {
        _finalizer.detach(this);
        _bridge._matrixFree(_ptr);
    }

    void set(int row, int col, String value) {
        final valueC = value.toNativeUtf8();
        final result = _bridge._matrixSetElement(_ptr, row, col, valueC);
        malloc.free(valueC);
        if (result != 0) {
            throw Exception('Failed to set matrix element. Error code: $result');
        }
    }

    String get(int row, int col) {
        final resultC = _bridge._matrixGetElement(_ptr, row, col);
        final result = resultC.toDartString();
        _bridge._freeString(resultC);
        return result;
    }
    
    String getDeterminant() {
        final resultC = _bridge._matrixDet(_ptr);
        final result = resultC.toDartString();
        _bridge._freeString(resultC);
        return result;
    }
    
    SymEngineMatrix inverse() {
        final resultPtr = _bridge._matrixInv(_ptr);
        if (resultPtr == nullptr) {
            throw Exception('Matrix inversion failed in native code.');
        }
        return SymEngineMatrix._fromPointer(resultPtr, _bridge);
    }

    SymEngineMatrix operator +(SymEngineMatrix other) {
        final resultPtr = _bridge._matrixAdd(_ptr, other._ptr);
        if (resultPtr == nullptr) {
            throw Exception('Matrix addition failed in native code.');
        }
        return SymEngineMatrix._fromPointer(resultPtr, _bridge);
    }
    
    SymEngineMatrix operator *(SymEngineMatrix other) {
        final resultPtr = _bridge._matrixMul(_ptr, other._ptr);
        if (resultPtr == nullptr) {
            throw Exception('Matrix multiplication failed in native code.');
        }
        return SymEngineMatrix._fromPointer(resultPtr, _bridge);
    }

    @override
    String toString() {
        final resultC = _bridge._matrixToString(_ptr);
        final result = resultC.toDartString();
        _bridge._freeString(resultC);
        return result;
    }
}

