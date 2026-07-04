## 1.4.0 (2026-07-04)

Taylor series + symbolic linear-system solve (native).

* **`series(expression, symbol, {point, order})`** — Taylor/Maclaurin
  expansion via SymEngine's C++ `series()` (FLINT-backed). Expansion
  about a non-zero point is handled by the shift substitution in the
  wrapper. New wrapper entry point `flutter_symengine_series`.
* **`linsolve(equations, symbols)`** — symbolic linear-system solve via
  SymEngine's C++ `linsolve()`; equations accept "lhs = rhs" or
  expressions implicitly = 0, result is "[v1, v2, ...]" in symbol
  order. New wrapper entry point `flutter_symengine_linsolve`.
* **`hasSeries` / `hasLinsolve`** capability getters; the FFI lookups
  are optional, so the Dart API degrades gracefully on older native
  libraries.
* Web: both gated off (`hasSeries`/`hasLinsolve` = false) until the
  WASM build exports the new entry points.
* Rebuilt `SymEngineFlutterWrapper.xcframework` (incremental wrapper
  relink; iOS device/sim + macOS).
* Note: pubspec `version:` field was lagging at 1.2.1 while the 1.3.0
  release shipped — both catch up to 1.4.0 here.

## 1.3.0 (2026-05-31)

Web support via SymEngine WASM. The bridge now provides real CAS
operations in the browser — the throw-only web stub has been replaced
with a `dart:js_interop` implementation that calls into SymEngine
compiled to WebAssembly.

* **`symbolic_math_bridge_web.dart` rewritten** from a throw-only stub
  to a full WASM bridge. Uses Emscripten's `ccall` via `dart:js_interop`
  to invoke all 55 `flutter_symengine_*` C functions in the WASM module.
* **Two-phase loading**: constructor throws until the WASM module has
  loaded (preserving the existing consumer pattern), then all CAS calls
  route through WASM. `SymbolicMathBridge.tryLoadWasm()` lets consumers
  check/trigger readiness. `NumericFallbackEvaluator` remains the
  synchronous pre-load path — no behavior change before WASM is ready.
* **Full CAS core on web**: evaluate, expand, differentiate, solve,
  substitute, 17 unary math functions (sin/cos/tan/asin/acos/atan/
  sinh/cosh/tanh/asinh/acosh/atanh/exp/log/sqrt/gamma/abs),
  gcd/lcm/factorial/fibonacci, symbolic constants (pi/e/gamma), and
  matrix operations (create/set/get/det/inv/add/mul).
* **Clean degradation for GMP/MPFR/FLINT features**: isprime,
  nextprime, prevprime, factorint, modpow, modinv, totient, jacobi,
  Bessel J/Y, arbitrary-precision evalf/cevalf, and precision constants
  all call into WASM stubs that return `"Error in <op>: not available
  in web build (requires GMP/MPFR/FLINT)"` — consumers see the same
  `SymbolicMathException` they already handle.
* **Matrix ops via opaque pointers**: WASM pointers are `i32` indices
  passed as `'number'` type through `ccall`. The Dart `SymEngineMatrix`
  class holds the int handle and passes it back on each matrix call.

### WASM module (built in math-stack-ios-builder)

* SymEngine 0.11.2 + Boost.Multiprecision 1.87 (header-only).
* `INTEGER_CLASS=boostmp` — no GMP/MPFR/FLINT native deps.
* Emscripten 5.0.7, `-O2`, `MODULARIZE=1`.
* Output: `symengine.js` (24 KB glue) + `symengine.wasm` (1.1 MB).
* Ships in `CrispCalc/web/`; loaded via `<script>` before Flutter
  bootstrap.

## 1.2.1 (2026-05-29)

Windows runtime loader fix. In a consumer build the SymEngine wrapper
symbols live in the bundled `libsymbolic_math_bridge.dll`, while the
side-by-side `symbolic_math_bridge_plugin.dll` is only the thin
Flutter registrar (no `flutter_symengine_*` exports in
consumer-prebuilt mode). The Dart loader was opening the registrar
DLL, so on a real Windows desktop every FFI lookup would fail with
"requires native library".

* `_openNativeLibrary()` now tries `libsymbolic_math_bridge.dll` first
  (the consumer layout) and falls back to
  `symbolic_math_bridge_plugin.dll` (the CI full-from-source layout).
  Strictly non-regressive — the old name is still attempted.

