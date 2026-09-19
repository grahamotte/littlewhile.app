import Foundation
import UserNotifications

@MainActor
protocol CompletionNotificationCenter: AnyObject {
    var delegate: (any UNUserNotificationCenterDelegate)? { get set }

    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

@MainActor
private final class SystemCompletionNotificationCenter: CompletionNotificationCenter {
    private let center = UNUserNotificationCenter.current()

    var delegate: (any UNUserNotificationCenterDelegate)? {
        get { center.delegate }
        set { center.delegate = newValue }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

@MainActor
final class CompletionAlerts: NSObject, UNUserNotificationCenterDelegate {
    static let notificationIdentifier = "littlewhile.timer.complete"

    private let center: any CompletionNotificationCenter
    private let now: () -> Date
    private var latestRun: FocusRun?
    private var isEnabled = true
    private var generation = 0
    private var isSynchronizing = false
    private var shouldRequestPermission = false

    convenience override init() {
        self.init(center: SystemCompletionNotificationCenter())
    }

    init(center: any CompletionNotificationCenter, now: @escaping () -> Date = Date.init) {
        self.center = center
        self.now = now
        super.init()
        center.delegate = self
    }

    func synchronize(run: FocusRun, requestPermission: Bool = false, enabled: Bool = true) async {
        latestRun = run
        isEnabled = enabled
        generation += 1
        shouldRequestPermission = shouldRequestPermission || requestPermission
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])

        guard !isSynchronizing else { return }

        isSynchronizing = true
        defer { isSynchronizing = false }

        while let run = latestRun {
            let currentGeneration = generation
            await schedule(run: run, generation: currentGeneration)
            guard currentGeneration != generation else { return }
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    private func schedule(run: FocusRun, generation currentGeneration: Int) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationIdentifier])
        guard isEnabled, run.isRunning, run.remaining(at: now()) > 0 else { return }

        let status = await center.authorizationStatus()
        guard currentGeneration == generation else { return }

        let isAuthorized: Bool
        switch status {
        case .authorized, .provisional:
            shouldRequestPermission = false
            isAuthorized = true
#if os(iOS)
        case .ephemeral:
            shouldRequestPermission = false
            isAuthorized = true
#endif
        case .notDetermined where shouldRequestPermission:
            shouldRequestPermission = false
            isAuthorized = (try? await center.requestAuthorization()) == true
        default:
            shouldRequestPermission = false
            isAuthorized = false
        }

        guard currentGeneration == generation, isAuthorized else { return }

        let remaining = run.remaining(at: now())
        guard remaining > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time’s up"
        content.body = "A little while, well spent."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: Self.notificationIdentifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(1, remaining), repeats: false),
        )
        try? await center.add(request)
    }
}
