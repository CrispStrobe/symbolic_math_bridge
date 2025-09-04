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
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.static_framework = true
  s.swift_version = '5.0'

  # CRITICAL: Force all library symbols to be linked and available for dlsym()
  # The SymEngineBridge.m +load method will reference all symbols to ensure linking
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => [
      '-lc++',
      '-lsymengine_flutter_wrapper',  # Updated to match the actual library name
      # Force load to ensure symbols survive linking and are available at runtime
      '-all_load'
    ].join(' '),
    'LIBRARY_SEARCH_PATHS' => '$(inherited)',
    # 'HEADER_SEARCH_PATHS' => '$(inherited) $(PODS_TARGET_SRCROOT)/Headers',

    # Ensure symbols aren't stripped during optimization
    'STRIP_STYLE' => 'debugging',
    'DEAD_CODE_STRIPPING' => 'NO'
  }

  # All XCFrameworks - these contain the actual library implementations
  s.vendored_frameworks = [
    'GMP.xcframework',
    'MPFR.xcframework',
    'MPC.xcframework',
    'FLINT.xcframework',
    'SymEngineFlutterWrapper.xcframework'  # Use the properly built Flutter wrapper
  ]
end