// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// SwatchRole.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// A swatch's place in the 60 · 30 · 10 ratio. Unassigned swatches stay out of
/// the ratio entirely, which is why this is modelled as an optional rather than
/// carrying a `.none` case.
enum SwatchRole: String, CaseIterable, Identifiable, Codable, Sendable {

    case dominant  = "60"
    case secondary = "30"
    case accent    = "10"

    var id: String { rawValue }

    /// Compact form for segmented controls.
    var shortLabel: String { "\(rawValue)%" }

    var label: String {
        switch self {
            case .dominant:  "60% Dominant"
            case .secondary: "30% Secondary"
            case .accent:    "10% Accent"
        }
    }

    var bandCaption: String {
        switch self {
            case .dominant:  "Dominant · grounds the layout"
            case .secondary: "Secondary · structure and type"
            case .accent:    "Accent · one action at a time"
        }
    }

    /// Relative height of this role's band in the 60 · 30 · 10 view.
    var bandWeight: Double {
        switch self {
            case .dominant:  6
            case .secondary: 3
            case .accent:    1
        }
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// Where a swatch's value came from. Surfaced in the inspector so a sampled
/// colour is distinguishable from a typed one.
enum ColorSource: String, CaseIterable, Codable, Sendable {

    case hex
    case picker
    case eyedropper
    case camera
    case mantia
    case harmony
    case pair
    case derived

    var label: String {
        switch self {
            case .hex:        "Hex"
            case .picker:     "Picker"
            case .eyedropper: "Eyedropper"
            case .camera:     "Camera"
            case .mantia:     "Mantia"
            case .harmony:    "Harmony"
            case .pair:       "Pair"
            case .derived:    "Derived"
        }
    }
}
