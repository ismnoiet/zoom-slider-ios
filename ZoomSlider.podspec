Pod::Spec.new do |s|
  s.name         = "ZoomSlider"
  s.version      = "1.0.0"
  s.summary      = "A SwiftUI slider for picking a number from a long range: press the pill to open a zoom bubble and spread the ticks under your finger."
  s.homepage     = "https://github.com/ismnoiet/zoom-slider-ios"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "ismnoiet" => "ismnoiet" }

  # sensoryFeedback and onChange(initial:) require iOS 17+
  s.platform     = :ios, "17.0"
  s.swift_version = "5.9"

  s.source       = {
    :git => "https://github.com/ismnoiet/zoom-slider-ios.git",
    :tag => "#{s.version}"
  }

  s.source_files = "Sources/ZoomSlider/**/*.swift"
  s.frameworks   = "SwiftUI"
end
