import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// ============================================================================
// EXCEPTION CLASSES
// ============================================================================

class SymbolicMathException implements Exception {
  final String operation;
  final String message;
  final String? library;
  
  SymbolicMathException(this.operation, this.message, [this.library]);
  
  @override
  String toString() {
    final libPrefix = library != null ? '[$library] ' : '';
    return 'SymbolicMathException: ${libPrefix}$operation - $message';
  }
}

class SymbolicMathParseException extends SymbolicMathException {
  SymbolicMathParseException(String operation, String message, [String? library]) 
      : super(operation, message, library);
}

class SymbolicMathMemoryException extends SymbolicMathException {
  SymbolicMathMemoryException(String operation, [String? library]) 
      : super(operation, 'Memory allocation failed', library);
}

class SymbolicMathNotAvailableException extends SymbolicMathException {
  SymbolicMathNotAvailableException(String library) 
      : super('initialize', 'Library not available: $library', library);
}

// ============================================================================
// C FUNCTION SIGNATURES - FLUTTER SYMENGINE WRAPPER
// ============================================================================

// Core symbolic operations
typedef _EvaluateC = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _SolveC = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _SubstituteC = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef _FreeStringC = Void Function(Pointer<Utf8>);
typedef _UnaryFuncC = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _BinaryFuncC = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _GetConstantC = Pointer<Utf8> Function();
typedef _GetVersionC = Pointer<Utf8> Function();
typedef _FactorialC = Pointer<Utf8> Function(Int32);
typedef _FibonacciC = Pointer<Utf8> Function(Int32);

// Matrix operations
typedef _MatrixNewC = Pointer<Void> Function(Int32, Int32);
typedef _MatrixFreeC = Void Function(Pointer<Void>);
typedef _MatrixSetElementC = Int32 Function(Pointer<Void>, Int32, Int32, Pointer<Utf8>);
typedef _MatrixGetElementC = Pointer<Utf8> Function(Pointer<Void>, Int32, Int32);
typedef _MatrixToStringC = Pointer<Utf8> Function(Pointer<Void>);
typedef _MatrixUnaryOpC = Pointer<Utf8> Function(Pointer<Void>);
typedef _MatrixUnaryOpReturnsMatrixC = Pointer<Void> Function(Pointer<Void>);
typedef _MatrixBinaryOpC = Pointer<Void> Function(Pointer<Void>, Pointer<Void>);

// ============================================================================
// DART FUNCTION SIGNATURES - FLUTTER SYMENGINE WRAPPER
// ============================================================================

typedef _EvaluateDart = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _SolveDart = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _SubstituteDart = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);
typedef _UnaryFuncDart = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _BinaryFuncDart = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _GetConstantDart = Pointer<Utf8> Function();
typedef _GetVersionDart = Pointer<Utf8> Function();
typedef _FactorialDart = Pointer<Utf8> Function(int);
typedef _FibonacciDart = Pointer<Utf8> Function(int);

typedef _MatrixNewDart = Pointer<Void> Function(int, int);
typedef _MatrixFreeDart = void Function(Pointer<Void>);
typedef _MatrixSetElementDart = int Function(Pointer<Void>, int, int, Pointer<Utf8>);
typedef _MatrixGetElementDart = Pointer<Utf8> Function(Pointer<Void>, int, int);
typedef _MatrixToStringDart = Pointer<Utf8> Function(Pointer<Void>);
typedef _MatrixUnaryOpDart = Pointer<Utf8> Function(Pointer<Void>);
typedef _MatrixUnaryOpReturnsMatrixDart = Pointer<Void> Function(Pointer<Void>);
typedef _MatrixBinaryOpDart = Pointer<Void> Function(Pointer<Void>, Pointer<Void>);

// ============================================================================
// MATRIX FINALIZER
// ============================================================================

late final NativeFinalizer _matrixFinalizer;

// ============================================================================
// MATRIX CLASS
// ============================================================================

class SymEngineMatrix implements Finalizable {
  late final Pointer<Void> _ptr;
  final SymbolicMathBridge _bridge;
  final int _rows;
  final int _cols;
  bool _disposed = false;

  SymEngineMatrix._fromPointer(this._ptr, this._bridge, this._rows, this._cols) {
    _matrixFinalizer.attach(this, _ptr, detach: this);
  }

  // Add the missing getters that the main.dart expects
  int get rows => _rows;
  int get cols => _cols;

