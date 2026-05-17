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

  s.pod_target_xcconfig = {
    # `-lc++` because SymEngine uses C++ stdlib.
    # `-lsymengine_flutter_wrapper` pulls in the big archive (SymEngine
    # itself, ~3000 symbols). `-lflutter_symengine_wrapper_only` pulls
    # in the tiny archive with just the 45 C wrapper entry points —
    # they're separated so `-all_load` can force-load only the wrapper
    # without trying to load every SymEngine object twice (which trips
    # duplicate-symbol errors). Without the wrapper-only lib + its own
    # force-load, release builds silently drop every flutter_symengine_*
    # symbol; see HISTORY.md / PLAN.md round 11.
    'OTHER_LDFLAGS' => [
      '-lc++',
      '-lsymengine_flutter_wrapper',
      '-all_load',
      # Belt-and-braces: in addition to `-all_load` on the big archive,
      # explicitly force-load the wrapper-only archive. The big-archive
      # path keeps debug builds working (45 symbols land in
      # crisp_calc.debug.dylib); the wrapper-only path is the seed for
      # the release-build fix when the upstream link pipeline cooperates.
      '-Wl,-force_load,${PODS_TARGET_SRCROOT}/FlutterSymEngineWrapperOnly.xcframework/macos-arm64_x86_64/libflutter_symengine_wrapper_only.a',
    ].join(' '),
    'LIBRARY_SEARCH_PATHS' => '$(inherited)',
    'STRIP_STYLE' => 'debugging',
    'DEAD_CODE_STRIPPING' => 'NO',
    'DEFINES_MODULE' => 'YES',
  }

  s.vendored_frameworks = [
    'GMP.xcframework',
    'MPFR.xcframework',
    'MPC.xcframework',
    'FLINT.xcframework',
    'SymEngineFlutterWrapper.xcframework',
    'FlutterSymEngineWrapperOnly.xcframework',
  ]
end
