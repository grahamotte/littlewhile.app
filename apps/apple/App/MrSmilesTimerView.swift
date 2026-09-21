import SwiftUI

private enum MrSmilesPalette {
    static let background = Color(red: 0.115, green: 0.125, blue: 0.14)
    static let yellow = Color(red: 1, green: 0.79, blue: 0.18)
    static let highlight = Color(red: 1, green: 0.86, blue: 0.29)
    static let ink = Color(red: 0.20, green: 0.16, blue: 0.09)
    static let love = Color(red: 0.90, green: 0.14, blue: 0.22)
    static let clock = Color(red: 0.73, green: 0.72, blue: 0.66)
}

enum MrSmilesEyeMetrics {
    static let heartWidth: CGFloat = 0.30
    static let heartHeight: CGFloat = 0.28
    static let starSize: CGFloat = 0.30
}

struct MrSmilesTimerView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animation = MrSmilesAnimation()
    @State private var screenCornerRadius: CGFloat?
    @State private var heldRunID: UUID?
    @State private var dragStartCenter: CGPoint?
    @State private var dragStartLocation: CGPoint?
    @State private var dragStartVelocity: CGVector?
    @GestureState private var isTouching = false

    let snapshot: TimerSnapshot

    var body: some View {
        GeometryReader { safeGeometry in
            GeometryReader { geometry in
                let diameter = min(108, geometry.size.width * 0.26, geometry.size.height * 0.22)
                let cornerRadius = screenCornerRadius.flatMap { $0 > 0 ? $0 : nil } ?? MrSmilesScreenGeometry.cornerRadius(
                    safeAreaTop: safeGeometry.safeAreaInsets.top,
                    safeAreaBottom: safeGeometry.safeAreaInsets.bottom,
                )

                TimelineView(.animation(
                    minimumInterval: 1.0 / 60,
                    paused: snapshot.status != .running || scenePhase != .active || reduceMotion,
                )) { context in
                    let frame = frame(at: context.date, size: geometry.size, diameter: diameter, cornerRadius: cornerRadius)
                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

                    ZStack(alignment: .bottomTrailing) {
                        MrSmilesPalette.background

                        Text(snapshot.clockText)
                            .font(.custom("ChalkboardSE-Regular", size: 25, relativeTo: .body))
                            .monospacedDigit()
                            .foregroundStyle(MrSmilesPalette.clock)
                            .padding(.trailing, max(30, safeGeometry.safeAreaInsets.trailing + 24))
                            .padding(.bottom, max(26, safeGeometry.safeAreaInsets.bottom + 15))
                            .accessibilityLabel("\(accessibilityStatus). \(snapshot.clockText) remaining. \(snapshot.goalSeconds / 60) minute focus. \(snapshot.restSeconds / 60) minute rest.")

                        MrSmilesFace(
                            paused: snapshot.status == .paused,
                            completed: snapshot.status == .complete,
                            resting: snapshot.isResting,
                            leftEyeWinking: snapshot.status == .running && (frame.motion?.leftEyeWinking ?? false),
                            rightEyeWinking: snapshot.status == .running && (frame.motion?.rightEyeWinking ?? false),
                        )
                        .frame(width: diameter, height: diameter)
                        .contentShape(Circle())
                        .rotationEffect(.radians(reduceMotion ? 0 : frame.motion?.rotation ?? 0))
                        .gesture(flickGesture(size: geometry.size, diameter: diameter, cornerRadius: cornerRadius))
                        .position(reduceMotion ? center : frame.motion?.position ?? center)
                        .accessibilityHidden(true)
                        .allowsHitTesting(snapshot.status == .running && scenePhase == .active && !reduceMotion)
                        .id(snapshot.runID)
                    }
                    .coordinateSpace(name: "mr-smiles-screen")
                    .onChange(of: context.date, initial: true) { _, date in
                        animation = self.frame(at: date, size: geometry.size, diameter: diameter, cornerRadius: cornerRadius)
                    }
                }
                .background {
                    MrSmilesScreenGeometryReader(cornerRadius: $screenCornerRadius)
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: isTouching) { _, touching in
            if !touching {
                heldRunID = nil
                dragStartCenter = nil
                dragStartLocation = nil
                dragStartVelocity = nil
            }
        }
    }

    private func flickGesture(size: CGSize, diameter: CGFloat, cornerRadius: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("mr-smiles-screen"))
            .updating($isTouching) { _, touching, _ in
                touching = true
            }
            .onChanged { gesture in
                guard snapshot.status == .running, scenePhase == .active, !reduceMotion else { return }
                let date = Date.now
                var frame = frame(at: date, size: size, diameter: diameter, cornerRadius: cornerRadius)
                if heldRunID == nil {
                    guard let motion = frame.motion, frame.stop(snapshot: snapshot, at: date) else { return }
                    heldRunID = snapshot.runID
                    dragStartCenter = motion.position
                    dragStartLocation = nil
                    dragStartVelocity = motion.velocity
                }
                guard heldRunID == snapshot.runID else { return }
                if dragStartLocation == nil {
                    dragStartLocation = gesture.startLocation
                }
                if let dragStartCenter, let dragStartLocation {
                    let target = CGPoint(
                        x: dragStartCenter.x + gesture.location.x - dragStartLocation.x,
                        y: dragStartCenter.y + gesture.location.y - dragStartLocation.y,
                    )
                    if frame.move(to: target, snapshot: snapshot, at: date) {
                        animation = frame
                    }
                }
            }
            .onEnded { gesture in
                let restingVelocity = dragStartVelocity
                defer {
                    heldRunID = nil
                    dragStartCenter = nil
                    dragStartLocation = nil
                    dragStartVelocity = nil
                }
                guard snapshot.status == .running, scenePhase == .active, !reduceMotion else { return }
                let date = Date.now
                var frame = frame(at: date, size: size, diameter: diameter, cornerRadius: cornerRadius)
                let flicked = frame.flick(
                    velocity: CGVector(dx: gesture.velocity.width, dy: gesture.velocity.height),
                    snapshot: snapshot,
                    at: date,
                )
                let resumed = !flicked && restingVelocity.map {
                    frame.flick(velocity: $0, snapshot: snapshot, at: date)
                } == true
                if flicked || resumed {
                    animation = frame
                }
            }
    }

    private func frame(at date: Date, size: CGSize, diameter: CGFloat, cornerRadius: CGFloat) -> MrSmilesAnimation {
        var frame = animation
        frame.update(
            snapshot: snapshot,
            at: date,
            size: size,
            faceRadius: diameter / 2,
            screenCornerRadius: cornerRadius,
        )
        return frame
    }

    private var accessibilityStatus: String {
        switch snapshot.status {
        case .ready: "Ready"
        case .running: snapshot.isResting ? "Resting" : "Focusing"
        case .paused: snapshot.isResting ? "Rest paused" : "Paused"
        case .complete: "Complete"
        }
    }
}

