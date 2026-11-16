import XCTest
import SwiftUI
@testable import ZoomSlider

final class ZoomMathTests: XCTestCase {
    private let bounds = 2000...16000
    private let step = 250

    // MARK: Values <-> progress

    func testTickCountIsOnePerStep() {
        XCTAssertEqual(ZoomMath.tickCount(bounds: bounds, step: step), 57)
        XCTAssertEqual(ZoomMath.tickCount(bounds: 0...100, step: 1), 101)
        XCTAssertEqual(ZoomMath.tickCount(bounds: 5...5, step: 1), 1)
    }

    func testProgressRunsFromZeroToOne() {
        XCTAssertEqual(ZoomMath.progress(of: 2000, bounds: bounds, step: step), 0, accuracy: 1e-9)
        XCTAssertEqual(ZoomMath.progress(of: 16000, bounds: bounds, step: step), 1, accuracy: 1e-9)
        XCTAssertEqual(ZoomMath.progress(of: 9000, bounds: bounds, step: step), 0.5, accuracy: 1e-9)
        XCTAssertEqual(ZoomMath.progress(of: 99_999, bounds: bounds, step: step), 1, accuracy: 1e-9)   // clamps
    }

    func testValueAtProgressSnapsToTheNearestTick() {
        XCTAssertEqual(ZoomMath.value(atProgress: 0, bounds: bounds, step: step), 2000)
        XCTAssertEqual(ZoomMath.value(atProgress: 1, bounds: bounds, step: step), 16000)
        XCTAssertEqual(ZoomMath.value(atProgress: -3, bounds: bounds, step: step), 2000)
        XCTAssertEqual(ZoomMath.value(atProgress: 7, bounds: bounds, step: step), 16000)
        // A hair past a tick still snaps to it.
        let p = ZoomMath.progress(of: 8250, bounds: bounds, step: step)
        XCTAssertEqual(ZoomMath.value(atProgress: p + 0.004, bounds: bounds, step: step), 8250)
    }

    func testEveryTickRoundTrips() {
        for v in stride(from: 2000, through: 16000, by: 250) {
            let p = ZoomMath.progress(of: v, bounds: bounds, step: step)
            XCTAssertEqual(ZoomMath.value(atProgress: p, bounds: bounds, step: step), v)
        }
    }

    func testSnapRoundsAndClamps() {
        XCTAssertEqual(ZoomMath.snap(8_100, bounds: bounds, step: step), 8_000)
        XCTAssertEqual(ZoomMath.snap(8_130, bounds: bounds, step: step), 8_250)
        XCTAssertEqual(ZoomMath.snap(-50, bounds: bounds, step: step), 2_000)
        XCTAssertEqual(ZoomMath.snap(99_999, bounds: bounds, step: step), 16_000)
    }

    func testMajorTicksFallEveryNthStep() {
        let majors = (0..<ZoomMath.tickCount(bounds: bounds, step: step)).filter { ZoomMath.isMajor(index: $0, every: 4) }
        XCTAssertEqual(majors.first, 0)
        XCTAssertEqual(majors.count, 15)                       // every 1,000 from 2,000 to 16,000
        XCTAssertTrue(majors.allSatisfy { (2000 + $0 * 250) % 1000 == 0 })
        XCTAssertTrue(ZoomMath.isMajor(index: 3, every: 0))   // a bad `every` can't divide by zero
    }

    // MARK: Positions

    func testFingerReachesBothEndsOfTheRuler() {
        let width: CGFloat = 300
        XCTAssertEqual(ZoomMath.fingerX(progress: 0, width: width), 1)
        XCTAssertEqual(ZoomMath.fingerX(progress: 1, width: width), width - 1)
        XCTAssertEqual(ZoomMath.progress(atX: 1, width: width), 0, accuracy: 1e-9)
        XCTAssertEqual(ZoomMath.progress(atX: width - 1, width: width), 1, accuracy: 1e-9)
        // ...and dragging past the ends stays pinned to them.
        XCTAssertEqual(ZoomMath.progress(atX: -400, width: width), 0)
        XCTAssertEqual(ZoomMath.progress(atX: 4_000, width: width), 1)
    }

