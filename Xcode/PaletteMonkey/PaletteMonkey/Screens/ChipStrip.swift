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
    var height: CGFloat = 26
    var bordered: Bool = true

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, value in
                Rectangle()
                    .fill(value.color)
                    .overlay {
                        if bordered {
                            Rectangle().strokeBorder(Theme.neutral300, lineWidth: 1)
                        }
                    }
            }
        }
        .frame(height: height)
    }
}
