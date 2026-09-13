import XCTest
@testable import App

final class TimerSnapshotTests: XCTestCase {
    private let date = Date(timeIntervalSince1970: 10_000)

    func testReadyRunPresentsDurationAndStartControl() {
        let run = FocusRun(createdAt: date)
        let snapshot = TimerSnapshot(run: run, at: date)
        XCTAssertEqual(snapshot.runID, run.id)
        XCTAssertEqual(snapshot.goalSeconds, 1500)
        XCTAssertEqual(snapshot.elapsedSeconds, 0)
        XCTAssertEqual(snapshot.remainingSeconds, 1500)
        XCTAssertEqual(snapshot.progress, 0)
        XCTAssertEqual(snapshot.status, .ready)
        XCTAssertEqual(snapshot.clockText, "25:00")
        XCTAssertEqual(snapshot.controlSymbol, "play.fill")
        XCTAssertEqual(snapshot.controlLabel, "Start timer")
    }

    func testRunningSnapshotRoundsRemainingTimeUp() {
        let run = FocusRun(createdAt: date, startedAt: date, resumedAt: date)
        let snapshot = TimerSnapshot(run: run, at: date.addingTimeInterval(60.2))
        XCTAssertEqual(snapshot.status, .running)
        XCTAssertEqual(snapshot.clockText, "24:00")
        XCTAssertEqual(snapshot.elapsedSeconds, 60.2, accuracy: 0.001)
        XCTAssertEqual(snapshot.progress, 60.2 / 1500, accuracy: 0.001)
        XCTAssertEqual(snapshot.controlSymbol, "pause.fill")
        XCTAssertEqual(snapshot.controlLabel, "Pause timer")
    }

    func testPausedSnapshotDoesNotAdvance() {
        let run = FocusRun(createdAt: date, startedAt: date, progressSeconds: 70)
        let snapshot = TimerSnapshot(run: run, at: date.addingTimeInterval(900))
        XCTAssertEqual(snapshot.status, .paused)
        XCTAssertEqual(snapshot.clockText, "23:50")
        XCTAssertEqual(snapshot.controlSymbol, "play.fill")
        XCTAssertEqual(snapshot.controlLabel, "Resume timer")
    }

    func testCompletionWinsOverRunningUntilStoreRefreshes() {
        let run = FocusRun(createdAt: date, startedAt: date, resumedAt: date)
        let snapshot = TimerSnapshot(run: run, at: date.addingTimeInterval(1800))
        XCTAssertEqual(snapshot.status, .complete)
        XCTAssertEqual(snapshot.clockText, "00:00")
        XCTAssertEqual(snapshot.progress, 1)
        XCTAssertEqual(snapshot.controlSymbol, "arrow.counterclockwise")
        XCTAssertEqual(snapshot.controlLabel, "New run with the same settings")
    }

    func testLongDurationsKeepMinutesRatherThanSwitchingToHours() {
        let run = FocusRun(createdAt: date, goalSeconds: 7200)
        XCTAssertEqual(TimerSnapshot(run: run, at: date).clockText, "120:00")
    }
}
