# Windows — R131 GREEN (MSYS2/MinGW64)

**Status (2026-05-27): build-windows.yml passing on branch
`r131-windows-vcpkg` (branch name kept even though we abandoned
vcpkg). `symbolic_math_bridge_plugin.dll` for x86-64 committed at
`windows/Libraries/` (5.7 MB stripped, PE32+, all `flutter_symengine_*`
symbols in DLL Export Table). Not yet merged to main. Not yet
pinned by CrispCalc.**

First successful run: `26535903971` — 4 min 28 sec wall clock. The
preceding 3 MinGW iterations each cycled in ~5 min vs the 1-6 hours
each vcpkg iteration burned.

## Why we pivoted

The vcpkg+MSVC approach worked architecturally — it's the same path
that produced Android #7 GREEN. Same vcpkg + same SymEngine port +
same `default-features: false` workaround. But on Windows it lost
to wall-clock time:

| Run | Outcome | Where it died |
|---|---|---|
| W#1 | cancelled at 3h 39m | LLVM compile (default feature trap) |
| W#2/3 | failed fast | builtin-baseline pin / schema |
| W#4 | cancelled at 1h 20m | LLVM re-pulled via `arb` |
| W#5 | cancelled by concurrency | superseded by W#6 |
| **W#6** | **cancelled at 6h 0m 22s** | **vcpkg install hit the GHA 6h cap** |

Even with LLVM disabled, cold-cache install of boost-math + flint +
mpfr + gmp + symengine via MSVC on the free `windows-latest` runner
(notoriously slow for template-heavy C++ libs) doesn't fit in 6
hours. Without a single green run there's no x-gha binary cache to
populate, so every run pays the full cold-cache tax.

For comparison: the same vcpkg dep set built in 14 min on Android
(`ubuntu-latest`, NDK cross-compile via vcpkg-chainload toolchain).
Ubuntu's C++ compile throughput on the free runner is roughly 10×
Windows's.

## New strategy — MSYS2/MinGW64

Skip vcpkg entirely on Windows. Use MSYS2's MinGW64 subsystem
(installed via `msys2/setup-msys2@v2`):

- **flint, mpfr, gmp, mpc** are pacman-installed pre-built from
  MSYS2's `mingw-w64-x86_64-*` repository (~30 sec each).
- **symengine** isn't in MSYS2 repos. Compile from source via
  CMake+ninja under MinGW (~5-15 min, vs hours under MSVC). Cache
  the build via `actions/cache@v4` keyed on the SymEngine version,
  so subsequent runs skip the compile entirely.
- **Wrapper DLL** static-links MinGW runtime (`-static-libgcc
  -static-libstdc++`) so consumers don't need to ship
  `libgcc_s_seh-1.dll` / `libwinpthread-1.dll` / `libstdc++-6.dll`
  alongside.
- **`-Wl,--export-all-symbols`** because the wrapper has no
  `__declspec(dllexport)` decorations — without it MinGW's linker
  only exports what's proven referenced from outside the DLL.

Expected total: **15-25 min cold, ~5 min cached.**

## Compatibility note

The MinGW-built DLL exposes a plain C ABI (the
`flutter_symengine_wrapper.c` surface). Flutter Windows is built
with MSVC, but it loads the bridge via `dart:ffi`
`DynamicLibrary.open()` at runtime — only the C calling convention
matters for that path, not which compiler built the DLL. MinGW C
DLLs are loadable from MSVC consumers without ABI gymnastics.

## What this branch ships

| Path | Purpose |
|---|---|
| `src/flutter_symengine_wrapper.{c,h}` | The 749-line C wrapper (vendored from math-stack-ios-builder/src/, where iOS/macOS read it). One source of truth for all platforms. |
| `windows/CMakeLists.txt` | Builds `symbolic_math_bridge_plugin.dll` against vcpkg-installed SymEngine. Two modes: standalone (CI; no parent Flutter project) + in-Flutter (default; parent project supplies the `flutter` / `flutter_wrapper_plugin` targets). `find_package(symengine CONFIG)` is the resolver. |
| `windows/vcpkg.json` | Manifest declaring `symengine[arb,flint,mpfr]` as a dep. Manifest mode (`--x-manifest-root`) means the workflow doesn't have to type `vcpkg install symengine[...]` imperatively. |
| `windows/symbolic_math_bridge_plugin.{cpp,h}` + `windows/include/.../*.h` | Flutter Windows plugin C++ glue. ffiPlugin: true → minimal; on plugin attach we just call `symbolic_math_bridge_force_link_symbols()` to pin the wrapper symbols. |
| `windows/force_link.c` | MSVC equivalent of iOS's force-link trick. Address-taken sinks for every `flutter_symengine_*` entry point. CMakeLists also passes `/INCLUDE:` link directives — belt + braces. |
| `windows/Libraries/.gitkeep` | Reserved for any prebuilt artifacts that need to ship in the plugin DLL alongside vcpkg-installed libs. Empty in the common case. |
| `.github/workflows/build-windows.yml` | The actual build. Runs on `windows-latest`, uses bundled vcpkg, manifest-mode install with x-gha binary cache, MSVC CMake configure with the vcpkg toolchain file, builds the plugin DLL, dumps exports, uploads as workflow artifact. |
| `pubspec.yaml` | Declares the `windows` platform with `ffiPlugin: true` and `pluginClass: SymbolicMathBridgePluginCApi`. |