Reasoned-correct from the Windows `GetProcAddress` single-module
resolution semantics + the consumer CMake's symbol split; still wants
a real-hardware runtime confirmation (no Windows host available here).

## 1.2.0 (2026-05-29)

Linux x86_64 support (P11 R130). The last tier-1 platform — the
bridge now ships full SymEngine on iOS / macOS / Android arm64-v8a /
Windows x86_64 / **Linux x86_64**.

* **`linux/` plugin** added. A hybrid of the Android and Windows
  patterns: statically links the whole math stack (SymEngine + FLINT
  + MPFR + MPC + GMP) into one `libsymbolic_math_bridge.so` like
  Android, with three-mode `CMakeLists.txt` like Windows
  (`full-from-source` for CI / `consumer-prebuilt` to bundle the
  committed `.so` / `degraded` fallback). Simpler than Windows: a
  Linux `ffiPlugin` needs no registrar `.cc` and no `flutter`
  linkage, so the consumer path is pure bundling — and there's no
  filename collision (Dart opens `libsymbolic_math_bridge.so`, which
  is exactly what `add_library()` emits).
* **`build-linux.yml`** workflow: vcpkg `x64-linux` (static) triplet
  on `ubuntu-22.04`, pinned for a GLIBC 2.35 baseline. First green
  run built an 18.3 MB stripped `.so` whose only dynamic deps are
  libc / libstdc++ / libm / libgcc_s (verified via `ldd`), with all
  `flutter_symengine_*` symbols in `.dynsym` and max referenced
  symbol GLIBC_2.35.
* **Committed binary** at `linux/Libraries/libsymbolic_math_bridge.so`.
* **`pubspec.yaml`**: `linux: ffiPlugin: true`.

## 1.1.1 (2026-05-27)

Consumer-integration fixes for v1.1.0's Android + Windows binaries.
v1.1.0 shipped working binaries but the consumer-side wiring tried
to compile from source in `flutter build` — which fails because
consumer machines don't have SymEngine installed. This release
restructures the plugin to use the pre-built binaries directly.

* **Android `build.gradle`: dropped `externalNativeBuild`**. For an
  `ffiPlugin: true` Android module, `jniLibs` alone is sufficient
  to package the `.so` into the consumer's APK. The CI workflow
  (`build-android.yml`) still invokes `android/CMakeLists.txt`
  directly to cross-compile the `.so` from source — that path is
  unchanged; only the consumer-side Gradle path is now CMake-free.
