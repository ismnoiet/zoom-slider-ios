//
//  DemoSupport.swift
//  ZoomSliderDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Shared pieces for the dark and light demo screens.
//
import SwiftUI
import ZoomSlider

/// Colors for one demo theme.
struct DemoTheme {
    let dark: Bool

    var page: Color { dark ? Color(white: 0.07) : Color(red: 0.96, green: 0.96, blue: 0.97) }
    var card: Color { dark ? Color(white: 0.11) : .white }
    var ink: Color { dark ? Color(white: 0.96) : Color(red: 0.10, green: 0.11, blue: 0.14) }
    var subtle: Color { dark ? .white.opacity(0.45) : Color(red: 0.45, green: 0.47, blue: 0.52) }
    var hairline: Color { dark ? .white.opacity(0.08) : .black.opacity(0.06) }
    var chip: Color { dark ? .white.opacity(0.10) : .black.opacity(0.06) }
    var buttonText: Color { dark ? Color(white: 0.10) : .white }
    var style: ZoomSliderStyle { dark ? .paper : .ink }
}

struct DemoSection<Content: View>: View {
    let title: String
    let theme: DemoTheme
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.subtle)
            content
        }
    }
}

struct DemoCard<Content: View>: View {
    let theme: DemoTheme
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(.vertical, 20)
            .frame(width: 340)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(theme.card))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(theme.hairline, lineWidth: 1))
            .shadow(color: .black.opacity(theme.dark ? 0 : 0.06), radius: 14, y: 6)
    }
}

/// A titled slider inside a card, with its own state and a live readout.
struct UnitDemo: View {
    let title: String
    let theme: DemoTheme
    @State var value: Int
    let bounds: ClosedRange<Int>
    let step: Int
    let majorEvery: Int
    let unit: String
    var haptics = true
    var style: ZoomSliderStyle? = nil
    var timing: ZoomTiming = .default
    let compact: (Int) -> String
    let full: (Int) -> String

    var body: some View {
        DemoCard(theme: theme) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.ink)
                Spacer()
                Text("\(full(value)) \(unit)")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.subtle)
                    .monospacedDigit()
            }
            .padding(.horizontal, 26)
            ZoomSlider(value: $value, bounds: bounds, step: step, majorEvery: majorEvery, unit: unit,
                       style: style ?? theme.style, timing: timing, haptics: haptics,
                       accessibilityName: title, compactLabel: compact, fullLabel: full)
            .padding(.horizontal, 26)
            .padding(.top, 6)
        }
    }
}

/// Preset chips that drive the slider from code: the pill glides to the chosen value.
struct PresetsCard: View {
    let theme: DemoTheme
    var haptics = true
    @State private var steps = 8000
    private let presets = [4000, 8000, 12000, 16000]

    var body: some View {
        DemoCard(theme: theme) {
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { p in
                    Button {
                        steps = p
                    } label: {
                        Text(ZoomLabels.compact(p))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(steps == p ? theme.buttonText : theme.ink)
                            .padding(.horizontal, 14)
                            .frame(height: 30)
                            .background(Capsule().fill(steps == p ? theme.ink : theme.chip))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 26)
            ZoomSlider(value: $steps, style: theme.style, haptics: haptics, accessibilityName: "Daily step goal")
                .padding(.horizontal, 26)
                .padding(.top, 6)
        }
    }
}

/// Label formatters for the demo units. Integer maths only, so they match the Android demo exactly.
enum DemoLabels {
    static func degrees(_ v: Int) -> String { "\(v)°" }

    /// 450 minutes -> "7.5h" (compact), "7h 30m" (full).
    static func hoursCompact(_ minutes: Int) -> String {
        let h = minutes / 60, r = minutes % 60
        if r == 0 { return "\(h)h" }
        return "\(h).\(r * 10 / 60)h"
    }

    static func hoursFull(_ minutes: Int) -> String {
        let h = minutes / 60, r = minutes % 60
        if r == 0 { return "\(h)h" }
        return "\(h)h \(r)m"
    }

    static func dollarsCompact(_ v: Int) -> String { "$" + ZoomLabels.compact(v) }
    static func dollarsFull(_ v: Int) -> String { "$" + ZoomLabels.grouped(v) }
}

/// Everything the dark and light showcases have in common.
struct ExampleStack: View {
    let theme: DemoTheme
    @State private var haptics = true

    var body: some View {
        VStack(spacing: 30) {
            Toggle(isOn: $haptics) {
                Text("Haptics")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.ink)
            }
            .tint(theme.ink)
            .padding(.horizontal, 6)

            DemoSection(title: "Daily step goal · press and drag", theme: theme) {
                StepGoalCard(theme: theme, haptics: haptics)
            }

            DemoSection(title: "Same slider, other units", theme: theme) {
                VStack(spacing: 16) {
                    UnitDemo(title: "Volume", theme: theme, value: 64,
                             bounds: 0...100, step: 1, majorEvery: 10, unit: "%", haptics: haptics,
                             compact: { "\($0)%" }, full: { String($0) })
                    UnitDemo(title: "Thermostat", theme: theme, value: 21,
                             bounds: 10...32, step: 1, majorEvery: 5, unit: "°C", haptics: haptics,
                             compact: DemoLabels.degrees, full: { String($0) })
                    UnitDemo(title: "Sleep goal", theme: theme, value: 450,
                             bounds: 240...720, step: 15, majorEvery: 4, unit: "hours", haptics: haptics,
                             compact: DemoLabels.hoursCompact, full: DemoLabels.hoursFull)
                    UnitDemo(title: "Budget", theme: theme, value: 1500,
                             bounds: 0...10000, step: 250, majorEvery: 4, unit: "/ month", haptics: haptics,
                             compact: DemoLabels.dollarsCompact, full: DemoLabels.dollarsFull)
                }
            }

            DemoSection(title: "Drive it from code", theme: theme) {
                PresetsCard(theme: theme, haptics: haptics)
            }

            DemoSection(title: "Your colors", theme: theme) {
                VStack(spacing: 16) {
                    UnitDemo(title: "Blue", theme: theme, value: 6000, bounds: 2000...16000, step: 250, majorEvery: 4,
                             unit: "steps", haptics: haptics, style: .accent(.blue),
                             compact: ZoomLabels.compact, full: ZoomLabels.grouped)
                    UnitDemo(title: "Green", theme: theme, value: 9000, bounds: 2000...16000, step: 250, majorEvery: 4,
                             unit: "steps", haptics: haptics, style: .accent(.green),
                             compact: ZoomLabels.compact, full: ZoomLabels.grouped)
                    UnitDemo(title: "Orange", theme: theme, value: 12000, bounds: 2000...16000, step: 250, majorEvery: 4,
                             unit: "steps", haptics: haptics, style: .accent(.orange),
                             compact: ZoomLabels.compact, full: ZoomLabels.grouped)
                }
            }

            DemoSection(title: "Heavy springs", theme: theme) {
                UnitDemo(title: "Slower timing", theme: theme, value: 8000, bounds: 2000...16000, step: 250, majorEvery: 4,
                         unit: "steps", haptics: haptics, timing: ZoomTiming(open: 0.6, close: 0.55, follow: 0.28),
                         compact: ZoomLabels.compact, full: ZoomLabels.grouped)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}
