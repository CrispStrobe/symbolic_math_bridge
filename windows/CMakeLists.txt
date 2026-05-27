# windows/CMakeLists.txt
#
# Three build modes:
#
# 1. **CI standalone** (`FLUTTER_PLUGIN_STANDALONE=ON`):
#    Build from source against vcpkg-resolved or MSYS2-resolved
#    SymEngine. Produces the full symbolic_math_bridge_plugin.dll
#    with all flutter_symengine_* symbols. Used by
#    `.github/workflows/build-windows.yml`. The resulting DLL is
#    committed to windows/Libraries/ for consumer-mode use.
#
# 2. **Consumer with prebuilt DLL** (default consumer path):
#    Consumer machine doesn't have SymEngine installed, but
#    windows/Libraries/libsymbolic_math_bridge.dll is already in the
#    bridge plugin checkout (committed by CI; named with the `lib`
#    prefix and without the `_plugin` suffix to AVOID a name collision
#    with the registrar `symbolic_math_bridge_plugin.dll` Flutter
#    builds from source in this mode). Tell Flutter to bundle the
#    prebuilt DLL alongside via
#    `symbolic_math_bridge_bundled_libraries`. Dart-side
#    `DynamicLibrary.open('libsymbolic_math_bridge.dll')` then
#    reaches the prebuilt DLL's symbols at runtime.
#
# 3. **Consumer without prebuilt** (degraded fallback):
#    Neither SymEngine on the machine nor a prebuilt DLL in
#    Libraries/. Compile only the registrar. Bridge functions will
#    fail at FFI lookup time — same as today's degraded Linux build.

cmake_minimum_required(VERSION 3.14)
project(symbolic_math_bridge LANGUAGES C CXX)

option(FLUTTER_PLUGIN_STANDALONE
    "Build the wrapper DLL without a parent Flutter project (CI mode)"
    OFF)

set(PLUGIN_NAME "symbolic_math_bridge_plugin")
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)

# === Locate SymEngine (resolved via vcpkg / MSYS2) ======================
# Note: SymEngine's CMake config exports as `SymEngine` (camelcase) with
# legacy variable-style outputs (SYMENGINE_INCLUDE_DIRS +
# SYMENGINE_LIBRARIES), NOT an IMPORTED target.

find_package(SymEngine CONFIG QUIET)

# === Pick the build mode ================================================
set(PREBUILT_DLL "${CMAKE_CURRENT_SOURCE_DIR}/Libraries/libsymbolic_math_bridge.dll")

if(FLUTTER_PLUGIN_STANDALONE AND SymEngine_FOUND)
    set(BRIDGE_BUILD_MODE "full-from-source")
elseif(EXISTS "${PREBUILT_DLL}" AND NOT FLUTTER_PLUGIN_STANDALONE)
    set(BRIDGE_BUILD_MODE "consumer-prebuilt")
elseif(SymEngine_FOUND)
    set(BRIDGE_BUILD_MODE "full-from-source")
else()
    set(BRIDGE_BUILD_MODE "registrar-stub")
endif()

message(STATUS "symbolic_math_bridge: build mode = ${BRIDGE_BUILD_MODE}")

# === Source list per mode ===============================================
set(PLUGIN_SOURCES)

if(NOT FLUTTER_PLUGIN_STANDALONE)
    # Real Flutter build: include the C++ glue that hooks into
    # Flutter's plugin registrar.
    list(APPEND PLUGIN_SOURCES "symbolic_math_bridge_plugin.cpp")
endif()

if(BRIDGE_BUILD_MODE STREQUAL "full-from-source")
    # Pull in the wrapper + force-link.
    list(APPEND PLUGIN_SOURCES
        "force_link.c"
        "${CMAKE_CURRENT_SOURCE_DIR}/../src/flutter_symengine_wrapper.c")
endif()

# Consumer modes still need to compile *something* (even just the
# registrar) so Flutter's plugin contract has a target to link against.
# If PLUGIN_SOURCES is empty (CI + no SymEngine — shouldn't happen but
# guard anyway), add an empty stub.
if(NOT PLUGIN_SOURCES)
    list(APPEND PLUGIN_SOURCES "force_link.c")
endif()

add_library(${PLUGIN_NAME} SHARED ${PLUGIN_SOURCES})

set_target_properties(${PLUGIN_NAME} PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    C_VISIBILITY_PRESET   default)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
    "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PLUGIN_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/../src")

if(NOT FLUTTER_PLUGIN_STANDALONE)
    apply_standard_settings(${PLUGIN_NAME})
    target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)
endif()

if(BRIDGE_BUILD_MODE STREQUAL "full-from-source")
    # force_link.c gets compiled in this mode (see PLUGIN_SOURCES
    # above). Tell symbolic_math_bridge_plugin.cpp it can call
    # symbolic_math_bridge_force_link_symbols(); without this define
    # that call compiles out (avoids link-time unresolved-extern in
    # the registrar-stub / consumer modes).
    target_compile_definitions(${PLUGIN_NAME} PRIVATE
        SYMBOLIC_MATH_BRIDGE_HAS_FORCE_LINK)

    target_include_directories(${PLUGIN_NAME} PRIVATE
        ${SYMENGINE_INCLUDE_DIRS})
    target_link_libraries(${PLUGIN_NAME} PRIVATE
        ${SYMENGINE_LIBRARIES})

    # MSVC dead-code-stripping defeat (CI MSVC builds only).
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

    if(MINGW)
        set_target_properties(${PLUGIN_NAME} PROPERTIES
            PREFIX ""
            LINK_FLAGS "-Wl,--export-all-symbols")
    endif()
endif()

# === Bundled libraries (consumer-prebuilt mode) =========================
# Flutter Windows reads <plugin>_bundled_libraries (PARENT_SCOPE) to know
# which extra files to copy into the runner's output directory. In
# consumer-prebuilt mode this is the prebuilt DLL that holds the actual
# SymEngine wrapper symbols.
if(BRIDGE_BUILD_MODE STREQUAL "consumer-prebuilt")
    set(symbolic_math_bridge_bundled_libraries
        "${PREBUILT_DLL}"
        PARENT_SCOPE)
elseif(NOT FLUTTER_PLUGIN_STANDALONE AND NOT CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    set(symbolic_math_bridge_bundled_libraries
        ""
        PARENT_SCOPE)
endif()
