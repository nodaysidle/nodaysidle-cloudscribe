import Carbon
import Carbon.HIToolbox
import Foundation

extension Notification.Name {
    static let cloudScribeToggleRecording = Notification.Name("cloudScribeToggleRecording")
}

/// Registers a configurable global hotkey while CloudScribe is running.
final class GlobalHotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: OSType(0x43445342), id: 1)
    private var handlerInstalled = false

    func setEnabled(_ enabled: Bool, binding: HotkeyBinding = UserPreferences.hotkeyBinding) {
        if enabled {
            register(binding: binding)
        } else {
            unregister()
        }
    }

    func register(binding: HotkeyBinding) {
        unregister()

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        if !handlerInstalled {
            InstallEventHandler(
                GetApplicationEventTarget(),
                { _, event, userData -> OSStatus in
                    guard let userData else { return OSStatus(eventNotHandledErr) }
                    let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                    var receivedID = EventHotKeyID()
                    let status = GetEventParameter(
                        event,
                        EventParamName(kEventParamDirectObject),
                        EventParamType(typeEventHotKeyID),
                        nil,
                        MemoryLayout<EventHotKeyID>.size,
                        nil,
                        &receivedID
                    )
                    guard status == noErr, receivedID.id == manager.hotKeyID.id else {
                        return OSStatus(eventNotHandledErr)
                    }
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .cloudScribeToggleRecording, object: nil)
                    }
                    return noErr
                },
                1,
                &eventType,
                Unmanaged.passUnretained(self).toOpaque(),
                &eventHandlerRef
            )
            handlerInstalled = true
        }

        RegisterEventHotKey(
            binding.keyCode,
            binding.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    deinit {
        unregister()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }
}