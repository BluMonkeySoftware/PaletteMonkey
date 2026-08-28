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

    @State private var hexDraft = ""
    @State private var tagsDraft = ""

    private var hsb: HSB { swatch.hsb }
    private var snapped: HSB { lattice.snap(hsb) }
    private var completion: PairCompletion {
        PairCompletion(assigned: palette.assignedRoles, lattice: lattice)
    }

    var body: some View {
        Form {
            preview
            identity
            roleSection
            tagsSection
            readouts
            harmonySection
            pairSection
            mantiaSection
            annotation

            Section {
                Button("Remove Swatch", systemImage: "trash", role: .destructive, action: onRemove)
                    .disabled(palette.orderedSwatches.count < 2)
            }
        }
        .formStyle(.grouped)
        .task(id: swatch.persistentModelID) { syncDrafts() }
    }


    // MARK: - Colour
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var preview: some View {
        Section {
            RoundedRectangle(cornerRadius: 10)
                .fill(hsb.color)
                .frame(height: 88)
                .overlay {
                    RoundedRectangle(cornerRadius: 10).strokeBorder(.separator, lineWidth: 0.5)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
    }

    private var identity: some View {
        Section("Swatch") {
            TextField("Name", text: $swatch.name)

            LabeledContent("Web hex") {
                TextField("#RRGGBB", text: $hexDraft)
                    .multilineTextAlignment(.trailing)
                    .font(.body.monospacedDigit())
                    .autocorrectionDisabled()
                    .onSubmit(commitHex)
                    #if os(iOS)
                    .textInputAutocapitalization(.characters)
                    #endif
            }

            ColorPicker("System picker", selection: pickerBinding, supportsOpacity: false)

            // The eyedropper is macOS-only, so it is hidden rather than
            // disabled on iPadOS, where the camera sampler takes its place.
            #if os(macOS)
            Button("Eyedropper", systemImage: "eyedropper", action: sampleScreen)
            #else
            Button("Camera", systemImage: "camera") {}
                .disabled(true)
            #endif

            Text(captureNote).font(.footnote).foregroundStyle(.secondary)
        }
    }


    // MARK: - Role and tags
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var roleSection: some View {
        Section("60 · 30 · 10 role") {
            Picker("Role", selection: $swatch.role) {
                ForEach(SwatchRole.allCases) { role in
                    Text(role.shortLabel).tag(Optional(role))
                }
                Text("None").tag(SwatchRole?.none)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var tagsSection: some View {
        Section("Tags") {
            ChipToggleRow(items: ["brand", "ui", "warm", "cool", "print", "text"],
                          label: { $0 },
                          isOn: { swatch.tags.contains($0) },
                          action: toggleTag)

            TextField("brand, ui, warm", text: $tagsDraft)
                .autocorrectionDisabled()
                .onSubmit(commitTags)
        }
    }


    // MARK: - Readouts
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var readouts: some View {
        Section("Readouts") {
            ForEach(readoutRows, id: \.key) { row in
                LabeledContent(row.key) {
                    Text(row.value).font(.body.monospacedDigit())
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
            ("Source", swatch.source.label)
        ]
    }


    // MARK: - Harmony
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var harmonySet: [HSB] { harmony.set(from: hsb, lattice: lattice) }

    private var harmonySection: some View {
        Section("Harmony from this base") {
            ChipToggleRow(items: Harmony.allCases,
                          label: \.label,
                          isOn: { $0 == harmony },
                          action: { harmony = $0 })

            ChipStrip(colors: [hsb] + harmonySet, height: 40)

            Button(action: onAppendHarmony) {
                Label("Append \(harmonySet.count) to palette", systemImage: "plus.circle")
            }
        }
    }


    // MARK: - Pair completion
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var pairSection: some View {
        Section("Complete the pair") {
            VStack(alignment: .leading, spacing: 4) {
                Text(pairTitle).font(.headline)
                Text(pairHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if completion.readiness == .ready, let missing = completion.missing {
                ForEach(completion.candidates) { candidate in
                    Button {
                        onAppendPair(candidate, missing)
                    } label: {
                        HStack(spacing: 12) {
                            SwatchWell(hsb: candidate.hsb, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(candidate.label).font(.subheadline.weight(.medium))
                                    Spacer(minLength: 8)
                                    Text(candidate.hsb.hexDisplay)
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                Text(candidate.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
        }
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
        Section("Mantia") {
            LabeledContent {
                HStack(spacing: 8) {
                    SwatchWell(hsb: hsb, size: 28)
                    Image(systemName: "arrow.right").foregroundStyle(.secondary)
                    SwatchWell(hsb: snapped, size: 28)
                }
            } label: {
                Text(mantiaDelta).font(.subheadline.monospacedDigit())
            }

            Button("Snap to Nearest Stop", systemImage: "scope") {
                swatch.hsb = snapped
                swatch.source = .mantia
            }
            .disabled(lattice.isOnStop(hsb))
        }
    }

    private var mantiaDelta: String {
        lattice.isOnStop(hsb)
            ? "Already on a stop"
            : "\(snapped.hexDisplay) · Δh \(Int(lattice.hueDelta(from: hsb, to: snapped).rounded()))°"
    }


    // MARK: - Annotation
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var annotation: some View {
        Section("Annotation") {
            TextField("Notes", text: $swatch.note, axis: .vertical)
                .lineLimit(3 ... 8)
        }
    }


    // MARK: - Editing
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var pickerBinding: Binding<CGColor> {
        Binding(get: { hsb.cgColor },
                set: { new in
                    guard let value = HSB(cgColor: new) else { return }
                    swatch.hsb = value
                    swatch.source = .picker
                    hexDraft = value.hexDisplay
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
