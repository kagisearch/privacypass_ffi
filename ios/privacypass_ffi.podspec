#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint privacypass_ffi.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'privacypass_ffi'
  s.version          = '0.1.0'
  s.summary          = 'Privacy Pass protocol implementation via Rust FFI'
  s.description      = <<-DESC
Privacy Pass protocol implementation for iOS using Rust FFI.
Provides native performance for cryptographic operations.
                       DESC
  s.homepage         = 'https://kagi.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Kagi' => 'support@kagi.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Static library containing Rust code
  s.vendored_libraries = 'Frameworks/*.a'

  # Pod configuration with conditional linking
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    # Conditional force load based on SDK
    'OTHER_LDFLAGS[sdk=iphoneos*]' => '-force_load "$(PODS_TARGET_SRCROOT)/Frameworks/libkagipp_ffi.a"',
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '-force_load "$(PODS_TARGET_SRCROOT)/Frameworks/libkagipp_ffi_sim.a"',
    # Library search paths
    'LIBRARY_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/Frameworks"'
  }

  s.user_target_xcconfig = {
    'LIBRARY_SEARCH_PATHS' => '"$(PODS_ROOT)/privacypass_ffi/Frameworks"'
  }

  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'privacypass_ffi_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
