import AppKit
import Foundation

/// User preferences stored in UserDefaults.
enum UserPreferences {
    private static let historyEnabledKey = "cloudscribe.history.enabled"
    private static let polishEnabledKey = "cloudscribe.polish.enabled"
    private static let hotkeyEnabledKey = "cloudscribe.hotkey.enabled"
    private static let hotkeyBindingKey = "cloudscribe.hotkey.binding"
    private static let autoPasteEnabledKey = "cloudscribe.autopaste.enabled"
    private static let pillEnabledKey = "cloudscribe.pill.enabled"
    private static let pillOriginXKey = "cloudscribe.pill.origin.x"
    private static let pillOriginYKey = "cloudscribe.pill.origin.y"

    static var historyEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: historyEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: historyEnabledKey) }
    }

    static var polishEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: polishEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: polishEnabledKey) }
    }

    static var hotkeyEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: hotkeyEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: hotkeyEnabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: hotkeyEnabledKey) }
    }

    static var hotkeyBinding: HotkeyBinding {
        get {
            guard let data = UserDefaults.standard.data(forKey: hotkeyBindingKey),
                  let binding = try? JSONDecoder().decode(HotkeyBinding.self, from: data) else {
                return .default
            }
            return binding
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: hotkeyBindingKey)
            }
        }
    }

    static var autoPasteEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: autoPasteEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: autoPasteEnabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: autoPasteEnabledKey) }
    }

    static var pillEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: pillEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: pillEnabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: pillEnabledKey) }
    }

    static func pillWindowOrigin() -> NSPoint {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let defaultX = screen.maxX - 340
        let defaultY = screen.minY + 28
        let x = UserDefaults.standard.object(forKey: pillOriginXKey) as? Double ?? defaultX
        let y = UserDefaults.standard.object(forKey: pillOriginYKey) as? Double ?? defaultY
        return NSPoint(x: x, y: y)
    }

    static func savePillWindowOrigin(_ origin: NSPoint) {
        UserDefaults.standard.set(origin.x, forKey: pillOriginXKey)
        UserDefaults.standard.set(origin.y, forKey: pillOriginYKey)
    }
}