struct MrSmilesThemePreview: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            MrSmilesPalette.background

            Text("18:00")
                .font(.custom("ChalkboardSE-Regular", size: 14))
                .foregroundStyle(MrSmilesPalette.clock)
                .padding(16)

            MrSmilesFace(paused: false, completed: false, resting: false, leftEyeWinking: false, rightEyeWinking: true)
                .frame(width: 66, height: 66)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environment(\.colorScheme, .dark)
        .accessibilityHidden(true)
    }
}

private struct MrSmilesFace: View {
    let paused: Bool
    let completed: Bool
    let resting: Bool
    let leftEyeWinking: Bool
    let rightEyeWinking: Bool

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)

            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [MrSmilesPalette.highlight, MrSmilesPalette.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing,
                    ))

                eye(paused: paused, completed: completed, resting: resting, winking: leftEyeWinking, side: side)
                    .position(x: side * 0.34, y: side * 0.38)

                eye(paused: paused, completed: completed, resting: resting, winking: rightEyeWinking, side: side)
                    .position(x: side * 0.66, y: side * 0.38)

                MrSmilesMouth()
                    .stroke(MrSmilesPalette.ink, style: StrokeStyle(lineWidth: side * 0.043, lineCap: .round))
            }
            .frame(width: side, height: side)
        }
    }

    @ViewBuilder
    private func eye(paused: Bool, completed: Bool, resting: Bool, winking: Bool, side: CGFloat) -> some View {
        if completed {
            MrSmilesHeart()
                .fill(MrSmilesPalette.love)
                .frame(width: side * MrSmilesEyeMetrics.heartWidth, height: side * MrSmilesEyeMetrics.heartHeight)
        } else if resting {
            MrSmilesStar()
                .fill(MrSmilesPalette.ink)
                .frame(width: side * MrSmilesEyeMetrics.starSize, height: side * MrSmilesEyeMetrics.starSize)
        } else if paused {
            Capsule()
                .fill(MrSmilesPalette.ink)
                .frame(width: side * 0.072, height: side * 0.24)
        } else if winking {
            MrSmilesWink()
                .stroke(MrSmilesPalette.ink, style: StrokeStyle(lineWidth: side * 0.042, lineCap: .round))
                .frame(width: side * 0.16, height: side * 0.075)
        } else {
            Circle()
                .fill(MrSmilesPalette.ink)
                .frame(width: side * 0.105, height: side * 0.105)
        }
    }
}

