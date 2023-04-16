//
//  StatusBarController.swift
//  SimpleMenuBarApp
//
//  Created by Luis Armendariz on 4/16/23.
//

import Foundation
import Cocoa

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private let menu = NSMenu()
    private var restorePasteboardMenuItem: NSMenuItem?
    private var oldPasteboardItem: NSPasteboardItem?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        setupMenu()
    }

    private func setupMenu() {
        // https://stackoverflow.com/questions/49294949/disable-enable-nsmenu-item
        menu.autoenablesItems = false

        let copyMenuItem = NSMenuItem(
            title: "Copy Today's Evernote Journal Prefix",
            action: #selector(copyDateString),
            keyEquivalent: ""
        )
        copyMenuItem.target = self
        menu.addItem(copyMenuItem)

        restorePasteboardMenuItem = NSMenuItem(
            title: "Restore Old Pasteboard",
            action: #selector(restoreOldPasteboardItem),
            keyEquivalent: ""
        )
        restorePasteboardMenuItem?.target = self
        restorePasteboardMenuItem?.isEnabled = false
        menu.addItem(restorePasteboardMenuItem!)
        
        menu.addItem(NSMenuItem.separator())

        let quitMenuItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)

        statusItem.menu = menu
        statusItem.button?.image = NSImage(named: "calendarIcon")
    }

    private func formattedDateString() -> String {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        // See http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
        dateFormatter.dateFormat = "yyyy-MM-dd: EEEE... "
        let dateString = dateFormatter.string(from: currentDate)
        return dateString
    }

    @objc private func copyDateString() {
        let dateString = formattedDateString()
        
        // Save the current pasteboard contents
        let pasteboard = NSPasteboard.general
        let oldPasteboardItems = pasteboard.pasteboardItems ?? []
        if let oldItem = oldPasteboardItems.first {
            self.oldPasteboardItem = NSPasteboardItem()
            for pasteboardType in oldItem.types {
                if let pasteboardData = oldItem.data(forType: pasteboardType) {
                    self.oldPasteboardItem?.setData(
                        pasteboardData,
                        forType: pasteboardType
                    )
                }
            }
            restorePasteboardMenuItem?.isEnabled = true
        } else {
            self.oldPasteboardItem = nil
            restorePasteboardMenuItem?.isEnabled = false
        }

        // Write the date string to the pasteboard
        pasteboard.clearContents()
        pasteboard.setString(dateString, forType: .string)
    }

    @objc func restoreOldPasteboardItem() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if let oldItem = oldPasteboardItem {
            pasteboard.writeObjects([oldItem])
        }
        oldPasteboardItem = nil
        restorePasteboardMenuItem?.isEnabled = false
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
