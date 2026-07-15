Pod::Spec.new do |s|
  s.name             = 'symbolic_math_bridge'
  s.version          = '1.5.0'
  s.summary          = 'A bridge for the complete symbolic math stack.'
  s.description      = 'This plugin provides C-wrapped access to SymEngine and math libraries. The plugin glue is MIT; bundled native libraries retain their upstream licenses. See THIRD-PARTY-NOTICES.md.'
  s.homepage         = 'https://github.com/CrispStrobe/symbolic_math_bridge'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'CrispStrobe' => 'cze@mailbox.org' }
  s.source           = { :path => '.' }

  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.static_framework = true
  s.swift_version = '5.0'

  # `-lc++` because SymEngine uses C++ stdlib.
  # `-lsymengine_flutter_wrapper` pulls in the big archive (~3000 SymEngine
  # symbols). `-Wl,-force_load,…FlutterSymEngineWrapperOnly…` pulls in the
  # tiny archive with just the 45 C wrapper entry points — they're
  # separated so we can force-load only the wrapper objects without
  # double-loading SymEngine (which would trip duplicate-symbol errors).
  # Without this split, release builds silently drop every
  # `flutter_symengine_*` symbol (the linker doesn't see them as
  # referenced because they're only reached via dlsym at runtime).
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => [
      '-lc++',
      '-lsymengine_flutter_wrapper',
      '-all_load',
    ].join(' '),
    'LIBRARY_SEARCH_PATHS' => '$(inherited)',
    'STRIP_STYLE' => 'debugging',
    'DEAD_CODE_STRIPPING' => 'NO',
  }

  s.vendored_frameworks = [
    'GMP.xcframework',
    'MPFR.xcframework',
    'MPC.xcframework',
    'FLINT.xcframework',
    'SymEngineFlutterWrapper.xcframework',
  ]
  # FlutterSymEngineWrapperOnly.xcframework is in the repo for the
  # release-link fix; not yet wired into the build. See macOS podspec.
end
