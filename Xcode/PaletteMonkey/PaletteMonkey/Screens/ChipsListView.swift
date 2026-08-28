// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// ChipsListView.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI
import SwiftData


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

struct ChipsListView: View {

    var palette: Palette
    var lattice: MantiaLattice
    @Binding var selection: PersistentIdentifier?

    /// The width the three-column row needs before it is worth using.
    ///
    /// Sized against real geometry: an 11-inch iPad is 834 × 1210pt, so with
    /// the sidebar (272) and inspector (344) both open the detail column is
    /// ~594pt in landscape and ~218pt in portrait. Sitting below 594 means
    /// landscape gets the row the design specifies and portrait folds instead.
    /// If it is ever wrong it falls back to the stacked layout, which fits at
    /// any width — the failure mode is a plainer row, never a clipped one.
    private static let wideLayoutThreshold: CGFloat = 560

    /// Narrower than the design's 1fr so the notes column keeps usable width
    /// at 594pt total.
    private static let readoutColumnWidth: CGFloat = 210

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {

                VStack(alignment: .leading, spacing: Theme.space2) {
                    Text("Palette").kicker(Theme.accent700)
                    Text(palette.name)
                        .font(Theme.heading(38))
                        .tracking(-1.14)
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.space8)
                .padding(.top, 28)
                .padding(.bottom, 20)

                Rule()

                ForEach(palette.orderedSwatches) { swatch in
                    row(swatch)
                    Rule()
                }
            }
        }
        .background(Theme.bg)
    }


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private func row(_ swatch: Swatch) -> some View {
        let isSelected = swatch.persistentModelID == selection

        return Button {
            selection = swatch.persistentModelID
        } label: {
            // The layout is chosen from the width actually offered to the row.
            // A GeometryReader on the detail column reports the full window
            // width rather than the column's, which silently picks the wide
            // layout in a 218pt column and pushes the readouts off the edge.
            // ViewThatFits asks the real question: does this fit?
            ViewThatFits(in: .horizontal) {
                wideRow(swatch).frame(minWidth: Self.wideLayoutThreshold)
                narrowRow(swatch)
            }
            .frame(minHeight: 104)
            .background(isSelected ? Theme.accent100 : Theme.bg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func wideRow(_ swatch: Swatch) -> some View {
        HStack(spacing: 0) {
            colorBlock(swatch)

            identity(swatch, isWide: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)

            readouts(swatch)
                .frame(width: Self.readoutColumnWidth, alignment: .leading)
                .padding(.trailing, 20)
                .padding(.vertical, 18)
        }
    }

    private func narrowRow(_ swatch: Swatch) -> some View {
        HStack(spacing: 0) {
            colorBlock(swatch)

            VStack(alignment: .leading, spacing: 10) {
                identity(swatch, isWide: false)
                readouts(swatch)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
    }

    private func colorBlock(_ swatch: Swatch) -> some View {
        Rectangle()
            .fill(swatch.hsb.color)
            .frame(width: 88)
            .overlay(alignment: .trailing) { Rule(axis: .vertical) }
    }

    private func identity(_ swatch: Swatch, isWide: Bool) -> some View {
        // Side by side when there is room; stacked when there is not. A role
        // badge squeezed off the edge of the column reads as a different role,
        // so it never competes with the name for width.
        let nameAndRole: AnyLayout = isWide
            ? AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.space2 + 2))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 6))

        return VStack(alignment: .leading, spacing: 6) {
            nameAndRole {
                Text(swatch.name)
                    .font(Theme.heading(17, .bold))
                    .tracking(-0.17)
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .truncationMode(.tail)

                RoleBadge(role: swatch.role)
                    .fixedSize()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(swatch.displayNote)
                .font(Theme.body(12))
                .foregroundStyle(Theme.neutral600)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func readouts(_ swatch: Swatch) -> some View {
        let hsb = swatch.hsb
        let snapped = lattice.snap(hsb)
        let onStop = lattice.isOnStop(hsb)
        let rgb = hsb.rgb255

        return VStack(alignment: .leading, spacing: Theme.space1) {
            Text(hsb.hexDisplay).tabularFigures(12, .bold).foregroundStyle(Theme.text)
            Text("rgb \(rgb.red) \(rgb.green) \(rgb.blue)")
                .tabularFigures().foregroundStyle(Theme.neutral600)
            Text("hsb \(Int(hsb.hue.rounded()))° \(Int((hsb.saturation * 100).rounded()))% \(Int((hsb.brightness * 100).rounded()))%")
                .tabularFigures().foregroundStyle(Theme.neutral600)
            Text("vs ink \(String(format: "%.2f", hsb.contrastRatio(with: .ink))):1")
                .tabularFigures().foregroundStyle(Theme.neutral600)
            Text(onStop ? "on Mantia stop" : "off stop → \(snapped.hexDisplay)")
                .tabularFigures()
                .foregroundStyle(onStop ? Theme.neutral600 : Theme.accent700)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// Assigned roles read as a filled chip; unassigned as an outline, so the
/// difference is visible without reading the text.
struct RoleBadge: View {

    var role: SwatchRole?

    var body: some View {
        Text(role?.label ?? "Unassigned")
            .font(Theme.body(10, .bold))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(role == nil ? Theme.neutral600 : Theme.bg)
            .padding(.horizontal, Theme.space2)
            .padding(.vertical, Theme.space1)
            .background(role == nil ? Color.clear : Theme.text)
            .overlay { Rectangle().strokeBorder(Theme.divider, lineWidth: Theme.rule) }
    }
}
