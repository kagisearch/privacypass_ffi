#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint privacypass_ffi.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'privacypass_ffi'
  s.version          = '0.1.0'
  s.summary          = 'Privacy Pass FFI plugin for Flutter (macOS)'
  s.description      = <<-DESC
A Flutter plugin that provides Privacy Pass token request and finalization via Rust FFI.
                       DESC
  s.homepage         = 'https://kagi.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Kagi' => 'support@kagi.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'

  # Vendor the compiled Rust library
  s.vendored_libraries = 'Frameworks/libkagipp_ffi.dylib'

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
