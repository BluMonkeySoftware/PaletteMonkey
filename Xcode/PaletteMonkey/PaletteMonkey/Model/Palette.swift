// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// Palette.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation
import SwiftData


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// Properties are all defaulted and the relationship is optional so the store
/// stays CloudKit-compatible: CloudKit rejects `@Attribute(.unique)` and any
/// non-optional inverse.
@Model final class Palette {

    var name: String = "Untitled"
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \Swatch.palette)
    var swatches: [Swatch]? = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    /// SwiftData relationships are unordered, so presentation order comes from
    /// an explicit index rather than insertion order.
    var orderedSwatches: [Swatch] {
        (swatches ?? []).sorted { $0.sortIndex < $1.sortIndex }
    }

    var swatchCountLabel: String {
        let n = swatches?.count ?? 0
        return "\(n) \(n == 1 ? "color" : "colors")"
    }

    func swatch(for role: SwatchRole) -> Swatch? {
        orderedSwatches.first { $0.role == role }
    }

    /// Role → swatch, for the pair-completion formulas.
    var assignedRoles: [SwatchRole: (name: String, hsb: HSB)] {
        var out: [SwatchRole: (name: String, hsb: HSB)] = [:]
        for swatch in orderedSwatches {
            guard let role = swatch.role, out[role] == nil else { continue }
            out[role] = (swatch.name, swatch.hsb)
        }
        return out
    }

    var nextSortIndex: Int { (swatches?.map(\.sortIndex).max() ?? -1) + 1 }
}
