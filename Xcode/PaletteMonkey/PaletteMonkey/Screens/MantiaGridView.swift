// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// MantiaGridView.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// A browser over the Mantia lattice: pick a hue on the rail, then a
/// saturation × brightness cell, and the selected swatch takes that value.
struct MantiaGridView: View {

    var lattice: MantiaLattice
    var selected: Swatch?
    @Binding var mantiaHue: Double?
    var onPick: (HSB) -> Void

    /// Falls back to the selected swatch's own hue, snapped to the rail.
    private var activeHue: Double {
        if let mantiaHue { return mantiaHue }
        guard let selected else { return 0 }
        return (selected.hsb.hue / lattice.hueStep).rounded() * lattice.hueStep
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 6) {
                    Text("Hue every \(number(lattice.hueStep))°, saturation and brightness in \(lattice.steps)ths")
                        .font(.title2.bold())

                    Text("The Louie Mantia transform quantises a color to a fixed lattice: \(lattice.hueStopCount) hue stops around the wheel, and \(lattice.steps) even steps of saturation and brightness. Pick a hue below, then a cell, and the selected swatch takes that value.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 700, alignment: .leading)
                }

                section("Hue stops · every \(number(lattice.hueStep))°") { hueRail }

                section("Saturation × brightness · hue \(number(activeHue))°") {
                    grid.frame(maxWidth: 560, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            content()
        }
    }

    private var hueRail: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 24), spacing: 3) {
            ForEach(lattice.hueStops, id: \.self) { stop in
                let value = HSB(hue: stop, saturation: 0.90, brightness: 0.95)
                Button { mantiaHue = stop } label: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(value.color)
                        .frame(height: 24)
                        .overlay { selectionRing(isOn: stop == activeHue, cornerRadius: 4) }
                }
                .buttonStyle(.plain)
                .help("\(number(stop))°")
            }
        }
    }

    private var grid: some View {
        VStack(spacing: 3) {
            ForEach(0 ..< lattice.steps, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0 ..< lattice.steps, id: \.self) { column in
                        cell(row: row, column: column)
                    }
                }
            }
        }
    }

    private func cell(row: Int, column: Int) -> some View {
        let inc = lattice.increment
        let value = HSB(hue: activeHue,
                        saturation: Double(column + 1) * inc,
                        brightness: 1 - Double(row) * inc)
        let isCurrent = selected.map { value.isApproximately($0.hsb) } ?? false

        return Button { onPick(value) } label: {
            RoundedRectangle(cornerRadius: 6)
                .fill(value.color)
                .aspectRatio(1, contentMode: .fit)
                .overlay { selectionRing(isOn: isCurrent, cornerRadius: 6) }
        }
        .buttonStyle(.plain)
        .help("\(value.hexDisplay) · s\(Int((value.saturation * 100).rounded())) b\(Int((value.brightness * 100).rounded()))")
    }

    /// Drawn in the accent colour rather than ink, so it stays visible on both
    /// dark and light cells.
    @ViewBuilder
    private func selectionRing(isOn: Bool, cornerRadius: CGFloat) -> some View {
        if isOn {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color.accentColor, lineWidth: 3)
        }
    }

    private func number(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}
