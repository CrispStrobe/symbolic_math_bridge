// Exception types for the symbolic-math bridge.
//
// Platform-agnostic (pure Dart, no dart:ffi / dart:io) so both the
// native FFI implementation and the web stub can share — and throw —
// the same exception hierarchy. Exported from the public
// `symbolic_math_bridge.dart` facade.

/// Base class for every error raised by the symbolic-math bridge.
///
/// Carries the [operation] that failed, a human-readable [message], and
/// optionally the native [library] that reported the error.
class SymbolicMathException implements Exception {
  /// The bridge operation that failed (e.g. `evaluate`, `matrix_set`).
  final String operation;

  /// A human-readable description of what went wrong.
  final String message;

  /// The native library that reported the error, if known.
  final String? library;

  /// Creates an exception for [operation] with [message] and optional
  /// [library].
  SymbolicMathException(this.operation, this.message, [this.library]);

  @override
  String toString() {
    final libPrefix = library != null ? '[$library] ' : '';
    return 'SymbolicMathException: $libPrefix$operation - $message';
  }
}

/// Thrown when an expression cannot be parsed (invalid syntax or arguments).
class SymbolicMathParseException extends SymbolicMathException {
  /// Creates a parse exception for [operation] with [message].
  SymbolicMathParseException(
    super.operation,
    super.message, [
    super.library,
  ]);
}

/// Thrown when the native side fails to allocate memory for an operation.
class SymbolicMathMemoryException extends SymbolicMathException {
  /// Creates a memory-allocation exception for [operation].
  SymbolicMathMemoryException(String operation, [String? library])
      : super(operation, 'Memory allocation failed', library);
}

/// Thrown when the native symbolic-math [library] is unavailable — for
/// example on the web, or when the shared library cannot be loaded.
class SymbolicMathNotAvailableException extends SymbolicMathException {
  /// Creates a not-available exception naming the missing [library].
  SymbolicMathNotAvailableException(String library)
      : super('initialize', 'Library not available: $library', library);
}
