import CoreGraphics
import Foundation

struct MrSmilesAnimation {
    private struct Layout: Equatable {
        let size: CGSize
        let faceRadius: CGFloat
        let screenCornerRadius: CGFloat
    }

    private enum Interaction {
        case stop
        case flick(CGVector)
        case move(CGPoint)
    }

    private struct InteractionEvent {
        let elapsed: TimeInterval
        let interaction: Interaction
    }

    private(set) var motion: MrSmilesMotion?
    private var runID: UUID?
    private var layout: Layout?
    private var latestSnapshot: TimerSnapshot?
    private var interactions: [InteractionEvent] = []
    private var appliedInteractionCount = 0

    mutating func update(
        snapshot incomingSnapshot: TimerSnapshot,
        at date: Date,
        size: CGSize,
        faceRadius: CGFloat,
        screenCornerRadius: CGFloat,
    ) {
        let snapshot: TimerSnapshot
        if let latestSnapshot, latestSnapshot.runID == incomingSnapshot.runID, latestSnapshot.sampledAt > incomingSnapshot.sampledAt {
            snapshot = latestSnapshot
        } else {
            snapshot = incomingSnapshot
        }
        let elapsed = activeElapsed(snapshot: snapshot, at: date)
        let layout = Layout(
            size: size,
            faceRadius: faceRadius,
            screenCornerRadius: screenCornerRadius,
        )

        if runID != snapshot.runID {
            interactions.removeAll()
        } else if snapshot.status != .running {
            interactions.removeAll { $0.elapsed > elapsed }
        }

        if runID != snapshot.runID || self.layout != layout || elapsed < (motion?.elapsed ?? 0) || motion == nil {
            motion = MrSmilesMotion(
                seed: snapshot.runID,
                size: size,
                faceRadius: faceRadius,
                screenCornerRadius: screenCornerRadius,
            )
            runID = snapshot.runID
            self.layout = layout
            appliedInteractionCount = 0
        }

        latestSnapshot = snapshot
        if var motion {
            while appliedInteractionCount < interactions.count && interactions[appliedInteractionCount].elapsed <= elapsed {
                let event = interactions[appliedInteractionCount]
                motion.advance(to: event.elapsed)
                apply(event.interaction, to: &motion)
                appliedInteractionCount += 1
            }
            motion.advance(to: elapsed)
            self.motion = motion
        }
    }

    @discardableResult
    mutating func flick(velocity: CGVector, snapshot: TimerSnapshot, at date: Date) -> Bool {
        interact(.flick(velocity), snapshot: snapshot, at: date)
    }

    @discardableResult
    mutating func stop(snapshot: TimerSnapshot, at date: Date) -> Bool {
        interact(.stop, snapshot: snapshot, at: date)
    }

    @discardableResult
    mutating func move(to position: CGPoint, snapshot: TimerSnapshot, at date: Date) -> Bool {
        interact(.move(position), snapshot: snapshot, at: date)
    }

    private mutating func interact(_ interaction: Interaction, snapshot: TimerSnapshot, at date: Date) -> Bool {
        guard snapshot.status == .running,
              runID == snapshot.runID,
              let latestSnapshot,
              latestSnapshot.status == .running,
              snapshot.sampledAt >= latestSnapshot.sampledAt,
              date.timeIntervalSinceReferenceDate.isFinite,
              activeElapsed(snapshot: snapshot, at: date) < TimeInterval(snapshot.totalSeconds),
              let layout else { return false }

        update(
            snapshot: snapshot,
            at: date,
            size: layout.size,
            faceRadius: layout.faceRadius,
            screenCornerRadius: layout.screenCornerRadius,
        )
        guard var motion, apply(interaction, to: &motion) else { return false }
        interactions.removeAll { $0.elapsed > motion.elapsed }
        interactions.append(InteractionEvent(elapsed: motion.elapsed, interaction: interaction))
        appliedInteractionCount = interactions.count
        self.motion = motion
        return true
    }

    @discardableResult
    private func apply(_ interaction: Interaction, to motion: inout MrSmilesMotion) -> Bool {
        switch interaction {
        case .stop:
            motion.stop()
            return true
        case let .flick(velocity):
            return motion.flick(velocity: velocity)
        case let .move(position):
            return motion.move(to: position)
        }
    }

    private func activeElapsed(snapshot: TimerSnapshot, at date: Date) -> TimeInterval {
        let interval = date.timeIntervalSince(snapshot.sampledAt)
        let additional = snapshot.status == .running && interval.isFinite ? max(0, interval) : 0
        return snapshot.status == .ready ? 0 : min(
            TimeInterval(max(0, snapshot.totalSeconds)),
            snapshot.elapsedSeconds + additional,
        )
    }
}
