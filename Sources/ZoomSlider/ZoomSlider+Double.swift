import SwiftUI

extension ZoomSlider {
    /// Creates a slider for decimal measurements, with one tick per `step`.
    ///
    /// Steps are anchored at the lower bound. If the range is not divisible by
    /// `step`, its last partial step is omitted, matching the integer initializer.
    /// Bounds must be finite, and `step` must be finite and greater than zero.
    ///
    ///     ZoomSlider(value: $weight, bounds: 0.01...10.0, step: 0.01, unit: "kg")
    public init(
        value: Binding<Double>,
        bounds: ClosedRange<Double>,
        step: Double,
        majorEvery: Int = 4,
        unit: String = "",
        style: ZoomSliderStyle = .ink,
        timing: ZoomTiming = .default,
        haptics: Bool = true,
        accessibilityName: String = "Value",
        compactLabel: @escaping (Double) -> String = { $0.formatted(.number.precision(.fractionLength(0...16))) },
        fullLabel: @escaping (Double) -> String = { $0.formatted(.number.precision(.fractionLength(0...16))) },
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        let scale = ZoomDecimalScale(bounds: bounds, step: step)
        self.init(
            value: Binding(
                get: { scale.index(of: value.wrappedValue) },
                set: { value.wrappedValue = scale.value(at: $0) }
            ),
            bounds: 0...scale.lastIndex,
            step: 1,
            majorEvery: majorEvery,
            unit: unit,
            style: style,
            timing: timing,
            haptics: haptics,
            accessibilityName: accessibilityName,
            compactLabel: { compactLabel(scale.value(at: $0)) },
            fullLabel: { fullLabel(scale.value(at: $0)) },
            onEditingChanged: onEditingChanged
        )
    }

    /// Returns a decimal value's continuous position between the first and last full ticks.
    public static func progress(of value: Double, bounds: ClosedRange<Double>, step: Double) -> CGFloat {
        let scale = ZoomDecimalScale(bounds: bounds, step: step)
        guard scale.lastIndex > 0, !value.isNaN else { return 0 }
        return CGFloat(min(max((value - bounds.lowerBound) / step / Double(scale.lastIndex), 0), 1))
    }
}
