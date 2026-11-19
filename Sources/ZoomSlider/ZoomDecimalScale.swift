import Foundation

/// Maps decimal measurements onto the integer tick indices used by the renderer.
struct ZoomDecimalScale {
    let bounds: ClosedRange<Double>
    let step: Double
    let lastIndex: Int
    private let origin: Decimal
    private let increment: Decimal

    init(bounds: ClosedRange<Double>, step: Double) {
        precondition(bounds.lowerBound.isFinite && bounds.upperBound.isFinite,
                     "ZoomSlider bounds must be finite")
        precondition(step.isFinite && step > 0, "ZoomSlider step must be finite and positive")
        self.bounds = bounds
        self.step = step
        // Decimal arithmetic avoids losing an endpoint for ranges such as 0...0.3 by 0.1.
        let locale = Locale(identifier: "en_US_POSIX")
        guard let origin = Decimal(string: String(bounds.lowerBound), locale: locale),
              let upper = Decimal(string: String(bounds.upperBound), locale: locale),
              let increment = Decimal(string: String(step), locale: locale),
              !origin.isNaN, !upper.isNaN, !increment.isNaN, increment > 0 else {
            preconditionFailure("ZoomSlider bounds and step must be representable as Decimal")
        }
        let quotient = NSDecimalNumber(decimal: (upper - origin) / increment).doubleValue
        let nearest = quotient.rounded()
        let aligned = abs(quotient - nearest) <= quotient.ulp * 4 ? nearest : quotient.rounded(.down)
        guard let lastIndex = Int(exactly: aligned), lastIndex >= 0, lastIndex < Int.max else {
            preconditionFailure("ZoomSlider range contains too many steps")
        }
        self.origin = origin
        self.increment = increment
        self.lastIndex = lastIndex
    }

    func index(of value: Double) -> Int {
        guard !value.isNaN, value > bounds.lowerBound else { return 0 }
        guard value < bounds.upperBound else { return lastIndex }
        let index = ((value - bounds.lowerBound) / step).rounded()
        return Int(min(max(index, 0), Double(lastIndex)))
    }

    func value(at index: Int) -> Double {
        let bounded = min(max(index, 0), lastIndex)
        let value = Double(NSDecimalNumber(decimal: origin + Decimal(bounded) * increment).stringValue)!
        return min(max(value, bounds.lowerBound), bounds.upperBound)
    }

}
