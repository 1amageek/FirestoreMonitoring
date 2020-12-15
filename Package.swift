// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirestoreMonitoring",
    platforms: [.iOS(.v10), .macOS(.v10_12)],
    products: [
        .library(
            name: "FirestoreMonitoring",
            targets: ["FirestoreMonitoring"]),
    ],
    dependencies: [
        .package(name: "Firebase", url: "git@github.com:firebase/firebase-ios-sdk.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "FirestoreMonitoring",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "Firebase")
            ]),
        .testTarget(
            name: "FirestoreMonitoringTests",
            dependencies: [
                "FirestoreMonitoring",
                .product(name: "FirebaseFirestore",
                         package: "Firebase")
            ]),
    ]
)
