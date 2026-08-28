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

    var body: some View {
        List(selection: $selection) {
            // The mode picker occupies the toolbar's principal slot, which is
            // where the navigation title would otherwise appear — so the
            // palette names itself here.
            Section(palette.name) {
                ForEach(palette.orderedSwatches) { swatch in
                    row(swatch).tag(swatch.persistentModelID)
                }
            }
        }
    }


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    /// One layout at every width, deliberately.
    ///
    /// The prototype puts the readouts in their own column, and a width-keyed
    /// switch to reproduce that was tried twice and misfired both times: on a
    /// portrait iPad the inspector presents as a floating *overlay* rather than
    /// a column, so the detail view still measures its full width and the
    /// readouts column lands underneath the panel — present in the layout,
    /// invisible on screen. No width the row can observe distinguishes "wide"
    /// from "wide but half-covered". Stacking always is correct at every size.
    private func row(_ swatch: Swatch) -> some View {
        HStack(alignment: .top, spacing: 16) {
            SwatchWell(hsb: swatch.hsb, size: 56, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 8) {
                identity(swatch)
                readouts(swatch)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
    }

    private func identity(_ swatch: Swatch) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(swatch.name).font(.headline).lineLimit(1)
                RoleBadge(role: swatch.role).fixedSize()
            }
            Text(swatch.displayNote)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func readouts(_ swatch: Swatch) -> some View {
        let hsb = swatch.hsb
        let snapped = lattice.snap(hsb)
        let onStop = lattice.isOnStop(hsb)
        let rgb = hsb.rgb255

        return VStack(alignment: .leading, spacing: 2) {
            Text(hsb.hexDisplay).font(.subheadline.monospacedDigit().weight(.medium))
            Text("rgb \(rgb.red) \(rgb.green) \(rgb.blue)")
            Text("hsb \(Int(hsb.hue.rounded()))° \(Int((hsb.saturation * 100).rounded()))% \(Int((hsb.brightness * 100).rounded()))%")
            Text("vs ink \(String(format: "%.2f", hsb.contrastRatio(with: .ink))):1")
            Text(onStop ? "on Mantia stop" : "off stop → \(snapped.hexDisplay)")
                .foregroundStyle(onStop ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.accentColor))
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}
