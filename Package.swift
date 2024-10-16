// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "SWToolKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SWToolKit",
            targets: ["SWToolKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.0")),
        .package(url: "https://github.com/tristanhimmelman/ObjectMapper.git", .upToNextMajor(from: "4.4.3")),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", .upToNextMajor(from: "2.28.0")),
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.75.0")),
        .package(url: "https://github.com/sunimp/SWExtensions.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.54.6"),
    ],
    targets: [
        .target(
            name: "SWToolKit",
            dependencies: [
                "Alamofire",
                "ObjectMapper",
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                "SWExtensions"
            ]
        ),
    ]
)
