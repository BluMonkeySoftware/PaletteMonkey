// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// PaletteEditing.swift
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

/// Mutations live here rather than in the views, so the screens stay
/// presentation-only and every edit is registered against the model context's
/// undo manager in one place.
extension ModelContext {

    @discardableResult
    func append(_ swatch: Swatch, to palette: Palette) -> Swatch {
        swatch.sortIndex = palette.nextSortIndex
        swatch.palette = palette
        insert(swatch)
        return swatch
    }

    @discardableResult
    func addSwatch(to palette: Palette) -> Swatch {
        append(Swatch(name: "Untitled",
                      hsb: HSB(hex: "#8c8c8c")!,
                      source: .hex),
               to: palette)
    }

    @discardableResult
    func newPalette() -> Palette {
        let palette = Palette(name: "New Palette")
        insert(palette)
        append(Swatch(name: "Base", hsb: HSB(hex: "#ec3013")!, role: .dominant, source: .hex),
               to: palette)
        return palette
    }

    /// Derivation creates a sibling palette rather than mutating the original,
    /// so the light and dark sets export together as one appearance pair.
    @discardableResult
    func deriveDark(from palette: Palette) -> Palette {
        let baseName = palette.name.replacingOccurrences(of: " dark",
                                                         with: "",
                                                         options: [.caseInsensitive, .anchored,
                                                                   .backwards])
        let dark = Palette(name: "\(baseName) Dark")
        insert(dark)

        for swatch in palette.orderedSwatches {
            let derived = Swatch(name: swatch.name,
                                 hsb: DarkVariant.of(swatch.hsb, role: swatch.role),
                                 role: swatch.role,
                                 source: .derived,
                                 tags: swatch.tags,
                                 note: swatch.note.isEmpty
                                     ? "Dark variant of \(swatch.name)."
                                     : "\(swatch.note) — dark variant.",
                                 sortIndex: swatch.sortIndex)
            derived.palette = dark
            insert(derived)
        }
        return dark
    }

    @discardableResult
    func appendHarmony(_ harmony: Harmony,
                       from swatch: Swatch,
                       in palette: Palette,
                       lattice: MantiaLattice) -> Swatch? {

        let set = harmony.set(from: swatch.hsb, lattice: lattice)
        var first: Swatch?

        for (index, value) in set.enumerated() {
            let new = append(Swatch(name: "\(harmony.label) \(index + 1)",
                                    hsb: value,
                                    source: .harmony,
                                    note: "Derived from \(swatch.name)."),
                             to: palette)
            if first == nil { first = new }
        }
        return first
    }

    @discardableResult
    func appendPairCandidate(_ candidate: PairCompletion.Candidate,
                             role: SwatchRole,
                             to palette: Palette) -> Swatch {
        append(Swatch(name: candidate.label,
                      hsb: candidate.hsb,
                      role: role,
                      source: .pair,
                      tags: ["derived"],
                      note: candidate.note),
               to: palette)
    }

    /// Refuses to empty a palette — the inspector always needs a subject.
    func removeSwatch(_ swatch: Swatch, from palette: Palette) -> Bool {
        guard palette.orderedSwatches.count > 1 else { return false }
        delete(swatch)
        return true
    }
}
