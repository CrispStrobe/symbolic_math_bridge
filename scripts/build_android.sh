#!/bin/bash
# scripts/build_android.sh
#
# R132 scaffold — orchestration script for the Android NDK cross-compile
# chain. Delegates the per-library builds to math-stack-android-builder
# (sibling repo, to be created) and copies the resulting .a archives into
# android/src/main/jniLibs/<abi>/ where this plugin's CMakeLists picks
# them up.
#
# This script is a SCAFFOLD. The actual per-library builds are NOT yet
# implemented; running it today prints the planned steps and exits
# without producing artifacts. Pick up here when R132 starts in earnest.
#
# Required environment:
#   ANDROID_NDK_HOME    path to NDK 27+ (28 LTS recommended; 25 / 26
#                       should also work but FLINT autotools sometimes
#                       wedges against older NDK assemblers)
#
# Optional:
#   ABIS                space-separated list (default: "arm64-v8a x86_64";
#                       add armeabi-v7a for 32-bit support, +30 min per
#                       library)
#   BUILDER_DIR         path to math-stack-android-builder (default:
#                       ../math-stack-android-builder)
#   API_LEVEL           Android API level for the toolchain (default: 21)
#
# Usage:
#   ANDROID_NDK_HOME=~/Library/Android/sdk/ndk/28.2.13676358 \
#     ./scripts/build_android.sh
#
# Build order (matches iOS / macOS chain):
#   1. GMP                — base arbitrary-precision integer arithmetic
#   2. MPFR (depends GMP) — arbitrary-precision floating-point
#   3. MPC  (depends MPFR+GMP) — complex arithmetic
#   4. FLINT (depends MPFR+GMP) — number theory
#   5. SymEngine (depends FLINT+MPFR+MPC+GMP) — the symbolic-math kernel
#   6. Flutter wrapper (depends SymEngine) — the C ABI surface
#
# Per ABI: roughly 1.5-2.5 hours of compile time on a recent Mac.
# Multi-ABI builds parallelise per top-level library but not across
# libraries (dependency chain is sequential).

set -euo pipefail

ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-}"
ABIS="${ABIS:-arm64-v8a x86_64}"
BUILDER_DIR="${BUILDER_DIR:-../math-stack-android-builder}"
API_LEVEL="${API_LEVEL:-21}"

readonly SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"
readonly PLUGIN_ROOT="$(cd "$SCRIPTDIR/.." && pwd)"
readonly JNI_DIR="$PLUGIN_ROOT/android/src/main/jniLibs"

log() { printf "[ANDROID-BUILD] %s\n" "$1"; }
err() { printf "[ANDROID-BUILD] ❌ %s\n" "$1" >&2; exit 1; }

# === Sanity checks ========================================================

[ -n "$ANDROID_NDK_HOME" ] || err "ANDROID_NDK_HOME unset. Point at an NDK r25+ install."
[ -d "$ANDROID_NDK_HOME" ] || err "ANDROID_NDK_HOME ($ANDROID_NDK_HOME) doesn't exist."
[ -f "$ANDROID_NDK_HOME/source.properties" ] || err "Doesn't look like an NDK install (no source.properties)."

NDK_VERSION="$(grep -E '^Pkg.Revision' "$ANDROID_NDK_HOME/source.properties" | awk -F= '{print $2}' | xargs)"
log "Using NDK ${NDK_VERSION:-(unknown)} at $ANDROID_NDK_HOME"
log "Target ABIs: $ABIS"
log "API level: $API_LEVEL"
log "Output dir: $JNI_DIR"

# === Status check =========================================================

if [ ! -d "$BUILDER_DIR" ]; then
    log "math-stack-android-builder not found at $BUILDER_DIR"
    log ""
    log "  R132 NEXT STEPS (not yet implemented):"
    log ""
    log "  1. Create sibling repo math-stack-android-builder, parallel to"
    log "     math-stack-ios-builder. Reuse the same source tarballs"
    log "     (gmp-6.3.0.tar.bz2, mpfr-4.2.2.tar.xz, mpc-1.3.1.tar.gz,"
    log "     flint-3.3.1.tar.gz, symengine-0.11.2.tar.gz)."
    log ""
    log "  2. Write per-library build scripts adapting math-stack-ios-builder/"
    log "     build_{gmp,mpfr,mpc,flint,symengine}.sh to use the Android"
    log "     NDK toolchain. Key differences from the iOS scripts:"
    log "       - configure --host=<aarch64-linux-android,armv7a-linux-androideabi,x86_64-linux-android>"
    log "       - CC=\$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/<host>/bin/<host>-clang"
    log "       - CFLAGS=-fPIC -D__ANDROID_API__=$API_LEVEL"
    log "       - No --enable-fat or universal-binary args (one ABI per pass)"
    log "       - Output to build-<lib>-android/<abi>/lib<lib>.a"
    log ""
    log "  3. Wire up scripts/copy_android_jniLibs.sh (sibling to"
    log "     copy_xcframeworks.sh) to populate"
    log "     $JNI_DIR/<abi>/ from the builder repo's output."
    log ""
    log "  4. Smoke-test on an arm64-v8a emulator: pubspec.yaml in CrispCalc"
    log "     stays pinned at the current bridge ref until the .so is"
    log "     verified to load and a handful of flutter_symengine_* calls"
    log "     resolve at runtime."
    log ""
    log "Exiting without action (scaffold only)."
    exit 0
fi

# === Reserved for when math-stack-android-builder lands ===================
# When the builder exists, this section invokes its per-library scripts in
# dependency order and copies artifacts. The skeleton is here so future-us
# fills in real implementations rather than reinventing the orchestration.

err "math-stack-android-builder found but the orchestration glue is not yet implemented. See R132 next-steps printed above."
