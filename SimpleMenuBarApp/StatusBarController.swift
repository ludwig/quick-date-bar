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
    private var copyYearWeekMenuItem: NSMenuItem?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        setupMenu()
    }

    private func setupMenu() {
        // https://stackoverflow.com/questions/49294949/disable-enable-nsmenu-item
        menu.autoenablesItems = false

        restorePasteboardMenuItem = NSMenuItem(
            title: "Restore Old Pasteboard",
            action: #selector(restoreOldPasteboardItem),
            keyEquivalent: "0"
        )
        restorePasteboardMenuItem?.target = self
        restorePasteboardMenuItem?.isEnabled = false
        menu.addItem(restorePasteboardMenuItem!)

        menu.addItem(NSMenuItem.separator())

        let copyJournalPrefixMenuItem = NSMenuItem(
            title: "Copy today's journal prefix for Evernote",
            action: #selector(copyJournalPrefix),
            keyEquivalent: "1"
        )
        copyJournalPrefixMenuItem.target = self
        menu.addItem(copyJournalPrefixMenuItem)

        let copyDateMenuItem = NSMenuItem(
            title: "Copy today's date as prefix",
            action: #selector(copyDate),
            keyEquivalent: "2"
        )
        copyDateMenuItem.target = self
        menu.addItem(copyDateMenuItem)

        let copyTimeMenuItem = NSMenuItem(
            title: "Copy now as time prefix",
            action: #selector(copyTime),
            keyEquivalent: "3"
        )
        copyTimeMenuItem.target = self
        menu.addItem(copyTimeMenuItem)

        copyYearWeekMenuItem = NSMenuItem(
            title: "Copy today's week prefix",
            action: #selector(copyYearWeek),
            keyEquivalent: "4"
        )
        copyYearWeekMenuItem?.target = self
        menu.addItem(copyYearWeekMenuItem!)
        
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenu),
            name: NSMenu.willSendActionNotification,
            object: nil
        )
    }

    @objc private func updateMenu() {
        let formatter = DateFormatter()
        formatter.dateFormat = "ww"
        let weekNumberString = formatter.string(from: Date())
        copyYearWeekMenuItem?.title = "Copy today's week prefix (W\(weekNumberString))"
    }

    private func formattedJournalPrefix() -> String {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        // See http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns
        dateFormatter.dateFormat = "yyyy-MM-dd: EEEE... "
        let dateString = dateFormatter.string(from: currentDate)
        return dateString
    }

    @objc private func copyJournalPrefix() {
        let prefix = formattedJournalPrefix()
        saveCurrentPasteboardContents()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(prefix, forType: .string)
    }

    @objc private func copyDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        saveCurrentPasteboardContents()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(dateString, forType: .string)
    }

    @objc private func copyTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd__HH_mm_ss"
        let timeString = formatter.string(from: Date())
        saveCurrentPasteboardContents()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(timeString, forType: .string)
    }

    @objc private func copyYearWeek() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-'W'ww"
        let yearWeekString = formatter.string(from: Date())
        saveCurrentPasteboardContents()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(yearWeekString, forType: .string)
    }

    private func saveCurrentPasteboardContents() {
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
