//
//  ZoomTrack.swift
//  ZoomSlider
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

/// The ruler and the pill / bubble. `Animatable`, so every tick follows the springs that
/// drive `z` (pill 0 ... bubble 1) and `pos` (0...1 along the ruler) frame by frame.
struct ZoomTrack: View, Animatable {
    var z: CGFloat
    var pos: CGFloat
    let ticks: Int
    let majorEvery: Int
    let style: ZoomSliderStyle
    let compactText: String
    let fullText: String
    let unit: String

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(z, pos) }
        set { z = newValue.first; pos = newValue.second }
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let zc = max(0, z)
            let p = ZoomMath.clamp01(pos)

            let fingerX = ZoomMath.fingerX(progress: p, width: width)
            let thumbW = ZoomMath.lerp(ZoomMetrics.pillWidth, ZoomMetrics.bubbleWidth, z)
            let thumbH = ZoomMath.lerp(ZoomMetrics.pillHeight, ZoomMetrics.bubbleHeight, z)
            let thumbX = ZoomMath.thumbCenter(fingerX: fingerX, width: width, z: z)
            let thumbY = ZoomMetrics.rulerY - ZoomMetrics.bubbleLift * zc

            ZStack(alignment: .topLeading) {
                // 1. Pill / bubble body
                ZoomThumbBody(z: z, style: style)
                    .frame(width: thumbW, height: thumbH)
                    .position(x: thumbX, y: thumbY)

                // 2. Ruler, drawn on top of the bubble so the zoomed ticks sit inside it
                Canvas { ctx, _ in
                    drawRuler(&ctx, width: width, fingerX: fingerX, thumbX: thumbX, thumbW: thumbW, p: p, zc: zc)
                }

                // 3. Labels
                ZoomThumbLabels(z: z, compactText: compactText, fullText: fullText, unit: unit, style: style)
                    .frame(width: thumbW, height: thumbH)
                    .position(x: thumbX, y: thumbY)
            }
        }
        .frame(height: ZoomMetrics.height)
    }

    private func drawRuler(
        _ ctx: inout GraphicsContext,
        width: CGFloat, fingerX: CGFloat, thumbX: CGFloat, thumbW: CGFloat, p: CGFloat, zc: CGFloat
    ) {
        let radius = max(1, ZoomMetrics.lensRadius * zc)
        let spread = ZoomMetrics.lensSpread * zc
        let n = max(ticks, 1)

        for i in 0..<n {
            let f: CGFloat = n > 1 ? CGFloat(i) / CGFloat(n - 1) : 0
            let x0 = 1 + f * (width - 2)
            let m = ZoomMath.lens(x: x0, center: fingerX, radius: radius, spread: spread)
            let w = ZoomMath.lensWeight(s: m.s, z: zc)
            let major = ZoomMath.isMajor(index: i, every: majorEvery)

            let h = (major ? ZoomMetrics.tickMajor : ZoomMetrics.tickMinor) * (1 + ZoomMetrics.lensHeightGain * w)
            let tw = (major ? ZoomMetrics.tickMajorWidth : ZoomMetrics.tickMinorWidth) * (1 + ZoomMetrics.lensWidthGain * w)
            let rect = CGRect(x: m.x - tw / 2, y: ZoomMetrics.rulerY - h / 2, width: tw, height: h)
            let path = Path(roundedRect: rect, cornerRadius: tw / 2)
            let filled = f <= p + 0.0001

            // Under the idle pill the ticks are hidden; they fade in as the bubble opens.
            let visible: CGFloat = abs(m.x - thumbX) < thumbW / 2 ? min(1, zc * 2.5) : 1

            // Subtle colour fringe where the lens meets the ruler
            let edge = ZoomMath.fringe(s: m.s, z: zc)
            if edge > 0.01 {
                ctx.opacity = Double(0.45 * edge * visible)
                ctx.fill(Path(roundedRect: rect.offsetBy(dx: -ZoomMetrics.fringeOffset, dy: 0), cornerRadius: tw / 2),
                         with: .color(Color(red: 0.35, green: 0.55, blue: 0.95)))
                ctx.fill(Path(roundedRect: rect.offsetBy(dx: ZoomMetrics.fringeOffset, dy: 0), cornerRadius: tw / 2),
                         with: .color(Color(red: 1.0, green: 0.55, blue: 0.35)))
            }

            ctx.opacity = Double(visible)
            if filled {
                ctx.fill(path, with: .color(style.tickOn))
            } else {
                ctx.fill(path, with: .color(style.tickOff))
                if w > 0.001 {
                    ctx.opacity = Double(visible * w)
                    ctx.fill(path, with: .color(style.tickOffZoomed))
                }
            }
            ctx.opacity = 1
        }
    }
}

// MARK: - Pill / bubble pieces

struct ZoomThumbBody: View {
    let z: CGFloat
    let style: ZoomSliderStyle

    var body: some View {
        let zc: CGFloat = max(0, z)
        let radius: CGFloat = ZoomMath.lerp(ZoomMetrics.pillRadius, ZoomMetrics.bubbleRadius, z)
        let toBubble: Double = Double(min(1, zc * 1.4))      // pill fill gives way to the bubble fill early

        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous).fill(style.pill)
            RoundedRectangle(cornerRadius: radius, style: .continuous).fill(style.bubble).opacity(toBubble)
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(style.bubbleBorder, lineWidth: 0.5)
                .opacity(toBubble)
        }
        .shadow(color: style.shadow, radius: 16 * zc, x: 0, y: 6 * zc)
    }
}

struct ZoomThumbLabels: View {
    let z: CGFloat
    let compactText: String
    let fullText: String
    let unit: String
    let style: ZoomSliderStyle

    var body: some View {
        let zc: CGFloat = max(0, z)
        let pillOpacity: Double = Double(max(0, 1 - zc * 3))
        let bubbleOpacity: Double = Double(max(0, min(1, (zc - 0.45) * 2)))

        ZStack {
            pillLabel.opacity(pillOpacity)
            bubbleLabel.opacity(bubbleOpacity).offset(y: -ZoomMetrics.labelLift * zc)   // ticks live in the lower part
        }
        .allowsHitTesting(false)
    }

    private var pillLabel: some View {
        let font: Font = Font.system(size: 11, weight: Font.Weight.semibold)
        return Text(compactText).font(font).foregroundColor(style.pillLabel)
    }

    private var bubbleLabel: some View {
        let big: Font = Font.system(size: 20, weight: Font.Weight.semibold).monospacedDigit()
        let small: Font = Font.system(size: 11, weight: Font.Weight.medium)
        return HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(fullText).font(big).foregroundColor(style.bubbleLabel)
            if !unit.isEmpty {
                Text(unit).font(small).foregroundColor(style.bubbleSecondary)
            }
        }
        .fixedSize()
    }
}
