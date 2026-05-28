# Linux — R130 BUILD GREEN (vcpkg x64-linux static + consumer-prebuilt bundling)

**Status (2026-05-29): green on the FIRST CI run; binary committed;
shipped as v1.2.0.** The last tier-1 platform. Closes the gap where
desktop Linux fell through to the bridge-unavailable error path.

First successful `build-linux.yml` run: `26604981909` — 19m5s wall
clock (cold vcpkg compile of the whole math stack). The committed
binary lives at `linux/Libraries/libsymbolic_math_bridge.so`
(18.3 MB stripped). Verified in CI:

- All `flutter_symengine_*` entry points exported in `.dynsym`
  (survive `strip --strip-all`).
- `ldd` shows only `libstdc++ / libm / libgcc_s / libc` + the loader
  — the math stack is fully static-linked, as intended.
- Max referenced versioned symbol is **GLIBC_2.35**, matching the
  ubuntu-22.04 baseline (no drift past the pin).

No iteration was needed — the Android+Windows lessons (drop `arb`,
don't pin `builtin-baseline`, camelcase `find_package(SymEngine)`)
transferred cleanly and configure/build/strip passed on attempt 1.

## Design — a hybrid of R132 (Android) and R131 (Windows)

| Borrowed from | What |
|---|---|
| **Android (R132)** | Static-link the entire math stack (SymEngine + FLINT + MPFR + MPC + GMP) into ONE `.so`. vcpkg resolves it; CMake links `${SYMENGINE_LIBRARIES}`. Only dynamic deps left are libc/libstdc++/libm/libgcc_s. |
| **Windows (R131)** | Three-mode `CMakeLists.txt` — a consumer Linux box has no SymEngine, so CI builds the full `.so` and commits it; the consumer build just bundles the prebuilt. |

**Simpler than Windows in one way:** a Linux *ffiPlugin* needs no
registrar `.cc` and no `flutter` / `flutter_wrapper_plugin` linkage.
The FFI entry points are reached directly from Dart via
`DynamicLibrary.open('libsymbolic_math_bridge.so')`
(`lib/symbolic_math_bridge.dart` `_openNativeLibrary()` already falls
through to this name on Linux). So the consumer path is pure bundling
— no compiled stub, and therefore **no filename-collision problem**
like Windows had: nothing else produces a `libsymbolic_math_bridge.so`
in the output dir.

## Build modes (`linux/CMakeLists.txt`)

| Mode | Detection | What happens |
|---|---|---|
| `full-from-source` | `FLUTTER_PLUGIN_STANDALONE=ON` + `SymEngine_FOUND` | compile wrapper + force_link, static-link SymEngine, emit full `libsymbolic_math_bridge.so` (CI path) |
| `consumer-prebuilt` | default + `linux/Libraries/libsymbolic_math_bridge.so` exists | bundle the prebuilt via `symbolic_math_bridge_bundled_libraries`; compile nothing |
| `degraded` | nothing found | bundle nothing; FFI lookups fail at runtime (today's behavior) |

## Workflow (`.github/workflows/build-linux.yml`)

Mirror of `build-android.yml` minus the NDK chainload (the runner IS
Linux). Key choices:

- **`ubuntu-22.04` runner**, not `ubuntu-latest` — pins the GLIBC
  baseline at 2.35 so the committed `.so` runs on a sensible range of
  distros. The workflow prints `objdump -T | grep GLIBC_` so we can
  see the max versioned symbol referenced.
- **`x64-linux` triplet** (static). `default-features: false` +
  `features: [flint, mpfr]` — drops `arb`, which transitively
  re-pulls LLVM (the R131/R132 cross-cutting lesson).
- apt-installs `autoconf autoconf-archive automake libtool` for
  vcpkg's mpfr port (same as Android).
- `nm --dynamic` + `strip --strip-all` + `ldd` sanity checks.

## Iteration log

- **Run `26604981909` (attempt 1) — GREEN.** vcpkg install, CMake
  configure (`full-from-source`), build, strip, symbol + ldd + GLIBC
  checks all passed. `.so` uploaded and committed.

## Open risks to watch in CI

1. **PIC of vcpkg's static archives.** Static `.a`s must be `-fPIC` to
   link into a shared `.so`. vcpkg's `x64-linux` triplet builds PIC
   static libs by default, but if the link fails with "recompile with
   -fPIC", a custom triplet setting `VCPKG_CMAKE_CONFIGURE_OPTIONS`
   (or `-fPIC` in CXX/C flags) is the fix.
2. **GLIBC drift** if the runner image bumps Ubuntu. The objdump check
   surfaces it; if it creeps past 2.35, pin the runner harder or build
   in a manylinux/older container.
3. **Symbol visibility under `--gc-sections`.** Default Linux
   visibility exports all globals to `.dynsym`; force_link.c +
   `-Wl,--export-dynamic` are belt-and-braces. The `nm --dynamic |
   grep flutter_symengine_` count in CI confirms the entry points
   survive the strip.

## After green

1. Commit the stripped `.so` to `linux/Libraries/`.
2. Bump `pubspec.yaml` to v1.2.0, update CHANGELOG.
3. Merge `r130-linux` → `main`.
4. Re-pin CrispCalc `pubspec.yaml` to the new bridge ref; update
   CrispCalc README platform table (Linux ✓), PLAN P11 (R130 SHIPPED),
   HISTORY, and the Dart loader doc comment.
5. Cut CrispCalc v0.4.1 (or fold into the next release).
