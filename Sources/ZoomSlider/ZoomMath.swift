//
//  ZoomMath.swift
//  ZoomSlider
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Pure geometry and value math, kept free of SwiftUI state so it can be unit-tested.
//
import Foundation

/// Sizes measured from the reference interaction (points).
enum ZoomMetrics {
    static let height: CGFloat = 100
    static let rulerY: CGFloat = 64             // vertical centre of the ticks

    static let pillWidth: CGFloat = 54
    static let pillHeight: CGFloat = 27
    static let pillRadius: CGFloat = 9

    static let bubbleWidth: CGFloat = 120
    static let bubbleHeight: CGFloat = 62
    static let bubbleRadius: CGFloat = 22
    static let bubbleLift: CGFloat = 16         // the bubble's centre rises this far above the ticks
    static let labelLift: CGFloat = 13          // the big number sits in the upper part of the bubble
    static let bubbleOverhang: CGFloat = 20     // the bubble may hang past either end of the ruler

    static let lensRadius: CGFloat = 58         // ticks inside this distance of the finger are magnified
    static let lensSpread: CGFloat = 0.75       // ticks move apart by 1 + this at the finger
    static let lensHeightGain: CGFloat = 0.5
    static let lensWidthGain: CGFloat = 0.35

    static let tickMinor: CGFloat = 8
    static let tickMajor: CGFloat = 13
    static let tickMinorWidth: CGFloat = 1.2
    static let tickMajorWidth: CGFloat = 1.6

    static let fringeBand: CGFloat = 0.18       // how close to the lens edge the colour fringe shows
    static let fringeOffset: CGFloat = 1.6

    static let grabSlop: CGFloat = 34           // a touch this close to the pill grabs it
}

enum ZoomMath {

    // MARK: Values <-> progress

    /// Number of ticks: one per `step` from the lower to the upper bound.
    /// (Bounds that aren't a multiple of `step` apart never reach the last partial step.)
    static func tickCount(bounds: ClosedRange<Int>, step: Int) -> Int {
        (bounds.upperBound - bounds.lowerBound) / max(step, 1) + 1
    }

    /// 0 at the first tick, 1 at the last.
    static func progress(of value: Int, bounds: ClosedRange<Int>, step: Int) -> CGFloat {
        let n = tickCount(bounds: bounds, step: step)
        guard n > 1 else { return 0 }
        let index = Double(value - bounds.lowerBound) / Double(max(step, 1))
        return clamp01(CGFloat(index / Double(n - 1)))
    }

    /// The value on the tick nearest to `progress`.
    static func value(atProgress progress: CGFloat, bounds: ClosedRange<Int>, step: Int) -> Int {
        let n = tickCount(bounds: bounds, step: step)
        guard n > 1 else { return bounds.lowerBound }
        let index = Int((clamp01(progress) * CGFloat(n - 1)).rounded())
        return bounds.lowerBound + index * max(step, 1)
    }

    /// Rounds any value to the nearest tick and clamps it to the bounds.
    static func snap(_ value: Int, bounds: ClosedRange<Int>, step: Int) -> Int {
        let n = tickCount(bounds: bounds, step: step)
        let s = max(step, 1)
        let index = Int((Double(value - bounds.lowerBound) / Double(s)).rounded())
        return bounds.lowerBound + min(max(index, 0), n - 1) * s
    }

    static func isMajor(index: Int, every: Int) -> Bool {
        index % max(every, 1) == 0
    }

    // MARK: Positions

    /// x of the finger (and of the zoom lens) for a progress on a track `width` wide:
    /// the first tick sits at 1 and the last at `width - 1`, so the finger reaches both ends.
    static func fingerX(progress: CGFloat, width: CGFloat) -> CGFloat {
        1 + clamp01(progress) * max(width - 2, 0)
    }

    /// The progress under an x position, clamped to the track.
    static func progress(atX x: CGFloat, width: CGFloat) -> CGFloat {
        clamp01((x - 1) / max(width - 2, 1))
    }

