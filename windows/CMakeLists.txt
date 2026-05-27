# windows/CMakeLists.txt
#
# R131 (Windows via vcpkg + MSVC).
#
# Flutter Windows plugin module. Produces `symbolic_math_bridge_plugin.dll`
# containing the full `flutter_symengine_*` C wrapper statically linked
# against SymEngine + ARB + FLINT + MPFR + MPC + GMP (all resolved via
# vcpkg).
#
# Two build modes supported via the FLUTTER_PLUGIN_STANDALONE switch:
#
#   FLUTTER_PLUGIN_STANDALONE=OFF (default)
#     Normal in-Flutter build. The parent windows app's CMakeLists
#     provides the `flutter` + `flutter_wrapper_plugin` IMPORTED targets,
#     `apply_standard_settings`, and the Flutter desktop plugin
#     registrar headers.
#
#   FLUTTER_PLUGIN_STANDALONE=ON
#     CI-friendly build that produces the same DLL without needing a
#     full Flutter Windows runner around it. The Flutter plugin
#     registrar surface (`flutter::PluginRegistrarWindows`,
#     `FlutterDesktopPluginRegistrarRef`) is stubbed via tiny
#     no-op definitions so the wrapper-and-glue still compile and
#     link. The resulting DLL exports the same `flutter_symengine_*`
#     C ABI; only the `SymbolicMathBridgePluginCApiRegisterWithRegistrar`
#     entry point is a no-op (in real use it calls force-link, which
#     CI-mode skips since address-taken pinning in force_link.c is
#     also-belt-and-braces).
#
# Wrapper symbols are reached at runtime via `dart:ffi`
# `DynamicLibrary.open('symbolic_math_bridge_plugin.dll')`. MSVC
# dead-code-stripping defeated via /INCLUDE: link flags + force_link.c.

cmake_minimum_required(VERSION 3.14)
project(symbolic_math_bridge LANGUAGES C CXX)

option(FLUTTER_PLUGIN_STANDALONE
    "Build the wrapper DLL without a parent Flutter project (CI mode)"
    OFF)

set(PLUGIN_NAME "symbolic_math_bridge_plugin")
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)

# === Locate SymEngine (resolved via vcpkg) ==============================

find_package(symengine CONFIG QUIET)
if(NOT symengine_FOUND)
    message(WARNING
        "symbolic_math_bridge (windows): vcpkg's symengine port not found. "
        "Falling back to a wrapper-only DLL — FFI calls will fail at "
        "runtime (the wrapper's SymEngine calls are unresolved). "
        "To produce a usable DLL, install vcpkg + the symengine port "
        "and pass -DCMAKE_TOOLCHAIN_FILE=<vcpkg>/scripts/buildsystems/"
        "vcpkg.cmake to CMake. See WINDOWS_STATUS.md.")
endif()

# === Source list =========================================================

set(PLUGIN_SOURCES
    "force_link.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/../src/flutter_symengine_wrapper.c"
)

if(NOT FLUTTER_PLUGIN_STANDALONE)
    # Real Flutter build: include the C++ glue that hooks into
    # Flutter's plugin registrar.
    list(APPEND PLUGIN_SOURCES "symbolic_math_bridge_plugin.cpp")
endif()

add_library(${PLUGIN_NAME} SHARED ${PLUGIN_SOURCES})

set_target_properties(${PLUGIN_NAME} PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    C_VISIBILITY_PRESET   default
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
    "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PLUGIN_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/../src")

if(NOT FLUTTER_PLUGIN_STANDALONE)
    # apply_standard_settings + the flutter targets come from the parent
    # Flutter project's CMakeLists; they're not available in CI standalone.
    apply_standard_settings(${PLUGIN_NAME})
    target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)
endif()

if(symengine_FOUND)
    target_link_libraries(${PLUGIN_NAME} PRIVATE symengine)
endif()

# MSVC dead-code-stripping defeat. /INCLUDE: tells the linker to keep
# the named symbol even with no static reference. Equivalent to iOS's
# `-all_load`. force_link.c also pins via address-taken sinks; both
# belt + braces.
if(MSVC)
    set_target_properties(${PLUGIN_NAME} PROPERTIES
        LINK_FLAGS "/INCLUDE:flutter_symengine_evaluate \
/INCLUDE:flutter_symengine_solve \
/INCLUDE:flutter_symengine_expand \
/INCLUDE:flutter_symengine_factor \
/INCLUDE:flutter_symengine_differentiate \
/INCLUDE:flutter_symengine_substitute \
/INCLUDE:flutter_symengine_free_string")
endif()

# List of absolute paths to libraries that should be bundled with the
# plugin's runtime DLLs (Flutter convention). Static-linked into our DLL,
# so empty. Only set PARENT_SCOPE when actually being included from a
# parent project; in standalone CI builds there is no parent.
if(NOT FLUTTER_PLUGIN_STANDALONE AND NOT CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(symbolic_math_bridge_bundled_libraries
        ""
        PARENT_SCOPE)
endif()
