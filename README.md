# symbolic_math_bridge

[![pub package](https://img.shields.io/badge/Flutter-Plugin-blue)](https://flutter.dev/to/develop-plugins)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS-lightgrey)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-yellow)](https://opensource.org/licenses/MIT)

A comprehensive Flutter plugin providing unified access to the mathematical computing stack for iOS and macOS. This plugin integrates **GMP, MPFR, MPC, FLINT, and SymEngine** libraries, offering both high-level symbolic computation and direct low-level mathematical operations.

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

## Quick Start

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  symbolic_math_bridge:
    path: ../symbolic_math_bridge  # Adjust path as needed
```

Then use it in your Dart code:

```dart
import 'package:symbolic_math_bridge/symbolic_math_bridge.dart';

void main() {
  final casBridge = CasBridge();
  
  // High-level symbolic computing
  print(casBridge.evaluate('2 + 3*4'));                    // → 14
  print(casBridge.solve('x^2 - 4', 'x'));                  // → 2, -2
  print(casBridge.expand('(x + 1)^2'));                    // → 1 + 2*x + x^2
  print(casBridge.factor('x^2 - 1'));                      // → (-1 + x)*(1 + x)
  
  // Direct arbitrary-precision arithmetic
  print(casBridge.testGMPDirect(256));                     // → 2^256 (78 digits)
  print(casBridge.testMPFRDirect());                       // → High-precision π
  print(casBridge.testMPCDirect());                        // → Complex: (3+4i)×(1+2i)
  print(casBridge.testFLINTDirect());                      // → 20! = 2432902008176640000
}
```

## Architecture

This plugin circumvents the problem of integrating multiple interdependent C/C++ mathematical libraries into a Flutter application. Our solution uses a simple approach to prevent symbol stripping and ensure all library functions are available at runtime.

### The Symbol Linking Challenge

When Flutter apps use native C libraries via FFI, the iOS linker often strips "unused" symbols from the final binary to save space. However, these symbols are actually used at runtime by Dart's FFI, causing "symbol not found" errors.

### Our Solution: Forced Symbol Loading

The plugin includes a `SymEngineBridge.m` file that explicitly references 40+ core functions from all mathematical libraries:

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

The `symbolic_math_bridge.podspec` uses several key settings:

```ruby
# Prevent symbol stripping
s.pod_target_xcconfig = {
  'OTHER_LDFLAGS' => '-lc++ -lsymengine_wrapper -all_load',
  'STRIP_STYLE' => 'debugging',
  'DEAD_CODE_STRIPPING' => 'NO'
}

# Include all mathematical libraries as XCFrameworks
s.vendored_frameworks = [
  'GMP.xcframework',
  'MPFR.xcframework', 
  'MPC.xcframework',
  'FLINT.xcframework',
  'SymEngineWrapper.xcframework'
]
```

## API Reference

### CasBridge Class

The main class providing access to all mathematical libraries:

```dart
class CasBridge {
  // SymEngine high-level operations
  String evaluate(String expression);
  String solve(String expression, String symbol);
  String factor(String expression);
  String expand(String expression);
  
  // Direct library access for maximum performance
  String testGMPDirect(int exponent);      // GMP: 2^exponent
  String testMPFRDirect();                 // MPFR: high-precision π
  String testMPCDirect();                  // MPC: complex arithmetic
  String testFLINTDirect();                // FLINT: factorial calculation
  
  // Status and diagnostics
  Map<String, bool> getLibraryStatus();
  Map<String, List<String>> getTestResults();
}
```

### Library Status

Check which libraries are available:

```dart
final status = casBridge.getLibraryStatus();
// Returns: {
//   'SymEngine Wrapper': true,
//   'GMP Direct': true,
//   'MPFR Direct': true,
//   'MPC Direct': true,
//   'FLINT Direct': true
// }
```

## Building from Source

This plugin requires pre-built XCFrameworks. Build them using the companion repository:

```bash
# Clone and build the mathematical libraries
git clone https://github.com/CrispStrobe/math-stack-ios-builder.git
cd math-stack-ios-builder

# Download source archives (gmp-6.3.0.tar.bz2, mpfr-4.2.2.tar.xz, etc.)
# Build in dependency order
./build_gmp.sh
./build_mpfr.sh  
./build_mpc.sh
./build_flint.sh
./build_symengine.sh

# Copy to plugin
./copy_symengine_wrapper.sh
```

## Platform Support

- ✅ **iOS**: 13.0+ (arm64 device, arm64/x86_64 simulator)
- ✅ **macOS**: 10.15+ (arm64/x86_64 universal)
- ❌ **Android**: Not yet implemented
- ❌ **Web**: Cannot support native C libraries

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
casBridge.evaluate('solve(x^2 + 2*x + 1, x)')  // → -1

// Arbitrary precision (GMP): 2^256  
// → 115792089237316195423570985008687907853269984665640564039457584007913129639936

// High precision π (MPFR, 256 bits)
// → 3.1415926535897932384626433832795028841971693993751058209749445923

// Complex arithmetic (MPC): (3+4i) × (1+2i)
// → (-5.0000000000000000e+00 1.0000000000000000e+01)

// Number theory (FLINT): 20!
// → 2432902008176640000
```

## Contributing

This plugin is part of a larger mathematical computing ecosystem. Contributions are welcome, particularly for:

- Android support
- Additional SymEngine wrapper functions  
- More direct library function bindings
- Performance optimizations
- Documentation improvements

## Related Projects

- **[math-stack-ios-builder](https://github.com/CrispStrobe/math-stack-ios-builder)**: Build system for the native libraries
- **[math-stack-test](https://github.com/CrispStrobe/math-stack-test)**: Comprehensive demo application

## License

This plugin is released under the **MIT License**. The underlying mathematical libraries (GMP, MPFR, MPC, FLINT, SymEngine) have their own licenses (LGPL, GPL, BSD) which you must comply with in your application.