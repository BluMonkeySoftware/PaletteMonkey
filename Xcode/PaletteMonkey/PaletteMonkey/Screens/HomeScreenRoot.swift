// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//
// HomeScreenRoot.swift
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

struct HomeScreenRoot: View {

    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Palette.createdAt)]) private var palettes: [Palette]

    @State private var selectedPaletteID: PersistentIdentifier?
    @State private var selectedSwatchID: PersistentIdentifier?
    @State private var columns: NavigationSplitViewVisibility = .all

    @State private var previewMode: PreviewMode = .chips
    @State private var inspectorShown = true
    @State private var showExport = false

    @State private var lattice = MantiaLattice()
    @State private var harmony: Harmony = .complementary
    @State private var mantiaHue: Double?

    @State private var captureNote = "Eyedropper uses the on-screen sampler; Camera opens the live IRL sampler on iPadOS."
    @State private var syncStatus = "Synced · PaletteMonkey.palettes"


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private var selectedPalette: Palette? {
        palettes.first { $0.persistentModelID == selectedPaletteID } ?? palettes.first
    }

    private var selectedSwatch: Swatch? {
        guard let palette = selectedPalette else { return nil }
        return palette.orderedSwatches.first { $0.persistentModelID == selectedSwatchID }
            ?? palette.orderedSwatches.first
    }


    // MARK: -
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    var body: some View {
        NavigationSplitView(columnVisibility: $columns) {
            CollectionsSidebar(palettes: palettes,
                               selection: $selectedPaletteID,
                               onNewPalette: newPalette)
                .navigationSplitViewColumnWidth(min: 220, ideal: 272, max: 320)
                .navigationTitle("Collections")
        } detail: {
            detail
                .inspector(isPresented: $inspectorShown) {
                    inspector
                        .inspectorColumnWidth(min: 280, ideal: 344, max: 400)
                }
                .toolbar { toolbar }
                .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        }
        .sheet(isPresented: $showExport) {
            if let palette = selectedPalette {
                ExportSheet(palette: palette, lattice: lattice)
            }
        }
        .task {
            SampleData.seedIfNeeded(context)
        }
        .onChange(of: selectedPaletteID) {
            selectedSwatchID = selectedPalette?.orderedSwatches.first?.persistentModelID
            mantiaHue = nil
        }
    }


    // MARK: - Detail
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    @ViewBuilder
    private var detail: some View {
        if let palette = selectedPalette {
            Group {
                switch previewMode {
                    case .chips:
                        ChipsListView(palette: palette,
                                      lattice: lattice,
                                      selection: $selectedSwatchID)
                    case .rule:
                        RuleBandsView(palette: palette)
                    case .mantia:
                        MantiaGridView(lattice: lattice,
                                       selected: selectedSwatch,
                                       mantiaHue: $mantiaHue,
                                       onPick: pickFromLattice)
                }
            }
            .navigationTitle(palette.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        } else {
            ContentUnavailableView("No palette selected",
                                   systemImage: "paintpalette",
                                   description: Text("Pick a palette from the sidebar, or create one."))
        }
    }

    @ViewBuilder
    private var inspector: some View {
        if let palette = selectedPalette, let swatch = selectedSwatch {
            SwatchInspector(swatch: swatch,
                            palette: palette,
                            lattice: lattice,
                            harmony: $harmony,
                            captureNote: $captureNote,
                            onAppendHarmony: appendHarmony,
                            onAppendPair: appendPair,
                            onRemove: removeSelectedSwatch)
        } else {
            ContentUnavailableView("No swatch selected",
                                   systemImage: "eyedropper",
                                   description: Text("Select a swatch to inspect it."))
        }
    }


    // MARK: - Chrome
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {

        ToolbarItem(placement: .principal) {
            Picker("View", selection: $previewMode) {
                ForEach(PreviewMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(minWidth: 260)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button("Add swatch", systemImage: "plus", action: addSwatch)
            Button("Derive dark mode", systemImage: "circle.lefthalf.filled", action: deriveDark)
            Button("Export to Xcode", systemImage: "square.and.arrow.up") { showExport = true }
                .keyboardShortcut("e")
            Button("Inspector", systemImage: "sidebar.trailing") { inspectorShown.toggle() }
        }
    }

    private var footer: some View {
        HStack {
            Label(syncStatus, systemImage: "icloud")
            Spacer(minLength: 16)
            Text("Hue step \(Int(lattice.hueStep))° · \(lattice.steps) S/B steps · ⌘E exports")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }


    // MARK: - Actions
    // ————————————————————————————————————————————————————————————————————————————————————————————————————————————————

    private func addSwatch() {
        guard let palette = selectedPalette else { return }
        selectedSwatchID = context.addSwatch(to: palette).persistentModelID
    }

    private func deriveDark() {
        guard let palette = selectedPalette else { return }
        let dark = context.deriveDark(from: palette)
        selectedPaletteID = dark.persistentModelID
        selectedSwatchID = dark.orderedSwatches.first?.persistentModelID
        syncStatus = "Saving to iCloud · \(dark.name)"
    }

    private func newPalette() {
        let palette = context.newPalette()
        selectedPaletteID = palette.persistentModelID
        selectedSwatchID = palette.orderedSwatches.first?.persistentModelID
    }

    private func appendHarmony() {
        guard let palette = selectedPalette, let swatch = selectedSwatch else { return }
        if let first = context.appendHarmony(harmony, from: swatch, in: palette, lattice: lattice) {
            selectedSwatchID = first.persistentModelID
        }
    }

    private func appendPair(_ candidate: PairCompletion.Candidate, role: SwatchRole) {
        guard let palette = selectedPalette else { return }
        selectedSwatchID = context.appendPairCandidate(candidate, role: role, to: palette).persistentModelID
    }

    private func removeSelectedSwatch() {
        guard let palette = selectedPalette, let swatch = selectedSwatch else { return }
        let remaining = palette.orderedSwatches.filter { $0.persistentModelID != swatch.persistentModelID }
        if context.removeSwatch(swatch, from: palette) {
            selectedSwatchID = remaining.first?.persistentModelID
        }
    }

    private func pickFromLattice(_ value: HSB) {
        guard let swatch = selectedSwatch else { return }
        swatch.hsb = value
        swatch.source = .mantia
    }
}


// MARK: -
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

#Preview {
    HomeScreenRoot()
        .modelContainer(for: [Palette.self, Swatch.self], inMemory: true)
}
