//
//  StepGoalCard.swift
//  ZoomSliderDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  The hero demo: an onboarding card. While you press the slider the rest of the card blurs and
//  dims, and the glow in the tile grid follows the value.
//
import SwiftUI
import ZoomSlider

/// Step-goal numbers behind the caption ("About 6.3 km · 1 hr 25 min of walking").
enum StepGoalMath {
    static let bounds = 2000...16000
    static let step = 250

    static func km(_ steps: Int) -> String { String(format: "%.1f km", Double(steps) * 0.00076) }

    /// About 100 steps a minute, rounded up to 5 minutes.
    static func walking(_ steps: Int) -> String {
        let m = Int((Double(steps) / 100 / 5).rounded(.up)) * 5
        let h = m / 60, r = m % 60
        if h == 0 { return "\(r) min" }
        if r == 0 { return "\(h) hr" }
        return "\(h) hr \(r) min"
    }
}

/// A grid of rounded tiles with a glow that slides left to right with the slider.
struct HeroGrid: View, Animatable {
    var pos: CGFloat
    let dark: Bool

    var animatableData: CGFloat {
        get { pos }
        set { pos = newValue }
    }

    private let tile: CGFloat = 46
    private let gap: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let pitch = tile + gap
            let cols = Int(w / pitch) + 2
            let rows = 4
            let x0 = (w - (CGFloat(cols) * pitch - gap)) / 2
            let glowX = 0.12 + 0.76 * Double(pos)
            let t = Double(pos)
            let green = (r: 0.30, g: 0.84, b: 0.34), lime = (r: 0.78, g: 0.96, b: 0.22)
            let glow = (r: green.r + (lime.r - green.r) * t, g: green.g + (lime.g - green.g) * t, b: green.b + (lime.b - green.b) * t)
            let pale = dark ? (r: 0.16, g: 0.21, b: 0.16) : (r: 0.90, g: 0.98, b: 0.90)

            ZStack(alignment: .topLeading) {
                ForEach(0..<rows, id: \.self) { r in
                    ForEach(0..<cols, id: \.self) { c in
                        let cx = Double((x0 + CGFloat(c) * pitch + tile / 2) / w)
                        let cy = Double((28 + CGFloat(r) * pitch + tile / 2) / h)
                        let dx = (cx - glowX) / 0.30, dy = (cy - 0.40) / 0.45
                        let i = exp(-(dx * dx + dy * dy))
                        let color = Color(red: pale.r + (glow.r - pale.r) * i,
                                          green: pale.g + (glow.g - pale.g) * i,
                                          blue: pale.b + (glow.b - pale.b) * i)
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(color.opacity(0.50 + 0.50 * i))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.white.opacity(dark ? 0.10 : 0.65), lineWidth: 1.2)
                            )
                            .frame(width: tile, height: tile)
                            .offset(x: x0 + CGFloat(c) * pitch, y: 28 + CGFloat(r) * pitch)
                    }
                }
            }
        }
    }
}

struct StepGoalCard: View {
    let theme: DemoTheme
    var haptics = true

    @State private var steps = 8000
    @State private var active = false

    private var progress: CGFloat {
        ZoomSlider.progress(of: steps, bounds: StepGoalMath.bounds, step: StepGoalMath.step)
    }

    private var blurAnimation: Animation { active ? .easeOut(duration: 0.30) : .easeInOut(duration: 0.40) }

    var body: some View {
        VStack(spacing: 0) {
            // Hero
            ZStack(alignment: .top) {
                HeroGrid(pos: progress, dark: theme.dark)
                    .animation(.easeOut(duration: 0.22), value: steps)
                    .mask(
                        LinearGradient(stops: [.init(color: .black, location: 0.55), .init(color: .clear, location: 1)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                HStack(spacing: 4) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule().fill(theme.ink.opacity(i < 2 ? 0.85 : 0.14)).frame(width: 14, height: 2)
                    }
                }
                .padding(.top, 12)
            }
            .frame(height: 190)
            .blur(radius: active ? 16 : 0)
            .animation(blurAnimation, value: active)

            // Copy
            VStack(alignment: .leading, spacing: 8) {
                Text("Set a daily step goal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(theme.ink)
                Text("Pick a number you can reach most days. You can change it anytime in Settings.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(theme.subtle)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 26)
            .offset(y: -22)
            .blur(radius: active ? 10 : 0)
            .opacity(active ? 0.7 : 1)
            .animation(blurAnimation, value: active)

            // The slider stays sharp
            ZoomSlider(value: $steps, bounds: StepGoalMath.bounds, step: StepGoalMath.step,
                       style: theme.style, haptics: haptics, accessibilityName: "Daily step goal",
                       onEditingChanged: { editing in active = editing })
            .padding(.horizontal, 26)
            .offset(y: -10)

            (Text("About ") + Text(StepGoalMath.km(steps)).foregroundColor(theme.ink)
                + Text(" · \(StepGoalMath.walking(steps)) of walking"))
                .font(.system(size: 11.5))
                .foregroundColor(theme.subtle)
                .monospacedDigit()
                .offset(y: -22)

            Spacer(minLength: 0)

            // Actions
            VStack(spacing: 14) {
                Button {} label: {
                    Text("Continue")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(theme.buttonText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(theme.ink))
                }
                .buttonStyle(.plain)
                Text("Skip for now")
                    .font(.system(size: 11.5))
                    .foregroundStyle(theme.subtle)
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 24)
            .blur(radius: active ? 7 : 0)
            .opacity(active ? 0.72 : 1)
            .animation(blurAnimation, value: active)
        }
        .frame(width: 340, height: 500)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(theme.hairline, lineWidth: 1))
        .shadow(color: .black.opacity(theme.dark ? 0 : 0.08), radius: 24, y: 12)
    }
}