  void _checkDisposed() {
    if (_disposed) {
      throw SymbolicMathException('matrix_operation', 'Matrix has been disposed');
    }
  }

  void dispose() {
    if (!_disposed) {
      _matrixFinalizer.detach(this);
      _bridge._matrixFree(_ptr);
      _disposed = true;
    }
  }

  void set(int row, int col, String value) {
    _checkDisposed();
    if (value.trim().isEmpty) {
      throw SymbolicMathParseException('matrix_set', 'Value cannot be empty');
    }
    
    final valueC = value.toNativeUtf8();
    try {
      final result = _bridge._matrixSetElement(_ptr, row, col, valueC);
      if (result != 0) {
        throw SymbolicMathException('matrix_set', 'Failed to set element at ($row, $col). Error code: $result');
      }
    } finally {
      malloc.free(valueC);
    }
  }

  String get(int row, int col) {
    _checkDisposed();
    final resultC = _bridge._matrixGetElement(_ptr, row, col);
    if (resultC == nullptr) {
      throw SymbolicMathException('matrix_get', 'Failed to get element at ($row, $col)');
    }
    
    try {
      final result = resultC.toDartString();
      if (result.startsWith('Error')) {
        throw SymbolicMathException('matrix_get', result);
      }
      return result;
    } finally {
      _bridge._freeString(resultC);
    }
  }
  
  String getDeterminant() {
    _checkDisposed();
    final resultC = _bridge._matrixDet(_ptr);
    if (resultC == nullptr) {
      throw SymbolicMathException('matrix_det', 'Failed to calculate determinant');
    }
    
    try {
      final result = resultC.toDartString();
      if (result.startsWith('Error')) {
        throw SymbolicMathException('matrix_det', result);
      }
      return result;
    } finally {
      _bridge._freeString(resultC);
    }
  }
  
  SymEngineMatrix inverse() {
    _checkDisposed();
    final resultPtr = _bridge._matrixInv(_ptr);
    if (resultPtr == nullptr) {
      throw SymbolicMathException('matrix_inv', 'Matrix inversion failed');
    }
    return SymEngineMatrix._fromPointer(resultPtr, _bridge, _rows, _cols);
  }

  SymEngineMatrix operator +(SymEngineMatrix other) {
    _checkDisposed();
    other._checkDisposed();
    final resultPtr = _bridge._matrixAdd(_ptr, other._ptr);
    if (resultPtr == nullptr) {
      throw SymbolicMathException('matrix_add', 'Matrix addition failed');
    }
    return SymEngineMatrix._fromPointer(resultPtr, _bridge, _rows, _cols);
  }
  
  SymEngineMatrix operator *(SymEngineMatrix other) {
    _checkDisposed();
    other._checkDisposed();
    final resultPtr = _bridge._matrixMul(_ptr, other._ptr);
    if (resultPtr == nullptr) {
      throw SymbolicMathException('matrix_mul', 'Matrix multiplication failed');
    }
    return SymEngineMatrix._fromPointer(resultPtr, _bridge, _rows, other._cols);
  }

  @override
  String toString() {
    _checkDisposed();
    final resultC = _bridge._matrixToString(_ptr);
    if (resultC == nullptr) {
      return 'Matrix(disposed or error)';
    }
    
    try {
      return resultC.toDartString();
    } finally {
      _bridge._freeString(resultC);
    }
  }
}

// ============================================================================
// MAIN BRIDGE CLASS
// ============================================================================

class SymbolicMathBridge {
  static final SymbolicMathBridge _instance = SymbolicMathBridge._internal();
  factory SymbolicMathBridge() => _instance;

  late final DynamicLibrary _dylib;

  // SymEngine wrapper functions
  late final _EvaluateDart _evaluate;
  late final _SolveDart _solve;
  late final _UnaryFuncDart _expand;
  late final _UnaryFuncDart _simplify;
  late final _UnaryFuncDart _factor;
  late final _SolveDart _differentiate;
  late final _SolveDart? _integrate;
  late final _SubstituteDart _substitute;
  late final _FreeStringDart _freeString;
  late final _GetVersionDart _version;
  late final _GetConstantDart _testBasic;
  late final _GetConstantDart _testSymbolic;
  
  // Mathematical functions
  late final Map<String, _UnaryFuncDart> _unaryFunctions;
  late final Map<String, _BinaryFuncDart> _binaryFunctions;
  
  // Number theory functions
  late final _BinaryFuncDart _gcd;
  late final _BinaryFuncDart _lcm;
  late final _FactorialDart _factorial;
  late final _FibonacciDart _fibonacci;
  
