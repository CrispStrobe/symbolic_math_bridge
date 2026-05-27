# android/CMakeLists.txt
#
# Two paths to a working libsymbolic_math_bridge.so:
#
# 1. **vcpkg path (preferred, used by build-android.yml workflow)**:
#    `find_package(symengine CONFIG)` resolves SymEngine + transitive
#    deps (boost-math, mpir/gmp, mpfr, mpc, flint, arb) from a vcpkg
#    install for the `arm64-android-release` (or x64-android, etc.)
#    triplet. All static-linked into a single .so per ABI. Builds
#    cleanly on ubuntu-latest with the NDK toolchain via vcpkg's
#    CHAINLOAD mechanism. Mirrors the Windows pattern (R131).
#
# 2. **jniLibs fallback (hand-rolled NDK path, math-stack-android-builder)**:
#    Per-ABI prebuilt static archives at
#    `src/main/jniLibs/<abi>/lib{gmp,mpfr,mpc,flint,symengine,symengine_flutter_wrapper}.a`.
#    Same shape iOS/macOS use via `.xcframework` bundles. Useful for
#    older NDKs or when vcpkg's symengine port wedges against a
#    triplet for some reason.
#
# If neither source is available, the .so still assembles (with the
# wrapper source compiled in) but the SymEngine calls inside the
# wrapper are unresolved at runtime — same degraded fallback as the
# desktop Linux / Windows builds today.

cmake_minimum_required(VERSION 3.18.1)
project(symbolic_math_bridge LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# === Path 1: vcpkg ========================================================

find_package(SymEngine CONFIG QUIET)
if(SymEngine_FOUND)
    message(STATUS "symbolic_math_bridge: vcpkg's SymEngine port found, linking static")
    set(BRIDGE_LINK_MODE "vcpkg")
    # SymEngine's config exposes SYMENGINE_INCLUDE_DIRS + SYMENGINE_LIBRARIES,
    # NOT a fully-baked INTERFACE target like modern Config packages would.
    # Wire them onto the wrapper manually below.
    message(STATUS "symbolic_math_bridge: SYMENGINE_INCLUDE_DIRS=${SYMENGINE_INCLUDE_DIRS}")
    message(STATUS "symbolic_math_bridge: SYMENGINE_LIBRARIES=${SYMENGINE_LIBRARIES}")
endif()

# === Path 2: prebuilt jniLibs (fallback) ==================================

if(NOT SymEngine_FOUND)
    set(PREBUILT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}")
    set(PREBUILT_ANY_FOUND OFF)
    foreach(lib IN ITEMS gmp mpfr mpc flint symengine symengine_flutter_wrapper)
        if(EXISTS "${PREBUILT_DIR}/lib${lib}.a")
            add_library(${lib} STATIC IMPORTED)
            set_target_properties(${lib} PROPERTIES
                IMPORTED_LOCATION "${PREBUILT_DIR}/lib${lib}.a")
            message(STATUS "symbolic_math_bridge: found prebuilt lib${lib}.a in ${PREBUILT_DIR}")
            set(PREBUILT_ANY_FOUND ON)
        endif()
    endforeach()
    if(PREBUILT_ANY_FOUND)
        set(BRIDGE_LINK_MODE "jniLibs")
    else()
        set(BRIDGE_LINK_MODE "none")
        message(WARNING
            "symbolic_math_bridge: no vcpkg symengine + no prebuilt jniLibs in "
            "${PREBUILT_DIR}. The .so will assemble but flutter_symengine_* "
            "calls will return errors. To produce a usable .so, either:\n"
            "  (a) install vcpkg + symengine[arb,flint,mpfr] for the chosen "
            "      Android triplet and re-CMake with the vcpkg toolchain, or\n"
            "  (b) run scripts/build_android.sh to populate the jniLibs dir.")
    endif()
endif()

# === The combined .so =====================================================

set(BRIDGE_SOURCES
    src/main/cpp/force_link.c
    "${CMAKE_CURRENT_SOURCE_DIR}/../src/flutter_symengine_wrapper.c"
)

add_library(symbolic_math_bridge SHARED ${BRIDGE_SOURCES})

target_include_directories(symbolic_math_bridge PRIVATE
    src/main/cpp
    "${CMAKE_CURRENT_SOURCE_DIR}/../src"
)

# Linker dependencies depend on which path resolved SymEngine.
if(BRIDGE_LINK_MODE STREQUAL "vcpkg")
    # SymEngine's CMake config exposes SYMENGINE_INCLUDE_DIRS +
    # SYMENGINE_LIBRARIES (legacy variable-style, not an IMPORTED
    # target). Apply both to the wrapper target manually so the
    # vendored flutter_symengine_wrapper.c can #include <symengine/
    # cwrapper.h> and link against the static archives vcpkg laid
    # down at vcpkg_installed/<triplet>/lib/.
    target_include_directories(symbolic_math_bridge PRIVATE
        ${SYMENGINE_INCLUDE_DIRS})
    target_link_libraries(symbolic_math_bridge PRIVATE
        ${SYMENGINE_LIBRARIES})
elseif(BRIDGE_LINK_MODE STREQUAL "jniLibs")
    # Per-iOS pattern: --whole-archive the wrapper archive only, normal
    # link for the rest so dead-code stripping works on SymEngine's
    # vast symbol table.
    set(LINK_LIBS "")
    if(TARGET symengine_flutter_wrapper)
        list(APPEND LINK_LIBS
            -Wl,--whole-archive
            symengine_flutter_wrapper
            -Wl,--no-whole-archive)
    endif()
    foreach(lib IN ITEMS symengine flint mpc mpfr gmp)
        if(TARGET ${lib})
            list(APPEND LINK_LIBS ${lib})
        endif()
    endforeach()
    target_link_libraries(symbolic_math_bridge PRIVATE ${LINK_LIBS})
endif()

# Android-specific: NDK ships its own libm + libc; only `log` extra.
target_link_libraries(symbolic_math_bridge PRIVATE log)

message(STATUS "symbolic_math_bridge: link mode = ${BRIDGE_LINK_MODE}")
