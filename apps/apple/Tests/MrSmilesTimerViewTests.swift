import CoreGraphics
import XCTest
@testable import App

final class MrSmilesTimerViewTests: XCTestCase {
    private let rect = CGRect(x: 0, y: 0, width: 100, height: 100)

    func testHeartAndStarEyesAreMuchLargerThanTheOpenEye() {
        XCTAssertGreaterThan(MrSmilesEyeMetrics.heartWidth, 0.21)
        XCTAssertGreaterThan(MrSmilesEyeMetrics.heartHeight, 0.21)
        XCTAssertGreaterThan(MrSmilesEyeMetrics.starSize, 0.21)
        XCTAssertEqual(MrSmilesEyeMetrics.heartWidth, MrSmilesEyeMetrics.starSize, accuracy: 0.0001)
    }

    func testHeartHasRoundLobesAndAWideBottom() {
        let path = MrSmilesHeart().path(in: rect).cgPath

        XCTAssertTrue(path.contains(CGPoint(x: 50, y: 50)))
        XCTAssertTrue(path.contains(CGPoint(x: 28, y: 32)))
        XCTAssertTrue(path.contains(CGPoint(x: 72, y: 32)))
        XCTAssertTrue(path.contains(CGPoint(x: 50, y: 78)))
        XCTAssertTrue(path.contains(CGPoint(x: 44, y: 76)))
        XCTAssertTrue(path.contains(CGPoint(x: 56, y: 76)))
        XCTAssertFalse(path.contains(CGPoint(x: 50, y: 96)))
        XCTAssertFalse(path.contains(CGPoint(x: 8, y: 8)))
    }

    func testStarHasChubbyRoundedPoints() {
        let path = MrSmilesStar().path(in: rect).cgPath

        XCTAssertTrue(path.contains(CGPoint(x: 50, y: 50)))
        XCTAssertTrue(path.contains(CGPoint(x: 50, y: 22)))
        XCTAssertTrue(path.contains(CGPoint(x: 56, y: 22)))
        XCTAssertFalse(path.contains(CGPoint(x: 50, y: 1)))
        XCTAssertFalse(path.contains(CGPoint(x: 50, y: 99)))
        XCTAssertFalse(path.contains(CGPoint(x: 1, y: 50)))
        XCTAssertFalse(path.contains(CGPoint(x: 99, y: 50)))
    }

    func testRoundedPolygonCutsSharpCorners() {
        let square = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 100, y: 0),
            CGPoint(x: 100, y: 100),
            CGPoint(x: 0, y: 100),
        ]
        let path = mrSmilesRoundedPolygon(square, cornerRadius: 20).cgPath

        XCTAssertTrue(path.contains(CGPoint(x: 50, y: 50)))
        XCTAssertFalse(path.contains(CGPoint(x: 1, y: 1)))
        XCTAssertTrue(path.contains(CGPoint(x: 20, y: 8)))
    }
}
