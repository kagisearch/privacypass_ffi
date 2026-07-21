import Flutter
import UIKit
import privacypass_ffi_retain

public class PrivacypassFfiPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Keep the Rust FFI symbols alive so Dart's DynamicLibrary.process()
    // can resolve them at runtime. See privacypass_ffi_retain for details.
    privacypass_ffi_retain_symbols()
  }
}
