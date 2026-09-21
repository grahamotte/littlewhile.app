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

    func testHeartAndStarEyesTiltInwardAndSitFartherApart() {
        XCTAssertGreaterThan(MrSmilesEyeMetrics.inwardRotation, 10)
        XCTAssertEqual(MrSmilesEyeMetrics.rotation(isLeft: true), -MrSmilesEyeMetrics.inwardRotation, accuracy: 0.0001)
        XCTAssertEqual(MrSmilesEyeMetrics.rotation(isLeft: false), MrSmilesEyeMetrics.inwardRotation, accuracy: 0.0001)
        XCTAssertLessThan(MrSmilesEyeMetrics.symbolX, MrSmilesEyeMetrics.openX)
        XCTAssertEqual(MrSmilesEyeMetrics.centerX(isLeft: true, symbol: true), MrSmilesEyeMetrics.symbolX, accuracy: 0.0001)
        XCTAssertEqual(MrSmilesEyeMetrics.centerX(isLeft: false, symbol: true), 1 - MrSmilesEyeMetrics.symbolX, accuracy: 0.0001)
        XCTAssertGreaterThan(
            MrSmilesEyeMetrics.centerX(isLeft: false, symbol: true) - MrSmilesEyeMetrics.centerX(isLeft: true, symbol: true),
            MrSmilesEyeMetrics.centerX(isLeft: false, symbol: false) - MrSmilesEyeMetrics.centerX(isLeft: true, symbol: false),
        )
    }

    func testHeartHasCircularLobesAndARightAnglePoint() {
        let path = MrSmilesHeart().path(in: rect).cgPath

        XCTAssertTrue(path.contains(CGPoint(x: 50, y: 50)))
        XCTAssertTrue(path.contains(CGPoint(x: 28, y: 32)))
        XCTAssertTrue(path.contains(CGPoint(x: 72, y: 32)))
        XCTAssertTrue(path.contains(CGPoint(x: 28, y: 18)))
        XCTAssertTrue(path.contains(CGPoint(x: 72, y: 18)))
        XCTAssertTrue(path.contains(CGPoint(x: 50, y: 92)))
        XCTAssertTrue(path.contains(CGPoint(x: 42, y: 78)))
        XCTAssertFalse(path.contains(CGPoint(x: 50, y: 4)))
        XCTAssertFalse(path.contains(CGPoint(x: 2, y: 2)))
        XCTAssertFalse(path.contains(CGPoint(x: 18, y: 78)))
        XCTAssertFalse(path.contains(CGPoint(x: 82, y: 78)))
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
