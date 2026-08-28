# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

PaletteMonkey is a SwiftUI multiplatform app (iPad + native macOS) at the "Hello, world!"
stage — one `App` and one root `View`. Bundle id `com.stevenmarcotte.experimental.PaletteMonkey`.

The repo is git-initialized on branch `main`.

## Layout

The Xcode project lives at `Xcode/PaletteMonkey/`, not the repo root. Source is under
`Xcode/PaletteMonkey/PaletteMonkey/`, split into `Application/` (the `@main` entry point),
`Screens/`, and `Resources/` (asset catalog), plus `ColorKit/`, `Model/`, and `Export/`.
Test sources sit alongside in `Xcode/PaletteMonkey/PaletteMonkeyTests/`.

The top-level `Assets/`, `Archive/`, `Design/`, `Docs/`, and `Notes/` directories are empty
and sit outside the Xcode project — they are not compiled.

## Build and run

All `xcodebuild` commands must run from `Xcode/PaletteMonkey/`. One shared scheme,
`PaletteMonkey`, covers both targets: the app and `PaletteMonkeyTests`. The scheme is committed
under `PaletteMonkey.xcodeproj/xcshareddata/xcschemes/` so a fresh clone and CI pick it up —
do not rely on Xcode auto-generating one into `xcuserdata/`, which is ignored.

`SDKROOT = auto` with several supported platforms means a `-destination` is effectively
required; without one, xcodebuild picks a platform you probably did not intend.

```bash
xcodebuild -scheme PaletteMonkey -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5),OS=27.0' build
```

```bash
xcodebuild -scheme PaletteMonkey -destination 'platform=macOS' build
```

`xcodebuild -scheme PaletteMonkey -showdestinations` lists what is currently valid, and its
"incompatible" section explains each rejection — useful because most destinations on this Mac
are rejected (see below).

## Tests

`PaletteMonkeyTests` is an app-hosted unit test bundle using **Swift Testing** (`import Testing`,
`@Suite` / `@Test`), not XCTest. Sources live in `Xcode/PaletteMonkey/PaletteMonkeyTests/`.

```bash
xcodebuild -scheme PaletteMonkey -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5),OS=27.0' test
```

Run a single suite or test with `-only-testing`:

```bash
xcodebuild -scheme PaletteMonkey -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5),OS=27.0' test -only-testing:PaletteMonkeyTests/HomeScreenRootTests
```

**Do not trust `Executed 0 tests, with 0 failures`** in the output. That line is the XCTest
harness reporting that it found no *XCTest* cases, which is always true here. Swift Testing
reports separately, with `◇` / `✔` markers and a final `Test run with N tests ... passed`.
Grep for that, or for `✔`/`✘`, when checking results programmatically.

## App architecture

PaletteMonkey is a palette editor: a sidebar of palettes, a detail view in one of three modes,
and an inspector on the selected swatch. It implements a Claude Design prototype — see
**Design provenance** below.

- **`ColorKit/`** — pure value types, no SwiftUI state and no persistence. `HSB` is the
  canonical colour type; `MantiaLattice`, `Harmony`, `PairCompletion`, and `DarkVariant` are
  all functions over it. This layer carries the test suite.
- **`Model/`** — SwiftData `@Model` classes plus `PaletteEditing.swift`, which holds every
  mutation as a `ModelContext` extension so views stay presentation-only.
- **`Export/`** — generates the three Xcode artefacts (a `Color` extension, a `.colorset`, a
  tokens JSON) as strings.
- **`Screens/`** — `HomeScreenRoot` owns all selection state and passes it down; no view
  reaches into the model context except through `PaletteEditing`.

**Colour is stored as HSB, never hex.** Every operation — lattice snapping, harmonies, dark
derivation — is an HSB operation, and round-tripping through 8-bit hex loses lattice stops.
`hexString` is a formatted view of the model. Anything that adds a colour path should keep
that direction.

