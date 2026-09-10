//
//  GlobalHotKey.swift
//  SimpleMenuBarApp
//

import Carbon
import Foundation

/// A system-wide keyboard shortcut registered through Carbon's
/// RegisterEventHotKey, which works from a sandboxed app and does not need
/// the Accessibility permission that NSEvent global monitors require.
final class GlobalHotKey {
    private static let signature: OSType = 0x5144_4254 // 'QDBT'
    private static var nextID: UInt32 = 1

    private let id: EventHotKeyID
    private let action: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    /// - Parameters:
    ///   - keyCode: a `kVK_*` virtual key code.
    ///   - modifiers: Carbon modifier mask, e.g. `cmdKey | optionKey`.
    init?(keyCode: Int, modifiers: Int, action: @escaping () -> Void) {
        self.action = action
        self.id = EventHotKeyID(signature: Self.signature, id: Self.nextID)
        Self.nextID += 1

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        let installed = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }
                let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                return hotKey.handle(event)
            },
            1,
            &eventType,
            selfPointer,
            &handlerRef
        )
        guard installed == noErr else { return nil }

        let registered = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            id,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        // deinit still runs when a failable init returns nil after all stored
        // properties are set, so it handles removing the event handler.
        guard registered == noErr else { return nil }
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
        }
    }

    private func handle(_ event: EventRef) -> OSStatus {
        var pressed = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &pressed
        )
        guard status == noErr, pressed.signature == id.signature, pressed.id == id.id else {
            return OSStatus(eventNotHandledErr)
        }
        action()
        return noErr
    }
}
