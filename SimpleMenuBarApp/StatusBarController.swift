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

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        setupMenu()
    }

    private func setupMenu() {
        let copyMenuItem = NSMenuItem(title: "Copy Today's Evernote Journal Prefix", action: #selector(copyString), keyEquivalent: "")
        copyMenuItem.target = self
        menu.addItem(copyMenuItem)

        menu.addItem(NSMenuItem.separator())

        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
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

    @objc private func copyString() {
        let pasteboard = NSPasteboard.general
        let dateString = formattedDateString()
        pasteboard.clearContents()
        pasteboard.setString(dateString, forType: .string)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