    func testPositionAndProgressRoundTrip() {
        let width: CGFloat = 300
        for p in stride(from: 0.0, through: 1.0, by: 0.1) {
            let x = ZoomMath.fingerX(progress: CGFloat(p), width: width)
            XCTAssertEqual(ZoomMath.progress(atX: x, width: width), CGFloat(p), accuracy: 1e-9)
        }
    }

    func testIdlePillStaysInsideTheRulerButTheBubbleMayOverhang() {
        let width: CGFloat = 300
        let pillHalf = ZoomMetrics.pillWidth / 2
        let bubbleHalf = ZoomMetrics.bubbleWidth / 2

        // Idle (z = 0): clamped so the pill never leaves the ruler.
        XCTAssertEqual(ZoomMath.thumbCenter(fingerX: 1, width: width, z: 0), pillHalf)
        XCTAssertEqual(ZoomMath.thumbCenter(fingerX: width - 1, width: width, z: 0), width - pillHalf)
        XCTAssertEqual(ZoomMath.pillCenter(fingerX: width - 1, width: width), width - pillHalf)

        // Pressed (z = 1): the bubble hangs `bubbleOverhang` past each end.
        let left = ZoomMath.thumbCenter(fingerX: 1, width: width, z: 1)
        let right = ZoomMath.thumbCenter(fingerX: width - 1, width: width, z: 1)
        XCTAssertEqual(left - bubbleHalf, -ZoomMetrics.bubbleOverhang, accuracy: 1e-9)
        XCTAssertEqual(right + bubbleHalf, width + ZoomMetrics.bubbleOverhang, accuracy: 1e-9)

        // In the middle the thumb is right under the finger.
        XCTAssertEqual(ZoomMath.thumbCenter(fingerX: 150, width: width, z: 1), 150)
    }

    func testGrabbingThePillNeverJumpsTheValue() {
        let width: CGFloat = 300
        // Pill parked at the right end: its centre is 27 pt in from the end, the finger x is the last tick.
        let fingerX = ZoomMath.fingerX(progress: 1, width: width)
        let pill = ZoomMath.pillCenter(fingerX: fingerX, width: width)

        for start in [pill - 25, pill, pill + 25] {
            let offset = ZoomMath.grabOffset(startX: start, fingerX: fingerX, width: width)
            XCTAssertEqual(ZoomMath.progress(atX: start + offset, width: width), 1, accuracy: 1e-9)
        }
        // A touch far from the pill is absolute: the thumb goes to the finger.
        XCTAssertEqual(ZoomMath.grabOffset(startX: 40, fingerX: fingerX, width: width), 0)
    }

    // MARK: Zoom lens

    func testLensLeavesTicksOutsideItUntouched() {
        let r = ZoomMath.lens(x: 250, center: 100, radius: 58, spread: 0.75)
        XCTAssertEqual(r.x, 250)
        XCTAssertGreaterThanOrEqual(r.s, 1)
        // ...and when the lens is closed (spread 0) nothing moves anywhere.
        for x in stride(from: 90.0, through: 110.0, by: 2.5) {
            XCTAssertEqual(ZoomMath.lens(x: CGFloat(x), center: 100, radius: 1, spread: 0).x, CGFloat(x), accuracy: 1e-9)
        }
    }

    func testLensIsContinuousAtItsEdge() {
        let radius: CGFloat = 58
        for side: CGFloat in [-1, 1] {
            let inside = ZoomMath.lens(x: 100 + side * (radius - 0.001), center: 100, radius: radius, spread: 0.75).x
            XCTAssertEqual(inside, 100 + side * (radius - 0.001), accuracy: 0.01)
        }
    }

