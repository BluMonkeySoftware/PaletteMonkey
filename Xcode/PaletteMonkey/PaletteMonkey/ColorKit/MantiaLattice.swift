// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// MantiaLattice.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// Quantises a colour onto a fixed lattice: hue stops every `hueStep` degrees,
/// saturation and brightness in `steps` even increments.
///
/// Snapping is the primary action; the grid view is a browser over the same
/// lattice. Off-lattice swatches are flagged rather than silently rewritten, so
/// the correction stays visible and reversible.
struct MantiaLattice: Equatable, Sendable {

    var hueStep: Double = 5
    var steps: Int = 8

    static let `default` = MantiaLattice()

    /// The size of one saturation / brightness increment, in `0 ... 1`.
    var increment: Double { 1 / Double(max(1, steps)) }

    var hueStopCount: Int { Int((360 / hueStep).rounded()) }

    var hueStops: [Double] {
        stride(from: 0, to: 360, by: hueStep).map { $0 }
    }

    func snap(_ value: HSB) -> HSB {
        let inc = increment
        return HSB(hue:        (value.hue / hueStep).rounded() * hueStep,
                   saturation: (value.saturation / inc).rounded() * inc,
                   brightness: (value.brightness / inc).rounded() * inc)
    }

    /// Compares the *rendered* colour rather than raw HSB.
    ///
    /// A swatch entered as hex lands on non-round HSB components — #FFD500 is
    /// hue 50.12°, not 50° — yet snapping it produces the same 8-bit colour.
    /// Comparing HSB directly would flag it as off-lattice and then print
    /// "off stop → #FFD500" next to a swatch already showing #FFD500. The
    /// honest test is whether snapping would actually change anything.
    func isOnStop(_ value: HSB) -> Bool {
        snap(value).hexString == value.hexString
    }

    /// Shortest signed distance around the wheel, for the "Δh" readout.
    func hueDelta(from a: HSB, to b: HSB) -> Double {
        let d = (b.hue - a.hue + 540).truncatingRemainder(dividingBy: 360) - 180
        return abs(d)
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

extension HSB {

    func isApproximately(_ other: HSB, tolerance: Double = 1e-6) -> Bool {
        // Hue is circular: 359.9999 and 0 are the same stop.
        let dh = abs((hue - other.hue + 540).truncatingRemainder(dividingBy: 360) - 180)
        return dh <= tolerance
            && abs(saturation - other.saturation) <= tolerance
            && abs(brightness - other.brightness) <= tolerance
    }
}
