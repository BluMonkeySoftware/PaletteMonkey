// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// ExportSheet.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

struct ExportSheet: View {

    var palette: Palette
    var lattice: MantiaLattice

    @State private var format: ExportFormat = .swift
    @State private var copied = false
    @Environment(\.dismiss) private var dismiss

    private var code: String {
        PaletteExport.code(for: palette, format: format, lattice: lattice)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Rule()
            tabs
            Rule()

            ScrollView([.horizontal, .vertical]) {
                Text(code)
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.text)
                    .lineSpacing(4)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
            }
            .background(Theme.neutral100)

            Rule()
            footer
        }
        .background(Theme.bg)
        .frame(minWidth: 520, minHeight: 420)
    }


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var header: some View {
        HStack(alignment: .top, spacing: Theme.space4) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Export").kicker(Theme.accent700)
                Text("\(palette.name) → Xcode")
                    .font(Theme.heading(24))
                    .tracking(-0.48)
                    .foregroundStyle(Theme.text)
            }
            Spacer(minLength: 0)
            Button("Close") { dismiss() }
                .buttonStyle(.plain)
                .controlLabel(Theme.accent)
                .frame(minHeight: Theme.minTarget)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
    }

    private var tabs: some View {
        HStack(spacing: 0) {
            ForEach(ExportFormat.allCases) { option in
                Button {
                    format = option
                    copied = false
                } label: {
                    Text(option.label)
                        .font(Theme.body(11, .bold))
                        .tracking(0.88)
                        .textCase(.uppercase)
                        .foregroundStyle(option == format ? Theme.bg : Theme.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(option == format ? Theme.text : Color.clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .trailing) { Rule(axis: .vertical) }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Text("Writes into the app's iCloud container, then hands a generated Swift file and asset catalog to Xcode. Dark-mode variants export as the \u{201C}any/dark\u{201D} appearance pair.")
                .font(Theme.body(11))
                .foregroundStyle(Theme.neutral600)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                copy(code)
                copied = true
            } label: {
                Text(copied ? "Copied" : "Copy")
                    .controlLabel(Theme.bg)
                    .padding(.horizontal, Theme.space4)
                    .frame(minHeight: Theme.minTarget)
                    .background(Theme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, Theme.space4)
    }


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private func copy(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}
