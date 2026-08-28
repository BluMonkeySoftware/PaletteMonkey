// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// Harmony.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// Sets of colours derived from one base swatch.
enum Harmony: String, CaseIterable, Identifiable, Sendable {

    case complementary
    case splitComplementary
    case analogous
    case triadic
    case tetradic
    case monochrome
    case shadesAndTints
    case mantia72

    var id: String { rawValue }

    var label: String {
        switch self {
            case .complementary:      "Complementary"
            case .splitComplementary: "Split-comp"
            case .analogous:          "Analogous"
            case .triadic:            "Triadic"
            case .tetradic:           "Tetradic"
            case .monochrome:         "Monochrome"
            case .shadesAndTints:     "Shades/tints"
            case .mantia72:           "Mantia 72"
        }
    }

    /// Hue offsets in degrees. Empty for the modes that vary S and B instead.
    var hueOffsets: [Double] {
        switch self {
            case .complementary:      [180]
            case .splitComplementary: [150, 210]
            case .analogous:          [-30, 30]
            case .triadic:            [120, 240]
            case .tetradic:           [90, 180, 270]
            case .monochrome:         [0, 0, 0]
            case .shadesAndTints:     [0, 0, 0, 0]
            case .mantia72:           []
        }
    }


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    func set(from base: HSB, lattice: MantiaLattice) -> [HSB] {
        switch self {
            case .mantia72:
                // Walk the whole wheel at the lattice's own S and B stop.
                let snapped = lattice.snap(base)
                let inc = lattice.increment
                let s = snapped.saturation == 0 ? inc : snapped.saturation
                let b = snapped.brightness == 0 ? inc * 4 : snapped.brightness
                return lattice.hueStops.map { HSB(hue: $0, saturation: s, brightness: b) }

            case .shadesAndTints:
                // Fixed brightness ladder; the light end desaturates so tints
                // do not read as washed-out versions of the same chip.
                return [0.86, 0.66, 0.44, 0.24].map { b in
                    HSB(hue: base.hue,
                        saturation: max(0.10, base.saturation - (b > 0.60 ? 0.18 : 0)),
                        brightness: b)
                }

            case .monochrome:
                return hueOffsets.enumerated().map { index, _ in
                    HSB(hue: base.hue,
                        saturation: max(0.08, base.saturation - Double(index) * 0.14),
                        brightness: min(0.96, max(0.14, base.brightness + (Double(index) - 1) * 0.24)))
                }

            default:
                return hueOffsets.map {
                    HSB(hue: base.hue + $0, saturation: base.saturation, brightness: base.brightness)
                }
        }
    }
}
