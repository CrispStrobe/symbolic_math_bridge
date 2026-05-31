// Exception types for the symbolic-math bridge.
//
// Platform-agnostic (pure Dart, no dart:ffi / dart:io) so both the
// native FFI implementation and the web stub can share — and throw —
// the same exception hierarchy. Exported from the public
// `symbolic_math_bridge.dart` facade.

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
  SymbolicMathParseException(
    String operation,
    String message, [
    String? library,
  ]) : super(operation, message, library);
}

class SymbolicMathMemoryException extends SymbolicMathException {
  SymbolicMathMemoryException(String operation, [String? library])
      : super(operation, 'Memory allocation failed', library);
}

class SymbolicMathNotAvailableException extends SymbolicMathException {
  SymbolicMathNotAvailableException(String library)
      : super('initialize', 'Library not available: $library', library);
}
