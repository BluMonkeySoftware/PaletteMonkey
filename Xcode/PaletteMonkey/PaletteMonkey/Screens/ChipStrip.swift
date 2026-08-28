// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// ChipStrip.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// The palette-at-a-glance strip used in the sidebar and the harmony preview.
struct ChipStrip: View {

    var colors: [HSB]
    var height: CGFloat = 24
    var cornerRadius: CGFloat = 6

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, value in
                Rectangle().fill(value.color)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(.separator, lineWidth: 0.5)
        }
    }
}
