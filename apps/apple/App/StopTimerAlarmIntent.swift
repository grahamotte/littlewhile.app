#if os(iOS)
import AppIntents

@available(iOS 26.0, *)
nonisolated struct StopTimerAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource { "Stop focus alarm" }

    @Parameter(title: "Run")
    var runIdentifier: String

    init() {
        runIdentifier = ""
    }

    init(runID: UUID) {
        runIdentifier = runID.uuidString
    }

    func perform() async throws -> some IntentResult {
        if let runID = UUID(uuidString: runIdentifier) {
            await TimerLiveActivity().finish(runID: runID)
        }
        return .result()
    }
}
#endif
