import Testing
import Foundation
@testable import CloudScribe

@Suite struct HotkeyBindingTests {
    @Test("Default binding displays Option Shift Space")
    func defaultDisplay() {
        #expect(HotkeyBinding.default.displayString == "⌥⇧Space")
    }

    @Test("Binding round-trips through UserDefaults storage")
    func bindingPersistence() {
        let original = UserPreferences.hotkeyBinding
        defer { UserPreferences.hotkeyBinding = original }

        let custom = HotkeyBinding(keyCode: UInt32(0x00), carbonModifiers: UInt32(256 | 512))
        UserPreferences.hotkeyBinding = custom
        #expect(UserPreferences.hotkeyBinding == custom)
    }
}

@MainActor
@Suite struct Slice3PreferencesTests {
    @Test("Auto-paste defaults to enabled for testing flow")
    func autoPasteDefaultEnabled() {
        let key = "cloudscribe.autopaste.enabled"
        let prior = UserDefaults.standard.object(forKey: key)
        defer {
            if let prior { UserDefaults.standard.set(prior, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        UserDefaults.standard.removeObject(forKey: key)
        #expect(UserPreferences.autoPasteEnabled == true)
    }

    @Test("Pill defaults to enabled")
    func pillDefaultEnabled() {
        let key = "cloudscribe.pill.enabled"
        let prior = UserDefaults.standard.object(forKey: key)
        defer {
            if let prior { UserDefaults.standard.set(prior, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        UserDefaults.standard.removeObject(forKey: key)
        #expect(UserPreferences.pillEnabled == true)
    }
}