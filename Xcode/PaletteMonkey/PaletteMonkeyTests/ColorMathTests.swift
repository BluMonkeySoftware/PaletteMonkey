// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// ColorMathTests.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import Testing

@testable import PaletteMonkey


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

@Suite("Hex parsing")
struct HexTests {

    @Test("Six-digit hex round-trips")
    func roundTrip() throws {
        for hex in ["#ec3013", "#005bb5", "#ffd500", "#0d1f2b", "#f3f2f2", "#000000", "#ffffff"] {
            let value = try #require(HSB(hex: hex))
            #expect(value.hexString == hex)
        }
    }

    @Test("Three-digit hex expands")
    func shorthand() throws {
        let short = try #require(HSB(hex: "#f0c"))
        #expect(short.hexString == "#ff00cc")
    }

    @Test("A leading hash is optional")
    func noHash() throws {
        #expect(try #require(HSB(hex: "ec3013")).hexString == "#ec3013")
    }

    @Test("Malformed input is rejected rather than coerced")
    func rejects() {
        for bad in ["", "#", "#12", "#12345", "#gggggg", "not a colour"] {
            #expect(HSB(hex: bad) == nil, "should reject \(bad)")
        }
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

@Suite("HSB")
struct HSBTests {

    @Test("Hue wraps into 0 ..< 360")
    func hueWraps() {
        #expect(HSB(hue: 365, saturation: 1, brightness: 1).hue == 5)
        #expect(HSB(hue: -30, saturation: 1, brightness: 1).hue == 330)
        #expect(HSB(hue: 720, saturation: 1, brightness: 1).hue == 0)
    }

    @Test("Saturation and brightness clamp")
    func clamps() {
        let over = HSB(hue: 0, saturation: 5, brightness: -2)
        #expect(over.saturation == 1)
        #expect(over.brightness == 0)
    }

    @Test("Known conversions land on the expected hue")
    func knownHues() throws {
        #expect(try #require(HSB(hex: "#ff0000")).hue == 0)
        #expect(try #require(HSB(hex: "#00ff00")).hue == 120)
        #expect(try #require(HSB(hex: "#0000ff")).hue == 240)
    }

    @Test("Greys have no saturation")
    func greys() throws {
        let grey = try #require(HSB(hex: "#8c8c8c"))
        #expect(grey.saturation == 0)
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

@Suite("Contrast")
struct ContrastTests {

    @Test("Black on white is the 21:1 maximum")
    func extremes() throws {
        let black = try #require(HSB(hex: "#000000"))
        #expect(abs(black.contrastRatio(with: .white) - 21) < 0.01)
    }

    @Test("A colour against itself is 1:1")
    func identity() throws {
        let value = try #require(HSB(hex: "#1f6f7a"))
        #expect(abs(value.contrastRatio(with: value) - 1) < 1e-9)
    }

    @Test("Ink flips to white only on dark grounds")
    func inkSelection() throws {
        #expect(try #require(HSB(hex: "#0d1f2b")).ink == .white)   // Abyss
        #expect(try #require(HSB(hex: "#f0ebe2")).ink == .ink)     // Bone
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

@Suite("Mantia lattice")
struct LatticeTests {

    let lattice = MantiaLattice.default

    @Test("Snapping is idempotent and lands on a stop")
    func snapping() throws {
        for hex in ["#ec3013", "#005bb5", "#b8674a", "#d9a02b", "#ca005d"] {
            let value = try #require(HSB(hex: hex))
            let once = lattice.snap(value)

            #expect(lattice.isOnStop(once), "\(hex) should be on a stop after snapping")
            #expect(lattice.snap(once).isApproximately(once), "snapping twice should not move it again")
        }
    }

    @Test("Hue lands on a multiple of the step")
    func hueStops() throws {
        let value = try #require(HSB(hex: "#ec3013"))
        let snapped = lattice.snap(value)
        #expect(snapped.hue.truncatingRemainder(dividingBy: lattice.hueStep) == 0)
    }

    @Test("The rail has 72 stops at 5°")
    func railSize() {
        #expect(lattice.hueStops.count == 72)
        #expect(lattice.hueStopCount == 72)
        #expect(lattice.hueStops.first == 0)
        #expect(lattice.hueStops.last == 355)
    }

    @Test("A colour whose snap renders identically counts as on-stop")
    func rendersIdentically() throws {
        // #FFD500 is hue 50.12°, not a round 50° — but snapping it produces
        // the same 8-bit colour, so reporting "off stop → #FFD500" beside a
        // swatch already showing #FFD500 would contradict itself.
        let yellow = try #require(HSB(hex: "#ffd500"))

        #expect(lattice.snap(yellow).hexString == yellow.hexString)
        #expect(lattice.isOnStop(yellow))
    }

    @Test("A genuinely off-lattice colour is still flagged")
    func flagsOffStop() throws {
        let blue = try #require(HSB(hex: "#005bb5"))   // brightness 71%, not an eighth

        #expect(lattice.snap(blue).hexString != blue.hexString)
        #expect(!lattice.isOnStop(blue))
    }

    @Test("Hue delta takes the short way around the wheel")
    func wrapAround() {
        let a = HSB(hue: 358, saturation: 1, brightness: 1)
        let b = HSB(hue: 2, saturation: 1, brightness: 1)
        #expect(lattice.hueDelta(from: a, to: b) == 4)
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

@Suite("Harmonies")
struct HarmonyTests {

    let lattice = MantiaLattice.default

    @Test("Complementary sits opposite the base")
    func complementary() throws {
        let base = try #require(HSB(hex: "#005bb5"))
        let set = Harmony.complementary.set(from: base, lattice: lattice)

        #expect(set.count == 1)
        #expect(abs(lattice.hueDelta(from: base, to: set[0]) - 180) < 0.001)
    }

    @Test("Every mode produces at least one colour")
    func nonEmpty() throws {
        let base = try #require(HSB(hex: "#ec3013"))
        for harmony in Harmony.allCases {
            #expect(!harmony.set(from: base, lattice: lattice).isEmpty, "\(harmony.label) was empty")
        }
    }

    @Test("Mantia 72 walks the whole wheel")
    func mantia72() throws {
        let base = try #require(HSB(hex: "#ec3013"))
        let set = Harmony.mantia72.set(from: base, lattice: lattice)

        #expect(set.count == 72)
        #expect(Set(set.map(\.hue)).count == 72, "every stop should be a distinct hue")
    }

    @Test("Monochrome and shades hold the base hue")
    func holdsHue() throws {
        let base = try #require(HSB(hex: "#1f6f7a"))
        for harmony in [Harmony.monochrome, .shadesAndTints] {
            for value in harmony.set(from: base, lattice: lattice) {
                #expect(value.hue == base.hue, "\(harmony.label) moved the hue")
            }
        }
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

@Suite("Pair completion")
struct PairCompletionTests {

    let lattice = MantiaLattice.default

    /// The seeded "Signal Pair" palette: a 60% and a 10%, no 30%.
    private func signalPair() throws -> [SwatchRole: (name: String, hsb: HSB)] {
        [.dominant: ("Federal Blue", try #require(HSB(hex: "#005bb5"))),
         .accent:   ("Sign Yellow",  try #require(HSB(hex: "#ffd500")))]
    }

    @Test("Two assigned roles identifies the missing one")
    func findsMissing() throws {
        let completion = PairCompletion(assigned: try signalPair(), lattice: lattice)

        #expect(completion.readiness == .ready)
        #expect(completion.missing == .secondary)
        #expect(completion.basis.count == 2)
        #expect(completion.candidates.count == 4)
    }

    @Test("Every candidate is already on the lattice")
    func candidatesSnapped() throws {
        let completion = PairCompletion(assigned: try signalPair(), lattice: lattice)
        for candidate in completion.candidates {
            #expect(lattice.isOnStop(candidate.hsb), "\(candidate.label) is off-lattice")
        }
    }

    @Test("Fewer than two roles is not solvable")
    func needsTwo() throws {
        let one: [SwatchRole: (name: String, hsb: HSB)] =
            [.dominant: ("Only", try #require(HSB(hex: "#005bb5")))]

        let completion = PairCompletion(assigned: one, lattice: lattice)
        #expect(completion.readiness == .needsTwoRoles)
        #expect(completion.candidates.isEmpty)
    }

    @Test("All three assigned leaves nothing to derive")
    func allAssigned() throws {
        var all = try signalPair()
        all[.secondary] = ("Bridge", try #require(HSB(hex: "#7d7979")))

        let completion = PairCompletion(assigned: all, lattice: lattice)
        #expect(completion.readiness == .allAssigned)
        #expect(completion.missing == nil)
    }

    @Test("Arc midpoint crosses zero the short way")
    func arcMidpoint() {
        #expect(PairCompletion.arcMidpoint(350, 10) == 0)
        #expect(PairCompletion.arcMidpoint(0, 90) == 45)
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

@Suite("Dark derivation")
struct DarkVariantTests {

    @Test("A light ground inverts to a dark one")
    func groundInverts() throws {
        let bone = try #require(HSB(hex: "#f0ebe2"))
        #expect(DarkVariant.of(bone, role: .dominant).brightness < 0.35)
    }

    @Test("A dark colour lifts instead of inverting")
    func darkLifts() throws {
        let abyss = try #require(HSB(hex: "#0d1f2b"))
        #expect(DarkVariant.of(abyss, role: .dominant).brightness > abyss.brightness)
    }

    @Test("An accent stays bright enough to read on a dark ground")
    func accentHolds() throws {
        let red = try #require(HSB(hex: "#ec3013"))
        let dark = DarkVariant.of(red, role: .accent)

        #expect(dark.brightness >= 0.52)
        #expect(abs(dark.hue - red.hue) < 0.001, "an accent should keep its hue")
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

@Suite("Export")
struct ExportTests {

    @Test("Display names become lower-camel Swift identifiers")
    func identifiers() {
        #expect(PaletteExport.identifier("Signal Red") == "signalRed")
        #expect(PaletteExport.identifier("Federal Blue") == "federalBlue")
        #expect(PaletteExport.identifier("Ink") == "ink")
        #expect(PaletteExport.identifier("Process  Black") == "processBlack")
    }

    @Test("Punctuation is dropped rather than emitted")
    func punctuation() {
        let identifier = PaletteExport.identifier("60/30 · Warm-Grey!")
        for bad in ["/", "·", "-", "!"] {
            #expect(!identifier.contains(bad), "identifier kept \(bad): \(identifier)")
        }
    }

    @Test("An identifier never leads with a digit")
    func leadingDigit() {
        #expect(PaletteExport.identifier("60 Percent").first?.isNumber == false)
    }

    @Test("An unnamed swatch still yields something usable")
    func empty() {
        #expect(PaletteExport.identifier("") == "color")
        #expect(PaletteExport.identifier("···") == "color")
    }
}
