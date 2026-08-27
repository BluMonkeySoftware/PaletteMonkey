# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

PaletteMonkey is a SwiftUI multiplatform app (iPad + native macOS) at the "Hello, world!"
stage — one `App` and one root `View`. Bundle id `com.stevenmarcotte.experimental.PaletteMonkey`.

The repo is git-initialized on branch `main`.

## Layout

The Xcode project lives at `Xcode/PaletteMonkey/`, not the repo root. Source is under
`Xcode/PaletteMonkey/PaletteMonkey/`, split into `Application/` (the `@main` entry point),
`Screens/`, and `Resources/` (asset catalog).

The top-level `Assets/`, `Archive/`, `Design/`, `Docs/`, and `Notes/` directories are empty
and sit outside the Xcode project — they are not compiled.

## Build and run

All `xcodebuild` commands must run from `Xcode/PaletteMonkey/`. There is a single scheme and
target, `PaletteMonkey`, and **no test target** — `xcodebuild test` will fail until one is added.

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
- Localization uses String Catalogs with generated symbols; no `Info.plist` file exists —
  it is generated from `INFOPLIST_KEY_*` build settings.
- Source files carry a banner comment header (rule-line separators, author, copyright) and
  `// MARK: -` dividers between declarations. Match that style in new files.
- `HomeScreenRoot.swift` imports `Playgrounds` and uses a `#Playground` block alongside
  `#Preview` — inline playgrounds are in use, not just previews.
