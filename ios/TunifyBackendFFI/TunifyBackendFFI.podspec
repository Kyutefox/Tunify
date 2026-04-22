Pod::Spec.new do |s|
  s.name             = 'TunifyBackendFFI'
  s.version          = '0.1.0'
  s.summary          = 'Bundled Rust backend bridge for Tunify iOS'
  s.description      = 'XCFramework wrapper for tunify-rust-backend static library FFI.'
  s.homepage         = 'https://github.com/kyutefox/Tunify'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Tunify' => 'dev@tunify.local' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '14.0'
  s.module_name      = 'TunifyBackendFFI'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'HEADER_SEARCH_PATHS' => '$(inherited) "${PODS_TARGET_SRCROOT}/TunifyBackendFFI.xcframework/ios-arm64/Headers" "${PODS_TARGET_SRCROOT}/TunifyBackendFFI.xcframework/ios-arm64-simulator/Headers"'
  }
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS[sdk=iphoneos*]' => '$(inherited) -force_load "${PODS_ROOT}/../TunifyBackendFFI/TunifyBackendFFI.xcframework/ios-arm64/libtunify_rust_backend.a"',
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '$(inherited) -force_load "${PODS_ROOT}/../TunifyBackendFFI/TunifyBackendFFI.xcframework/ios-arm64-simulator/libtunify_rust_backend.a"'
  }
  s.source_files = 'TunifyBackendFFI.xcframework/ios-arm64/Headers/*.h'
end
