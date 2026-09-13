import Foundation
import Observation

@MainActor
@Observable
final class RunStore {
    private(set) var runs: [FocusRun]
    private let defaults: UserDefaults
    private static let storageKey = "littlewhile.runs.v1"

    var currentRun: FocusRun {
        runs[0]
    }

    var history: [FocusRun] {
        Array(runs.dropFirst())
    }

    init(defaults: UserDefaults = .standard, now: Date = .now) {
        self.defaults = defaults
        var restored: [FocusRun] = []
        var identifiers = Set<UUID>()
        if let data = defaults.data(forKey: Self.storageKey),
           let records = try? JSONDecoder().decode([StoredRun].self, from: data) {
            for record in records {
                guard var run = record.run, identifiers.insert(run.id).inserted else { continue }
                run.goalSeconds = min(120 * 60, max(60, run.goalSeconds))
                run.progressSeconds = run.progressSeconds.isFinite
                    ? min(TimeInterval(run.goalSeconds), max(0, run.progressSeconds))
                    : 0
                if run.theme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    run.theme = "standard"
                }
                if !run.createdAt.timeIntervalSinceReferenceDate.isFinite {
                    run.createdAt = now
                }
                if let startedAt = run.startedAt, !startedAt.timeIntervalSinceReferenceDate.isFinite {
                    run.startedAt = nil
                }
                if let resumedAt = run.resumedAt, !resumedAt.timeIntervalSinceReferenceDate.isFinite {
                    run.resumedAt = nil
                }
                if let resumedAt = run.resumedAt, resumedAt > now {
                    run.resumedAt = now
                }
                if run.startedAt == nil, run.progressSeconds > 0 || run.isRunning {
                    run.startedAt = run.createdAt
                }
                if let newerRun = restored.last, run.isRunning {
                    run.progressSeconds = run.elapsed(at: min(now, newerRun.createdAt))
                    run.resumedAt = nil
                }
                restored.append(run)
            }
        }
        runs = restored.isEmpty ? [FocusRun(createdAt: now)] : restored
        refresh(at: now)
    }

    func start(at date: Date = .now) {
        guard !currentRun.isRunning, !currentRun.isComplete(at: date) else {
            refresh(at: date)
            return
        }
        if runs[0].startedAt == nil {
            runs[0].startedAt = date
        }
        runs[0].resumedAt = date
        save()
    }

    func pause(at date: Date = .now) {
        runs[0].progressSeconds = currentRun.elapsed(at: date)
        runs[0].resumedAt = nil
        save()
    }

    func toggle(at date: Date = .now) {
        if currentRun.isRunning {
            pause(at: date)
        } else {
            start(at: date)
        }
    }

    func refresh(at date: Date = .now) {
        if currentRun.isComplete(at: date) {
            runs[0].progressSeconds = TimeInterval(currentRun.goalSeconds)
            runs[0].resumedAt = nil
        } else if let resumedAt = currentRun.resumedAt, date >= resumedAt {
            runs[0].progressSeconds = currentRun.elapsed(at: date)
            runs[0].resumedAt = date
        }
        save()
    }

    func createRun(minutes: Int, theme: String, at date: Date = .now) {
        pause(at: date)
        let selectedTheme = theme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "standard" : theme
        runs.insert(
            FocusRun(createdAt: date, goalSeconds: min(120, max(1, minutes)) * 60, theme: selectedTheme),
            at: 0,
        )
        save()
    }

    func restart(at date: Date = .now) {
        let previous = currentRun
        pause(at: date)
        runs.insert(FocusRun(createdAt: date, goalSeconds: previous.goalSeconds, theme: previous.theme), at: 0)
        save()
    }

    func deleteRun(id: UUID) {
        guard id != currentRun.id else {
            save()
            return
        }
        runs.removeAll { $0.id == id }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(runs) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    private struct StoredRun: Decodable {
        let run: FocusRun?

        init(from decoder: Decoder) throws {
            run = try? FocusRun(from: decoder)
        }
    }
}
