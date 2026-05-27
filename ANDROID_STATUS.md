# Android — R132 scaffold

**Status (2026-05-27): scaffold-only on branch `r132-android-scaffold`.
Not merged to main. Not pinned by CrispCalc.**

This branch lands the Flutter plugin's `android/` directory structure but
does **not** ship the per-ABI native artifacts. A consumer that
`flutter pub get`s against this branch and then runs `flutter build apk`
will:

- ✅ Build successfully (the Gradle module + CMakeLists + Kotlin glue all
  assemble; the resulting `libsymbolic_math_bridge.so` carries the
  Kotlin↔C glue + force-link symbol table but no actual SymEngine
  implementation)
- ❌ Resolve every `flutter_symengine_*` FFI call to an "unavailable"
  fallback path at runtime (same behaviour as today's Linux / Windows
  builds — CrispCalc's `EngineService` already handles this)

## What this branch *does* ship

| Path | Purpose |
|---|---|
| `android/build.gradle` | Plugin Gradle module: `compileSdk 34`, `minSdk 21`, `abiFilters arm64-v8a/armeabi-v7a/x86_64`, externalNativeBuild → CMakeLists, `doNotStrip` for the wrapper symbols |
| `android/CMakeLists.txt` | Imports per-ABI prebuilt `.a` archives (gmp, mpfr, mpc, flint, symengine, symengine_flutter_wrapper), links them into `libsymbolic_math_bridge.so` with `--whole-archive` around the wrapper to defeat dead-code stripping. Emits a clear warning when archives are missing. |
| `android/src/main/AndroidManifest.xml` | Empty manifest (FFI plugins need no Android permissions) |
| `android/src/main/kotlin/.../SymbolicMathBridgePlugin.kt` | Plugin glue. `System.loadLibrary` before dart:ffi races it. Calls `forceLinkSymbols()` to pin the wrapper symbols. Catches load failures gracefully — falls through to the unavailable path rather than crashing. |
| `android/src/main/cpp/force_link.c` | Android equivalent of iOS's `SymEngineBridge.m` + `DummySymbols.c` trick. Takes addresses of 45+ `flutter_symengine_*` entry points so the static linker keeps them. |
| `android/src/main/jniLibs/.gitkeep` | Placeholder for the per-ABI `.a` archives (written by the build script when R132 actually runs the cross-compile). |
| `scripts/build_android.sh` | Orchestration entry point. Today: prints next-step instructions and exits. Future: invokes the math-stack-android-builder per-library scripts in dependency order. |
| `pubspec.yaml` | Declares the `android` platform with `ffiPlugin: true` and `package: be.crispstro.symbolic_math_bridge`. |

## What this branch does *not* ship

| Piece | Where it'll live | Effort |
|---|---|---|
| `math-stack-android-builder/` sibling repo | New repo, parallel to `math-stack-ios-builder/`. Reuses the same source tarballs. | ~1 day to port the 5 `build_*.sh` scripts to Android NDK toolchains |
| Per-library `.a` archives (×3 ABIs) | `android/src/main/jniLibs/<abi>/lib*.a` | 1.5–2.5 hours of compile per ABI, dominated by SymEngine + FLINT |
| `scripts/copy_android_jniLibs.sh` | Sibling to `copy_xcframeworks.sh` | <30 min |
| Smoke tests on arm64 emulator | `example/` Android run | open-ended (first run almost always finds an issue) |

## Cross-compile order

Sequential dependency chain (parallelism is per-ABI within each library,
not across libraries):

```
GMP → MPFR → MPC → FLINT → SymEngine → symengine_flutter_wrapper
```

Same order as the iOS chain in `math-stack-ios-builder/build_*.sh`.

## Known build pitfalls (anticipate these in R132)

- **GMP + Android NDK**: `__builtin_constant_p` semantics differ between
  the Android Clang and the host Clang on some assembler routines.
  Workaround: `./configure --disable-assembly` for armeabi-v7a (drops
  perf on 32-bit but keeps the build sane). arm64-v8a + x86_64
  usually build cleanly.
- **FLINT autotools**: assumes a Unix-like build environment; the NDK
  toolchain's `pkg-config` setup needs `PKG_CONFIG_PATH` pointing at
  the GMP / MPFR / MPC build outputs. The iOS builder script handles
  this; the Android port has to thread the same env-var dance through
  each `./configure` invocation.
- **SymEngine CMake toolchain**: pass
  `-DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake`
  and `-DANDROID_ABI=<abi>` and `-DANDROID_PLATFORM=android-21`.
  SymEngine's `WITH_FLINT=ON` + `WITH_MPFR=ON` need explicit paths
  to the per-ABI install dirs.
- **Static linking + `--whole-archive`**: the linker has to `--whole-archive`
  the wrapper `.a` only — the other libs use normal `--no-whole-archive`
  so dead-code stripping works on SymEngine's vast symbol table.
  CMakeLists.txt already encodes this; verify on first build that the
  resulting `.so` is reasonably sized (<25 MB unstripped; ~3-5 MB
  stripped).

## Why the structure is this way

The intent is to mirror the iOS / macOS setup as closely as possible:

- **One build-infrastructure repo per Apple-ish target group**:
  `math-stack-ios-builder` covers iOS + macOS. `math-stack-android-builder`
  will cover Android (and later Linux / Windows if those join in).
- **Prebuilt artifacts checked into the plugin repo**: same as iOS today.
  Keeps `pub get` fast (no compile on the consumer side) and the artifact
  reproducibility scoped to the builder repo's CI.
- **Plugin's `android/` is a thin Flutter shell**: just the Gradle module
  + CMakeLists that pulls the prebuilt archives into a `.so`. No SymEngine
  source lives here.

## How to pick this up

1. `git checkout r132-android-scaffold` in this repo (already on it).
2. Create `math-stack-android-builder/` parallel to
   `math-stack-ios-builder/`. Symlink or copy the source tarballs.
3. Port each `build_*.sh` script to Android NDK. Start with `build_gmp.sh`
   (smallest, most foundational); validate the toolchain works before
   touching the rest.
4. Once all five libraries plus the wrapper build cleanly for arm64-v8a,
   re-run `scripts/build_android.sh` (or its successor) to populate
   `android/src/main/jniLibs/arm64-v8a/`.
5. Build `example/` Android, install on an arm64 device or emulator,
   invoke a couple of `flutter_symengine_*` calls via the example UI,
   verify they return real results (not the fallback error string).
6. Repeat for `x86_64` (for emulators) and `armeabi-v7a` (for legacy
   devices, optional).
7. Merge `r132-android-scaffold` into `main`, bump `pubspec.yaml`
   version to `1.0.16-android-beta` or similar.
8. Update CrispCalc's `pubspec.yaml` git pin to the merged ref.
9. The release-y0.4.0 workflow in CrispCalc can then mark Android as
   "full support" instead of "degraded mode".

See `PLAN.md` P11 in CrispCalc for the wider context (Linux R130 and
Windows R131 will follow the same pattern).
