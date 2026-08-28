// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// Swatch.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation
import SwiftData
import SwiftUI


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// Colour is stored as HSB, not hex.
///
/// Every operation in the app — lattice snapping, harmonies, dark derivation —
/// is an HSB operation, and round-tripping through 8-bit hex loses lattice
/// stops. Hex is a formatted view of this model, not the model.
@Model final class Swatch {

    var name: String = "Untitled"

    var hue: Double = 0         // 0 ..< 360
    var saturation: Double = 0  // 0 ... 1
    var brightness: Double = 0  // 0 ... 1

    var roleRaw: String?
    var sourceRaw: String = ColorSource.hex.rawValue
    var tags: [String] = []
    var note: String = ""
    var sortIndex: Int = 0

    var palette: Palette?

    init(name: String,
         hsb: HSB,
         role: SwatchRole? = nil,
         source: ColorSource = .hex,
         tags: [String] = [],
         note: String = "",
         sortIndex: Int = 0) {

        self.name       = name
        self.hue        = hsb.hue
        self.saturation = hsb.saturation
        self.brightness = hsb.brightness
        self.roleRaw    = role?.rawValue
        self.sourceRaw  = source.rawValue
        self.tags       = tags
        self.note       = note
        self.sortIndex  = sortIndex
    }


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    var hsb: HSB {
        get { HSB(hue: hue, saturation: saturation, brightness: brightness) }
        set {
            hue        = newValue.hue
            saturation = newValue.saturation
            brightness = newValue.brightness
        }
    }

    var role: SwatchRole? {
        get { roleRaw.flatMap(SwatchRole.init(rawValue:)) }
        set { roleRaw = newValue?.rawValue }
    }

    var source: ColorSource {
        get { ColorSource(rawValue: sourceRaw) ?? .hex }
        set { sourceRaw = newValue.rawValue }
    }

    var color: Color { hsb.color }

    var roleLabel: String { role?.label ?? "Unassigned" }

    var displayNote: String { note.isEmpty ? "—" : note }
}
