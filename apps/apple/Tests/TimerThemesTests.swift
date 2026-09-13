import XCTest
@testable import App

@MainActor
final class TimerThemesTests: XCTestCase {
    func testRegistryContainsOnlyTheBoringThemeWithStableIdentity() async {
        XCTAssertEqual(TimerThemes.all.map(\.id), ["boring"])
        XCTAssertEqual(TimerThemes.resolve("boring").name, "Boring")
    }

    func testUnavailableThemeUsesBoringWithoutChangingSavedIdentifier() async {
        let run = FocusRun(theme: "future-theme")
        XCTAssertEqual(TimerThemes.resolve(run.theme).id, "boring")
        XCTAssertEqual(run.theme, "future-theme")
    }
}
