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

/// A titled block with the system's 2pt rule beneath it. Every inspector
/// section is one of these, which is what gives the column its even rhythm.
struct InspectorSection<Content: View>: View {

    var title: String?
    var padding: CGFloat = Theme.space4
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title).kicker().padding(.bottom, Theme.space2 + 2)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .overlay(alignment: .bottom) { Rule() }
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// The system's flat field: a 2pt border, no radius, surface fill.
struct ModernistFieldStyle: TextFieldStyle {

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, Theme.space2)
            .background(Theme.surface)
            .overlay { Rectangle().strokeBorder(Theme.divider, lineWidth: Theme.rule) }
    }
}

extension TextFieldStyle where Self == ModernistFieldStyle {
    static var modernist: ModernistFieldStyle { ModernistFieldStyle() }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// A joined row of segments with shared 2pt borders — the design's segmented
/// control, which is squared off rather than the system's rounded one.
struct SegmentedRow<Item: Hashable>: View {

    var items: [Item]
    var label: (Item) -> String
    var isOn: (Item) -> Bool
    var action: (Item) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Button {
                    action(item)
                } label: {
                    Text(label(item))
                        .font(Theme.body(11, .bold))
                        .tracking(0.66)
                        .foregroundStyle(isOn(item) ? Theme.bg : Theme.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(isOn(item) ? Theme.text : Theme.neutral100)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay { Rectangle().strokeBorder(Theme.divider, lineWidth: Theme.rule) }
            }
        }
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// A wrapping set of toggle chips, used for tags and harmony modes.
struct ChipToggleRow<Item: Hashable>: View {

    var items: [Item]
    var label: (Item) -> String
    var isOn: (Item) -> Bool
    var action: (Item) -> Void

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Button {
                    action(item)
                } label: {
                    Text(label(item))
                        .font(Theme.body(10, .bold))
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(isOn(item) ? Theme.bg : Theme.text)
                        .padding(.horizontal, 10)
                        .padding(.vertical, Theme.space2)
                        .background(isOn(item) ? Theme.text : Theme.neutral100)
                        .overlay { Rectangle().strokeBorder(Theme.divider, lineWidth: Theme.rule) }
                }
                .buttonStyle(.plain)
            }
        }
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// Wrapping row layout — the equivalent of the prototype's `flex-wrap`, which
/// `HStack` has no direct analogue for.
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
                current = Row()
                current.indices = [index]
                current.width = size.width
                current.height = size.height
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