    func testLensSpreadsTicksAtTheCentreAndKeepsThemOrdered() {
        let spread: CGFloat = 0.75
        let a = ZoomMath.lens(x: 100, center: 100, radius: 58, spread: spread).x
        let b = ZoomMath.lens(x: 105, center: 100, radius: 58, spread: spread).x
        XCTAssertEqual(a, 100, accuracy: 1e-9)
        XCTAssertGreaterThan(b - a, 5 * 1.6)                    // ~1.75x at the finger

        var previous = -CGFloat.infinity
        for x in stride(from: 20.0, through: 180.0, by: 1.0) {
            let moved = ZoomMath.lens(x: CGFloat(x), center: 100, radius: 58, spread: spread).x
            XCTAssertGreaterThan(moved, previous, "ticks must never cross")
            previous = moved
        }
    }

    func testLensIsSymmetric() {
        let l = ZoomMath.lens(x: 70, center: 100, radius: 58, spread: 0.75).x
        let r = ZoomMath.lens(x: 130, center: 100, radius: 58, spread: 0.75).x
        XCTAssertEqual(100 - l, r - 100, accuracy: 1e-9)
    }

    func testLensWeightAndFringe() {
        XCTAssertEqual(ZoomMath.lensWeight(s: 0, z: 1), 1, accuracy: 1e-9)
        XCTAssertEqual(ZoomMath.lensWeight(s: 1, z: 1), 0)
        XCTAssertEqual(ZoomMath.lensWeight(s: 0, z: 0), 0)                        // idle: no zoom at all
        XCTAssertGreaterThan(ZoomMath.lensWeight(s: 0.3, z: 1), ZoomMath.lensWeight(s: 0.8, z: 1))

        XCTAssertEqual(ZoomMath.fringe(s: 1, z: 1), 1, accuracy: 1e-9)
        XCTAssertEqual(ZoomMath.fringe(s: 0.5, z: 1), 0)
        XCTAssertEqual(ZoomMath.fringe(s: 1, z: 0), 0)
    }

    // MARK: Springs

    func testStiffnessGrowsAsResponseShrinks() {
        XCTAssertGreaterThan(ZoomMath.stiffness(response: 0.14), ZoomMath.stiffness(response: 0.34))
        XCTAssertEqual(ZoomMath.stiffness(response: 1), 4 * Double.pi * Double.pi, accuracy: 1e-9)
    }

    func testTimingDefaults() {
        XCTAssertEqual(ZoomTiming.default, ZoomTiming(open: 0.34, close: 0.32, follow: 0.14))
    }

    // MARK: Labels

    func testCompactLabel() {
        XCTAssertEqual(ZoomLabels.compact(8000), "8k")
        XCTAssertEqual(ZoomLabels.compact(8250), "8.25k")
        XCTAssertEqual(ZoomLabels.compact(13500), "13.5k")
        XCTAssertEqual(ZoomLabels.compact(3750), "3.75k")
        XCTAssertEqual(ZoomLabels.compact(16000), "16k")
        XCTAssertEqual(ZoomLabels.compact(1005), "1.005k")
        XCTAssertEqual(ZoomLabels.compact(-2500), "-2.5k")
        XCTAssertEqual(ZoomLabels.compact(750), "750")
        XCTAssertEqual(ZoomLabels.compact(0), "0")
    }

    func testGroupedLabel() {
        XCTAssertEqual(ZoomLabels.grouped(8250), "8,250")
        XCTAssertEqual(ZoomLabels.grouped(16000), "16,000")
        XCTAssertEqual(ZoomLabels.grouped(250), "250")
        XCTAssertEqual(ZoomLabels.grouped(1_234_567), "1,234,567")
        XCTAssertEqual(ZoomLabels.grouped(-1500), "-1,500")
        XCTAssertEqual(ZoomLabels.grouped(0), "0")
    }

    // MARK: Style

    func testPresetStylesDiffer() {
        XCTAssertNotEqual(ZoomSliderStyle.ink, ZoomSliderStyle.paper)
        XCTAssertNotEqual(ZoomSliderStyle.accent(.blue), ZoomSliderStyle.accent(.green))
        XCTAssertEqual(ZoomSliderStyle.accent(.blue), ZoomSliderStyle.accent(.blue))
    }
}
