#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint symbolic_math_bridge.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'symbolic_math_bridge'
  s.version          = '1.0.14'
  s.summary          = 'A bridge for the complete symbolic math stack.'
  s.description      = 'This plugin provides C-wrapped access to SymEngine and math libraries.'
  s.homepage         = 'https://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'CrispStrobe' => 'cze@mailbox.org' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform         = :osx, '10.15'
  s.static_framework = true
  s.swift_version    = '5.0'

  # Match the iOS spec: force-load all native symbols so dart:ffi can find
  # them at runtime via DynamicLibrary.process().
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => [
      '-lc++',
      '-lsymengine_flutter_wrapper',
      '-all_load',
    ].join(' '),
    'LIBRARY_SEARCH_PATHS' => '$(inherited)',
    'STRIP_STYLE' => 'debugging',
    'DEAD_CODE_STRIPPING' => 'NO',
    'DEFINES_MODULE' => 'YES',
  }

  # Same xcframeworks the iOS spec uses. They live in the iOS plugin dir
  # but each one ships a macos-arm64_x86_64 slice; we expose them here via
  # symlinks so CocoaPods picks them up without `..` paths (which it doesn't
  # accept in vendored_frameworks).
  s.vendored_frameworks = [
    'GMP.xcframework',
    'MPFR.xcframework',
    'MPC.xcframework',
    'FLINT.xcframework',
    'SymEngineFlutterWrapper.xcframework',
  ]
end
