# linux/CMakeLists.txt
#
# R130 — Linux x86_64 SymEngine build. A hybrid of the Android (R132)
# and Windows (R131) patterns:
#
#   * Like Android: statically link the whole math stack (SymEngine +
#     FLINT + MPFR + MPC + GMP, resolved by vcpkg's `x64-linux`
#     triplet) into ONE shared object — `libsymbolic_math_bridge.so`.
#     The only remaining dynamic deps are the C/C++ runtime
#     (libc / libstdc++ / libm / libgcc_s).
#   * Like Windows: three build modes, because a consumer Linux
#     machine has no SymEngine installed. CI builds the full `.so`
#     from source and commits it to `linux/Libraries/`; the consumer
#     build just bundles that prebuilt artifact.
#
# Unlike Windows, a Linux *ffiPlugin* needs no registrar `.cc` and no
# `flutter` / `flutter_wrapper_plugin` linkage — the FFI entry points
# are reached straight from Dart via
# `DynamicLibrary.open('libsymbolic_math_bridge.so')`. So the consumer
# path is pure bundling, no compiled stub.
#
# Three build modes:
#
# 1. **CI standalone** (`-DFLUTTER_PLUGIN_STANDALONE=ON` + SymEngine
#    found via vcpkg): compile the wrapper + force_link against the
#    static SymEngine archives and emit the full
#    `libsymbolic_math_bridge.so`. Driven by build-linux.yml; the
#    resulting `.so` is committed to `linux/Libraries/`.
#
# 2. **Consumer with prebuilt .so** (default consumer path): the
#    machine has no SymEngine, but `linux/Libraries/
#    libsymbolic_math_bridge.so` is present in the plugin checkout
#    (committed by CI). Tell Flutter to bundle it via
#    `symbolic_math_bridge_bundled_libraries`; Flutter copies it into
#    the app bundle's `lib/` and Dart's `DynamicLibrary.open(...)`
#    reaches its symbols at runtime. No target is compiled here —
#    the bundled file IS `libsymbolic_math_bridge.so`, so compiling a
#    same-named target would collide in the output dir.
#
# 3. **Degraded fallback** (no SymEngine on the machine, no prebuilt
#    in Libraries/): bundle nothing. The app builds; the FFI lookups
#    fail at load time — same bridge-unavailable path the desktop
#    Linux build has today.

cmake_minimum_required(VERSION 3.14)
project(symbolic_math_bridge LANGUAGES C CXX)

option(FLUTTER_PLUGIN_STANDALONE
    "Build the wrapper .so without a parent Flutter project (CI mode)"
    OFF)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# === Locate SymEngine (resolved via vcpkg x64-linux triplet) ============
# Note: SymEngine's CMake config exports as `SymEngine` (camelcase) with
# legacy variable-style outputs (SYMENGINE_INCLUDE_DIRS +
# SYMENGINE_LIBRARIES), NOT an IMPORTED target — same as Android/Windows.
find_package(SymEngine CONFIG QUIET)

set(PREBUILT_SO "${CMAKE_CURRENT_SOURCE_DIR}/Libraries/libsymbolic_math_bridge.so")

# === Pick the build mode ================================================
if(FLUTTER_PLUGIN_STANDALONE AND SymEngine_FOUND)
    set(BRIDGE_BUILD_MODE "full-from-source")
elseif(EXISTS "${PREBUILT_SO}" AND NOT FLUTTER_PLUGIN_STANDALONE)
    set(BRIDGE_BUILD_MODE "consumer-prebuilt")
elseif(SymEngine_FOUND)
    set(BRIDGE_BUILD_MODE "full-from-source")
else()
    set(BRIDGE_BUILD_MODE "degraded")
endif()

message(STATUS "symbolic_math_bridge(linux): build mode = ${BRIDGE_BUILD_MODE}")
if(SymEngine_FOUND)
    message(STATUS "symbolic_math_bridge(linux): SYMENGINE_INCLUDE_DIRS=${SYMENGINE_INCLUDE_DIRS}")
    message(STATUS "symbolic_math_bridge(linux): SYMENGINE_LIBRARIES=${SYMENGINE_LIBRARIES}")
endif()

if(BRIDGE_BUILD_MODE STREQUAL "full-from-source")
    # The combined .so: wrapper source + force_link belt-and-braces,
    # static-linked against vcpkg's SymEngine archives. Default symbol
    # visibility on Linux puts every extern `flutter_symengine_*` into
    # .dynsym, so DynamicLibrary.open + lookup reaches them; force_link
    # is kept as defense-in-depth against aggressive --gc-sections.
    add_library(symbolic_math_bridge SHARED
        "force_link.c"
        "${CMAKE_CURRENT_SOURCE_DIR}/../src/flutter_symengine_wrapper.c")

    # add_library() already yields libsymbolic_math_bridge.so on Linux
    # (CMake prepends `lib`), which is exactly the name the Dart loader
    # opens — no OUTPUT_NAME override needed.
    set_target_properties(symbolic_math_bridge PROPERTIES
        C_VISIBILITY_PRESET   default
        CXX_VISIBILITY_PRESET default)

    target_include_directories(symbolic_math_bridge PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "${CMAKE_CURRENT_SOURCE_DIR}/../src"
        ${SYMENGINE_INCLUDE_DIRS})

    target_link_libraries(symbolic_math_bridge PRIVATE ${SYMENGINE_LIBRARIES})

    # Keep dynamic symbols exported even if the toolchain defaults to
    # --gc-sections; mirrors the MinGW --export-all-symbols intent.
    target_link_options(symbolic_math_bridge PRIVATE -Wl,--export-dynamic)

    if(NOT FLUTTER_PLUGIN_STANDALONE)
        # Real Flutter Linux build that found SymEngine locally (rare):
        # bundle the freshly built target.
        set(symbolic_math_bridge_bundled_libraries
            "$<TARGET_FILE:symbolic_math_bridge>"
            PARENT_SCOPE)
    endif()

elseif(BRIDGE_BUILD_MODE STREQUAL "consumer-prebuilt")
    # Bundle the committed prebuilt .so. No target compiled — the
    # bundled file is itself libsymbolic_math_bridge.so.
    set(symbolic_math_bridge_bundled_libraries
        "${PREBUILT_SO}"
        PARENT_SCOPE)

else()
    # Degraded: nothing to bundle. FFI lookups fail at runtime.
    if(NOT FLUTTER_PLUGIN_STANDALONE)
        set(symbolic_math_bridge_bundled_libraries
            ""
            PARENT_SCOPE)
    endif()
endif()
