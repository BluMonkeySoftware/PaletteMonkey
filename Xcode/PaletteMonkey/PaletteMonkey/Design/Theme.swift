// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// Theme.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// Tokens from the Modernist design system.
///
/// The system is deliberately flat: every radius is 0 and structure is carried
/// by 2px rules rather than shadow or rounding. Micro-labels are uppercase with
/// wide tracking; headings are heavy and tightly tracked.
///
/// The system specifies Archivo, which is not a system face on iPadOS or macOS.
/// Rather than bundle a webfont, headings map onto the system face at matching
/// weights — both are grotesques, so proportion and colour survive the swap.
enum Theme {

    // MARK: Ground

    static let bg      = Color(hex: 0xF3F2F2)
    static let surface = Color(hex: 0xEAE9E9)
    static let text    = Color(hex: 0x201E1D)
    static let accent  = Color(hex: 0xEC3013)

    /// 40% ink, so rules read as structure rather than as another colour.
    static let divider = Color(hex: 0x201E1D).opacity(0.40)


    // MARK: Neutral ramp

    static let neutral100 = Color(hex: 0xF8F4F4)
    static let neutral200 = Color(hex: 0xEAE7E7)
    static let neutral300 = Color(hex: 0xD7D3D3)
    static let neutral400 = Color(hex: 0xBAB6B6)
    static let neutral500 = Color(hex: 0x9B9797)
    static let neutral600 = Color(hex: 0x7D7979)
    static let neutral700 = Color(hex: 0x605D5D)
    static let neutral800 = Color(hex: 0x444141)
    static let neutral900 = Color(hex: 0x2D2B2B)


    // MARK: Accent ramp

    static let accent100 = Color(hex: 0xFFF2EF)
    static let accent200 = Color(hex: 0xFFE0D9)
    static let accent300 = Color(hex: 0xFFC4B8)
    static let accent600 = Color(hex: 0xDD2B0F)
    static let accent700 = Color(hex: 0xAE1800)


    // MARK: Metrics

    /// The system's structural rule weight. Not a hairline — 2pt is the look.
    static let rule: CGFloat = 2

    static let space1: CGFloat = 4
    static let space2: CGFloat = 8
    static let space3: CGFloat = 12
    static let space4: CGFloat = 16
    static let space6: CGFloat = 24
    static let space8: CGFloat = 32

    /// Apple's minimum comfortable hit target, which the prototype's 44px
    /// controls were already sized to.
    static let minTarget: CGFloat = 44


    // MARK: Type

    static func heading(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight)
    }

    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

extension Color {

    /// `Color(hex: 0xEC3013)` — for design tokens, which are authored as hex.
    init(hex: UInt32) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >>  8) & 0xFF) / 255,
                  blue:  Double( hex        & 0xFF) / 255,
                  opacity: 1)
    }
}


// MARK: - Reusable text treatments
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

extension View {

    /// The system's micro-label: small, heavy, wide-tracked, uppercase.
    func kicker(_ color: Color = Theme.neutral600, size: CGFloat = 10) -> some View {
        self.font(Theme.body(size, .bold))
            .tracking(size * 0.16)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }

    /// Slightly looser tracking, used on control labels rather than headers.
    func controlLabel(_ color: Color = Theme.text, size: CGFloat = 11) -> some View {
        self.font(Theme.body(size, .semibold))
            .tracking(size * 0.08)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }

    /// Figures that need to line up in columns.
    func tabularFigures(_ size: CGFloat = 12, _ weight: Font.Weight = .regular) -> some View {
        self.font(Theme.body(size, weight).monospacedDigit())
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

/// A 2pt structural rule.
struct Rule: View {
    var axis: Axis = .horizontal
    var color: Color = Theme.divider

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width:  axis == .vertical   ? Theme.rule : nil,
                   height: axis == .horizontal ? Theme.rule : nil)
    }
}
