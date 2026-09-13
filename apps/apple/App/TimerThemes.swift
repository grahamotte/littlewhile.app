import SwiftUI

struct TimerTheme: Identifiable {
    let id: String
    let name: String
    let colorScheme: ColorScheme
    let preview: AnyView
    let screen: (TimerSnapshot) -> AnyView
}

@MainActor
enum TimerThemes {
    static let all: [TimerTheme] = [
        TimerTheme(
            id: "boring",
            name: "Boring",
            colorScheme: .light,
            preview: AnyView(BoringThemePreview()),
            screen: { AnyView(BoringTimerView(snapshot: $0)) },
        ),
    ]

    static func resolve(_ id: String) -> TimerTheme {
        all.first { $0.id == id } ?? all[0]
    }
}
