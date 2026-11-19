import XCTest
import SwiftUI
@testable import ZoomSlider

final class ZoomDecimalScaleTests: XCTestCase {
    func testDecimalEndpointIsNotLostToBinaryRounding() {
        let scale = ZoomDecimalScale(bounds: 0...0.3, step: 0.1)
        XCTAssertEqual(scale.lastIndex, 3)
        XCTAssertEqual(scale.value(at: 3), 0.3)
    }

    func testWeightTicksRoundTrip() {
        let scale = ZoomDecimalScale(bounds: 0.01...10, step: 0.01)
        XCTAssertEqual(scale.value(at: scale.index(of: 1.98)), 1.98)
        for index in 0...scale.lastIndex {
            XCTAssertEqual(scale.index(of: scale.value(at: index)), index)
        }
    }

    func testStepsAreAnchoredAtLowerBound() {
        let scale = ZoomDecimalScale(bounds: -0.35...0.35, step: 0.1)
        XCTAssertEqual(scale.lastIndex, 7)
        XCTAssertEqual(scale.value(at: 1), -0.25)
        XCTAssertEqual(scale.value(at: 7), 0.35)
    }

    func testPartialStepIsOmitted() {
        let scale = ZoomDecimalScale(bounds: 0...1, step: 0.3)
        XCTAssertEqual(scale.lastIndex, 3)
        XCTAssertEqual(scale.value(at: 3), 0.9)
        XCTAssertEqual(scale.index(of: 1), 3)
    }

    func testSnappingAndClamping() {
        let scale = ZoomDecimalScale(bounds: 0...2, step: 0.01)
        XCTAssertEqual(scale.value(at: scale.index(of: 1.984)), 1.98)
        XCTAssertEqual(scale.value(at: scale.index(of: 1.986)), 1.99)
        XCTAssertEqual(scale.index(of: -.infinity), 0)
        XCTAssertEqual(scale.index(of: .infinity), 200)
        XCTAssertEqual(scale.index(of: .nan), 0)
        XCTAssertEqual(scale.value(at: -1), 0)
        XCTAssertEqual(scale.value(at: 999), 2)
    }

    func testTinyWeightsAndSingleTickRanges() {
        let scale = ZoomDecimalScale(bounds: 0.0001...0.001, step: 0.0001)
        XCTAssertEqual(scale.lastIndex, 9)
        XCTAssertEqual(scale.value(at: 2), 0.0003)
        let single = ZoomDecimalScale(bounds: 1.98...1.98, step: 0.01)
        XCTAssertEqual(single.lastIndex, 0)
        XCTAssertEqual(single.value(at: 0), 1.98)
        XCTAssertEqual(ZoomDecimalScale(bounds: 0...0.01, step: 1).lastIndex, 0)
    }

    func testDecimalInitializerAndOriginalIntegerAPICompile() {
        _ = ZoomSlider(value: .constant(1.98), bounds: 0.01...10, step: 0.01, unit: "kg")
        _ = ZoomSlider(value: .constant(8000))
        _ = ZoomSlider(value: .constant(50), bounds: 0...100, step: 1)
    }

    func testDecimalProgress() {
        XCTAssertEqual(ZoomSlider.progress(of: 1.98, bounds: 0...3.96, step: 0.01), 0.5, accuracy: 1e-9)
        XCTAssertEqual(ZoomSlider.progress(of: -1.0, bounds: 0...1, step: 0.1), 0)
        XCTAssertEqual(ZoomSlider.progress(of: 2.0, bounds: 0...1, step: 0.1), 1)
        XCTAssertEqual(ZoomSlider.progress(of: 0.3, bounds: 0...0.3, step: 0.1), 1, accuracy: 1e-9)
        XCTAssertEqual(ZoomSlider.progress(of: 1.98, bounds: 1.98...1.98, step: 0.01), 0)
    }
}
