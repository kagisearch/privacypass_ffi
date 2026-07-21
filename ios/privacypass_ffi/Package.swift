// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "privacypass_ffi",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "privacypass-ffi", targets: ["privacypass_ffi"])
    ],
    targets: [
        .target(
            name: "privacypass_ffi",
            dependencies: [
                "KagiPrivacyPassFFI",
                "privacypass_ffi_retain"
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        // C shim that references the Rust FFI symbols so the linker does not
        // dead-strip them from the final app binary. This is required because
        // Dart resolves them at runtime via DynamicLibrary.process()
        // (dlsym/RTLD_DEFAULT); nothing references them at link time otherwise.
        // SwiftPM's .binaryTarget has no `-force_load` equivalent (unlike the
        // CocoaPods podspec), so we anchor the symbols manually.
        .target(
            name: "privacypass_ffi_retain",
            dependencies: [
                "KagiPrivacyPassFFI"
            ]
        ),
        .binaryTarget(
            name: "KagiPrivacyPassFFI",
            path: "Frameworks/KagiPrivacyPassFFI.xcframework"
        )
    ]
)
