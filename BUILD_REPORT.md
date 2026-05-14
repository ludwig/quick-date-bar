# Build Report

Date: 2026-05-14

## Summary

Built the macOS app target `SimpleMenuBarApp` successfully in `Release` configuration.

The app bundle was produced at:

```text
build/DerivedData/Build/Products/Release/SimpleMenuBarApp.app
```

## What I Ran

First, I inspected the Xcode project to confirm the available target, scheme, and build configurations:

```sh
xcodebuild -list -project SimpleMenuBarApp.xcodeproj
```

That confirmed:

- Target: `SimpleMenuBarApp`
- Scheme: `SimpleMenuBarApp`
- Configurations: `Debug`, `Release`

Then I built the app:

```sh
xcodebuild \
  -project SimpleMenuBarApp.xcodeproj \
  -scheme SimpleMenuBarApp \
  -configuration Release \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

The build completed with:

```text
** BUILD SUCCEEDED **
```

## Build Helpers Added

I added `build.sh` as a repeatable command-line build entry point for this project. It builds the same `SimpleMenuBarApp` scheme in `Release` by default and writes DerivedData under `build/DerivedData`.

The script can be run with:

```sh
./build.sh
```

It also supports these environment overrides:

- `CONFIGURATION`, defaulting to `Release`
- `DERIVED_DATA_PATH`, defaulting to `build/DerivedData`
- `CODE_SIGNING_ALLOWED`, defaulting to `NO`

I also added a `Justfile` with:

```sh
just build
just clean
```

`just build` delegates to `./build.sh`. `just clean` removes the generated `build/` directory.

## Why These Options

`-configuration Release` was used because the request was to build the project, and Release is the appropriate configuration for a distributable app artifact.

`-derivedDataPath build/DerivedData` was used to keep all generated build products inside this repository. Without this, Xcode tries to write to the default DerivedData location under `~/Library/Developer/Xcode`, which is outside the workspace and caused sandbox permission warnings during inspection.

`CODE_SIGNING_ALLOWED=NO` was used to produce a local unsigned build without requiring a signing identity, provisioning setup, or keychain access. This is suitable for confirming that the project compiles and emits an app bundle. A signed or notarized build would require developer identity configuration.

## Artifact Checks

I verified that the build output exists:

```text
build/DerivedData/Build/Products/Release/SimpleMenuBarApp.app
build/DerivedData/Build/Products/Release/SimpleMenuBarApp.app.dSYM
build/DerivedData/Build/Products/Release/SimpleMenuBarApp.swiftmodule
```

I checked the executable format:

```text
Mach-O universal binary with 2 architectures: x86_64 and arm64
```

I also verified the app bundle metadata:

- Bundle identifier: `com.SixtyThreeBooks.SimpleMenuBarApp`
- Version: `1.0`
- Build number: `1`
- Minimum macOS version: `13.3`
- `LSUIElement`: `true`, meaning this is configured as a menu bar / agent-style app rather than a normal Dock app.

The app bundle size is approximately:

```text
212K
```

## Notes

The build emitted simulator-related warnings because the sandboxed environment could not access CoreSimulator services and logs under `~/Library`. This project builds a macOS app, not an iOS simulator app, and those warnings did not prevent the build from succeeding.

No source files or Xcode project settings were changed. The intentional repository changes are this report, `.gitignore`, `build.sh`, and `Justfile`. Generated build output remains under `build/` and is ignored by Git.
