// Public entry point for the symbolic-math bridge.
//
// Conditional export: every platform with `dart:io` (iOS / macOS /
// Android / Windows / Linux) gets the native `dart:ffi` implementation;
// the web build — which has neither `dart:ffi` nor `dart:io` — gets a
// pure-Dart stub whose constructor throws
// `SymbolicMathNotAvailableException`, so consumers transparently fall
// back to their "native library unavailable" path. The exception
// hierarchy is platform-agnostic and always exported.
//
// `dart.library.io` is the condition because it is reliably true on the
// native VM and false on every web target (dart2js *and* dart2wasm),
// unlike `dart.library.html` which is absent under wasm.
export 'src/symbolic_math_exceptions.dart';
export 'src/symbolic_math_bridge_web.dart'
    if (dart.library.io) 'src/symbolic_math_bridge_io.dart';
