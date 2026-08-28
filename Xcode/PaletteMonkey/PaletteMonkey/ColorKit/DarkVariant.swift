// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// DarkVariant.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

enum DarkVariant {

    /// Accents hold, grounds invert, mid-tones lift.
    ///
    /// Derivation produces a sibling palette rather than mutating the original,
    /// so the light and dark sets export together as one appearance pair.
    static func of(_ value: HSB, role: SwatchRole?) -> HSB {

        // An accent has to stay the loud one in either appearance, so it keeps
        // its hue and chroma and only gains enough brightness to clear a dark ground.
        if role == .accent {
            return HSB(hue: value.hue,
                       saturation: min(1, value.saturation * 0.94),
                       brightness: min(0.96, max(0.52, value.brightness * 1.04)))
        }

        // A light ground inverts to a dark one, gaining a little chroma so it
        // does not read as flat grey.
        if value.brightness > 0.62 {
            return HSB(hue: value.hue,
                       saturation: min(1, value.saturation * 1.12 + 0.04),
                       brightness: max(0.09, 0.30 - (value.brightness - 0.62) * 0.22))
        }

        // Everything already dark lifts instead, or it would vanish against the
        // inverted ground.
        return HSB(hue: value.hue,
                   saturation: max(0.08, value.saturation * 0.86),
                   brightness: min(0.92, value.brightness + 0.26))
    }
}
