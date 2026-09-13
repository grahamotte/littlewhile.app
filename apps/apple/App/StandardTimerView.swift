import SwiftUI

private enum StandardPalette {
    static let paper = Color(red: 0.97, green: 0.96, blue: 0.92)
    static let ink = Color(red: 0.22, green: 0.27, blue: 0.25)
    static let quiet = Color(red: 0.44, green: 0.48, blue: 0.44)
    static let accent = Color(red: 0.79, green: 0.36, blue: 0.24)
}

struct StandardTimerView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let snapshot: TimerSnapshot

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 680 || dynamicTypeSize.isAccessibilitySize
            let diameter = min(geometry.size.width - 52, geometry.size.height * (compact ? 0.38 : 0.48), 380)

            ZStack {
                StandardBackground()

                VStack(spacing: 0) {
                    Spacer(minLength: compact ? 74 : 84)

                    VStack(spacing: compact ? 6 : 12) {
                        Image(systemName: "sun.max")
                            .font(.system(size: compact ? 18 : 25, weight: .light))
                            .foregroundStyle(StandardPalette.accent)
                        Text("little while")
                            .font(.system(size: 19, weight: .medium, design: .serif))
                            .tracking(0.5)
                    }
                    .accessibilityElement(children: .combine)

                    Spacer(minLength: compact ? 16 : 30)

                    StandardDial(progress: snapshot.progress) {
                        VStack(spacing: 12) {
                            Text(statusTitle)
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(3)
                                .foregroundStyle(StandardPalette.quiet)
                            Text(snapshot.clockText)
                                .font(.system(size: diameter * 0.205, weight: .ultraLight, design: .rounded))
                                .monospacedDigit()
                                .tracking(-2)
                                .contentTransition(.numericText(countsDown: true))
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(snapshot.status == .running ? StandardPalette.accent : StandardPalette.quiet.opacity(0.45))
                                    .frame(width: 5, height: 5)
                                Text(statusDetail)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(StandardPalette.quiet)
                            }
                        }
                    }
                    .frame(width: diameter, height: diameter)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(statusTitle). \(snapshot.clockText) remaining. \(snapshot.goalSeconds / 60) minute run.")

                    Spacer(minLength: compact ? 16 : 30)

                    VStack(spacing: compact ? 8 : 12) {
                        Text(footerTitle)
                            .font(.system(size: compact ? 21 : 25, weight: .regular, design: .serif))
                            .multilineTextAlignment(.center)
                        if !dynamicTypeSize.isAccessibilitySize {
                            Text(footerDetail)
                                .font(.subheadline)
                                .foregroundStyle(StandardPalette.quiet)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer(minLength: compact ? 16 : 30)

                    HStack(spacing: 8) {
                        Rectangle().frame(width: 22, height: 1)
                        Text("ONE THING AT A TIME")
                            .font(.system(size: 9, weight: .medium))
                            .tracking(2)
                        Rectangle().frame(width: 22, height: 1)
                    }
                    .foregroundStyle(StandardPalette.quiet.opacity(0.65))
                    .padding(.bottom, compact ? 16 : 26)
                    .accessibilityHidden(true)
                }
                .foregroundStyle(StandardPalette.ink)
            }
        }
    }

    private var statusTitle: String {
        switch snapshot.status {
        case .ready: "A MOMENT FOR YOU"
        case .running: "IN THE MOMENT"
        case .paused: "TAKE A BREATH"
        case .complete: "NICELY DONE"
        }
    }

    private var statusDetail: String {
        switch snapshot.status {
        case .ready: "\(snapshot.goalSeconds / 60) \(snapshot.goalSeconds == 60 ? "minute" : "minutes") of focus"
        case .running: "of a little while"
        case .paused: "paused, whenever you’re ready"
        case .complete: "a little time well spent"
        }
    }

    private var footerTitle: String {
        switch snapshot.status {
        case .ready: "Make room for one thing."
        case .running: "You’re right where you need to be."
        case .paused: "A pause is part of the process."
        case .complete: "You made a little space."
        }
    }

    private var footerDetail: String {
        switch snapshot.status {
        case .ready: "Press play. The rest can wait."
        case .running: "No rush. Just this moment."
        case .paused: "Press play to find your flow again."
        case .complete: "Take a breath. Enjoy a well-earned break."
        }
    }
}

struct StandardThemePreview: View {
    var body: some View {
        ZStack {
            StandardBackground()
            StandardDial(progress: 0.28) {
                VStack(spacing: 4) {
                    Text("little while")
                        .font(.system(size: 8, weight: .medium, design: .serif))
                    Text("18:00")
                        .font(.system(size: 26, weight: .ultraLight, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundStyle(StandardPalette.ink)
            }
            .padding(22)
        }
        .environment(\.colorScheme, .light)
        .accessibilityHidden(true)
    }
}

private struct StandardBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                StandardPalette.paper
                RadialGradient(
                    colors: [Color(red: 0.84, green: 0.89, blue: 0.79).opacity(0.65), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: geometry.size.height * 0.9,
                )
                RadialGradient(
                    colors: [Color(red: 0.95, green: 0.78, blue: 0.64).opacity(0.55), .clear],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: geometry.size.height * 0.6,
                )
            }
        }
        .ignoresSafeArea()
    }
}

private struct StandardDial<Content: View>: View {
    let progress: Double
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let lineWidth = max(2, side * 0.012)

            ZStack {
                Circle()
                    .fill(.white.opacity(0.19))
                    .padding(side * 0.1)
                Circle()
                    .strokeBorder(StandardPalette.ink.opacity(0.12), lineWidth: 1)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(StandardPalette.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(0.5)
                ForEach(0..<60, id: \.self) { tick in
                    Capsule()
                        .fill(StandardPalette.ink.opacity(tick.isMultiple(of: 5) ? 0.52 : 0.19))
                        .frame(width: tick.isMultiple(of: 5) ? 1.5 : 1, height: side * (tick.isMultiple(of: 5) ? 0.034 : 0.014))
                        .offset(y: -side * 0.438)
                        .rotationEffect(.degrees(Double(tick) * 6))
                }
                Circle()
                    .fill(StandardPalette.accent)
                    .frame(width: lineWidth * 2.2, height: lineWidth * 2.2)
                    .overlay { Circle().strokeBorder(StandardPalette.paper, lineWidth: 2) }
                    .offset(y: -side / 2 + 0.5)
                    .rotationEffect(.degrees(progress * 360))
                content()
            }
            .frame(width: side, height: side)
        }
    }
}
