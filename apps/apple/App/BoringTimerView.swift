import SwiftUI

private enum BoringPalette {
    static let background = Color(red: 0.95, green: 0.95, blue: 0.93)
    static let ink = Color(red: 0.16, green: 0.16, blue: 0.15)
    static let track = Color(red: 0.82, green: 0.82, blue: 0.79)
}

struct BoringTimerView: View {
    let snapshot: TimerSnapshot

    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width - 64, geometry.size.height * 0.52, 380)

            ZStack {
                BoringPalette.background
                    .ignoresSafeArea()

                BoringDial(progress: snapshot.progress) {
                    Text(snapshot.clockText)
                        .font(.system(size: diameter * 0.21, weight: .regular, design: .rounded))
                        .monospacedDigit()
                        .tracking(-2)
                        .contentTransition(.numericText(countsDown: true))
                }
                .frame(width: diameter, height: diameter)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(accessibilityStatus). \(snapshot.clockText) remaining. \(snapshot.goalSeconds / 60) minute run.")
                .foregroundStyle(BoringPalette.ink)
            }
        }
    }

    private var accessibilityStatus: String {
        switch snapshot.status {
        case .ready: "Ready"
        case .running: "Running"
        case .paused: "Paused"
        case .complete: "Complete"
        }
    }
}

struct BoringThemePreview: View {
    var body: some View {
        ZStack {
            BoringPalette.background
            BoringDial(progress: 0.28) {
                Text("18:00")
                    .font(.system(size: 26, weight: .regular, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(BoringPalette.ink)
            }
            .padding(22)
        }
        .environment(\.colorScheme, .light)
        .accessibilityHidden(true)
    }
}

private struct BoringDial<Content: View>: View {
    let progress: Double
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let lineWidth = max(3, side * 0.014)

            ZStack {
                Circle()
                    .stroke(BoringPalette.track, lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(BoringPalette.ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                content()
            }
            .padding(lineWidth / 2)
            .frame(width: side, height: side)
        }
    }
}
