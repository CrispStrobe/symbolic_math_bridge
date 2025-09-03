#!/bin/bash
# Create a proper SymEngine XCFramework with consistent binary names

set -e

readonly PLUGIN_DIR="/Users/christianstrobele/code/symbolic_math_bridge/ios"
readonly FRAMEWORK_NAME="SymEngineWrapper"
readonly FRAMEWORK_DIR="$PLUGIN_DIR/$FRAMEWORK_NAME.xcframework"

logMsg() { printf "[XCFRAMEWORK] %s\n" "$1"; }

# Check if libraries exist
if [ ! -f "$PLUGIN_DIR/Libraries/libsymengine_wrapper-iphoneos-arm64.a" ]; then
    echo "❌ Device library not found. Run the build and copy scripts first."
    exit 1
fi

if [ ! -f "$PLUGIN_DIR/Libraries/libsymengine_wrapper-iphonesimulator-universal.a" ]; then
    echo "❌ Simulator library not found. Run the build and copy scripts first."
    exit 1
fi

# Clean up old framework
rm -rf "$FRAMEWORK_DIR"

# Create temporary directory for renaming
temp_dir="/tmp/symengine_xcframework_$$"
rm -rf "$temp_dir"
mkdir -p "$temp_dir/device" "$temp_dir/simulator" "$temp_dir/macos"

# CocoaPods requires IDENTICAL names for all libraries
consistent_name="libsymengine_wrapper.a"

logMsg "Creating libraries with consistent names..."

# Copy and rename to consistent names
cp "$PLUGIN_DIR/Libraries/libsymengine_wrapper-iphoneos-arm64.a" \
   "$temp_dir/device/$consistent_name"

cp "$PLUGIN_DIR/Libraries/libsymengine_wrapper-iphonesimulator-universal.a" \
   "$temp_dir/simulator/$consistent_name"

cp "$PLUGIN_DIR/Libraries/libsymengine_wrapper-macosx-universal.a" \
   "$temp_dir/macos/$consistent_name"

# Create XCFramework with consistently named libraries
logMsg "Creating XCFramework with consistent binary names..."

xcodebuild -create-xcframework \
    -library "$temp_dir/device/$consistent_name" \
    -headers "$PLUGIN_DIR/Headers" \
    -library "$temp_dir/simulator/$consistent_name" \
    -headers "$PLUGIN_DIR/Headers" \
    -library "$temp_dir/macos/$consistent_name" \
    -headers "$PLUGIN_DIR/Headers" \
    -output "$FRAMEWORK_DIR"

# Clean up temp directory
rm -rf "$temp_dir"

# Verify the XCFramework was created correctly
if [ -d "$FRAMEWORK_DIR" ]; then
    logMsg "✅ XCFramework created successfully with consistent naming"
    logMsg "Verifying binary names:"
    
    # Check each slice has the consistent name
    for slice_dir in "$FRAMEWORK_DIR"/*/; do
        if [ -d "$slice_dir" ]; then
            echo "  Slice: $(basename "$slice_dir")"
            ls -la "$slice_dir" | grep -E "SymEngineWrapper|\.a" || echo "    No binaries found"
        fi
    done
    
    logMsg "Info.plist verification:"
    plutil -p "$FRAMEWORK_DIR/Info.plist" | grep -A 2 -B 2 "BinaryPath\|LibraryPath" | head -10
else
    logMsg "❌ Failed to create XCFramework"
    exit 1
fi

logMsg "🚀 Ready to use the properly named XCFramework!"