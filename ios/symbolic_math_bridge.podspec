Pod::Spec.new do |s|
  s.name             = 'symbolic_math_bridge'
  s.version          = '1.0.13'
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

  # Simple configuration - let CocoaPods handle XCFramework linking automatically
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-lc++ -lsymengine_wrapper',
    'LIBRARY_SEARCH_PATHS' => '$(inherited)'
  }

  # All XCFrameworks treated identically - no special handling for SymEngine
  s.vendored_frameworks = [
    'GMP.xcframework',
    'MPFR.xcframework', 
    'MPC.xcframework',
    'FLINT.xcframework',
    'SymEngineWrapper.xcframework'
  ]
end