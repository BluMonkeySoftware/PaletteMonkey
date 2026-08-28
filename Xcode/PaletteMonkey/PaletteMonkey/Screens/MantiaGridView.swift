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
            VStack(alignment: .leading, spacing: 0) {

                Text("Mantia transform").kicker(Theme.accent700)

                Text("Hue every \(number(lattice.hueStep))°, saturation and brightness in \(lattice.steps)ths")
                    .font(Theme.heading(34))
                    .tracking(-1.02)
                    .foregroundStyle(Theme.text)
                    .padding(.top, Theme.space2)
                    .padding(.bottom, 6)

                Text("The Louie Mantia transform quantises a color to a fixed lattice: \(lattice.hueStopCount) hue stops around the wheel, and \(lattice.steps) even steps of saturation and brightness. Pick a hue below, then a cell, and the selected swatch takes that value.")
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.neutral700)
                    .lineSpacing(4)
                    .frame(maxWidth: 700, alignment: .leading)

                Rule().padding(.top, 22).padding(.bottom, Theme.space4)

                Text("Hue stops · every \(number(lattice.hueStep))°").kicker()
                    .padding(.bottom, Theme.space2)

                hueRail

                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text("Saturation × brightness · ⅛ of 100%").kicker()
                    Text("hue \(number(activeHue))°")
                        .tabularFigures(11)
                        .foregroundStyle(Theme.neutral600)
                }
                .padding(.top, Theme.space6)
                .padding(.bottom, Theme.space2)

                grid
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.space8)
        }
        .background(Theme.bg)
    }


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var hueRail: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 24), spacing: 2) {
            ForEach(lattice.hueStops, id: \.self) { stop in
                let value = HSB(hue: stop, saturation: 0.90, brightness: 0.95)
                Button {
                    mantiaHue = stop
                } label: {
                    Rectangle()
                        .fill(value.color)
                        .frame(height: 22)
                        .overlay {
                            if stop == activeHue {
                                Rectangle().strokeBorder(Theme.text, lineWidth: 3)
                            }
                        }
                }
                .buttonStyle(.plain)
                .help("\(number(stop))°")
            }
        }
        .padding(2)
        .overlay { Rectangle().strokeBorder(Theme.divider, lineWidth: Theme.rule) }
    }

    private var grid: some View {
        VStack(spacing: 2) {
            ForEach(0 ..< lattice.steps, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0 ..< lattice.steps, id: \.self) { column in
                        cell(row: row, column: column)
                    }
                }
            }
        }
        .padding(2)
        .overlay { Rectangle().strokeBorder(Theme.divider, lineWidth: Theme.rule) }
        .frame(maxWidth: 560, alignment: .leading)
    }

    private func cell(row: Int, column: Int) -> some View {
        let inc = lattice.increment
        let value = HSB(hue: activeHue,
                        saturation: Double(column + 1) * inc,
                        brightness: 1 - Double(row) * inc)
        let isCurrent = selected.map { value.isApproximately($0.hsb) } ?? false

        return Button {
            onPick(value)
        } label: {
            Rectangle()
                .fill(value.color)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if isCurrent {
                        Rectangle().strokeBorder(Theme.text, lineWidth: 3)
                    }
                }
        }
        .buttonStyle(.plain)
        .help("\(value.hexDisplay) · s\(Int((value.saturation * 100).rounded())) b\(Int((value.brightness * 100).rounded()))")
    }

    private func number(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}
