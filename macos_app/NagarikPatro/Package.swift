// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NagarikPatro",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CalendarCore", targets: ["CalendarCore"]),
    ],
    targets: [
        .target(
            name: "CalendarCore",
            path: "CalendarCore/Sources/CalendarCore",
            resources: [
                .copy("Resources/bs_calendar_data.json"),
                .copy("Resources/nepali_calendar_events.json"),
                .copy("Resources/nepali_calendar_auspicious.json"),
            ]
        ),
        .testTarget(
            name: "CalendarCoreTests",
            dependencies: ["CalendarCore"],
            path: "CalendarCore/Tests/CalendarCoreTests"
        ),
    ]
)
