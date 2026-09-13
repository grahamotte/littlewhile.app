import XCTest
@testable import App

@MainActor
final class TimerThemesTests: XCTestCase {
    func testRegistryContainsOnlyTheStandardThemeWithStableIdentity() async {
        XCTAssertEqual(TimerThemes.all.map(\.id), ["standard"])
        XCTAssertEqual(TimerThemes.resolve("standard").name, "Standard")
    }

    func testUnavailableThemeUsesStandardWithoutChangingSavedIdentifier() async {
        let run = FocusRun(theme: "future-theme")
        XCTAssertEqual(TimerThemes.resolve(run.theme).id, "standard")
        XCTAssertEqual(run.theme, "future-theme")
    }
}
