// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "privacypass_ffi",
    platforms: [
        .macOS("10.14")
    ],
    products: [
        .library(name: "privacypass-ffi", targets: ["privacypass_ffi"])
    ],
    targets: [
        .target(
            name: "privacypass_ffi",
            dependencies: [
                "KagiPrivacyPassFFI"
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .binaryTarget(
            name: "KagiPrivacyPassFFI",
            path: "Frameworks/KagiPrivacyPassFFI.xcframework"
        )
    ]
)
