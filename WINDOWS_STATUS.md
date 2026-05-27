# Windows — R131 scaffold (vcpkg + MSVC)

**Status (2026-05-27): scaffold + GHA workflow on branch
`r131-windows-vcpkg`. Not merged to main. Not pinned by CrispCalc.
First workflow run pending — expect 1-3 iterations of debugging
before a clean DLL drops out.**

## Strategy

Mirror what CrispASR's `build.yml` does for Whisper.cpp on Windows:
`windows-latest` GHA runner + MSVC toolchain + vcpkg for native deps,
with the `x-gha` binary cache so subsequent runs after the initial
~30-min vcpkg install land in ~5 min.

The key win over the math-stack-android-builder approach is that
**vcpkg already has an official `symengine` port** (Microsoft-maintained,
SymEngine 0.14.0, supports `arb` + `flint` + `mpfr` features). No
hand-rolled cross-compile chain needed; vcpkg's port-of-ports tree
resolves boost-math, boost-random, mpir/gmp, mpfr, flint, arb
automatically.

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
