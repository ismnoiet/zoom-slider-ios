//
//  ZoomSliderConfiguration.swift
//  ZoomSlider
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
import SwiftUI

/// Colors of the slider. Use a preset or build your own.
///
///     ZoomSlider(value: $steps, style: .ink)             // dark pill, white bubble, for light surfaces (default)
///     ZoomSlider(value: $steps, style: .paper)           // light pill, dark bubble, for dark surfaces
///     ZoomSlider(value: $steps, style: .accent(.green))  // colored pill and ticks
public struct ZoomSliderStyle: Equatable {
    /// Fill of the idle pill.
    public var pill: Color
    /// Text color inside the idle pill.
    public var pillLabel: Color
    /// Fill of the bubble that opens while you press.
    public var bubble: Color
    /// The big number inside the bubble.
    public var bubbleLabel: Color
    /// The unit next to the big number ("steps").
    public var bubbleSecondary: Color
    /// Hairline around the bubble.
    public var bubbleBorder: Color
    /// Ticks up to the current value.
    public var tickOn: Color
    /// Ticks after the current value.
    public var tickOff: Color
    /// Ticks after the current value, while they are under the zoom lens.
    public var tickOffZoomed: Color
    /// Drop shadow under the bubble.
    public var shadow: Color

    public init(
        pill: Color,
        pillLabel: Color,
        bubble: Color,
        bubbleLabel: Color,
        bubbleSecondary: Color,
        bubbleBorder: Color = .black.opacity(0.06),
        tickOn: Color,
        tickOff: Color,
        tickOffZoomed: Color,
        shadow: Color = .black.opacity(0.14)
    ) {
        self.pill = pill
        self.pillLabel = pillLabel
        self.bubble = bubble
        self.bubbleLabel = bubbleLabel
        self.bubbleSecondary = bubbleSecondary
        self.bubbleBorder = bubbleBorder
        self.tickOn = tickOn
        self.tickOff = tickOff
        self.tickOffZoomed = tickOffZoomed
        self.shadow = shadow
    }

    /// Near-black pill and ticks with a white bubble, for light surfaces.
    public static let ink = ZoomSliderStyle(
        pill: Color(white: 0.09),
        pillLabel: .white,
        bubble: .white,
        bubbleLabel: Color(white: 0.08),
        bubbleSecondary: Color(white: 0.45),
        tickOn: .black.opacity(0.85),
        tickOff: .black.opacity(0.17),
        tickOffZoomed: .black.opacity(0.30)
    )

    /// Near-white pill and ticks with a graphite bubble, for dark surfaces.
    public static let paper = ZoomSliderStyle(
        pill: Color(white: 0.96),
        pillLabel: Color(white: 0.10),
        bubble: Color(white: 0.17),
        bubbleLabel: Color(white: 0.97),
        bubbleSecondary: .white.opacity(0.55),
        bubbleBorder: .white.opacity(0.10),
        tickOn: .white.opacity(0.90),
        tickOff: .white.opacity(0.20),
        tickOffZoomed: .white.opacity(0.34),
        shadow: .black.opacity(0.50)
    )

    /// A colored pill with white text; the ticks and the bubble number follow the color.
    public static func accent(_ color: Color) -> ZoomSliderStyle {
        ZoomSliderStyle(
            pill: color,
            pillLabel: .white,
            bubble: .white,
            bubbleLabel: color,
            bubbleSecondary: Color(white: 0.45),
            bubbleBorder: color.opacity(0.14),
            tickOn: color,
            tickOff: color.opacity(0.22),
            tickOffZoomed: color.opacity(0.38),
            shadow: color.opacity(0.30)
        )
    }
}

/// How the slider moves. Every value is a spring *response* in seconds: roughly how long the
/// element takes to catch up. Smaller is snappier.
public struct ZoomTiming: Equatable {
    /// The pill opening into the bubble when you press.
    public var open: Double
    /// The bubble collapsing back into the pill when you let go.
    public var close: Double
    /// The thumb and the zoom lens chasing your finger while you drag.
    public var follow: Double

    public init(open: Double = 0.34, close: Double = 0.32, follow: Double = 0.14) {
        self.open = open
        self.close = close
        self.follow = follow
    }

    public static let `default` = ZoomTiming()
}

/// Spring damping used for the three motions. Under 1 so the bubble pops open with a little overshoot.
enum ZoomDamping {
    static let open: Double = 0.72
    static let close: Double = 0.82
    static let follow: Double = 0.85
}
