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
