// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// RuleBandsView.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// The 60 · 30 · 10 proportions, drawn as bands sized to the assigned roles.
struct RuleBandsView: View {

    var palette: Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text(palette.name).font(.title2.bold())

            // flex-grow has no direct SwiftUI equivalent, so the 6 : 3 : 1
            // proportions are measured and applied as explicit heights.
            GeometryReader { geo in
                let gaps = 8 * Double(SwatchRole.allCases.count - 1)
                let available = max(0, geo.size.height - gaps)
                let total = SwatchRole.allCases.reduce(0) { $0 + $1.bandWeight }

                VStack(spacing: 8) {
                    ForEach(SwatchRole.allCases) { role in
                        band(role).frame(height: available * role.bandWeight / total)
                    }
                }
            }
            .frame(minHeight: 360)

            Text("Bands are sized to the annotated roles. Assign a role in the inspector and the proportions follow — unassigned swatches stay out of the ratio.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 620, alignment: .leading)
        }
        .padding()
        .navigationTitle(palette.name)
    }


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    /// Falls back to the first swatch when a role is unassigned — the band
    /// still needs something to show.
    private func swatch(for role: SwatchRole) -> Swatch? {
        palette.swatch(for: role) ?? palette.orderedSwatches.first
    }

    @ViewBuilder
    private func band(_ role: SwatchRole) -> some View {
        if let swatch = swatch(for: role) {
            let hsb = swatch.hsb

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(role.shortLabel).font(.title.bold())
                    Text(role.bandCaption).font(.subheadline)
                }

                Spacer(minLength: 16)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(swatch.name).font(.headline)
                    Text(hsb.hexDisplay).font(.subheadline.monospacedDigit())
                }
            }
            .foregroundStyle(hsb.ink.color)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(hsb.color, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
