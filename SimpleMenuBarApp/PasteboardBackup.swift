//
//  PasteboardBackup.swift
//  SimpleMenuBarApp
//

import Cocoa

/// Writes strings to the general pasteboard while keeping a copy of whatever
/// was there before, so the user can undo an accidental copy.
final class PasteboardBackup {
    private var savedItem: NSPasteboardItem?

    var hasBackup: Bool {
        savedItem != nil
    }

    /// Whether reading the general pasteboard is allowed without an alert.
    ///
    /// Since macOS 15.4 a programmatic read of the general pasteboard shows a
    /// "paste from other apps" alert unless the user chose Always Allow in
    /// System Settings. `.default` means the app has never triggered the alert;
    /// the first read shows it once and flips the state to `.ask`. That one
    /// alert is deliberate: an app only appears in the Paste from Other Apps
    /// settings pane after it has triggered the alert. Under `.ask` every read
    /// would prompt again, so the snapshot is skipped until the user picks
    /// Always Allow.
    static var isReadAllowed: Bool {
        guard #available(macOS 15.4, *) else { return true }
        switch NSPasteboard.general.accessBehavior {
        case .default, .alwaysAllow:
            return true
        case .ask, .alwaysDeny:
            return false
        @unknown default:
            return false
        }
    }

    /// Where the user can grant access when `isReadAllowed` is false.
    static let accessHint =
        "Restore is unavailable until SimpleMenuBarApp is allowed under "
        + "System Settings › Privacy & Security › Paste from Other Apps."

    func copy(_ string: String) {
        if Self.isReadAllowed {
            save()
        } else {
            savedItem = nil
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    func restore() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let savedItem {
            pasteboard.writeObjects([savedItem])
        }
        savedItem = nil
    }

    /// Snapshots the first pasteboard item with all of its representations.
    /// Multi-item contents (e.g. several dragged files) only keep the first.
    private func save() {
        guard let oldItem = NSPasteboard.general.pasteboardItems?.first else {
            savedItem = nil
            return
        }
        let copy = NSPasteboardItem()
        for type in oldItem.types {
            if let data = oldItem.data(forType: type) {
                copy.setData(data, forType: type)
            }
        }
        savedItem = copy
    }
}
