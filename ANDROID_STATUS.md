# Android — R132 SHIPPED (vcpkg + NDK chainload)

**Status (2026-05-27): merged to `main` as v1.1.0 then v1.1.1.
Pinned by CrispCalc v0.4.0 at bridge ref `931adcf`. APK delta
+17.7 MB matches the stripped `.so` size, confirming the binary
actually ships in releases.**

First successful build-android.yml run: `26513083096` — 14 min
wall clock. All 40+ `flutter_symengine_*` symbols defined and
exported in the .so.

## v1.1.1 consumer-integration fix

v1.1.0 shipped the binary correctly but the consumer's Gradle
build (i.e. `flutter build apk` in a downstream Flutter app)
failed: bridge's `android/build.gradle` had `externalNativeBuild
{ cmake { path 'CMakeLists.txt' } }`, forcing consumer Gradle to
invoke our CMake — which tries to compile
`flutter_symengine_wrapper.c` against SymEngine headers that
aren't on consumer machines.

Fix in v1.1.1: dropped `externalNativeBuild`. For an
`ffiPlugin: true` Android module, `jniLibs.srcDirs +=
'src/main/jniLibs'` alone is sufficient — Flutter packages the
per-ABI `.so` into the APK automatically. The CI workflow
(`build-android.yml`) still invokes `android/CMakeLists.txt`
directly (bypassing Gradle) to cross-compile the `.so` from
source via vcpkg + NDK. That path is unchanged; only the
consumer-side Gradle path is now CMake-free.

Caught by CrispCalc CI's "Build Android" job on the 1.1.0 pin
attempt; green after 1.1.1 + force_link guard.

## How we got here (iteration log)

7 iterations, 8 distinct failure modes — each one drilling one
step deeper into the build:

1. **vcpkg's mpfr port needed autoconf-archive + libtool** —
   ubuntu-latest doesn't have them pre-installed. Added apt step.
2. **`default-features: false` didn't drop LLVM** because the
   symengine port's `arb` feature has a self-referencing
   `symengine[flint]` dep without that flag set, which re-enables
   the default `arb` + `llvm` + `mpfr` set. Killed the build
   after 70 min on Android, 3h 39m on Windows. **Fix: drop `arb`
   from our feature list** — CrispCalc doesn't use it.
3. **`builtin-baseline` pin stale** — pinned ref wasn't in the
   runner's bundled vcpkg history (different runner image
   snapshot). Dropped the pin; will re-add with a `git fetch`
   step when reproducibility matters.
4. **JSON schema rejected unknown `_note_baseline` field**.
   Cosmetic; removed.
5. **`find_package(symengine)` lowercase** silently returned
   not-found because vcpkg's port exports `SymEngineConfig.cmake`
   (camelcase). Fix: `find_package(SymEngine ...)` + explicit
   `${SYMENGINE_INCLUDE_DIRS}` + `${SYMENGINE_LIBRARIES}`
   propagation (config uses legacy variable-style, not IMPORTED
   target).
6. **`<jni.h>` not on include path** for the standalone CMake
   build (vcpkg's Android triplet sets the NDK toolchain but
   doesn't add the JNI headers). Fix: split force_link.c into a
   portable plain-C function + a JNI wrapper guarded by
   `__has_include(<jni.h>)` so both Gradle and CI builds compile.
7. **Host `/usr/bin/ld` (x86_64) cross-arch link error** —
   "vcpkg_installed/arm64-android-release/lib/libsymengine.a:
   file in wrong format". vcpkg's toolchain cross-compiles its
   own port builds via VCPKG_TARGET_TRIPLET but doesn't propagate
   the NDK toolchain to the consumer project. **Fix:
   `VCPKG_CHAINLOAD_TOOLCHAIN_FILE` = NDK's
   `android.toolchain.cmake`** so vcpkg's toolchain chainloads it
   for both halves of the build.

## Path

The branch now lands two paths to a working
`libsymbolic_math_bridge.so`:

1. **vcpkg path (working, committed binary)** — `build-android.yml`
   runs `vcpkg install symengine[flint,mpfr]` against the
   `arm64-android-release` triplet on `ubuntu-latest` + bundled
   Android NDK, then builds the wrapper `.so` static-linked against
   everything. Stripped `.so` lands at
   `src/main/jniLibs/arm64-v8a/libsymbolic_math_bridge.so` committed
   to this branch so `pub get` consumers get it without running
   vcpkg themselves.

2. **jniLibs fallback (hand-rolled NDK)** — `android/CMakeLists.txt`
   also supports per-ABI prebuilt `.a` archives at
   `src/main/jniLibs/<abi>/lib*.a` (same shape iOS/macOS use via
   `.xcframework` bundles). Path 1 is the one that actually shipped;
   path 2 stays around for when we need armeabi-v7a or x86_64 and
   want to revisit hand-rolling.

If neither is available, the `.so` still assembles (wrapper source
compiled in) but FFI calls return errors — same degraded fallback
as today's Linux / Windows builds.

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
