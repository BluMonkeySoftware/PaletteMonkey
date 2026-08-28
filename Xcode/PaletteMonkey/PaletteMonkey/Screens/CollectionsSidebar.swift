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
            ForEach(palettes) { palette in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(palette.name).font(.headline)
                        Spacer(minLength: 8)
                        Text(palette.swatchCountLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ChipStrip(colors: palette.orderedSwatches.map(\.hsb))
                }
                .padding(.vertical, 4)
                .tag(palette.persistentModelID)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button("New Palette", systemImage: "plus", action: onNewPalette)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
        }
    }
}
