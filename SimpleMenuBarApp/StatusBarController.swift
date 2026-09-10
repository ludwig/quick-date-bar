//
//  StatusBarController.swift
//  SimpleMenuBarApp
//
//  Created by Luis Armendariz on 4/16/23.
//

import Carbon.HIToolbox
import Cocoa
import ServiceManagement

/// One copyable menu item: how to title it and what to put on the pasteboard.
struct CopyEntry {
    let title: (Date) -> String
    let render: (Date) -> String
    let keyEquivalent: String

    /// A plain pattern whose live value is shown in the title.
    static func pattern(_ title: String, _ pattern: String, key: String) -> CopyEntry {
        CopyEntry(
            title: { "\(title) (\(DateFormats.string(pattern, from: $0)))" },
            render: { DateFormats.string(pattern, from: $0) },
            keyEquivalent: key
        )
    }

    static let todaysDate = pattern("Copy today's date", DateFormats.date, key: "1")

    static let builtIn: [CopyEntry] = [
        todaysDate,
        CopyEntry(
            title: { _ in "Copy now in ISO8601 format" },
            render: { DateFormats.iso8601(from: $0) },
            keyEquivalent: "2"
        ),
        CopyEntry(
            title: { _ in "Copy now as filename string" },
            render: { DateFormats.string(DateFormats.filename, from: $0) },
            keyEquivalent: "3"
        ),
        pattern("Copy current week", DateFormats.week, key: "w"),
        CopyEntry(
            title: { _ in "Copy Evernote journal prefix" },
            render: { DateFormats.string(DateFormats.journalPrefix, from: $0) },
            keyEquivalent: "e"
        ),
        CopyEntry(
            title: { _ in "Copy Hugo front matter template" },
            render: { DateFormats.hugoFrontMatter(from: $0) },
            keyEquivalent: "f"
        ),
    ]

    /// User-defined patterns from the `customFormats` default: an array of
    /// dictionaries with `format` (DateFormatter pattern), optional `title`,
    /// and optional single-character `key`. Example:
    ///
    ///     defaults write com.SixtyThreeBooks.SimpleMenuBarApp customFormats \
    ///         -array-add '{ title = "Copy month"; format = "yyyy-MM"; key = "m"; }'
    static func custom(from defaults: UserDefaults = .standard) -> [CopyEntry] {
        let raw = defaults.array(forKey: "customFormats") as? [[String: Any]] ?? []
        return raw.compactMap { dict in
            guard let format = dict["format"] as? String, !format.isEmpty else { return nil }
            let title = dict["title"] as? String ?? "Copy \(format)"
            let key = dict["key"] as? String ?? ""
            return pattern(title, format, key: String(key.prefix(1)))
        }
    }
}

class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let pasteboard = PasteboardBackup()
    private let restoreItem: NSMenuItem
    private var entries: [CopyEntry] = []
    private var dateHotKey: GlobalHotKey?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        restoreItem = NSMenuItem(
            title: "Restore Old Pasteboard",
            action: #selector(restoreOldPasteboardItem),
            keyEquivalent: "0"
        )
        super.init()

        restoreItem.target = self
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu
        // SF Symbols are template images, so the icon tints correctly in light
        // and dark menu bars and renders crisply at every scale.
        if let image = NSImage(systemSymbolName: "calendar", accessibilityDescription: "Quick Date") {
            statusItem.button?.image = image
        } else {
            statusItem.button?.title = "Date"
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timeZoneDidChange),
            name: .NSSystemTimeZoneDidChange,
            object: nil
        )

        // ⌃⌥⌘D copies today's date from any app.
        dateHotKey = GlobalHotKey(
            keyCode: kVK_ANSI_D,
            modifiers: controlKey | optionKey | cmdKey
        ) { [weak self] in
            self?.copy(.todaysDate)
        }
        if dateHotKey == nil {
            NSLog("Could not register the ⌃⌥⌘D global hotkey")
        }
    }

    // MARK: - Menu

    /// Rebuilds every item right before the menu is shown, so titles carry
    /// the current date.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let now = Date()

        restoreItem.isEnabled = pasteboard.hasBackup
        restoreItem.toolTip = PasteboardBackup.isReadAllowed ? nil : PasteboardBackup.accessHint
        menu.addItem(restoreItem)
        menu.addItem(.separator())

        // Re-read defaults on every open so `defaults write` takes effect
        // without relaunching.
        let custom = CopyEntry.custom()
        entries = CopyEntry.builtIn + custom
        for (index, entry) in entries.enumerated() {
            if index == CopyEntry.builtIn.count {
                menu.addItem(.separator())
            }
            let item = NSMenuItem(
                title: entry.title(now),
                action: #selector(copyEntry(_:)),
                keyEquivalent: entry.keyEquivalent
            )
            item.target = self
            item.tag = index
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Actions

    @objc private func copyEntry(_ sender: NSMenuItem) {
        guard entries.indices.contains(sender.tag) else { return }
        copy(entries[sender.tag])
    }

    private func copy(_ entry: CopyEntry) {
        pasteboard.copy(entry.render(Date()))
    }

    @objc private func restoreOldPasteboardItem() {
        pasteboard.restore()
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            switch service.status {
            case .enabled:
                try service.unregister()
            case .requiresApproval:
                // Registered but blocked by the user; only System Settings
                // can clear that.
                SMAppService.openSystemSettingsLoginItems()
            default:
                try service.register()
            }
        } catch {
            NSLog("Launch at Login change failed: %@", error.localizedDescription)
        }
    }

    @objc private func timeZoneDidChange() {
        DateFormats.resetCache()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
