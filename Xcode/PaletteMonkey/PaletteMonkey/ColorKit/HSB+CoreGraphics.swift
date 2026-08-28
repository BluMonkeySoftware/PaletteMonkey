// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// HSB+CoreGraphics.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import CoreGraphics


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// `ColorPicker` speaks `CGColor`. Everything is converted through sRGB on the
/// way in and out, because the picker can hand back a wide-gamut colour on
/// displays that support one and the store is sRGB for now.
extension HSB {

    var cgColor: CGColor {
        let c = rgb
        return CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                       components: [c.red, c.green, c.blue, 1])
            ?? CGColor(gray: 0, alpha: 1)
    }

    init?(cgColor: CGColor) {
        guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = cgColor.converted(to: srgb, intent: .defaultIntent, options: nil),
              let components = converted.components,
              components.count >= 3
        else { return nil }

        self.init(red: Double(components[0]),
                  green: Double(components[1]),
                  blue: Double(components[2]))
    }
}
