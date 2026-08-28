// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// SwatchInspector.swift
//
//
// Created by Steven Marcotte on 2026-Aug-27
// Copyright (c) 1996 - 2026 Steven Marcotte, All Rights Reserved
//
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import SwiftUI
import SwiftData

#if os(macOS)
import AppKit
#endif


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

struct SwatchInspector: View {

    @Bindable var swatch: Swatch
    var palette: Palette
    var lattice: MantiaLattice

    @Binding var harmony: Harmony
    @Binding var captureNote: String

    var onAppendHarmony: () -> Void
    var onAppendPair: (PairCompletion.Candidate, SwatchRole) -> Void
    var onRemove: () -> Void

    @State private var hexDraft: String = ""
    @State private var tagsDraft: String = ""

    private var hsb: HSB { swatch.hsb }
    private var snapped: HSB { lattice.snap(hsb) }
    private var completion: PairCompletion {
        PairCompletion(assigned: palette.assignedRoles, lattice: lattice)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                preview
                identity
                roleSection
                tagsSection
                readouts
                harmonySection
                pairSection
                mantiaSection
                annotation
                removeSection
            }
        }
        .background(Theme.neutral100)
        .task(id: swatch.persistentModelID) { syncDrafts() }
    }


    // MARK: - Header
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Inspector").kicker()
            Spacer()
            Text(swatch.source.label).controlLabel(Theme.accent700, size: 10)
        }
        .padding(Theme.space4)
        .overlay(alignment: .bottom) { Rule() }
    }

    private var preview: some View {
        Rectangle()
            .fill(hsb.color)
            .frame(height: 96)
            .overlay(alignment: .bottom) { Rule() }
    }


    // MARK: - Identity
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var identity: some View {
        InspectorSection {
            VStack(alignment: .leading, spacing: Theme.space3) {

                labelled("Name") {
                    TextField("Name", text: $swatch.name)
                        .textFieldStyle(.modernist)
                        .font(Theme.body(13))
                }

                HStack(alignment: .top, spacing: 10) {
                    labelled("Web hex") {
                        TextField("#RRGGBB", text: $hexDraft)
                            .textFieldStyle(.modernist)
                            .font(Theme.body(13).monospacedDigit())
                            .autocorrectionDisabled()
                            .onSubmit(commitHex)
                    }
                    labelled("System picker") {
                        ColorPicker("", selection: pickerBinding, supportsOpacity: false)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                    }
                }

                captureControls

                Text(captureNote)
                    .font(Theme.body(11))
                    .foregroundStyle(Theme.neutral600)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// The eyedropper is macOS-only, so it is hidden rather than disabled on
    /// iPadOS, where the camera sampler takes its place.
    @ViewBuilder
    private var captureControls: some View {
        HStack(spacing: Theme.space2) {
            #if os(macOS)
            secondaryButton("Eyedropper", action: sampleScreen)
            #else
            secondaryButton("Camera", action: {})
                .disabled(true)
            #endif
        }
    }


    // MARK: - Role and tags
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var roleSection: some View {
        InspectorSection(title: "60 · 30 · 10 role") {
            SegmentedRow(items: SwatchRole.allCases.map { Optional($0) } + [nil],
                         label: { $0?.shortLabel ?? "None" },
                         isOn: { swatch.role == $0 },
                         action: { swatch.role = $0 })
        }
    }

    private var tagsSection: some View {
        InspectorSection(title: "Tags") {
            VStack(alignment: .leading, spacing: 10) {
                ChipToggleRow(items: ["brand", "ui", "warm", "cool", "print", "text"],
                              label: { $0 },
                              isOn: { swatch.tags.contains($0) },
                              action: toggleTag)

                TextField("brand, ui, warm", text: $tagsDraft)
                    .textFieldStyle(.modernist)
                    .font(Theme.body(12))
                    .autocorrectionDisabled()
                    .onSubmit(commitTags)
            }
        }
    }


    // MARK: - Readouts
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var readouts: some View {
        InspectorSection(title: "Readouts") {
            VStack(spacing: 0) {
                ForEach(readoutRows, id: \.key) { row in
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.key).kicker()
                        Spacer(minLength: 10)
                        Text(row.value).tabularFigures(12, .semibold).foregroundStyle(Theme.text)
                    }
                    .padding(.vertical, 6)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Theme.neutral300).frame(height: 1)
                    }
                }
            }
        }
    }

    private var readoutRows: [(key: String, value: String)] {
        let rgb = hsb.rgb255
        let ok = hsb.oklch
        return [
            ("Hex", hsb.hexDisplay),
            ("RGB", "\(rgb.red), \(rgb.green), \(rgb.blue)"),
            ("HSB", "\(Int(hsb.hue.rounded()))°, \(Int((hsb.saturation * 100).rounded()))%, \(Int((hsb.brightness * 100).rounded()))%"),
            ("OKLCH", "\(String(format: "%.1f", ok.l))% \(String(format: "%.3f", ok.c)) \(Int(ok.h.rounded()))°"),
            ("On white", "\(String(format: "%.2f", hsb.contrastRatio(with: .white))):1"),
            ("On ink", "\(String(format: "%.2f", hsb.contrastRatio(with: .ink))):1"),
            ("Role", swatch.roleLabel)
        ]
    }


    // MARK: - Harmony
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var harmonySection: some View {
        InspectorSection(title: "Harmony from this base") {
            VStack(alignment: .leading, spacing: Theme.space3) {

                ChipToggleRow(items: Harmony.allCases,
                              label: \.label,
                              isOn: { $0 == harmony },
                              action: { harmony = $0 })

                ChipStrip(colors: [hsb] + harmonySet, height: 44, bordered: false)
                    .overlay { Rectangle().strokeBorder(Theme.divider, lineWidth: Theme.rule) }

                Button(action: onAppendHarmony) {
                    HStack(spacing: Theme.space2) {
                        Text("Append to palette")
                        Text("\(harmonySet.count) \(harmony.label.lowercased())")
                            .opacity(0.72)
                            .monospacedDigit()
                    }
                    .font(Theme.body(11, .semibold))
                    .tracking(0.88)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.bg)
                    .frame(maxWidth: .infinity, minHeight: Theme.minTarget)
                    .background(Theme.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var harmonySet: [HSB] { harmony.set(from: hsb, lattice: lattice) }


    // MARK: - Pair completion
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var pairSection: some View {
        InspectorSection(title: "Complete the pair") {
            VStack(alignment: .leading, spacing: Theme.space2) {

                Text(pairTitle)
                    .font(Theme.heading(14, .bold))
                    .tracking(-0.14)
                    .foregroundStyle(Theme.text)

                Text(pairHint)
                    .font(Theme.body(11))
                    .foregroundStyle(Theme.neutral600)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if completion.readiness == .ready, let missing = completion.missing {
                    basisStrip
                    VStack(spacing: 2) {
                        ForEach(completion.candidates) { candidate in
                            candidateRow(candidate, missing: missing)
                        }
                    }
                    .padding(.top, Theme.space2)
                }
            }
        }
    }

    private var basisStrip: some View {
        HStack(spacing: 2) {
            ForEach(completion.basis) { basis in
                VStack(alignment: .leading) {
                    Spacer(minLength: 0)
                    Text("\(basis.role.rawValue)% \(basis.name)")
                        .font(Theme.body(10, .bold))
                        .tracking(1)
                        .foregroundStyle(basis.hsb.ink.color)
                }
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .bottomLeading)
                .padding(.horizontal, 9)
                .padding(.vertical, Theme.space2)
                .background(basis.hsb.color)
            }
        }
        .overlay { Rectangle().strokeBorder(Theme.divider, lineWidth: Theme.rule) }
        .padding(.top, Theme.space2)
    }

    private func candidateRow(_ candidate: PairCompletion.Candidate, missing: SwatchRole) -> some View {
        Button {
            onAppendPair(candidate, missing)
        } label: {
            HStack(spacing: 0) {
                Rectangle().fill(candidate.hsb.color).frame(width: 48)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(candidate.label).controlLabel(Theme.text, size: 11)
                        Spacer(minLength: Theme.space2)
                        Text(candidate.hsb.hexDisplay)
                            .tabularFigures(10)
                            .foregroundStyle(Theme.neutral600)
                    }
                    Text(candidate.note)
                        .font(Theme.body(10.5))
                        .foregroundStyle(Theme.neutral600)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, Theme.space2)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 56)
            .background(Theme.bg)
            .overlay { Rectangle().strokeBorder(Theme.divider, lineWidth: Theme.rule) }
        }
        .buttonStyle(.plain)
    }

    private var pairTitle: String {
        switch completion.readiness {
            case .ready:         "Compute the missing \(completion.missing?.rawValue ?? "")%"
            case .allAssigned:   "All three roles assigned"
            case .needsTwoRoles: "Assign two roles first"
        }
    }

    private var pairHint: String {
        let names = completion.basis.map { "\($0.role.rawValue)% \($0.name)" }
        switch completion.readiness {
            case .ready:
                return "The \(names.joined(separator: " and ")) are fixed. Pick a formula for the \(completion.missing?.rawValue ?? "")% and it joins the palette with that role."
            case .allAssigned:
                return "Set one of the three — \(names.joined(separator: ", ")) — to None, and the remaining pair drives the formulas for the one you cleared."
            case .needsTwoRoles:
                return "Tag any two swatches with roles above — say 60% and 10% — and PaletteMonkey will derive the third from the pair."
        }
    }


    // MARK: - Mantia
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var mantiaSection: some View {
        InspectorSection(title: "Mantia") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    chip(hsb)
                    Text("→").font(Theme.body(16)).foregroundStyle(Theme.neutral600)
                    chip(snapped)
                    Text(mantiaDelta)
                        .tabularFigures(11)
                        .foregroundStyle(Theme.neutral700)
                        .fixedSize(horizontal: false, vertical: true)
                }

                secondaryButton("Snap to nearest stop", fullWidth: true) {
                    swatch.hsb = snapped
                    swatch.source = .mantia
                }
                .disabled(lattice.isOnStop(hsb))
            }
        }
    }

    private var mantiaDelta: String {
        lattice.isOnStop(hsb)
            ? "already on a stop"
            : "\(snapped.hexDisplay) · Δh \(Int(lattice.hueDelta(from: hsb, to: snapped).rounded()))°"
    }

    private func chip(_ value: HSB) -> some View {
        Rectangle()
            .fill(value.color)
            .frame(width: 34, height: 34)
            .overlay { Rectangle().strokeBorder(Theme.divider, lineWidth: Theme.rule) }
    }


    // MARK: - Annotation and removal
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var annotation: some View {
        InspectorSection {
            labelled("Annotation") {
                TextEditor(text: $swatch.note)
                    .font(Theme.body(12))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 84)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Theme.surface)
                    .overlay { Rectangle().strokeBorder(Theme.divider, lineWidth: Theme.rule) }
            }
        }
    }

    private var removeSection: some View {
        Button(action: onRemove) {
            Text("Remove swatch")
                .controlLabel(Theme.accent700)
                .frame(maxWidth: .infinity, minHeight: Theme.minTarget)
        }
        .buttonStyle(.plain)
        .disabled(palette.orderedSwatches.count < 2)
        .padding(.horizontal, Theme.space4)
        .padding(.top, Theme.space4)
        .padding(.bottom, Theme.space8)
    }


    // MARK: - Pieces
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private func labelled<Content: View>(_ title: String,
                                         @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).kicker(Theme.neutral600)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func secondaryButton(_ title: String,
                                 fullWidth: Bool = false,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .controlLabel(Theme.text, size: 11)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(Theme.neutral100)
                .overlay { Rectangle().strokeBorder(Theme.divider, lineWidth: Theme.rule) }
        }
        .buttonStyle(.plain)
    }


    // MARK: - Editing
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var pickerBinding: Binding<CGColor> {
        Binding(get: { hsb.cgColor },
                set: { new in
                    if let value = HSB(cgColor: new) {
                        swatch.hsb = value
                        swatch.source = .picker
                        hexDraft = value.hexDisplay
                    }
                })
    }

    private func syncDrafts() {
        hexDraft = hsb.hexDisplay
        tagsDraft = swatch.tags.joined(separator: ", ")
    }

    /// Rejects on commit rather than per keystroke, so a half-typed hex does
    /// not repeatedly rewrite the swatch.
    private func commitHex() {
        if let value = HSB(hex: hexDraft) {
            swatch.hsb = value
            swatch.source = .hex
        }
        hexDraft = swatch.hsb.hexDisplay
    }

    private func commitTags() {
        swatch.tags = tagsDraft
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        tagsDraft = swatch.tags.joined(separator: ", ")
    }

    private func toggleTag(_ tag: String) {
        if let index = swatch.tags.firstIndex(of: tag) {
            swatch.tags.remove(at: index)
        } else {
            swatch.tags.append(tag)
        }
        tagsDraft = swatch.tags.joined(separator: ", ")
    }

    #if os(macOS)
    private func sampleScreen() {
        NSColorSampler().show { picked in
            guard let picked, let value = HSB(cgColor: picked.cgColor) else { return }
            swatch.hsb = value
            swatch.source = .eyedropper
            hexDraft = value.hexDisplay
            captureNote = "Sampler picked a pixel from the screen behind the window."
        }
    }
    #endif
}
