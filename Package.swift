// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ReadeckAPI",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "ReadeckAPI",
            targets: ["ReadeckAPI"]
        ),
    ],
    dependencies: [
        // Swift OpenAPI Generator (Codegenerierung beim Build)
        .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.2.0"),
        // OpenAPI Runtime (Laufzeitkomponenten)
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.3.0"),
        // Optional: URLSession-Transport für HTTP-Clients
        .package(url: "https://github.com/apple/swift-openapi-urlsession.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ReadeckAPI",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession")
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .testTarget(
            name: "ReadeckAPITests",
            dependencies: ["ReadeckAPI"]
        )
    ]
)
