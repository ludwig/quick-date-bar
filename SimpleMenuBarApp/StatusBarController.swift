//
//  StatusBarController.swift
//  SimpleMenuBarApp
//
//  Created by Luis Armendariz on 4/16/23.
//

import Foundation
import Cocoa

class StatusBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem
    private let menu = NSMenu()
    private var restorePasteboardMenuItem: NSMenuItem?
    private var oldPasteboardItem: NSPasteboardItem?
    private var copyDateMenuItem: NSMenuItem?
    private var copyYearWeekMenuItem: NSMenuItem?

    private var dateFormat = "yyyy-MM-dd"
    private var dateTitle: String {
        let date = formattedDate(with: dateFormat)
        return "Copy today's date as prefix (\(date))"
    }

    private var yearWeekFormat = "yyyy-'W'ww"
    private var yearWeekTitle: String {
        let yearWeek = formattedDate(with: yearWeekFormat)
        return "Copy today's week prefix (\(yearWeek))"
    }

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        setupMenu()
    }

    private func setupMenu() {
        menu.delegate = self

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

        copyDateMenuItem = NSMenuItem(
            title: dateTitle,
            action: #selector(copyDate),
            keyEquivalent: "2"
        )
        copyDateMenuItem?.target = self
        menu.addItem(copyDateMenuItem!)

        let copyTimeMenuItem = NSMenuItem(
            title: "Copy now as time filename suffix",
            action: #selector(copyTime),
            keyEquivalent: "3"
        )
        copyTimeMenuItem.target = self
        menu.addItem(copyTimeMenuItem)

        let copyISO8601DateMenuItem = NSMenuItem(
            title: "Copy now in ISO8601 format",
            action: #selector(copyISO8601Date),
            keyEquivalent: "4"
        )
        copyISO8601DateMenuItem.target = self
        menu.addItem(copyISO8601DateMenuItem)

        copyYearWeekMenuItem = NSMenuItem(
            title: yearWeekTitle,
            action: #selector(copyYearWeek),
            keyEquivalent: "w"
        )
        copyYearWeekMenuItem?.target = self
        menu.addItem(copyYearWeekMenuItem!)

        let copyHugoFrontMatterMenuItem = NSMenuItem(
            title: "Copy Hugo front matter template",
            action: #selector(copyHugoFrontMatterTemplate),
            keyEquivalent: "f"
        )
        copyHugoFrontMatterMenuItem.target = self
        menu.addItem(copyHugoFrontMatterMenuItem)

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

    func menuWillOpen(_ menu: NSMenu) {
        copyDateMenuItem?.title = dateTitle
        copyYearWeekMenuItem?.title = yearWeekTitle
    }

    private func formattedDate(with format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: Date())
    }

    private func formattedISO8601Date() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withDashSeparatorInDate,
            .withColonSeparatorInTime,
            .withColonSeparatorInTimeZone,
        ]
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
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
        copyToClipboard(prefix)
    }

    @objc private func copyDate() {
        let dateString = formattedDate(with: dateFormat)
        copyToClipboard(dateString)
    }

    @objc private func copyTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd__HH_mm_ss"
        let timeString = formatter.string(from: Date())
        copyToClipboard(timeString)
    }

    @objc private func copyISO8601Date() {
        let dateString = formattedISO8601Date()
        copyToClipboard(dateString)
    }

    @objc private func copyYearWeek() {
        let yearWeekString = formattedDate(with: yearWeekFormat)
        copyToClipboard(yearWeekString)
    }

    @objc private func copyHugoFrontMatterTemplate() {
        let template = """
        ---
        title: "Your title here"
        date: \(formattedISO8601Date())
        tags: []
        draft: false
        ---
        """
        copyToClipboard(template)
    }

    private func copyToClipboard(_ string: String) {
        saveCurrentPasteboardContents()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
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
