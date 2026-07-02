// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SKBrotherPrinterWrapper",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SKBrotherPrinterWrapper",
            targets: ["SKBrotherPrinterWrapper"]
        )
    ],
    targets: [
        // Brother's precompiled SDK, vendored as a binary target.
        .binaryTarget(
            name: "BRLMPrinterKit",
            path: "BrotherSDK/BRLMPrinterKit.xcframework"
        ),
        // The wrapper. Only the `public` types (PrinterManager, PrintRequest, …)
        // are visible to consumers; everything else stays module-internal.
        .target(
            name: "SKBrotherPrinterWrapper",
            dependencies: ["BRLMPrinterKit"],
            path: "Sources"
        )
    ]
)
