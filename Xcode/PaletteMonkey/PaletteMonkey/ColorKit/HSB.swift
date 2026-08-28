// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// HSB.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// The canonical colour value for the whole app.
///
/// Every feature here — Mantia snapping, harmonies, dark derivation — is an HSB
/// operation, so HSB is what gets stored. Hex is a formatted view of this, never
/// the source of truth: round-tripping through 8-bit hex loses lattice stops.
struct HSB: Equatable, Hashable, Codable, Sendable {

    /// Degrees, normalised to `0 ..< 360`.
    var hue: Double
    /// `0 ... 1`
    var saturation: Double
    /// `0 ... 1`
    var brightness: Double

    init(hue: Double, saturation: Double, brightness: Double) {
        self.hue        = HSB.normalizedHue(hue)
        self.saturation = saturation.clamped(to: 0 ... 1)
        self.brightness = brightness.clamped(to: 0 ... 1)
    }

    static func normalizedHue(_ h: Double) -> Double {
        guard h.isFinite else { return 0 }
        let wrapped = h.truncatingRemainder(dividingBy: 360)
        return wrapped < 0 ? wrapped + 360 : wrapped
    }
}


// MARK: - RGB bridging
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

extension HSB {

    /// Components in `0 ... 1`.
    var rgb: (red: Double, green: Double, blue: Double) {
        let c = brightness * saturation
        let x = c * (1 - abs((hue / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = brightness - c

        let (r, g, b): (Double, Double, Double)
        switch Int(hue / 60) % 6 {
            case 0:  (r, g, b) = (c, x, 0)
            case 1:  (r, g, b) = (x, c, 0)
            case 2:  (r, g, b) = (0, c, x)
            case 3:  (r, g, b) = (0, x, c)
            case 4:  (r, g, b) = (x, 0, c)
            default: (r, g, b) = (c, 0, x)
        }
        return (r + m, g + m, b + m)
    }

    var rgb255: (red: Int, green: Int, blue: Int) {
        let c = rgb
        func byte(_ v: Double) -> Int { Int((v * 255).rounded()).clamped(to: 0 ... 255) }
        return (byte(c.red), byte(c.green), byte(c.blue))
    }

    init(red: Double, green: Double, blue: Double) {
        let mx = max(red, green, blue)
        let mn = min(red, green, blue)
        let d  = mx - mn

        var h = 0.0
        if d != 0 {
            if mx == red {
                h = ((green - blue) / d).truncatingRemainder(dividingBy: 6)
            } else if mx == green {
                h = (blue - red) / d + 2
            } else {
                h = (red - green) / d + 4
            }
            h *= 60
        }

        self.init(hue: h, saturation: mx == 0 ? 0 : d / mx, brightness: mx)
    }
}


// MARK: - Hex
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

extension HSB {

    /// Accepts 3- and 6-digit forms, with or without a leading `#`.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if s.hasPrefix("#") { s.removeFirst() }

        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        guard s.count == 6, let n = UInt32(s, radix: 16) else { return nil }

        self.init(red:   Double((n >> 16) & 0xFF) / 255,
                  green: Double((n >>  8) & 0xFF) / 255,
                  blue:  Double( n        & 0xFF) / 255)
    }

    var hexString: String {
        let c = rgb255
        return String(format: "#%02x%02x%02x", c.red, c.green, c.blue)
    }

    var hexDisplay: String { hexString.uppercased() }
}


// MARK: - Contrast
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

extension HSB {

    /// WCAG relative luminance.
    var relativeLuminance: Double {
        let c = rgb
        func linear(_ v: Double) -> Double {
            v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(c.red) + 0.7152 * linear(c.green) + 0.0722 * linear(c.blue)
    }

    /// WCAG contrast ratio, always >= 1.
    func contrastRatio(with other: HSB) -> Double {
        let a = relativeLuminance, b = other.relativeLuminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// Legible ink for text drawn on top of this colour.
    var ink: HSB {
        contrastRatio(with: .white) >= 4.0 ? .white : .ink
    }

    static let white = HSB(hue: 0, saturation: 0, brightness: 1)
    static let ink   = HSB(hex: "#201e1d")!
}


// MARK: - OKLCH
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

extension HSB {

    /// Perceptual readout. `l` is a percentage, `c` is chroma, `h` is degrees.
    var oklch: (l: Double, c: Double, h: Double) {
        let comps = rgb
        func linear(_ v: Double) -> Double {
            v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        let r = linear(comps.red), g = linear(comps.green), b = linear(comps.blue)

        let l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
        let m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
        let s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)

        let L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
        let A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
        let B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s

        var h = atan2(B, A) * 180 / .pi
        if h < 0 { h += 360 }

        return (l: L * 100, c: (A * A + B * B).squareRoot(), h: h)
    }
}


// MARK: - SwiftUI
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

extension HSB {
    var color: Color {
        Color(hue: hue / 360, saturation: saturation, brightness: brightness)
    }
}

extension Color {
    init(_ hsb: HSB) { self = hsb.color }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
