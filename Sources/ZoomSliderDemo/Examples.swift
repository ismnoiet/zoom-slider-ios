//
//  Examples.swift
//  ZoomSliderDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Dark-theme demos. Open Package.swift in Xcode, pick the ZoomSliderDemo scheme and use
//  the canvas (or call `ZoomSliderExamples()` from an app). Add demos by appending a
//  `DemoSection` in `ExampleStack` (DemoSupport.swift).
//
import SwiftUI

public struct ZoomSliderExamples: View {
    public init() {}

    public var body: some View {
        let theme = DemoTheme(dark: true)
        ScrollView(showsIndicators: false) {
            ExampleStack(theme: theme)
        }
        .background(theme.page.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

#Preview { ZoomSliderExamples() }
