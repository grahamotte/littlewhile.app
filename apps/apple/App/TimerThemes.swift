import SwiftUI

struct TimerTheme: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let colorScheme: ColorScheme
    let preview: AnyView
    let screen: (TimerSnapshot) -> AnyView
}

@MainActor
enum TimerThemes {
    static let all: [TimerTheme] = [
        TimerTheme(
            id: "standard",
            name: "Standard",
            subtitle: "A little space to focus.",
            colorScheme: .light,
            preview: AnyView(StandardThemePreview()),
            screen: { AnyView(StandardTimerView(snapshot: $0)) },
        ),
    ]

    static func resolve(_ id: String) -> TimerTheme {
        all.first { $0.id == id } ?? all[0]
    }
}
