// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// InspectorControls.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// A wrapping set of toggle chips, used for tags and harmony modes.
///
/// Selection is carried by the standard bordered / bordered-prominent button
/// styles, so the chips pick up the app's accent colour and the platform's own
/// pressed and disabled treatments.
struct ChipToggleRow<Item: Hashable>: View {

    var items: [Item]
    var label: (Item) -> String
    var isOn: (Item) -> Bool
    var action: (Item) -> Void

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                chip(item)
            }
        }
    }

    /// Branching on the style rather than type-erasing it: `.buttonStyle` is
    /// generic, so the two cases cannot be selected with a ternary.
    @ViewBuilder
    private func chip(_ item: Item) -> some View {
        let title = label(item)

        if isOn(item) {
            Button(title) { action(item) }
                .font(.caption)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
        } else {
            Button(title) { action(item) }
                .font(.caption)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(.secondary)
        }
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// Wrapping row layout — the equivalent of CSS `flex-wrap`, which `HStack` has
/// no direct analogue for.
struct FlowLayout: Layout {

    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = arrange(subviews: subviews, width: width)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(subviews: subviews, width: bounds.width)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y),
                                      anchor: .topLeading,
                                      proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width

            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row(indices: [index], width: size.width, height: size.height)
            } else {
                current.indices.append(index)
                current.width = needed
                current.height = max(current.height, size.height)
            }
        }

        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// A colour well with the system's rounded-rectangle shape.
struct SwatchWell: View {

    var hsb: HSB
    var size: CGFloat? = nil
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(hsb.color)
            .frame(width: size, height: size)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.separator, lineWidth: 0.5)
            }
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// The swatch's 60 · 30 · 10 role, as a standard tag.
struct RoleBadge: View {

    var role: SwatchRole?

    var body: some View {
        Text(role?.label ?? "Unassigned")
            .font(.caption2.weight(.medium))
            .foregroundStyle(role == nil ? .secondary : Color.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(role == nil ? AnyShapeStyle(.quaternary)
                                           : AnyShapeStyle(Color.accentColor.opacity(0.15)))
            )
    }
}