  // Constants
  late final _GetConstantDart _getPi;
  late final _GetConstantDart _getE;
  late final _GetConstantDart _getEulerGamma;

  // Arbitrary-precision real constants (via MPFR through SymEngine's
  // basic_evalf). Optional — older bridge builds don't expose them;
  // a runtime null means "fall back to the standard constant".
  _FactorialDart? _piWithPrecision;
  _FactorialDart? _eWithPrecision;
  _FactorialDart? _eulerGammaWithPrecision;
  _FactorialDart? _sqrt2WithPrecision;

  // Round 89: number-theory primitives. Same string-in/string-out
  // signature as the existing unary functions.
  _UnaryFuncDart? _isprime;
  _UnaryFuncDart? _nextprime;
  _UnaryFuncDart? _prevprime;
  // Round 90: integer factorization via FLINT.
  _UnaryFuncDart? _factorint;
  
  // Matrix operations
  late final _MatrixNewDart _matrixNew;
  late final _MatrixFreeDart _matrixFree;
  late final _MatrixSetElementDart _matrixSetElement;
  late final _MatrixGetElementDart _matrixGetElement;
  late final _MatrixToStringDart _matrixToString;
  late final _MatrixUnaryOpDart _matrixDet;
  late final _MatrixUnaryOpReturnsMatrixDart _matrixInv;
  late final _MatrixBinaryOpDart _matrixAdd;
  late final _MatrixBinaryOpDart _matrixMul;

  // Library availability flags
  bool _symEngineAvailable = false;

  SymbolicMathBridge._internal() {
    _dylib = _openNativeLibrary();
    _initializeSymEngine();
    _initializeMatrixFinalizer();
  }

