import Testing
@testable import CloudScribe

@Suite struct MicrophonePermissionManagerTests {

    @Test("MicrophonePermissionStatus display names")
    func displayNames() {
        #expect(MicrophonePermissionStatus.notDetermined.displayName == "Not requested")
        #expect(MicrophonePermissionStatus.granted.displayName == "Allowed")
        #expect(MicrophonePermissionStatus.denied.displayName == "Denied")
    }

    @Test("MicrophonePermissionStatus settings hints mention System Settings when needed")
    func settingsHints() {
        #expect(MicrophonePermissionStatus.notDetermined.settingsHint.contains("Request Access") == true)
        #expect(MicrophonePermissionStatus.denied.settingsHint.contains("System Settings") == true)
        #expect(MicrophonePermissionStatus.granted.settingsHint.contains("enabled") == true)
    }
}