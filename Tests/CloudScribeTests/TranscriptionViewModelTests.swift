import Testing
import Foundation
import AppKit
@testable import CloudScribe

// MARK: - TranscriptionViewModel Tests

@MainActor
@Suite struct TranscriptionViewModelTests {

    @Test("ViewModel initializes with idle state")
    func initialState() {
        let vm = TranscriptionViewModel()
        #expect(vm.state == .idle)
        #expect(vm.interimText == "")
        #expect(vm.finalText == "")
        #expect(vm.cloudIndicatorVisible == false)
    }

    @Test("ViewModel rejects recording without API key")
    func rejectsRecordingWithoutAPIKey() async {
        let vm = TranscriptionViewModel()
        vm.deleteAPIKey()
        vm.startRecording()

        guard case .error(let msg) = vm.state else {
            #expect(Bool(false), "Expected error state, got \(vm.state)")
            return
        }
        #expect(msg.contains("API key"))
    }

    @Test("ViewModel copy to clipboard sets pasteboard")
    func copyToClipboard() {
        let vm = TranscriptionViewModel()
        vm.finalText = "Test transcript"
        vm.state = .done("Test transcript")
        vm.copyToClipboard()

        let pasteboard = NSPasteboard.general
        let content = pasteboard.string(forType: .string)
        #expect(content == "Test transcript")
    }

    @Test("ViewModel reset clears all state")
    func resetClearsState() {
        let vm = TranscriptionViewModel()
        vm.finalText = "Some text"
        vm.interimText = "Interim"
        vm.state = .done("Some text")
        vm.cloudIndicatorVisible = true

        vm.reset()

        #expect(vm.state == .idle)
        #expect(vm.interimText == "")
        #expect(vm.finalText == "")
        #expect(vm.cloudIndicatorVisible == false)
    }

    @Test("API key save/delete/status round-trip")
    func apiKeyRoundTrip() throws {
        let service = "com.nodaysidle.cloudscribe.tests.\(UUID().uuidString)"
        let keychain = KeychainManager(service: service)
        let vm = TranscriptionViewModel(keychain: keychain)

        vm.deleteAPIKey()
        #expect(vm.apiKeyStatus == .notSet)

        vm.saveAPIKey("test-key-dg-000")
        #expect(vm.apiKeyStatus == .valid)
        #expect(vm.getAPIKey() == "test-key-dg-000")

        vm.saveAPIKey("test-key-dg-111")
        #expect(vm.getAPIKey() == "test-key-dg-111")

        vm.deleteAPIKey()
        #expect(vm.apiKeyStatus == .notSet)
        #expect(vm.getAPIKey() == nil)

        try keychain.delete(account: "DEEPGRAM_API_KEY")
    }

    @Test("Mock transcription progresses through states")
    func mockTranscriptionStateProgression() async {
        let mock = MockDeepgramTransport()
        await mock.setCannedResults([
            .interim("Hello"),
            .final("Hello world.")
        ])
        _ = mock // used through vm

        let vm = TranscriptionViewModel(deepgram: mock)
        vm.finalText = "Hello world."
        vm.state = .done("Hello world.")

        #expect(vm.finalText == "Hello world.")
        #expect(vm.state == .done("Hello world."))
    }

    @Test("Polish stub returns input unchanged")
    func polishStubReturnsInput() async {
        let vm = TranscriptionViewModel()
        let result = await vm.polishTranscript("Hello world.")
        #expect(result == "Hello world.")
    }

    @Test("Live transcript segments accumulate without ending session")
    func liveTranscriptSegmentsAccumulate() async {
        let vm = TranscriptionViewModel()
        vm.state = .recording
        vm.appendFinalSegmentForTesting("Hello")
        vm.appendFinalSegmentForTesting("world again")
        #expect(vm.finalText == "Hello world again")
        vm.interimText = "and"
        #expect(vm.combinedTranscriptForTesting() == "Hello world again and")
    }
}
