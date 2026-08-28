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
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Format", selection: $format) {
                    ForEach(ExportFormat.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: format) { copied = false }

                Divider()

                ScrollView([.horizontal, .vertical]) {
                    Text(code)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(.quaternary.opacity(0.4))

                Divider()

                HStack {
                    Text("Dark-mode variants export as the \u{201C}any/dark\u{201D} appearance pair.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 12)

                    Button(copied ? "Copied" : "Copy",
                           systemImage: copied ? "checkmark" : "doc.on.doc") {
                        copy(code)
                        copied = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("\(palette.name) → Xcode")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 420)
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
