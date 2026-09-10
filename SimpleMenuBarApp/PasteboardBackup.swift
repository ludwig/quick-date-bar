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

    func copy(_ string: String) {
        save()
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