  /// Locate the per-platform native binary that holds the
  /// `flutter_symengine_*` C entry points.
  ///
  /// - **iOS / macOS**: static-linked into the host process via the
  ///   xcframework bundles. `DynamicLibrary.process()` reaches the
  ///   symbols directly.
  /// - **Android**: shipped at `android/src/main/jniLibs/<abi>/`
  ///   as `libsymbolic_math_bridge.so`. Flutter packages it into
  ///   the APK; `DynamicLibrary.open('libsymbolic_math_bridge.so')`
  ///   loads it.
  /// - **Windows**: shipped at `windows/Libraries/` as
  ///   `symbolic_math_bridge_plugin.dll`. Flutter bundles it
  ///   alongside the runner exe via the plugin's
  ///   `<plugin>_bundled_libraries`. Loaded by filename.
  /// - **Linux**: shipped at `linux/Libraries/` as
  ///   `libsymbolic_math_bridge.so` (P11 R130, v1.2.0). Flutter
  ///   bundles it alongside the app via the plugin's
  ///   `<plugin>_bundled_libraries`; `DynamicLibrary.open` loads it by
  ///   the same name `add_library()` emits.
  static DynamicLibrary _openNativeLibrary() {
    if (Platform.isIOS || Platform.isMacOS) {
      return DynamicLibrary.process();
    }
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libsymbolic_math_bridge.so');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('symbolic_math_bridge_plugin.dll');
    }
    // Linux + anything else: try a sensible default; the caller is
    // expected to catch and surface the "bridge unavailable" path.
    return DynamicLibrary.open('libsymbolic_math_bridge.so');
  }

  void _initializeMatrixFinalizer() {
    _matrixFinalizer = NativeFinalizer(
      _dylib.lookup<NativeFunction<_MatrixFreeC>>('flutter_symengine_matrix_free')
    );
  }

  void _initializeSymEngine() {
    try {
      // Core operations
      _evaluate = _dylib.lookupFunction<_EvaluateC, _EvaluateDart>('flutter_symengine_evaluate');
      _solve = _dylib.lookupFunction<_SolveC, _SolveDart>('flutter_symengine_solve');
      _expand = _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_expand');
      _simplify = _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_simplify');
      _factor = _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>('flutter_symengine_factor');
      _differentiate = _dylib.lookupFunction<_SolveC, _SolveDart>('flutter_symengine_differentiate');
      // Integrate is present in some bridge builds and absent in others;
      // look it up optionally and leave `_integrate = null` if missing.
      try {
        _integrate = _dylib.lookupFunction<_SolveC, _SolveDart>(
            'flutter_symengine_integrate');
      } catch (_) {
        _integrate = null;
      }
      _substitute = _dylib.lookupFunction<_SubstituteC, _SubstituteDart>('flutter_symengine_substitute');
      _freeString = _dylib.lookupFunction<_FreeStringC, _FreeStringDart>('flutter_symengine_free_string');

      // Utility functions - NOTE: version returns const char*, not char*
      _version = _dylib.lookupFunction<_GetVersionC, _GetVersionDart>('flutter_symengine_version');
      _testBasic = _dylib.lookupFunction<_GetConstantC, _GetConstantDart>('flutter_symengine_test_basic_operations');
      _testSymbolic = _dylib.lookupFunction<_GetConstantC, _GetConstantDart>('flutter_symengine_test_symbolic');

      // Mathematical functions
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

      // Binary functions (empty as none are implemented in your C wrapper)
      _binaryFunctions = {};

      // Number theory
      _gcd = _dylib.lookupFunction<_BinaryFuncC, _BinaryFuncDart>('flutter_symengine_gcd');
      _lcm = _dylib.lookupFunction<_BinaryFuncC, _BinaryFuncDart>('flutter_symengine_lcm');
      _factorial = _dylib.lookupFunction<_FactorialC, _FactorialDart>('flutter_symengine_factorial');
      _fibonacci = _dylib.lookupFunction<_FibonacciC, _FibonacciDart>('flutter_symengine_fibonacci');

      // Constants
      _getPi = _dylib.lookupFunction<_GetConstantC, _GetConstantDart>('flutter_symengine_get_pi');
      _getE = _dylib.lookupFunction<_GetConstantC, _GetConstantDart>('flutter_symengine_get_e');
      _getEulerGamma = _dylib.lookupFunction<_GetConstantC, _GetConstantDart>('flutter_symengine_get_euler_gamma');

      // Arbitrary-precision real constants. Looked up optionally —
      // builds without the new wrappers leave each field null, and
      // the corresponding mpfrHighPrecision* method throws
      // SymbolicMathNotAvailableException when called.
      try {
        _piWithPrecision = _dylib.lookupFunction<_FactorialC, _FactorialDart>(
            'flutter_symengine_pi_with_precision');
      } catch (_) {
        _piWithPrecision = null;
      }
      try {
        _eWithPrecision = _dylib.lookupFunction<_FactorialC, _FactorialDart>(
            'flutter_symengine_e_with_precision');
      } catch (_) {
        _eWithPrecision = null;
      }
      try {
        _eulerGammaWithPrecision =
            _dylib.lookupFunction<_FactorialC, _FactorialDart>(
                'flutter_symengine_euler_gamma_with_precision');
      } catch (_) {
        _eulerGammaWithPrecision = null;
      }
      try {
        _sqrt2WithPrecision = _dylib.lookupFunction<_FactorialC, _FactorialDart>(
            'flutter_symengine_sqrt2_with_precision');
      } catch (_) {
        _sqrt2WithPrecision = null;
      }

      // Round 89: number-theory primitives. Each lookup is in its
      // own try/catch so older bridge builds without one of the
      // symbols (e.g. a build between rounds 88 and 89) still load.
      try {
        _isprime = _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>(
            'flutter_symengine_isprime');
      } catch (_) {
        _isprime = null;
      }
      try {
        _nextprime = _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>(
            'flutter_symengine_nextprime');
      } catch (_) {
        _nextprime = null;
      }
      try {
        _prevprime = _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>(
            'flutter_symengine_prevprime');
      } catch (_) {
        _prevprime = null;
      }
      try {
        _factorint = _dylib.lookupFunction<_UnaryFuncC, _UnaryFuncDart>(
            'flutter_symengine_factorint');
      } catch (_) {
        _factorint = null;
      }

      // Matrix operations
      _matrixNew = _dylib.lookupFunction<_MatrixNewC, _MatrixNewDart>('flutter_symengine_matrix_new');
      _matrixFree = _dylib.lookupFunction<_MatrixFreeC, _MatrixFreeDart>('flutter_symengine_matrix_free');
      _matrixSetElement = _dylib.lookupFunction<_MatrixSetElementC, _MatrixSetElementDart>('flutter_symengine_matrix_set_element');
      _matrixGetElement = _dylib.lookupFunction<_MatrixGetElementC, _MatrixGetElementDart>('flutter_symengine_matrix_get_element');
      _matrixToString = _dylib.lookupFunction<_MatrixToStringC, _MatrixToStringDart>('flutter_symengine_matrix_to_string');
      _matrixDet = _dylib.lookupFunction<_MatrixUnaryOpC, _MatrixUnaryOpDart>('flutter_symengine_matrix_det');
      _matrixInv = _dylib.lookupFunction<_MatrixUnaryOpReturnsMatrixC, _MatrixUnaryOpReturnsMatrixDart>('flutter_symengine_matrix_inv');
      _matrixAdd = _dylib.lookupFunction<_MatrixBinaryOpC, _MatrixBinaryOpDart>('flutter_symengine_matrix_add');
      _matrixMul = _dylib.lookupFunction<_MatrixBinaryOpC, _MatrixBinaryOpDart>('flutter_symengine_matrix_mul');

      _symEngineAvailable = true;
    } catch (e) {
      print('SymEngine initialization failed: $e');
    }
  }

  // ============================================================================
  // VALIDATION AND HELPER METHODS
  // ============================================================================

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

  String _performStringOperation(_UnaryFuncDart op, String input, String operationName) {
    if (!_symEngineAvailable) {
      throw SymbolicMathNotAvailableException('SymEngine');
    }
    
    if (!isValidExpression(input)) {
      throw SymbolicMathParseException(operationName, 'Invalid expression syntax');
    }

    final inputC = input.toNativeUtf8();
    try {
      final resultC = op(inputC);
      if (resultC == nullptr) {
        throw SymbolicMathMemoryException(operationName);
      }
      
      final result = resultC.toDartString();
      
      if (result.startsWith('Error in $operationName:')) {
        final errorMsg = result.substring('Error in $operationName: '.length);
        if (errorMsg.contains('parse')) {
          throw SymbolicMathParseException(operationName, errorMsg);
        }
        throw SymbolicMathException(operationName, errorMsg);
      }
      
      _freeString(resultC);
      return result;
    } finally {
      malloc.free(inputC);
    }
  }

  String _performBinaryStringOperation(_BinaryFuncDart op, String input1, String input2, String operationName) {
    if (!_symEngineAvailable) {
      throw SymbolicMathNotAvailableException('SymEngine');
    }

    final input1C = input1.toNativeUtf8();
    final input2C = input2.toNativeUtf8();
    try {
      final resultC = op(input1C, input2C);
      if (resultC == nullptr) {
        throw SymbolicMathMemoryException(operationName);
      }
      
      final result = resultC.toDartString();
      if (result.startsWith('Error')) {
        throw SymbolicMathException(operationName, result);
      }
      
      _freeString(resultC);
      return result;
    } finally {
      malloc.free(input1C);
      malloc.free(input2C);
    }
  }

  // ============================================================================
  // PUBLIC API - SYMENGINE HIGH-LEVEL OPERATIONS
  // ============================================================================

  String evaluate(String expression) => _performStringOperation(_evaluate, expression, 'evaluate');
  String expand(String expression) => _performStringOperation(_expand, expression, 'expand');
  String simplify(String expression) => _performStringOperation(_simplify, expression, 'simplify');
  String factor(String expression) => _performStringOperation(_factor, expression, 'factor');

  String solve(String expression, String symbol) {
    if (!_symEngineAvailable) {
      throw SymbolicMathNotAvailableException('SymEngine');
    }
    
    final exprC = expression.toNativeUtf8();
    final symC = symbol.toNativeUtf8();
    try {
      final resultC = _solve(exprC, symC);
      if (resultC == nullptr) {
        throw SymbolicMathMemoryException('solve');
      }
      
      final result = resultC.toDartString();
      if (result.startsWith('Error')) {
        throw SymbolicMathException('solve', result);
      }
      
      _freeString(resultC);
      return result;
    } finally {
      malloc.free(exprC);
      malloc.free(symC);
    }
  }
  
  String differentiate(String expression, String symbol) {
    if (!_symEngineAvailable) {
      throw SymbolicMathNotAvailableException('SymEngine');
    }
    
    final exprC = expression.toNativeUtf8();
    final symC = symbol.toNativeUtf8();
    try {
      final resultC = _differentiate(exprC, symC);
      if (resultC == nullptr) {
        throw SymbolicMathMemoryException('differentiate');
      }
      
      final result = resultC.toDartString();
      if (result.startsWith('Error')) {
        throw SymbolicMathException('differentiate', result);
      }
      
      _freeString(resultC);
      return result;
    } finally {
      malloc.free(exprC);
      malloc.free(symC);
    }
  }
  
  /// Symbolic indefinite integration ∫ f dx. Returns the antiderivative as
  /// a string. Whether this actually works depends on the C wrapper build —
  /// some builds expose the symbol but return an error from SymEngine. Test
  /// with `hasIntegrate` first if you want a safe fallback.
  String integrate(String expression, String symbol) {
    if (!_symEngineAvailable || _integrate == null) {
      throw SymbolicMathNotAvailableException('SymEngine integrate');
    }
    final exprC = expression.toNativeUtf8();
    final symC = symbol.toNativeUtf8();
    try {
      final resultC = _integrate!(exprC, symC);
      if (resultC == nullptr) {
        throw SymbolicMathMemoryException('integrate');
      }
      final result = resultC.toDartString();
      if (result.startsWith('Error')) {
        throw SymbolicMathException('integrate', result);
      }
      _freeString(resultC);
      return result;
    } finally {
      malloc.free(exprC);
      malloc.free(symC);
    }
  }

  /// True if the underlying wrapper exposes the integrate entry point.
  /// Callers can use this to switch between symbolic and numerical paths.
  bool get hasIntegrate => _symEngineAvailable && _integrate != null;

  String substitute(String expression, String symbol, String value) {
    if (!_symEngineAvailable) {
      throw SymbolicMathNotAvailableException('SymEngine');
    }
    
    final exprC = expression.toNativeUtf8();
    final symC = symbol.toNativeUtf8();
    final valC = value.toNativeUtf8();
    try {
      final resultC = _substitute(exprC, symC, valC);
      if (resultC == nullptr) {
        throw SymbolicMathMemoryException('substitute');
      }
      
      final result = resultC.toDartString();
      if (result.startsWith('Error')) {
        throw SymbolicMathException('substitute', result);
      }
      
      _freeString(resultC);
      return result;
    } finally {
      malloc.free(exprC);
      malloc.free(symC);
      malloc.free(valC);
    }
  }
  
  // Mathematical functions
  String callUnary(String funcName, String expression) {
    final func = _unaryFunctions[funcName];
    if (func == null) {
      throw ArgumentError('Unknown unary function: $funcName');
    }
    return _performStringOperation(func, expression, funcName);
  }

  String callBinary(String funcName, String expr1, String expr2) {
    final func = _binaryFunctions[funcName];
    if (func == null) {
      throw ArgumentError('Unknown binary function: $funcName');
    }
    return _performBinaryStringOperation(func, expr1, expr2, funcName);
  }

  // Number theory
  String gcd(String a, String b) => _performBinaryStringOperation(_gcd, a, b, 'gcd');
  String lcm(String a, String b) => _performBinaryStringOperation(_lcm, a, b, 'lcm');
  
  String factorial(int n) {
    if (!_symEngineAvailable) {
      throw SymbolicMathNotAvailableException('SymEngine');
    }
    if (n < 0) {
      throw SymbolicMathException('factorial', 'Input must be non-negative');
    }
    
    final resultC = _factorial(n);
    if (resultC == nullptr) {
      throw SymbolicMathMemoryException('factorial');
    }
    
    try {
      final result = resultC.toDartString();
      if (result.startsWith('Error')) {
        throw SymbolicMathException('factorial', result);
      }
      return result;
    } finally {
      _freeString(resultC);
    }
  }
  
  String fibonacci(int n) {
    if (!_symEngineAvailable) {
      throw SymbolicMathNotAvailableException('SymEngine');
    }
    if (n < 0) {
      throw SymbolicMathException('fibonacci', 'Input must be non-negative');
    }
    
    final resultC = _fibonacci(n);
    if (resultC == nullptr) {
      throw SymbolicMathMemoryException('fibonacci');
    }
    
    try {
      final result = resultC.toDartString();
      if (result.startsWith('Error')) {
        throw SymbolicMathException('fibonacci', result);
      }
      return result;
    } finally {
      _freeString(resultC);
    }
  }

  // Constants
  String getPi() {
    if (!_symEngineAvailable) {
      throw SymbolicMathNotAvailableException('SymEngine');
    }
    
    final resultC = _getPi();
    if (resultC == nullptr) {
      throw SymbolicMathMemoryException('getPi');
    }
    
    try {
      return resultC.toDartString();
    } finally {
      _freeString(resultC);
    }
  }

  String getE() {
    if (!_symEngineAvailable) {
      throw SymbolicMathNotAvailableException('SymEngine');
    }
    
    final resultC = _getE();
    if (resultC == nullptr) {
      throw SymbolicMathMemoryException('getE');
    }
    
    try {
      return resultC.toDartString();
    } finally {
      _freeString(resultC);
    }
  }
  
  String getEulerGamma() {
    if (!_symEngineAvailable) {
      throw SymbolicMathNotAvailableException('SymEngine');
    }
    
    final resultC = _getEulerGamma();
    if (resultC == nullptr) {
      throw SymbolicMathMemoryException('getEulerGamma');
    }
    
    try {
      return resultC.toDartString();
    } finally {
      _freeString(resultC);
    }
  }

  String getConstant(String name) {
    switch (name.toUpperCase()) {
      case 'PI': return getPi();
      case 'E': return getE();
      case 'GAMMA': return getEulerGamma();
      default: throw ArgumentError('Unknown constant: $name');
    }
  }

  // Matrix operations
  SymEngineMatrix createMatrix(int rows, int cols) {
    if (!_symEngineAvailable) {
      throw SymbolicMathNotAvailableException('SymEngine');
    }
    if (rows <= 0 || cols <= 0) {
      throw SymbolicMathException('matrix_create', 'Dimensions must be positive');
    }
    
    final ptr = _matrixNew(rows, cols);
    if (ptr == nullptr) {
      throw SymbolicMathMemoryException('matrix_create');
    }
    return SymEngineMatrix._fromPointer(ptr, this, rows, cols);
  }

  // Batch operations for efficiency
  Map<String, String> evaluateMultiple(List<String> expressions) {
    final results = <String, String>{};
    for (int i = 0; i < expressions.length; i++) {
      try {
        results['expr_$i'] = evaluate(expressions[i]);
      } catch (e) {
        results['expr_$i'] = 'Error: $e';
      }
    }
    return results;
  }

  // ============================================================================
  // UTILITY AND TEST METHODS
  // ============================================================================

  String getVersion() {
    if (!_symEngineAvailable) {
      return 'SymEngine not available';
    }
    
    final resultC = _version();
    // Note: version() returns const char*, don't free it
    return resultC.toDartString();
  }

  String testBasicOperations() {
    if (!_symEngineAvailable) {
      return 'SymEngine not available';
    }
    
    final resultC = _testBasic();
    if (resultC == nullptr) {
      return 'Test failed';
    }
    
    try {
      return resultC.toDartString();
    } finally {
      _freeString(resultC);
    }
  }

  String testSymbolic() {
    if (!_symEngineAvailable) {
      return 'SymEngine not available';
    }
    
    final resultC = _testSymbolic();
    if (resultC == nullptr) {
      return 'Test failed';
    }
    
    try {
      return resultC.toDartString();
    } finally {
      _freeString(resultC);
    }
  }

  Map<String, bool> getLibraryStatus() {
    return {
      'SymEngine Wrapper': _symEngineAvailable,
      'GMP Direct': false, // Not implemented yet
      'MPFR Direct': false, // Not implemented yet  
      'MPC Direct': false, // Not implemented yet
      'FLINT Direct': false, // Not implemented yet
    };
  }

  String getPreferredWrapperType() {
    if (_symEngineAvailable) return 'SymEngine Flutter Wrapper';
    return 'None Available';
  }

  List<String> getAvailableUnaryFunctions() {
    return _unaryFunctions.keys.toList();
  }

  List<String> getAvailableBinaryFunctions() {
    return _binaryFunctions.keys.toList();
  }

  List<String> getAvailableConstants() {
    return ['PI', 'E', 'GAMMA'];
  }

  // ============================================================================
  // HIGH-PRECISION METHODS - Add implementations as needed
  // ============================================================================

  // High-precision evaluation using MPFR
  String evaluateWithPrecision(String expression, int precision) {
    // TODO: Implement later
    throw SymbolicMathNotAvailableException('MPFR high-precision evaluation');
  }

  // GMP arbitrary precision power
  String gmpPower(String base, int exponent) {
    // TODO: Implement later
    throw SymbolicMathNotAvailableException('GMP power operation');
  }

  // MPFR high-precision pi. [precision] is the requested number of
  // decimal digits (1..10000). Implementation lives in
  // flutter_symengine_pi_with_precision (math-stack-ios-builder /
  // src/flutter_symengine_wrapper.c). The wrapper goes through
  // SymEngine's basic_const_pi + basic_evalf at the bit precision
  // derived from the requested decimal digits.
  String mpfrHighPrecisionPi(int precision) {
    if (!_symEngineAvailable) {
      throw SymbolicMathNotAvailableException('MPFR high-precision pi');
    }
    final fn = _piWithPrecision;
    if (fn == null) {
      throw SymbolicMathNotAvailableException(
          'flutter_symengine_pi_with_precision (older bridge build — '
          'rebuild from math-stack-ios-builder)');
    }
    if (precision < 1 || precision > 10000) {
      throw SymbolicMathException(
          'pi_with_precision', 'precision must be in 1..10000 (got $precision)');
    }
    final resultC = fn(precision);
    if (resultC == nullptr) {
      throw SymbolicMathException(
          'pi_with_precision', 'native returned null');
    }
    try {
      final result = resultC.toDartString();
      if (result.startsWith('Error in ')) {
        throw SymbolicMathException('pi_with_precision', result);
      }
      return result;
    } finally {
      _freeString(resultC);
    }
  }

  // Shared helper for the round-86 MPFR constants. `fn` is the
  // resolved native lookup (may be null on older bridge builds);
  // `op` is the label used in exceptions.
  String _callPrecisionFn(_FactorialDart? fn, String op, int precision) {
    if (!_symEngineAvailable) {
      throw SymbolicMathNotAvailableException('MPFR high-precision $op');
    }
    if (fn == null) {
      throw SymbolicMathNotAvailableException(
          'flutter_symengine_${op}_with_precision (older bridge build — '
          'rebuild from math-stack-ios-builder)');
    }
    if (precision < 1 || precision > 10000) {
      throw SymbolicMathException(
          '${op}_with_precision',
          'precision must be in 1..10000 (got $precision)');
    }
    final resultC = fn(precision);
    if (resultC == nullptr) {
      throw SymbolicMathException(
          '${op}_with_precision', 'native returned null');
    }
    try {
      final result = resultC.toDartString();
      if (result.startsWith('Error in ')) {
        throw SymbolicMathException('${op}_with_precision', result);
      }
      return result;
    } finally {
      _freeString(resultC);
    }
  }

  // MPFR high-precision e. See [mpfrHighPrecisionPi] for the
  // implementation pattern; the wrapper uses basic_const_E.
  String mpfrHighPrecisionE(int precision) =>
      _callPrecisionFn(_eWithPrecision, 'e', precision);

  // MPFR high-precision Euler–Mascheroni constant γ. Wrapper uses
  // basic_const_EulerGamma.
  String mpfrHighPrecisionEulerGamma(int precision) =>
      _callPrecisionFn(_eulerGammaWithPrecision, 'euler_gamma', precision);

  // MPFR high-precision √2. Wrapper parses `sqrt(2)` and evaluates.
  String mpfrHighPrecisionSqrt2(int precision) =>
      _callPrecisionFn(_sqrt2WithPrecision, 'sqrt2', precision);

  // Round 89: number-theory primitives. Each accepts an arbitrary-
  // precision decimal string. `isprime` returns "true" / "false";
  // `nextprime` / `prevprime` return a decimal string.
  String _callStringInOut(_UnaryFuncDart? fn, String op, String input) {
    if (!_symEngineAvailable) {
      throw SymbolicMathNotAvailableException(op);
    }
    if (fn == null) {
      throw SymbolicMathNotAvailableException(
          'flutter_symengine_$op (older bridge build — rebuild from '
          'math-stack-ios-builder)');
    }
    final inputC = input.toNativeUtf8();
    try {
      final resultC = fn(inputC);
      if (resultC == nullptr) {
        throw SymbolicMathException(op, 'native returned null');
      }
      try {
        final result = resultC.toDartString();
        if (result.startsWith('Error in ')) {
          throw SymbolicMathException(op, result);
        }
        return result;
      } finally {
        _freeString(resultC);
      }
    } finally {
      malloc.free(inputC);
    }
  }

  bool ntheoryIsprime(String n) =>
      _callStringInOut(_isprime, 'isprime', n) == 'true';

  String ntheoryNextprime(String n) =>
      _callStringInOut(_nextprime, 'nextprime', n);

  String ntheoryPrevprime(String n) =>
      _callStringInOut(_prevprime, 'prevprime', n);

  // Round 90: integer factorization via FLINT. Returns the raw
  // `"p1^e1*p2^e2*..."` string; the CrispCalc engine parses this
  // into structured `(prime, exponent)` records.
  String ntheoryFactorint(String n) =>
      _callStringInOut(_factorint, 'factorint', n);
}