import Foundation

enum TimerAlarmCoverage: Equatable, Sendable {
    case scheduled
    case unavailable
    case uncertain
}

enum TimerAlarmAuthorization {
    case notDetermined
    case denied
    case authorized
}

struct TimerAlarmRecord {
    enum State {
        case scheduled
        case alerting
        case other
    }

    let id: UUID
    let deadline: Date?
    let state: State
}

@MainActor
protocol TimerAlarmManager: AnyObject {
    var authorizationState: TimerAlarmAuthorization { get }

    func requestAuthorization() async throws -> TimerAlarmAuthorization
    func alarms() throws -> [TimerAlarmRecord]
    func schedule(id: UUID, deadline: Date) async throws
    func cancel(id: UUID) throws
}

@MainActor
final class TimerAlarm {
    private let manager: (any TimerAlarmManager)?
    private let now: () -> Date
    private var latestRun: FocusRun?
    private var generation = 0
    private var isSynchronizing = false
    private var shouldRequestPermission = false
    private var waiters: [(generation: Int, continuation: CheckedContinuation<TimerAlarmCoverage, Never>)] = []

    convenience init() {
#if os(iOS) && !targetEnvironment(macCatalyst) && canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            self.init(manager: SystemTimerAlarmManager())
            return
        }
#endif
        self.init(manager: nil)
    }

    init(manager: (any TimerAlarmManager)?, now: @escaping () -> Date = Date.init) {
        self.manager = manager
        self.now = now
    }

    func synchronize(run: FocusRun, requestPermission: Bool = false) async -> TimerAlarmCoverage {
        latestRun = run
        generation += 1
        let requestedGeneration = generation
        shouldRequestPermission = shouldRequestPermission || requestPermission

        if isSynchronizing {
            return await withCheckedContinuation { continuation in
                waiters.append((requestedGeneration, continuation))
            }
        }

        isSynchronizing = true
        while let currentRun = latestRun {
            let currentGeneration = generation
            let covered = await reconcile(run: currentRun, generation: currentGeneration)
            guard currentGeneration == generation else { continue }

            isSynchronizing = false
            let finishedWaiters = waiters
            waiters.removeAll()
            for waiter in finishedWaiters {
                waiter.continuation.resume(returning: waiter.generation == currentGeneration ? covered : .unavailable)
            }
            return requestedGeneration == currentGeneration ? covered : .unavailable
        }

        isSynchronizing = false
        return .unavailable
    }

    private func reconcile(run: FocusRun, generation currentGeneration: Int) async -> TimerAlarmCoverage {
        guard let manager else { return .unavailable }

        var authorization = manager.authorizationState
        if run.isRunning, !run.isComplete(at: now()),
           authorization == .notDetermined, shouldRequestPermission {
            shouldRequestPermission = false
            authorization = (try? await manager.requestAuthorization()) ?? manager.authorizationState
        }
        guard currentGeneration == generation else { return .unavailable }
        shouldRequestPermission = false
        guard authorization != .denied else { return .unavailable }
        guard let alarms = try? manager.alarms() else { return .uncertain }

        var cancellationFailed = false
        for alarm in alarms where alarm.id != run.id {
            do {
                try manager.cancel(id: alarm.id)
            } catch {
                cancellationFailed = true
            }
        }
        guard !cancellationFailed else { return .uncertain }

        let existing = alarms.first { $0.id == run.id }
        let date = now()
        if run.isComplete(at: date) {
            if let existing {
                if existing.state == .alerting {
                    return .scheduled
                }
                if existing.state == .scheduled, let deadline = existing.deadline, deadline <= date {
                    return .scheduled
                }
                do {
                    try manager.cancel(id: existing.id)
                } catch {
                    return .uncertain
                }
            }
            return .unavailable
        }

        guard run.isRunning else {
            if let existing {
                do {
                    try manager.cancel(id: existing.id)
                } catch {
                    return .uncertain
                }
            }
            return .unavailable
        }

        if existing?.state == .alerting {
            return .scheduled
        }

        guard authorization == .authorized else { return existing == nil ? .unavailable : .uncertain }

        let scheduleDate = now()
        let remaining = run.remaining(at: scheduleDate)
        guard remaining > 0 else { return .unavailable }
        let deadline = scheduleDate.addingTimeInterval(remaining)

        if let existing, existing.state == .scheduled,
           let existingDeadline = existing.deadline,
           abs(existingDeadline.timeIntervalSince(deadline)) < 0.5 {
            return .scheduled
        }

        if let existing {
            do {
                try manager.cancel(id: existing.id)
            } catch {
                return .uncertain
            }
        }

        do {
            try await manager.schedule(id: run.id, deadline: deadline)
            return .scheduled
        } catch {
            guard let remainingAlarms = try? manager.alarms() else { return .uncertain }
            if remainingAlarms.isEmpty {
                return .unavailable
            }
            if remainingAlarms.count == 1, let alarm = remainingAlarms.first, alarm.id == run.id {
                if alarm.state == .alerting {
                    return .scheduled
                }
                if alarm.state == .scheduled, let recordedDeadline = alarm.deadline,
                   abs(recordedDeadline.timeIntervalSince(deadline)) < 0.5 {
                    return .scheduled
                }
            }
            return .uncertain
        }
    }
}

#if os(iOS) && !targetEnvironment(macCatalyst) && canImport(AlarmKit)
import AlarmKit
import SwiftUI

@available(iOS 26.0, *)
nonisolated private struct FocusAlarmMetadata: AlarmMetadata {
    let runID: UUID
}

@available(iOS 26.0, *)
@MainActor
private final class SystemTimerAlarmManager: TimerAlarmManager {
    private let manager = AlarmManager.shared

    var authorizationState: TimerAlarmAuthorization {
        authorization(manager.authorizationState)
    }

    func requestAuthorization() async throws -> TimerAlarmAuthorization {
        authorization(try await manager.requestAuthorization())
    }

    func alarms() throws -> [TimerAlarmRecord] {
        try manager.alarms.map { alarm in
            let deadline: Date?
            if let schedule = alarm.schedule, case let .fixed(date) = schedule {
                deadline = date
            } else {
                deadline = nil
            }
            let state: TimerAlarmRecord.State
            switch alarm.state {
            case .scheduled: state = .scheduled
            case .alerting: state = .alerting
            default: state = .other
            }
            return TimerAlarmRecord(id: alarm.id, deadline: deadline, state: state)
        }
    }

    func schedule(id: UUID, deadline: Date) async throws {
        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alert = AlarmPresentation.Alert(title: "Your little while is complete")
        } else {
            alert = AlarmPresentation.Alert(
                title: "Your little while is complete",
                stopButton: AlarmButton(text: "Done", textColor: .white, systemImageName: "checkmark"),
            )
        }
        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(alert: alert),
            metadata: FocusAlarmMetadata(runID: id),
            tintColor: Color(red: 0.76, green: 0.42, blue: 0.28),
        )
        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(deadline),
            attributes: attributes,
            stopIntent: StopTimerAlarmIntent(runID: id),
            sound: .default,
        )
        _ = try await manager.schedule(id: id, configuration: configuration)
    }

    func cancel(id: UUID) throws {
        try manager.cancel(id: id)
    }

    private func authorization(_ state: AlarmManager.AuthorizationState) -> TimerAlarmAuthorization {
        switch state {
        case .authorized: .authorized
        case .notDetermined: .notDetermined
        default: .denied
        }
    }
}
#endif
