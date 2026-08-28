// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// CollectionsSidebar.swift
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

struct CollectionsSidebar: View {

    var palettes: [Palette]
    @Binding var selection: PersistentIdentifier?
    var onNewPalette: () -> Void

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(palettes) { palette in
                    row(palette)
                        .tag(palette.persistentModelID)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            } header: {
                Text("Collections")
                    .kicker()
                    .padding(.bottom, Theme.space1)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.neutral100)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Rule()
                Button(action: onNewPalette) {
                    Text("+ New palette")
                        .controlLabel(Theme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Theme.space4)
                        .padding(.vertical, Theme.space3)
                }
                .buttonStyle(.plain)
            }
            .background(Theme.neutral100)
        }
    }


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private func row(_ palette: Palette) -> some View {
        let isSelected = palette.persistentModelID == selection

        return VStack(alignment: .leading, spacing: Theme.space2 + 2) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.space2) {
                Text(palette.name)
                    .font(Theme.heading(13, .bold))
                    .tracking(-0.13)
                    .foregroundStyle(Theme.text)

                Spacer(minLength: 0)

                Text(palette.swatchCountLabel)
                    .font(Theme.body(10, .semibold))
                    .tracking(1)
                    .foregroundStyle(Theme.neutral600)
            }

            ChipStrip(colors: palette.orderedSwatches.map(\.hsb))
        }
        .padding(.horizontal, Theme.space4)
        .padding(.top, Theme.space3)
        .padding(.bottom, Theme.space3 + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .leading) {
            // The selected row is a lighter field with an accent bar on the
            // leading edge, rather than a filled highlight.
            ZStack(alignment: .leading) {
                isSelected ? Theme.bg : Color.clear
                if isSelected {
                    Rectangle().fill(Theme.accent).frame(width: 4)
                }
            }
        }
        .overlay(alignment: .top) { Rule() }
        .contentShape(Rectangle())
    }
}
