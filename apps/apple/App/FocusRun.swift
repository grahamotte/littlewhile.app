import Foundation

struct FocusRun: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var createdAt: Date = .now
    var startedAt: Date?
    var progressSeconds: TimeInterval = 0
    var goalSeconds: Int = 25 * 60
    var theme: String = "standard"
    var resumedAt: Date?

    var isRunning: Bool {
        resumedAt != nil
    }

    var hasStarted: Bool {
        startedAt != nil
    }

    func elapsed(at date: Date) -> TimeInterval {
        let goal = TimeInterval(max(0, goalSeconds))
        let progress = progressSeconds.isFinite ? min(goal, max(0, progressSeconds)) : 0
        let interval = resumedAt.map { date.timeIntervalSince($0) } ?? 0
        let additional = interval.isFinite ? max(0, interval) : 0
        return min(goal, progress + additional)
    }

    func remaining(at date: Date) -> TimeInterval {
        max(0, TimeInterval(goalSeconds) - elapsed(at: date))
    }

    func fraction(at date: Date) -> Double {
        guard goalSeconds > 0 else { return 1 }
        return elapsed(at: date) / TimeInterval(goalSeconds)
    }

    func isComplete(at date: Date) -> Bool {
        elapsed(at: date) >= TimeInterval(goalSeconds)
    }
}