* **Windows `CMakeLists.txt`: three build modes**:
  - `FLUTTER_PLUGIN_STANDALONE=ON` + `SymEngine_FOUND` → build the
    full wrapper from source (CI workflow only).
  - Default consumer build with `windows/Libraries/libsymbolic_math_bridge.dll`
    present → compile only the thin registrar from
    `symbolic_math_bridge_plugin.cpp`; bundle the pre-built
    `libsymbolic_math_bridge.dll` via
    `symbolic_math_bridge_bundled_libraries`. No SymEngine
    needed on the consumer machine.
  - No `SymEngine` + no pre-built DLL → registrar-stub mode. The
    plugin DLL still exists for Flutter's plugin contract; FFI
    calls return errors (same as today's Linux degraded path).
* **Renamed `windows/Libraries/symbolic_math_bridge_plugin.dll` →
  `libsymbolic_math_bridge.dll`** to avoid a filename collision
  with the registrar DLL Flutter's CMake builds in consumer mode.
  The two DLLs ship side-by-side in the consumer's runner output
  directory.
* **Dart `symbolic_math_bridge.dart` — per-platform
  `DynamicLibrary.open`**:
  - iOS / macOS: `DynamicLibrary.process()` (static-linked)
  - Android: `DynamicLibrary.open('libsymbolic_math_bridge.so')`
  - Windows: `DynamicLibrary.open('libsymbolic_math_bridge.dll')`
  - Linux (fallback): same as Android name; degraded gracefully
    when the open fails.
  Replaces the prior catch-all `libSymEngineFlutterWrapper.so`
  which never matched our actual shipped binary names.
* `build-windows.yml`: strip step now renames the built DLL to
  `libsymbolic_math_bridge.dll` before artifact upload so the
  artifact name matches what we commit to `windows/Libraries/`.

## 1.1.0 (2026-05-27)

Full SymEngine bridge now works on **four** native platforms.
iOS and macOS were already supported via the
`math-stack-ios-builder` repo. This release adds:

### Android arm64-v8a (R132)

* `android/` directory: Gradle module, CMakeLists, Kotlin plugin
  glue with JNI force-link entry point, AndroidManifest, scaffold
  build script, declared `android` platform in `pubspec.yaml` with
  `ffiPlugin: true` and `package: be.crispstro.symbolic_math_bridge`.
* `.github/workflows/build-android.yml` — `ubuntu-latest` + vcpkg
  manifest install of `symengine[flint,mpfr]` against the
  `arm64-android-release` triplet, with `VCPKG_CHAINLOAD_TOOLCHAIN_FILE`
  set to the NDK's `android.toolchain.cmake` so the consumer build
  uses the same cross-toolchain vcpkg uses for its port builds.
  ~14 min cold cache; reproducibly green.
* `android/src/main/jniLibs/arm64-v8a/libsymbolic_math_bridge.so`
  committed (17 MB stripped, full ELF arm64-v8a, all
  `flutter_symengine_*` symbols exported, verified by `llvm-nm
  --dynamic-only`).
* Per-iteration debug log in [`ANDROID_STATUS.md`](ANDROID_STATUS.md)
  (7 iterations: mpfr autotools deps → arb-pulls-back-LLVM →
  builtin-baseline → JSON schema → `SymEngine` capitalization →
  `<jni.h>` optional → `VCPKG_CHAINLOAD_TOOLCHAIN_FILE`).

### Windows x86_64 (R131)

* `windows/` directory: Flutter Windows plugin module with
  `CMakeLists.txt`, plugin C++ glue, force-link C source, declared
  `windows` platform in `pubspec.yaml` with `ffiPlugin: true` and
  `pluginClass: SymbolicMathBridgePluginCApi`.
* `.github/workflows/build-windows.yml` — `windows-latest` +
  MSYS2/MinGW64 (`msys2/setup-msys2@v2`) + pacman pre-built
  `flint/mpfr/gmp/mpc/boost` + `actions/cache@v4`-keyed SymEngine
  source build via CMake+ninja. Static-linked MinGW runtime
  (`-static-libgcc -static-libstdc++`), `--export-all-symbols` to
  ensure wrapper symbols land in the DLL Export Table. ~7 min
  cold cache; ~5 min cached.
* `windows/Libraries/symbolic_math_bridge_plugin.dll` committed
  (5.7 MB stripped PE32+ x86_64, all `flutter_symengine_*` symbols
  in the Export Table, verified by `objdump -p`).
* The vcpkg+MSVC path was abandoned after 6 attempts hit the GHA
  6-hour Windows runner cap during cold-cache install (boost-math
  + flint + symengine compile is genuinely too slow on free Windows
  runners). MinGW64 is structurally faster because flint/mpfr/gmp/
  mpc/boost come pre-built from MSYS2 — only SymEngine itself
  needs compiling. Per-iteration debug log in
  [`WINDOWS_STATUS.md`](WINDOWS_STATUS.md).

### Cross-cutting

* New top-level `src/flutter_symengine_wrapper.{c,h}` — the 749-line
  C wrapper source vendored from `math-stack-ios-builder/src/`
  (identical content, verified by diff). Both Android and Windows
  CMakeLists compile against this single source of truth. iOS/macOS
  continue using their pre-built `.xcframework` bundles.
* Static-linking everywhere, mirroring iOS/macOS — no runtime DLL/
  .so dependency on libgcc / libstdc++ / libwinpthread / NDK
  libc++_shared. Single binary per platform.
* MIT licensed bridge code; LGPL-3+ static dependencies (FLINT,
  MPFR, MPC, GMP) require shipping their license texts in the
  consuming application. CrispCalc already does this in
  `assets/licenses/SYMENGINE_STACK.txt`.

### Known limitations

* **Android x86_64** (for emulators) and **armeabi-v7a** (32-bit
  phones) not yet built. Matrix the workflow when needed.
* **Linux** not yet built. Tracked as PLAN P11 R130 in the
  CrispCalc host repo; the vcpkg pattern that worked for Android
  should adapt directly (same `ubuntu-latest` runner, no NDK
  chainload needed since the host IS Linux).
* **Smoke-tested**: compile + link + symbols-in-export-table
  verified in CI. End-to-end runtime FFI call from a Flutter app
  on a real Android device or Windows desktop is the natural
  follow-up.

## 0.0.1

* TODO: Describe initial release.
