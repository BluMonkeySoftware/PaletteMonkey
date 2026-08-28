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
        VStack(alignment: .leading, spacing: 0) {

            Text("60 · 30 · 10").kicker(Theme.accent700)

            Text(palette.name)
                .font(Theme.heading(34))
                .tracking(-1.02)
                .foregroundStyle(Theme.text)
                .padding(.top, Theme.space2)
                .padding(.bottom, 22)

            // flex-grow has no direct SwiftUI equivalent, so the 6 : 3 : 1
            // proportions are measured and applied as explicit heights.
            GeometryReader { geo in
                let gaps = Theme.rule * Double(SwatchRole.allCases.count - 1)
                let available = max(0, geo.size.height - gaps)
                let total = SwatchRole.allCases.reduce(0) { $0 + $1.bandWeight }

                VStack(spacing: Theme.rule) {
                    ForEach(SwatchRole.allCases) { role in
                        band(role)
                            .frame(height: available * role.bandWeight / total)
                    }
                }
            }
            .background(Theme.divider)
            .overlay { Rectangle().strokeBorder(Theme.divider, lineWidth: Theme.rule) }
            .frame(minHeight: 360)

            Text("Bands are sized to the annotated roles. Assign a role in the inspector and the proportions follow — unassigned swatches stay out of the ratio.")
                .font(Theme.body(12))
                .foregroundStyle(Theme.neutral600)
                .lineSpacing(4)
                .frame(maxWidth: 620, alignment: .leading)
                .padding(.top, 18)
        }
        .padding(Theme.space8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bg)
    }


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    /// Falls back to the first swatch when a role is unassigned, matching the
    /// prototype — the band still needs something to show.
    private func swatch(for role: SwatchRole) -> Swatch? {
        palette.swatch(for: role) ?? palette.orderedSwatches.first
    }

    @ViewBuilder
    private func band(_ role: SwatchRole) -> some View {
        if let swatch = swatch(for: role) {
            let hsb = swatch.hsb
            let ink = hsb.ink.color

            HStack(alignment: .top, spacing: Theme.space4) {
                VStack(alignment: .leading, spacing: Theme.space1) {
                    Text(role.shortLabel)
                        .font(Theme.heading(26))
                        .tracking(-0.52)
                    Text(role.bandCaption)
                        .font(Theme.body(11, .semibold))
                        .tracking(1.32)
                        .textCase(.uppercase)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: Theme.space1) {
                    Text(swatch.name).font(Theme.body(13, .bold))
                    Text(hsb.hexDisplay).tabularFigures()
                }
            }
            .foregroundStyle(ink)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(hsb.color)
            .clipped()
        }
    }
}
