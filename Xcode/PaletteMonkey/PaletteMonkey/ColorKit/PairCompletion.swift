// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// PairCompletion.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// Completes a 60 · 30 · 10 set from the two roles that *are* assigned.
///
/// With exactly two roles fixed, the third is a derivation rather than a guess:
/// each candidate is a different defensible reading of the pair, and all of them
/// are snapped to the lattice before being offered.
struct PairCompletion {

    struct Basis: Identifiable {
        var id: String { role.rawValue }
        var role: SwatchRole
        var name: String
        var hsb: HSB
    }

    struct Candidate: Identifiable {
        var id: String { label }
        var label: String
        var note: String
        var hsb: HSB
    }

    enum Readiness { case ready, allAssigned, needsTwoRoles }

    var readiness: Readiness
    var missing: SwatchRole?
    var basis: [Basis]
    var candidates: [Candidate]


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    /// - Parameter assigned: role → (name, value) for every role currently set.
    init(assigned: [SwatchRole: (name: String, hsb: HSB)], lattice: MantiaLattice) {

        let order = SwatchRole.allCases
        let present = order.filter { assigned[$0] != nil }
        let basis = present.map { Basis(role: $0, name: assigned[$0]!.name, hsb: assigned[$0]!.hsb) }

        guard present.count == 2, let missing = order.first(where: { assigned[$0] == nil }) else {
            self.readiness  = present.count == 3 ? .allAssigned : .needsTwoRoles
            self.missing    = nil
            self.basis      = basis
            self.candidates = []
            return
        }

        let a = basis[0].hsb
        let b = basis[1].hsb

        let mid = PairCompletion.arcMidpoint(a.hue, b.hue)
        let far = (mid + 180).truncatingRemainder(dividingBy: 360)
        let meanS = (a.saturation + b.saturation) / 2
        let meanB = (a.brightness + b.brightness) / 2

        let raw: [Candidate]
        switch missing {

            case .secondary:
                raw = [
                    Candidate(label: "Hue bridge",
                              note: "Midpoint of the two hues, mean S and B — reads as related to both.",
                              hsb: HSB(hue: mid, saturation: meanS, brightness: meanB)),
                    Candidate(label: "Muted bridge",
                              note: "Same hue, saturation cut to 45% so it can carry large areas of structure.",
                              hsb: HSB(hue: mid,
                                       saturation: max(0.10, meanS * 0.45),
                                       brightness: a.brightness > 0.55 ? max(0.22, meanB * 0.55)
                                                                       : min(0.88, meanB * 1.35))),
                    Candidate(label: "Far bridge",
                              note: "Opposite the midpoint — separates the pair instead of blending them.",
                              hsb: HSB(hue: far, saturation: max(0.18, meanS * 0.7), brightness: meanB)),
                    Candidate(label: "Dominant tone",
                              note: "The 60% hue held, brightness stepped toward the accent for a tonal secondary.",
                              hsb: HSB(hue: a.hue,
                                       saturation: min(1, a.saturation * 0.9),
                                       brightness: a.brightness > 0.55 ? max(0.20, a.brightness - 0.34)
                                                                       : min(0.92, a.brightness + 0.34)))
                ]

            case .dominant:
                raw = [
                    Candidate(label: "Secondary tint",
                              note: "The 30% hue at 10% saturation, near-white — a ground that stays in family.",
                              hsb: HSB(hue: a.hue, saturation: 0.10, brightness: 0.96)),
                    Candidate(label: "Secondary shade",
                              note: "Same hue held very dark, for a dark-mode ground.",
                              hsb: HSB(hue: a.hue, saturation: min(0.60, a.saturation * 0.8), brightness: 0.12)),
                    Candidate(label: "Bridge tint",
                              note: "Midpoint hue, barely tinted — neutral but not grey.",
                              hsb: HSB(hue: mid, saturation: 0.07, brightness: 0.95)),
                    Candidate(label: "Accent-warmed grey",
                              note: "A grey pulled 6% toward the accent hue so the accent looks intentional.",
                              hsb: HSB(hue: b.hue, saturation: 0.06, brightness: 0.93))
                ]

            case .accent:
                raw = [
                    Candidate(label: "Complement",
                              note: "Opposite the 60% hue at full chroma — the loudest legitimate accent.",
                              hsb: HSB(hue: a.hue + 180,
                                       saturation: max(0.70, a.saturation * 1.4),
                                       brightness: max(0.62, min(0.92, a.brightness * 1.2)))),
                    Candidate(label: "Split accent",
                              note: "30° off the complement, biased toward the secondary — less shrill.",
                              hsb: HSB(hue: PairCompletion.arcMidpoint(a.hue + 180, b.hue),
                                       saturation: max(0.65, meanS * 1.3),
                                       brightness: max(0.60, meanB * 1.15))),
                    Candidate(label: "Warm signal",
                              note: "Fixed warm signal hue at high chroma, ignoring the pair — reads as an alarm.",
                              hsb: HSB(hue: (a.hue > 40 && a.hue < 200) ? 18 : 48,
                                       saturation: 0.92, brightness: 0.88)),
                    Candidate(label: "Far bridge",
                              note: "Opposite the pair's midpoint, pushed to accent chroma.",
                              hsb: HSB(hue: far,
                                       saturation: max(0.72, meanS * 1.35),
                                       brightness: max(0.64, meanB * 1.1)))
                ]
        }

        self.readiness  = .ready
        self.missing    = missing
        self.basis      = basis
        self.candidates = raw.map { Candidate(label: $0.label, note: $0.note, hsb: lattice.snap($0.hsb)) }
    }


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    /// Midpoint along the *shorter* arc between two hues.
    static func arcMidpoint(_ h1: Double, _ h2: Double) -> Double {
        let d = (h2 - h1 + 540).truncatingRemainder(dividingBy: 360) - 180
        return HSB.normalizedHue(h1 + d / 2)
    }
}
