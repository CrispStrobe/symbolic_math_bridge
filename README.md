# symbolic_math_bridge

[![pub package](https://img.shields.io/badge/Flutter-Plugin-blue)](https://flutter.dev/to/develop-plugins)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20Android%20%7C%20Windows-lightgrey)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT%20%2B%20LGPL%20native%20deps-yellow)](THIRD-PARTY-NOTICES.md)

A comprehensive Flutter plugin providing unified `dart:ffi` access to a powerful mathematical computing stack. This plugin integrates **GMP, MPFR, MPC, FLINT, and SymEngine** libraries, offering both high-level symbolic computation and direct, low-level access to each library's core functions.

> **Platform status (v1.3.0):** full SymEngine on **iOS, macOS,
> Android (arm64-v8a), Windows (x86_64), Linux (x86_64), Web (WASM)**.
>
> | Platform | Artifact | Built by |
> |---|---|---|
> | iOS, macOS | `.xcframework` bundles under `ios/` | `math-stack-ios-builder` (separate repo) |
> | Android arm64-v8a | `android/src/main/jniLibs/arm64-v8a/libsymbolic_math_bridge.so` | `.github/workflows/build-android.yml` (vcpkg + NDK cross-compile) |
> | Windows x86_64 | `windows/Libraries/libsymbolic_math_bridge.dll` | `.github/workflows/build-windows.yml` (MSYS2/MinGW64 + source-built SymEngine) |
> | Linux x86_64 | `linux/Libraries/libsymbolic_math_bridge.so` | `.github/workflows/build-linux.yml` (vcpkg x64-linux static) |
> | **Web (WASM)** | `symengine.js` + `symengine.wasm` (1.1 MB) | `math-stack-ios-builder` Emscripten build (`INTEGER_CLASS=boostmp`) |
>
> The web build provides full CAS (evaluate, expand, differentiate,
> solve, substitute, trig/hyp/exp/log, gcd/lcm/factorial/fibonacci,
> matrices). Functions requiring GMP/MPFR/FLINT (isprime, factorint,
> Bessel, arbitrary-precision evalf, modular arithmetic) return clean
> error strings.
>
> See [`ANDROID_STATUS.md`](ANDROID_STATUS.md),
> [`WINDOWS_STATUS.md`](WINDOWS_STATUS.md), and
> [`LINUX_STATUS.md`](LINUX_STATUS.md) for per-platform iteration logs.

## Features

### 🔥 **High-Level Symbolic Computing (SymEngine)**
- Algebraic expression evaluation and simplification
- Equation solving (polynomial, transcendental)
- Symbolic differentiation and integration
- Expression factoring and expansion
- Mathematical function evaluation

### 🔢 **Arbitrary Precision Integer Arithmetic (GMP)**
- Unlimited precision integer operations
- Modular arithmetic and number theory functions
- Cryptographic computations
- Large number factorization

### 🎯 **Arbitrary Precision Floating-Point (MPFR)**
- Correctly rounded arbitrary precision real numbers
- All standard mathematical functions (sin, cos, exp, log, etc.)
- Special functions (gamma, Bessel, etc.)
- Configurable precision up to memory limits

### 🔵 **Arbitrary Precision Complex Numbers (MPC)**
- Complex arithmetic with arbitrary precision
- Complex mathematical functions
- Polar and rectangular forms
- Integration with MPFR for real/imaginary parts

### 🧮 **Advanced Number Theory (FLINT)**
- Polynomial arithmetic over various rings
- Integer factorization algorithms
- Matrix operations over exact rings
- Optimized algorithms for number theory

### 🔗 **Type-Safe FFI**
- Clean, type-safe Dart API that abstracts away C interoperability complexities
- Automatic memory management for most operations
- Matrix algebra with determinant and inversion operations

## Quick Start

### Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  symbolic_math_bridge: ^1.5.0
```

### Basic Usage

```dart
import 'package:symbolic_math_bridge/symbolic_math_bridge.dart';

void main() {
  final bridge = SymbolicMathBridge();
  
  // High-level symbolic computing
  print('Evaluate: ${bridge.evaluate("2 + 3*4")}');            // → 14
  print('Solve: ${bridge.solve("x^2 - 4", "x")}');              // → [-2, 2]
  print('Expand: ${bridge.expand("(x + 1)^2")}');              // → 1 + 2*x + x^2
  print('Differentiate: ${bridge.differentiate("sin(x)", "x")}'); // → cos(x)
  print('Log: ${bridge.callUnary("log", "E")}');              // → 1
  
  // Matrix operations
  final matrix = bridge.createMatrix(2, 2);
  matrix.set(0, 0, "4");
  matrix.set(0, 1, "7");
  matrix.set(1, 0, "2");
  matrix.set(1, 1, "6");
  print('Matrix Determinant: ${matrix.getDeterminant()}');      // → 10
  matrix.dispose(); // Important: free the native memory
  
  // Direct library testing
  print('GMP: ${bridge.testGMPDirect(256)}');                  // → 2^256 (78 digits)
  print('MPFR: ${bridge.testMPFRDirect()}');                   // → High-precision π
  print('MPC: ${bridge.testMPCDirect()}');                     // → Complex: (3+4i)×(1+2i)
  print('FLINT: ${bridge.testFLINTDirect()}');                 // → 20! = 2432902008176640000
}
```

## API Reference

The primary class is `SymbolicMathBridge`, which provides a singleton instance for all mathematical operations.

### Core Symbolic Operations

- `String evaluate(String expression)` - Evaluate mathematical expressions
- `String expand(String expression)` - Expand algebraic expressions
- `String solve(String expression, String symbol)` - Solve equations for a symbol
- `String differentiate(String expression, String symbol)` - Symbolic differentiation
- `String substitute(String expr, String sym, String val)` - Substitute values in expressions

### Unary Mathematical Functions

- `String callUnary(String funcName, String expression)`

Available function names: `abs`, `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `sinh`, `cosh`, `tanh`, `asinh`, `acosh`, `atanh`, `exp`, `log`, `sqrt`, `gamma`

### Number Theory Functions

- `String gcd(String a, String b)` - Greatest common divisor
- `String lcm(String a, String b)` - Least common multiple
- `String factorial(int n)` - Factorial calculation
- `String fibonacci(int n)` - Fibonacci number calculation

### Matrix Operations

- `SymEngineMatrix createMatrix(int rows, int cols)` - Create a new matrix
- `matrix.set(int row, int col, String value)` - Set matrix element
- `String matrix.get(int row, int col)` - Get matrix element
- `String matrix.getDeterminant()` - Calculate matrix determinant
- `SymEngineMatrix matrix.inverse()` - Calculate matrix inverse
- `matrix.dispose()` - **Crucial for preventing memory leaks**

### Direct Library Access

For maximum performance and direct access to library functions:

- `String testGMPDirect(int exponent)` - GMP: Calculate 2^exponent
- `String testMPFRDirect()` - MPFR: High-precision π calculation
- `String testMPCDirect()` - MPC: Complex arithmetic example
- `String testFLINTDirect()` - FLINT: Factorial calculation

### Library Status and Diagnostics

- `Map<String, bool> getLibraryStatus()` - Check which libraries are available
- `Map<String, List<String>> getTestResults()` - Get comprehensive test results

## Architecture

This plugin uses a robust FFI architecture to bridge the gap between Dart and the native C/C++ libraries, solving the complex problem of integrating multiple interdependent mathematical libraries into a Flutter application.

### The Symbol Linking Challenge

When Flutter apps use native C libraries via FFI, the iOS linker often strips "unused" symbols from the final binary to save space. However, these symbols are actually used at runtime by Dart's FFI, causing "symbol not found" errors. Our solution applies forced symbol loading: The plugin includes a `SymEngineBridge.m` file that explicitly references over 100 core functions from all five mathematical libraries:

```objc
// Forces the linker to preserve all symbols
static void* refs[] = {
    // SymEngine symbols
    symengine_evaluate, symengine_solve, symengine_factor, /* ... */
    
    // GMP symbols  
    (void *)__gmpz_init_set_str, (void *)__gmpz_pow_ui, /* ... */
    
    // MPFR symbols
    (void *)mpfr_init2, (void *)mpfr_const_pi, /* ... */
    
    // MPC symbols
    (void *)mpc_init2, (void *)mpc_mul, /* ... */
    
    // FLINT symbols
    (void *)fmpz_init, (void *)fmpz_fac_ui, /* ... */
};
```

This approach ensures all symbols remain available for Dart FFI lookup via `dlsym()`.

### Plugin Configuration

The `symbolic_math_bridge.podspec` is configured to correctly integrate the native libraries:

```ruby
# The podspec references the single, combined wrapper
s.vendored_frameworks = [
  'GMP.xcframework',
  'MPFR.xcframework', 
  'MPC.xcframework',
  'FLINT.xcframework',
  'SymEngineFlutterWrapper.xcframework'
]

# Linker flags to prevent dead code stripping
s.pod_target_xcconfig = {
  'OTHER_LDFLAGS' => '-all_load',
  'STRIP_STYLE' => 'debugging',
  'DEAD_CODE_STRIPPING' => 'NO'
}
```

## Building the Native Libraries from Source

This plugin requires pre-built `.xcframework` files for the underlying C/C++ libraries. These are generated using the companion [math-stack-ios-builder](https://github.com/CrispStrobe/math-stack-ios-builder) repository. The streamlined build process handles everything from compilation to verification.

### 1. Clone the Builder Repository

```bash
git clone https://github.com/CrispStrobe/math-stack-ios-builder.git
cd math-stack-ios-builder
```

### 2. Download Source Archives

Ensure the required tarballs (e.g., `gmp-6.3.0.tar.bz2`, `mpfr-4.2.2.tar.xz`, etc.) are present in the directory.

### 3. Run the Master Build Script

This single command compiles all libraries in the correct order, patches them for CocoaPods compatibility, and verifies the final artifacts:

```bash
# Make all build scripts executable
chmod +x build_*.sh

# Run the master script
./build_all.sh
```

### 4. Automated Verification & Copy

After a successful build, the script will automatically verify the integrity of all generated `.xcframework` files. It will then prompt you to copy the new frameworks directly into the `symbolic_math_bridge` plugin directory, completing the workflow.

## Platform Support

- ✅ **iOS**: 13.0+ (arm64 device, arm64/x86_64 simulator)
- ✅ **macOS**: 10.15+ (arm64/x86_64 universal)
- ✅ **Android**: arm64-v8a (v1.1.0)
- ✅ **Windows**: x86_64 (v1.1.0)
- ✅ **Linux**: x86_64, GLIBC 2.35+ (v1.2.0)
- ✅ **Web**: WASM via Emscripten (v1.3.0) — full CAS core, no MPFR/FLINT

## Performance Characteristics

| Library | Use Case | Performance |
|---------|----------|-------------|
| **SymEngine** | Symbolic math, CAS operations | Very fast C++ engine |
| **GMP** | Large integer arithmetic | Highly optimized assembly |
| **MPFR** | High-precision floating-point | Correctly rounded results |
| **MPC** | Complex number arithmetic | Built on MPFR foundation |
| **FLINT** | Number theory algorithms | Specialized optimizations |

## Example Results

```dart
// High-level symbolic computing
bridge.evaluate('2 + 3*4')                    // → 14
bridge.solve('x^2 - 4', 'x')                  // → [-2, 2]
bridge.expand('(x + 1)^2')                    // → 1 + 2*x + x^2
bridge.differentiate('sin(x)', 'x')           // → cos(x)

// Number theory
bridge.gcd('48', '18')                        // → 6
bridge.fibonacci(10)                          // → 55
```

## Related Projects

- **[math-stack-ios-builder](https://github.com/CrispStrobe/math-stack-ios-builder)**: Build system for generating the native `.xcframework` libraries
- **[math-stack-test](https://github.com/CrispStrobe/math-stack-test)**: Comprehensive demo application showcasing the plugin's full functionality

## License

The Dart, Flutter, Swift, Objective-C and C wrapper code written in this
repository is released under the **MIT License**. This package also distributes
prebuilt native math libraries, so the complete distributed package has mixed
license obligations. Those native libraries are not relicensed by this
repository:

| Component | License |
|-----------|---------|
| SymEngine | MIT |
| GMP | LGPL-3.0-or-later / GPL-2.0-or-later |
| MPFR | LGPL-3.0-or-later |
| MPC | LGPL-3.0-or-later |
| FLINT | LGPL-2.1-or-later |
| Bundled SymEngine header utilities | BSD-3-Clause and GNU Bison special-exception parser skeletons, where present |

If you distribute an app that links the bundled LGPL libraries, you must provide
the notices, source/build information, and rebuild or relink path those licenses
require. See [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) and the builder
repo's [LGPL-COMPLIANCE.md](https://github.com/CrispStrobe/math-stack-ios-builder/blob/master/LGPL-COMPLIANCE.md).
