//
//  ExamplesLight.swift
//  ZoomSliderDemo
//
//  Author: ismnoiet
//  Minimum supported: iOS 17 (macOS 14, visionOS 1)
//
//  Light-theme demos, same layout as the dark ones. Open Package.swift in Xcode, pick the
//  ZoomSliderDemo scheme and use the canvas (or call `ZoomSliderExamplesLight()`).
//
import SwiftUI

public struct ZoomSliderExamplesLight: View {
    public init() {}

    public var body: some View {
        let theme = DemoTheme(dark: false)
        ScrollView(showsIndicators: false) {
            ExampleStack(theme: theme)
        }
        .background(theme.page.ignoresSafeArea())
        .preferredColorScheme(.light)
    }
}

#Preview { ZoomSliderExamplesLight() }
