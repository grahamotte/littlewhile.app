import Foundation
import Observation

@MainActor
@Observable
final class TimerCompanion {
    var alarmIssue: String?
    private let alarms: TimerAlarm
    private let liveActivity: TimerLiveActivity
    private let notifications: CompletionAlerts
    private var generation = 0

    convenience init() {
        self.init(alarms: TimerAlarm(), liveActivity: TimerLiveActivity(), notifications: CompletionAlerts())
    }

    init(alarms: TimerAlarm, liveActivity: TimerLiveActivity, notifications: CompletionAlerts) {
        self.alarms = alarms
        self.liveActivity = liveActivity
        self.notifications = notifications
    }

    func synchronize(run: FocusRun, userInitiated: Bool = false) async {
        generation += 1
        let currentGeneration = generation
        if !run.isRunning { alarmIssue = nil }
        await notifications.synchronize(run: run, enabled: false)
        async let alarmCoverage = alarms.synchronize(run: run, requestPermission: userInitiated)
        await liveActivity.synchronize(run: run, userInitiated: userInitiated)
        let coverage = await alarmCoverage
        guard currentGeneration == generation else { return }
        if userInitiated, coverage == .uncertain, run.isRunning {
            alarmIssue = "Your timer is running, but iOS couldn’t confirm its alarm. Try pausing and resuming the timer."
        }

        await notifications.synchronize(
            run: run,
            requestPermission: userInitiated && coverage == .unavailable,
            enabled: coverage == .unavailable,
        )
    }

    func complete(run: FocusRun) async {
        await liveActivity.synchronize(run: run)
    }
}
