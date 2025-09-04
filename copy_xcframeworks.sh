#!/bin/bash
# copy_xcframeworks.sh
# Simple script to copy finished XCFrameworks from math-stack-ios-builder
# and ensure a clean state in the target directory.

set -e

readonly SCRIPTDIR=$(cd "$(dirname "$0")" && pwd)
readonly TARGET_DIR="$SCRIPTDIR/ios"
readonly SOURCE_DIR="../math-stack-ios-builder"

logMsg() { printf "[COPY] %s\n" "$1"; }
errorExit() { logMsg "❌ ERROR: $1"; exit 1; }

checkSourceDirectory() {
    if [ ! -d "$SOURCE_DIR" ]; then
        errorExit "Source directory not found: $SOURCE_DIR"
    fi
    logMsg "✅ Source directory found: $SOURCE_DIR"
}

copyXCFramework() {
    local framework_name="$1"
    local source_path="$SOURCE_DIR/$framework_name.xcframework"
    local target_path="$TARGET_DIR/$framework_name.xcframework"
    
    if [ ! -d "$source_path" ]; then
        errorExit "Framework not found: $source_path. Build it first in math-stack-ios-builder."
    fi
    
    logMsg "Copying $framework_name.xcframework..."
    rm -rf "$target_path"  # Remove old version
    cp -R "$source_path" "$target_path"
    logMsg "✅ Copied $framework_name.xcframework"
}

verifyFramework() {
    local framework_name="$1"
    local framework_path="$TARGET_DIR/$framework_name.xcframework"
    
    if [ -d "$framework_path" ]; then
        logMsg "✅ $framework_name.xcframework available"
        # List the slices to verify
        for slice_dir in "$framework_path"/*/; do
            if [ -d "$slice_dir" ]; then
                echo "  Slice: $(basename "$slice_dir")"
            fi
        done
    else
        logMsg "❌ $framework_name.xcframework missing"
    fi
}

# --- Main Execution ---
logMsg "Copying all XCFrameworks from math-stack-ios-builder..."

checkSourceDirectory

# **NEW:** Clean up the old, separate Headers directory to avoid conflicts.
# The correct headers are now located inside each XCFramework.
if [ -d "$TARGET_DIR/Headers" ]; then
    logMsg "Cleaning up stale external Headers directory..."
    rm -rf "$TARGET_DIR/Headers"
    logMsg "✅ Stale headers removed."
fi

# Copy all base mathematical frameworks
copyXCFramework "GMP"
copyXCFramework "MPFR"
copyXCFramework "MPC"
copyXCFramework "FLINT"

# Copy the main SymEngine framework with Flutter wrapper
copyXCFramework "SymEngineFlutterWrapper"

logMsg "🚀 All XCFrameworks copied successfully!"
logMsg ""
logMsg "Verification:"
verifyFramework "GMP"
verifyFramework "MPFR" 
verifyFramework "MPC"
verifyFramework "FLINT"
verifyFramework "SymEngineFlutterWrapper"

logMsg ""
logMsg "Next steps:"
logMsg "1. Run 'flutter clean' in your test app."
logMsg "2. Run 'flutter run' - the build should now succeed!"