## What this branch does NOT ship

- **A pre-built DLL committed to `windows/Libraries/`.** That's the
  R131 follow-up after the first clean workflow run: download the
  artifact, commit it to the branch so consumers don't have to wait
  for `vcpkg install` themselves.
- **arm64-windows** triplet. The matrix could grow to include it for
  Surface Pro X / Copilot+ PCs but x64 covers ~99% of Windows
  desktops today.
- **Updates to CrispCalc's `pubspec.yaml`** pin. Stays at the
  current bridge ref (`505074d`) until the R131 workflow lands a
  verified DLL and a smoke test passes against the Flutter Windows
  example.

## Likely failure modes on first run

1. **vcpkg's symengine port pulls in a transitive that fails to build
   on the current windows-latest image**. Most likely culprits:
   FLINT (autotools-Windows pain even with vcpkg's patches), or LLVM
   (which we disabled — `arb` + `flint` + `mpfr` shouldn't trigger
   the llvm feature). Mitigation: bisect vcpkg port versions if it
   hits.
2. **`find_package(symengine CONFIG)` doesn't pick up the static
   triplet's install location**. CMakeLists assumes the vcpkg
   toolchain-file dispatch works; if the static triplet's CMake
   config files aren't where `find_package` looks, we need to set
   `CMAKE_PREFIX_PATH` explicitly.
3. **MSVC dead-code stripping wins anyway** even with `/INCLUDE:` +
   force_link.c. Diagnose via `dumpbin /EXPORTS` (the workflow's
   inspect step already runs this) — if entry points are missing,
   either tighten the linker directives or split the wrapper into a
   `.def` file with explicit `EXPORTS` lines.
4. **Boost dep timeout**. vcpkg installs all of boost-math + the
   subset boost-math needs. On a cold runner this can take 20+ min.
   First-build budget is conservative; cache miss subsequent runs
   should be 3-5 min total.

## What unlocks once this works

- CrispCalc's `release.yml` Windows build can switch from "degraded
  mode" to full symbolic support. The release-notes blurb for v0.4.0
  drops the "Windows / Linux / Android ship without SymEngine"
  asterisk.
- The same vcpkg-based pattern can be lifted into a `build-linux.yml`
  workflow (R130) — vcpkg's symengine port works on Linux too.
- The Android scaffold (R132 on branch `r132-android-scaffold`)
  remains the odd one out — Android can't use vcpkg directly,
  needs the math-stack-android-builder hand-roll. But getting Linux
  + Windows green first means the CI matrix has confidence by the
  time we tackle Android's NDK rabbit hole.

## How to verify locally

Requires Windows + Visual Studio 2022 + vcpkg.

```pwsh
git clone -b r131-windows-vcpkg https://github.com/CrispStrobe/symbolic_math_bridge.git
cd symbolic_math_bridge\windows
$env:VCPKG_ROOT="C:\vcpkg"   # or wherever
& $env:VCPKG_ROOT\vcpkg.exe install --triplet x64-windows-static --x-manifest-root="$PWD"
cmake -S . -B build -A x64 `
    -DCMAKE_BUILD_TYPE=Release `
    -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake" `
    -DVCPKG_TARGET_TRIPLET=x64-windows-static `
    -DFLUTTER_PLUGIN_STANDALONE=ON
cmake --build build --config Release
dumpbin /EXPORTS build\Release\symbolic_math_bridge_plugin.dll | findstr flutter_symengine_
```

That last `dumpbin` call should print 40+ `flutter_symengine_*` symbols.
If it does, the wrapper DLL is ready to integrate into a Flutter
Windows app (drop into `windows/runner/Debug` or `windows/runner/Release`
and the runner's plugin registrar picks it up).
