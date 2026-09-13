import XCTest
@testable import App

final class FocusRunTests: XCTestCase {
    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    func testNewRunIsReadyWithTwentyFiveMinuteGoal() {
        let run = FocusRun(createdAt: date)

        XCTAssertEqual(run.createdAt, date)
        XCTAssertEqual(run.goalSeconds, 1_500)
        XCTAssertEqual(run.theme, "boring")
        XCTAssertEqual(run.elapsed(at: date), 0)
        XCTAssertEqual(run.remaining(at: date), 1_500)
        XCTAssertEqual(run.fraction(at: date), 0)
        XCTAssertFalse(run.hasStarted)
        XCTAssertFalse(run.isRunning)
        XCTAssertFalse(run.isComplete(at: date))
    }

    func testRunningAddsFractionalTimeToSavedProgress() {
        let run = FocusRun(createdAt: date, startedAt: date, progressSeconds: 12.25, resumedAt: date)
        let later = date.addingTimeInterval(5.5)

        XCTAssertEqual(run.elapsed(at: later), 17.75)
        XCTAssertEqual(run.remaining(at: later), 1_482.25)
        XCTAssertEqual(run.fraction(at: later), 17.75 / 1_500)
        XCTAssertTrue(run.hasStarted)
        XCTAssertTrue(run.isRunning)
    }

    func testPausedRunKeepsSavedProgressAsTimePasses() {
        let run = FocusRun(createdAt: date, startedAt: date, progressSeconds: 300)

        XCTAssertEqual(run.elapsed(at: date.addingTimeInterval(100_000)), 300)
        XCTAssertEqual(run.remaining(at: date), 1_200)
        XCTAssertEqual(run.fraction(at: date), 0.2)
        XCTAssertTrue(run.hasStarted)
        XCTAssertFalse(run.isRunning)
    }

    func testCompletionClampsToGoalAtAndBeyondDeadline() {
        let run = FocusRun(createdAt: date, startedAt: date, goalSeconds: 60, resumedAt: date)

        XCTAssertFalse(run.isComplete(at: date.addingTimeInterval(59.999)))
        XCTAssertTrue(run.isComplete(at: date.addingTimeInterval(60)))
        XCTAssertEqual(run.elapsed(at: date.addingTimeInterval(1_000)), 60)
        XCTAssertEqual(run.remaining(at: date.addingTimeInterval(1_000)), 0)
        XCTAssertEqual(run.fraction(at: date.addingTimeInterval(1_000)), 1)
    }

    func testClockMovingBackwardsDoesNotSubtractProgress() {
        let run = FocusRun(createdAt: date, startedAt: date, progressSeconds: 30.75, resumedAt: date)

        XCTAssertEqual(run.elapsed(at: date.addingTimeInterval(-100)), 30.75)
    }

    func testNegativeProgressCannotProduceNegativeElapsedTime() {
        let run = FocusRun(createdAt: date, progressSeconds: -100)

        XCTAssertEqual(run.elapsed(at: date), 0)
        XCTAssertEqual(run.remaining(at: date), 1_500)
        XCTAssertEqual(run.fraction(at: date), 0)
    }

    func testExcessiveSavedProgressCannotExceedGoal() {
        let run = FocusRun(createdAt: date, progressSeconds: 5_000, goalSeconds: 60)

        XCTAssertEqual(run.elapsed(at: date), 60)
        XCTAssertEqual(run.remaining(at: date), 0)
        XCTAssertEqual(run.fraction(at: date), 1)
        XCTAssertTrue(run.isComplete(at: date))
    }

    func testInvalidProgressIsTreatedAsZero() {
        for progress in [TimeInterval.nan, .infinity, -.infinity] {
            let run = FocusRun(createdAt: date, progressSeconds: progress)

            XCTAssertEqual(run.elapsed(at: date), 0)
            XCTAssertEqual(run.fraction(at: date), 0)
        }
    }

    func testInvalidClockIntervalDoesNotDamageSavedProgress() {
        let run = FocusRun(createdAt: date, progressSeconds: 20, resumedAt: date)

        XCTAssertEqual(run.elapsed(at: Date(timeIntervalSinceReferenceDate: .infinity)), 20)
    }

    func testInvalidGoalsRemainSafeForRendering() {
        for goal in [0, -60] {
            let run = FocusRun(createdAt: date, goalSeconds: goal)

            XCTAssertEqual(run.elapsed(at: date), 0)
            XCTAssertEqual(run.remaining(at: date), 0)
            XCTAssertEqual(run.fraction(at: date), 1)
            XCTAssertTrue(run.isComplete(at: date))
        }
    }

    func testRunRoundTripsAllFieldsIncludingFractionalProgressAndTheme() throws {
        let run = FocusRun(
            createdAt: date,
            startedAt: date.addingTimeInterval(30),
            progressSeconds: 24.125,
            goalSeconds: 900,
            theme: "future-theme",
            resumedAt: date.addingTimeInterval(100),
        )

        let decoded = try JSONDecoder().decode(FocusRun.self, from: JSONEncoder().encode(run))

        XCTAssertEqual(decoded, run)
    }

    func testReadyRunRoundTripsOptionalTimestamps() throws {
        let run = FocusRun(createdAt: date)

        let decoded = try JSONDecoder().decode(FocusRun.self, from: JSONEncoder().encode(run))

        XCTAssertEqual(decoded, run)
        XCTAssertNil(decoded.startedAt)
        XCTAssertNil(decoded.resumedAt)
    }
}
