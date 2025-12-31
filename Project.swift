import ProjectDescription

let project = Project(
    name: "Daroku",
    options: .options(
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    targets: [
        .target(
            name: "Daroku",
            destinations: .macOS,
            product: .app,
            bundleId: "com.kokiTakashiki.Daroku",
            deploymentTargets: .macOS("26.0"),
            infoPlist: .extendingDefault(with: [:]),
            sources: ["Daroku/**"],
            resources: [
                "Daroku/Assets.xcassets",
                "Daroku/Base.lproj/**",
                "Daroku/Daroku.xcdatamodeld",
                "Daroku.icon",
            ],
            entitlements: .file(path: "Daroku/Daroku.entitlements"),
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "6.0",
                    "ENABLE_HARDENED_RUNTIME": "YES",
                    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
                    "ENABLE_APP_SANDBOX": "YES",
                    "STRING_CATALOG_GENERATE_SYMBOLS": "YES",
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                    "SWIFT_STRICT_MEMORY_SAFETY": "YES",
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "Daroku",
                    "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOL_EXTENSIONS": "YES"
                ]
            )
        ),
        .target(
            name: "DarokuTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.kokiTakashiki.DarokuTests",
            deploymentTargets: .macOS("26.0"),
            sources: ["DarokuTests/**"],
            dependencies: [
                .target(name: "Daroku"),
            ]
        ),
        .target(
            name: "DarokuUITests",
            destinations: .macOS,
            product: .uiTests,
            bundleId: "com.kokiTakashiki.DarokuUITests",
            deploymentTargets: .macOS("26.0"),
            sources: ["DarokuUITests/**"],
            dependencies: [
                .target(name: "Daroku"),
            ]
        ),
    ]
)
