// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// SampleData.swift
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

enum SampleData {

    struct Seed {
        var name: String
        var hex: String
        var role: SwatchRole?
        var source: ColorSource
        var tags: [String] = []
        var note: String = ""
    }

    /// The palettes the prototype ships with. "Signal Pair" is deliberately
    /// missing its 30% so the pair-completion panel has something to solve on
    /// first launch.
    static let palettes: [(name: String, swatches: [Seed])] = [

        ("Signal Pair", [
            Seed(name: "Federal Blue", hex: "#005bb5", role: .dominant, source: .hex,
                 tags: ["brand"],
                 note: "Ground and the whole identity. The 30% is still open."),
            Seed(name: "Sign Yellow", hex: "#ffd500", role: .accent, source: .picker,
                 tags: ["brand", "warm"],
                 note: "Accent only — one action per screen.")
        ]),

        ("Studio Warm", [
            Seed(name: "Bone", hex: "#f0ebe2", role: .dominant, source: .hex,
                 note: "Ground for long reading passages. Warm enough to sit beside the reds."),
            Seed(name: "Signal Red", hex: "#ec3013", role: .accent, source: .picker,
                 note: "Primary action only. Never as a field behind body copy."),
            Seed(name: "Ink", hex: "#201e1d", role: .secondary, source: .hex,
                 note: "Type and 2px rules."),
            Seed(name: "Clay", hex: "#b8674a", role: nil, source: .camera,
                 note: "Sampled off a terracotta tile."),
            Seed(name: "Ochre", hex: "#d9a02b", role: nil, source: .eyedropper)
        ]),

        ("Deep Sea", [
            Seed(name: "Abyss", hex: "#0d1f2b", role: .dominant, source: .hex,
                 note: "Dark ground. Test all type at 4.5:1."),
            Seed(name: "Shelf", hex: "#1f6f7a", role: .secondary, source: .picker),
            Seed(name: "Foam", hex: "#d6e8e6", role: nil, source: .hex),
            Seed(name: "Buoy", hex: "#ff7a1a", role: .accent, source: .camera,
                 note: "Only warm note; use for the single accent.")
        ]),

        ("Press Proof", [
            Seed(name: "Newsprint", hex: "#f3f2f2", role: .dominant, source: .hex),
            Seed(name: "Process Black", hex: "#151515", role: .secondary, source: .hex),
            Seed(name: "Rubine", hex: "#ca005d", role: .accent, source: .picker,
                 note: "Mantia-ized from a scanned swatch book."),
            Seed(name: "Cyan", hex: "#0090d6", role: nil, source: .hex),
            Seed(name: "Warm Grey", hex: "#a8a29b", role: nil, source: .eyedropper),
            Seed(name: "Kraft", hex: "#c9a97e", role: nil, source: .camera)
        ])
    ]


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    /// Seeds an empty store. A store that already has palettes is left alone.
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Palette>())) ?? 0
        guard existing == 0 else { return }

        for (name, seeds) in palettes {
            let palette = Palette(name: name)
            context.insert(palette)

            for (index, seed) in seeds.enumerated() {
                guard let hsb = HSB(hex: seed.hex) else { continue }
                let swatch = Swatch(name: seed.name,
                                    hsb: hsb,
                                    role: seed.role,
                                    source: seed.source,
                                    tags: seed.tags,
                                    note: seed.note,
                                    sortIndex: index)
                swatch.palette = palette
                context.insert(swatch)
            }
        }

        try? context.save()
    }
}
