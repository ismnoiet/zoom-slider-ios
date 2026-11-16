//
//  ZoomSlider.swift
//  ZoomSlider
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

/// A slider for picking a whole number from a range, shown as a ruler of ticks.
///
///  • At rest it is a small pill showing the current value.
///  • Press it and the pill opens into a bubble with the full value, while the ticks under your
///    finger spread apart so each step is easy to land on.
///  • Let go and the bubble closes back into the pill on the nearest tick.
///
///     ZoomSlider(value: $value)                                        // default range, one tick per step
///     ZoomSlider(value: $volume, bounds: 0...100, step: 1, majorEvery: 10, unit: "%")
///     ZoomSlider(value: $value, onEditingChanged: { dimTheRest = $0 })  // react to press and release
///
/// The slider fills the width you give it and is 100 pt tall. While you press, the bubble rises
/// about 44 pt above the ruler and may hang 20 pt past either end of it, so leave some room around it.
public struct ZoomSlider: View {
    @Binding private var value: Int
    private let bounds: ClosedRange<Int>
    private let step: Int
    private let majorEvery: Int
    private let unit: String
    private let style: ZoomSliderStyle
    private let timing: ZoomTiming
    private let haptics: Bool
    private let accessibilityName: String
    private let compactLabel: (Int) -> String
    private let fullLabel: (Int) -> String
    private let onEditingChanged: (Bool) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pos: CGFloat        // 0...1 along the ruler (continuous while dragging)
    @State private var z: CGFloat = 0      // 0 = pill, 1 = bubble
    @State private var grabOffset: CGFloat?
    @State private var editing = false

    // MARK: Init

    public init(
        value: Binding<Int>,
        bounds: ClosedRange<Int> = 2000...16000,
        step: Int = 250,
        majorEvery: Int = 4,
        unit: String = "steps",
        style: ZoomSliderStyle = .ink,
        timing: ZoomTiming = .default,
        haptics: Bool = true,
        accessibilityName: String = "Value",
        compactLabel: @escaping (Int) -> String = ZoomLabels.compact,
        fullLabel: @escaping (Int) -> String = ZoomLabels.grouped,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _value = value
        self.bounds = bounds
        self.step = max(step, 1)
        self.majorEvery = max(majorEvery, 1)
        self.unit = unit
        self.style = style
        self.timing = timing
        self.haptics = haptics
        self.accessibilityName = accessibilityName
        self.compactLabel = compactLabel
        self.fullLabel = fullLabel
        self.onEditingChanged = onEditingChanged
        _pos = State(initialValue: ZoomMath.progress(of: value.wrappedValue, bounds: bounds, step: max(step, 1)))
    }

    /// 0...1 position of `value` on a slider with these bounds, e.g. to drive something that follows the slider.
    public static func progress(of value: Int, bounds: ClosedRange<Int> = 2000...16000, step: Int = 250) -> CGFloat {
        ZoomMath.progress(of: value, bounds: bounds, step: max(step, 1))
    }

    // MARK: Body

    public var body: some View {
        GeometryReader { geo in
            ZoomTrack(
                z: z, pos: pos,
                ticks: ZoomMath.tickCount(bounds: bounds, step: step),
                majorEvery: majorEvery,
                style: style,
                compactText: compactLabel(value),
                fullText: fullLabel(value),
                unit: unit
            )
            .contentShape(Rectangle())
            .gesture(drag(width: geo.size.width))
        }
        .frame(height: ZoomMetrics.height)
        .onChange(of: value) { _, new in
            // The parent moved the value (a preset, a reset): glide there unless a drag is in charge.
            guard !editing else { return }
            animate(.spring(response: timing.close, dampingFraction: ZoomDamping.close)) {
                pos = ZoomMath.progress(of: new, bounds: bounds, step: step)
            }
        }
        .sensoryFeedback(trigger: value) { _, _ in haptics && editing ? .selection : nil }
        .sensoryFeedback(trigger: editing) { _, now in haptics && now ? .impact(flexibility: .soft, intensity: 0.6) : nil }
        .accessibilityRepresentation { accessibilityControl }
    }

    // MARK: Gesture

    private func drag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                if grabOffset == nil {
                    let fingerX = ZoomMath.fingerX(progress: pos, width: width)
                    grabOffset = ZoomMath.grabOffset(startX: g.startLocation.x, fingerX: fingerX, width: width)
                    begin()
                }
                let x = g.location.x + (grabOffset ?? 0)
                let p = ZoomMath.progress(atX: x, width: width)
                animate(.interactiveSpring(response: timing.follow, dampingFraction: ZoomDamping.follow)) { pos = p }
                let v = ZoomMath.value(atProgress: p, bounds: bounds, step: step)
                if v != value { value = v }
            }
            .onEnded { _ in end() }
    }

    private func begin() {
        editing = true
        onEditingChanged(true)
        animate(.spring(response: timing.open, dampingFraction: ZoomDamping.open)) { z = 1 }
    }

    private func end() {
        grabOffset = nil
        editing = false
        onEditingChanged(false)
        animate(.spring(response: timing.close, dampingFraction: ZoomDamping.close)) {
            z = 0
            pos = ZoomMath.progress(of: value, bounds: bounds, step: step)   // settle onto the snapped tick
        }
    }

    /// Reduce Motion: jump to the end state instead of springing.
    private func animate(_ animation: Animation, _ body: () -> Void) {
        withAnimation(reduceMotion ? nil : animation, body)
    }

    // MARK: Accessibility

    private var accessibilityControl: some View {
        Slider(
            value: Binding(
                get: { Double(value) },
                set: { value = ZoomMath.snap(Int($0.rounded()), bounds: bounds, step: step) }
            ),
            in: Double(bounds.lowerBound)...Double(bounds.upperBound),
            step: Double(step)
        )
        .accessibilityLabel(accessibilityName)
        .accessibilityValue(unit.isEmpty ? fullLabel(value) : "\(fullLabel(value)) \(unit)")
    }
}
