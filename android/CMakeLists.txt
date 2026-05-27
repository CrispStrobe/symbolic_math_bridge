# android/CMakeLists.txt
#
# R132 scaffold — assembles libsymbolic_math_bridge.so per ABI from the
# prebuilt static archives produced by the math-stack-android-builder
# sibling repo. Mirrors how iOS/macOS link the wrapper + SymEngine +
# GMP/MPFR/MPC/FLINT through the .xcframework bundles, but produces a
# single combined .so per ABI here.
#
# Expected layout when the prebuilt artifacts land (set up by
# scripts/build_android.sh):
#
#   src/main/jniLibs/<abi>/libgmp.a
#   src/main/jniLibs/<abi>/libmpfr.a
#   src/main/jniLibs/<abi>/libmpc.a
#   src/main/jniLibs/<abi>/libflint.a
#   src/main/jniLibs/<abi>/libsymengine.a
#   src/main/jniLibs/<abi>/libsymengine_flutter_wrapper.a
#
# Until those exist, the build produces an empty libsymbolic_math_bridge.so
# (just the force-link C source) and the wrapper symbols are missing.
# Runtime FFI falls back to the "bridge unavailable" path.

cmake_minimum_required(VERSION 3.18.1)
project(symbolic_math_bridge LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Path to the per-ABI prebuilt static archives.
set(PREBUILT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}")

# === Prebuilt static archives ============================================
#
# Imported as IMPORTED targets so the linker pulls only what it needs from
# each .a — except for libsymengine_flutter_wrapper which holds the 45
# `flutter_symengine_*` entry points reached via dlsym only. Those need
# --whole-archive to defeat dead-code elimination.

foreach(lib IN ITEMS gmp mpfr mpc flint symengine symengine_flutter_wrapper)
    if(EXISTS "${PREBUILT_DIR}/lib${lib}.a")
        add_library(${lib} STATIC IMPORTED)
        set_target_properties(${lib} PROPERTIES
            IMPORTED_LOCATION "${PREBUILT_DIR}/lib${lib}.a")
        message(STATUS "symbolic_math_bridge: found lib${lib}.a in ${PREBUILT_DIR}")
    else()
        message(WARNING
            "symbolic_math_bridge: lib${lib}.a missing from ${PREBUILT_DIR}. "
            "Run scripts/build_android.sh from math-stack-android-builder to "
            "produce it. The .so will assemble without it, but the "
            "flutter_symengine_* symbols will be unresolved.")
    endif()
endforeach()

# === The combined .so ====================================================
#
# A single source file holding `force_all_math_symbols_linking` (the
# Android equivalent of iOS's force_symbolic_math_stack_linking trick).
# That symbol is called from the Kotlin plugin's plugin-registration entry
# point so the linker keeps the wrapper symbols around even when the only
# real references are dlsym/dart:ffi at runtime.

add_library(symbolic_math_bridge SHARED
    src/main/cpp/force_link.c
)

target_include_directories(symbolic_math_bridge PRIVATE
    src/main/cpp
)

# --whole-archive the wrapper static lib so its 45 entry points survive
# the linker's dead-code pass. The other libs (gmp/mpfr/mpc/flint/symengine)
# can be normal --no-whole-archive — only the symbols actually referenced
# by the wrapper get pulled in, keeping the .so size down.
if(TARGET symengine_flutter_wrapper)
    target_link_libraries(symbolic_math_bridge
        -Wl,--whole-archive
        symengine_flutter_wrapper
        -Wl,--no-whole-archive
        symengine
        flint
        mpc
        mpfr
        gmp
    )
else()
    message(WARNING
        "symbolic_math_bridge: no prebuilt wrapper — building empty .so. "
        "Runtime FFI calls will fail with 'symbol not found', and the "
        "bridge falls back to the same unavailable path Linux/Windows take.")
endif()

# Android-specific: the NDK ships its own libm + libc; nothing extra needed.
# C++ stdlib comes from c++_static via the NDK toolchain default.
target_link_libraries(symbolic_math_bridge log)
