# SimpleMenuBarApp

A tiny macOS menu bar utility that copies the current date or time to the
clipboard in the formats I reach for most, and can put the previous clipboard
contents back if I copied by mistake.

## Menu

| Item | Example | Key while menu is open |
|---|---|---|
| Restore Old Pasteboard | whatever was on the clipboard before the last copy | `0` |
| Copy today's date | `2026-09-10` | `1` |
| Copy now in ISO8601 format | `2026-09-10T00:15:30-07:00` | `2` |
| Copy now as filename string | `2026_09_10__00_15_30` | `3` |
| Copy current week | `2026-W37` (ISO 8601 week) | `w` |
| Copy Evernote journal prefix | `2026-09-10: Thursday... ` | `e` |
| Copy Hugo front matter template | YAML block with the ISO timestamp | `f` |
| Launch at Login | toggles login item registration | |
| Quit | | `q` |

**Global hotkey:** `⌃⌥⌘D` copies today's date from any app.

### Custom formats

Extra items can be added without touching the source. Each entry needs a
[DateFormatter pattern](https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Format_Patterns)
and may set a title and a single-character key equivalent:

```sh
defaults write com.SixtyThreeBooks.SimpleMenuBarApp customFormats \
    -array-add '{ title = "Copy month"; format = "yyyy-MM"; key = "m"; }'
```

They appear below the built-in items the next time the menu opens. To clear
them:

```sh
defaults delete com.SixtyThreeBooks.SimpleMenuBarApp customFormats
```

Patterns use the ISO 8601 calendar, so `ww` and `YYYY` give ISO week numbers
and the week-based year.

### Restore and pasteboard privacy

Every copy first snapshots the current clipboard so Restore can undo it. On
macOS 15.4 and later, reading the clipboard programmatically shows a
"paste from other apps" alert the first time. After that the app appears in
System Settings › Privacy & Security › Paste from Other Apps. Choose
**Always Allow** there to keep Restore working; otherwise the app skips the
snapshot and Restore stays disabled (its tooltip explains this).

The app is ad-hoc signed, so macOS may forget that choice after reinstalling
a new build.

## Building

Requires Xcode and [just](https://github.com/casey/just).

```sh
just build     # Release build into build/DerivedData
just run       # build if needed, then launch from the build directory
just install   # build if needed, ad-hoc sign, replace /Applications copy, relaunch
just test      # boundary-date checks for the formatters
just icon      # regenerate the app icon PNGs from scripts/make-icon.swift
just release 1.0  # bump MARKETING_VERSION, commit, tag v1.0, build, zip, push, publish a GitHub release
just clean
```

`build.sh` is the underlying `xcodebuild` wrapper; it accepts
`CONFIGURATION`, `DERIVED_DATA_PATH`, and `CODE_SIGNING_ALLOWED` overrides.

## Layout

- `SimpleMenuBarApp/StatusBarController.swift`: menu items, hotkey, login item.
- `SimpleMenuBarApp/DateFormats.swift`: all date rendering (Foundation only, testable).
- `SimpleMenuBarApp/PasteboardBackup.swift`: copy with snapshot, restore, privacy check.
- `SimpleMenuBarApp/GlobalHotKey.swift`: Carbon `RegisterEventHotKey` wrapper.
- `Tests/DateFormatsTests.swift`: run by `just test` with plain `swiftc`.
- `scripts/make-icon.swift`: draws the app icon (calendar SF Symbol on a blue tile); `just icon` writes all sizes into the asset catalog.