    /// Centre of the idle pill: it follows the finger but stays inside the ruler.
    static func pillCenter(fingerX: CGFloat, width: CGFloat) -> CGFloat {
        let half = ZoomMetrics.pillWidth / 2
        return min(max(fingerX, half), width - half)
    }

    /// Centre of the pill / bubble for the current `z` (0 = pill, 1 = bubble). The bubble is
    /// wider and may overhang the ends of the ruler a little.
    static func thumbCenter(fingerX: CGFloat, width: CGFloat, z: CGFloat) -> CGFloat {
        let zc = max(z, 0)
        let thumbW = lerp(ZoomMetrics.pillWidth, ZoomMetrics.bubbleWidth, z)
        let half = thumbW / 2
        let overhang = ZoomMetrics.bubbleOverhang * zc
        return min(max(fingerX, half - overhang), width - half + overhang)
    }

    /// Offset kept between your finger and the thumb when a drag starts, so grabbing the pill
    /// anywhere (even at its edge when it sits at an end) doesn't move the value.
    static func grabOffset(startX: CGFloat, fingerX: CGFloat, width: CGFloat) -> CGFloat {
        let pill = pillCenter(fingerX: fingerX, width: width)
        return abs(startX - pill) < ZoomMetrics.grabSlop ? fingerX - startX : 0
    }

    // MARK: Zoom lens

    /// Fisheye: ticks within `radius` of `center` spread apart by `1 + spread` at the centre and
    /// ease back to 1 at the edge, so ticks outside the lens never move. Returns the new x and
    /// `s`, the distance from the centre in lens radii (>= 1 means outside the lens).
    static func lens(x: CGFloat, center: CGFloat, radius: CGFloat, spread: CGFloat) -> (x: CGFloat, s: CGFloat) {
        let u = x - center
        let r = max(radius, 1)
        let s = abs(u) / r
        guard s < 1 else { return (x, s) }
        let m = 1 + spread
        let g = m * s - 2 * (m - 1) * s * s + (m - 1) * s * s * s
        return (center + (u < 0 ? -1 : 1) * r * g, s)
    }

    /// 1 in the middle of the lens, 0 at and beyond its edge. Scaled by `z`.
    static func lensWeight(s: CGFloat, z: CGFloat) -> CGFloat {
        guard s < 1 else { return 0 }
        let s2 = s * s
        return max(z, 0) * (1 - s2 * s2)
    }

    /// 1 right at the lens edge, fading to 0 within `fringeBand` either side. Scaled by `z`.
    static func fringe(s: CGFloat, z: CGFloat) -> CGFloat {
        max(z, 0) * max(0, 1 - abs(s - 1) / ZoomMetrics.fringeBand)
    }

    // MARK: Springs

    /// Stiffness of a spring that takes about `response` seconds to catch up (matches SwiftUI's `response`).
    static func stiffness(response: Double) -> Double {
        let w = 2 * Double.pi / max(response, 0.05)
        return w * w
    }

    static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
    static func clamp01(_ v: CGFloat) -> CGFloat { min(max(v, 0), 1) }
}

/// Ready-made labels. Pass your own `(Int) -> String` to `ZoomSlider` for anything else.
public enum ZoomLabels {

    /// "8k", "8.25k", "13.5k"; values under 1,000 are shown as they are.
    public static func compact(_ value: Int) -> String {
        guard abs(value) >= 1000 else { return String(value) }
        let sign = value < 0 ? "-" : ""
        let whole = abs(value) / 1000
        let rem = abs(value) % 1000
        guard rem != 0 else { return "\(sign)\(whole)k" }
        var fraction = String(rem)
        fraction = String(repeating: "0", count: 3 - fraction.count) + fraction
        while fraction.hasSuffix("0") { fraction.removeLast() }
        return "\(sign)\(whole).\(fraction)k"
    }

    /// "8,250", "16,000", "-1,500"
    public static func grouped(_ value: Int) -> String {
        let digits = String(abs(value))
        var out = ""
        for (i, ch) in digits.reversed().enumerated() {
            if i > 0 && i % 3 == 0 { out.append(",") }
            out.append(ch)
        }
        return (value < 0 ? "-" : "") + String(out.reversed())
    }
}
