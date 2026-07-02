import Testing
import Foundation
@testable import CloudScribe

@MainActor
@Suite struct Slice2PreferencesTests {
    @Test("Disabling history clears saved entries")
    func historyToggleClearsEntries() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cloudscribe-tests-\(UUID().uuidString)", isDirectory: true)
        let store = TranscriptHistoryStore(appSupportDirectory: tempDir)
        store.add(text: "Saved line", source: .microphone)

        let vm = TranscriptionViewModel(historyStore: store)
        vm.setHistoryEnabled(true)
        #expect(!vm.historyEntries.isEmpty)

        vm.setHistoryEnabled(false)
        #expect(vm.historyEntries.isEmpty)
        #expect(store.load().isEmpty)
    }

    @Test("Polish returns input when disabled")
    func polishDisabledPassthrough() async {
        let vm = TranscriptionViewModel()
        vm.setPolishEnabled(false)
        let result = await vm.polishTranscript("Raw transcript.")
        #expect(result == "Raw transcript.")
    }

    @Test("Hotkey toggle respects enabled flag")
    func hotkeyRespectsEnabledFlag() {
        let vm = TranscriptionViewModel()
        vm.setHotkeyEnabled(false)
        vm.state = .idle
        vm.toggleRecordingFromHotkey()
        #expect(vm.state == .idle)
    }
}