The models are CloudKit-shaped (all properties defaulted, relationships optional, no
`.unique`) but sync is **not** enabled — that needs an iCloud entitlement and provisioning.
`PaletteMonkeyApp` documents the one-line change.

## Design provenance

The UI implements `PaletteMonkey.dc.html` from the Claude Design project
`0a445559-0b00-416e-810c-f961b083b8be` ("PaletteMonkey SwiftUI prototype"), read via the
`DesignSync` tool. That project also holds `SwiftUI Notes.dc.html`, which specifies the
intended architecture — read both before changing layout or colour behaviour, since the
prototype is the visual contract.

**The prototype's visual style is deliberately not implemented.** It uses the Modernist
design system — flat, zero-radius, 2pt rules, Archivo, uppercase micro-labels. That was built
and then removed: the app uses stock SwiftUI instead (`Form`/`List`, `LabeledContent`,
`Picker(.segmented)`, `ColorPicker`, system fonts, the system accent). Treat the prototype as
the spec for **structure and behaviour**, not for appearance — do not reintroduce a custom
theme layer without asking.

The other departure: the prototype **fakes** eyedropper and camera sampling by nudging the
current colour. The real eyedropper (`NSColorSampler`) is wired on macOS; the iPadOS camera
sampler is a disabled control rather than a fake, because faking a capture would be a lie in
a shipping UI.

## Platform constraints that bite

Two settings disqualify most simulators, and the failure looks like a broken toolchain if you
do not know about them:

- `TARGETED_DEVICE_FAMILY = 2` — **iPad only**. Every iPhone simulator and the connected
  iPhone are rejected. Building "for iOS" means picking an iPad.
- Deployment targets are all **27.0** (iOS/macOS/visionOS/watchOS/tvOS). Only iOS 27.0
  simulators qualify; the 26.5 runtimes installed here are all rejected.

`SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"` with `SUPPORTS_MACCATALYST = NO`, so
macOS is a native destination, not Catalyst. `XROS_DEPLOYMENT_TARGET` is set but visionOS is
not in `SUPPORTED_PLATFORMS`.

Requires Xcode 27 (`objectVersion = 90`); this machine builds with `/Applications/Xcode-beta.app`.

## Project conventions

- **Synchronized folders.** The target uses `PBXFileSystemSynchronizedRootGroup`, so files
  added under `Xcode/PaletteMonkey/PaletteMonkey/` are picked up automatically. Do **not**
  hand-edit `project.pbxproj` to register new sources.
- **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** with `SWIFT_APPROACHABLE_CONCURRENCY = YES`
  — types are `@MainActor` by default. Mark work that must leave the main actor explicitly
  (`nonisolated`, `@concurrent`) rather than assuming background execution.
- Swift language mode 5.0, with `MEMBER_IMPORT_VISIBILITY` upcoming feature on: an extension's
  members need their defining module imported directly, not transitively.
- App Sandbox is on (`ENABLE_APP_SANDBOX`), with user-selected files read-only.
- **`ENABLE_USER_SCRIPT_SANDBOXING = YES`** project-wide. Any run-script phase that reads
  outside the build directory fails with `Operation not permitted` — the sandbox denies `exec`
  on the script itself, before it runs a single line, and declaring `inputPaths` does not help
  because reading `.git` is blocked too. `Scripts/set_build_number.sh` (stamps `CFBundleVersion`
  from `git rev-list HEAD --count`) needs this setting off for the app target. Verify whether
  the phase is wired before assuming either state.
- Localization uses String Catalogs with generated symbols; no `Info.plist` file exists —
  it is generated from `INFOPLIST_KEY_*` build settings.
- Source files carry a banner comment header (rule-line separators, author, copyright) and
  `// MARK: -` dividers between declarations. Match that style in new files.
- `HomeScreenRoot.swift` imports `Playgrounds` and uses a `#Playground` block alongside
  `#Preview` — inline playgrounds are in use, not just previews.