struct MrSmilesStar: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.50
        let points = (0..<10).map { index -> CGPoint in
            let angle = Double(index) * .pi / 5 - .pi / 2
            let radius = index.isMultiple(of: 2) ? outer : inner
            return CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius,
            )
        }
        return mrSmilesRoundedPolygon(points, cornerRadius: outer * 0.18)
    }
}

struct MrSmilesHeart: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        path.move(to: CGPoint(x: width * 0.42, y: height * 0.76))
        path.addCurve(
            to: CGPoint(x: width * 0.06, y: height * 0.38),
            control1: CGPoint(x: width * 0.24, y: height * 0.66),
            control2: CGPoint(x: width * 0.00, y: height * 0.54),
        )
        path.addCurve(
            to: CGPoint(x: width * 0.50, y: height * 0.32),
            control1: CGPoint(x: width * 0.12, y: height * 0.12),
            control2: CGPoint(x: width * 0.40, y: height * 0.14),
        )
        path.addCurve(
            to: CGPoint(x: width * 0.94, y: height * 0.38),
            control1: CGPoint(x: width * 0.60, y: height * 0.14),
            control2: CGPoint(x: width * 0.88, y: height * 0.12),
        )
        path.addCurve(
            to: CGPoint(x: width * 0.58, y: height * 0.76),
            control1: CGPoint(x: width * 1.00, y: height * 0.54),
            control2: CGPoint(x: width * 0.76, y: height * 0.66),
        )
        path.addQuadCurve(
            to: CGPoint(x: width * 0.42, y: height * 0.76),
            control: CGPoint(x: width * 0.50, y: height * 0.88),
        )
        path.closeSubpath()
        return path
    }
}

func mrSmilesRoundedPolygon(_ points: [CGPoint], cornerRadius: CGFloat) -> Path {
    var path = Path()
    guard points.count >= 3 else { return path }
    for index in 0..<points.count {
        let previous = points[(index + points.count - 1) % points.count]
        let current = points[index]
        let next = points[(index + 1) % points.count]
        let toPrevious = CGVector(dx: previous.x - current.x, dy: previous.y - current.y)
        let toNext = CGVector(dx: next.x - current.x, dy: next.y - current.y)
        let previousLength = hypot(toPrevious.dx, toPrevious.dy)
        let nextLength = hypot(toNext.dx, toNext.dy)
        let trim = min(cornerRadius, previousLength * 0.45, nextLength * 0.45)
        let start = CGPoint(
            x: current.x + toPrevious.dx / previousLength * trim,
            y: current.y + toPrevious.dy / previousLength * trim,
        )
        let end = CGPoint(
            x: current.x + toNext.dx / nextLength * trim,
            y: current.y + toNext.dy / nextLength * trim,
        )
        if index == 0 {
            path.move(to: start)
        } else {
            path.addLine(to: start)
        }
        path.addQuadCurve(to: end, control: current)
    }
    path.closeSubpath()
    return path
}

private struct MrSmilesMouth: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.275, y: rect.height * 0.575))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.725, y: rect.height * 0.575),
            control1: CGPoint(x: rect.width * 0.33, y: rect.height * 0.84),
            control2: CGPoint(x: rect.width * 0.67, y: rect.height * 0.84),
        )
        return path
    }
}

private struct MrSmilesWink: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.7))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.7),
            control: CGPoint(x: rect.midX, y: -rect.height * 0.25),
        )
        return path
    }
}
