import Testing
import Foundation
import AppKit
@testable import CloudScribe

// MARK: - DeepgramClient Tests

@Suite struct DeepgramClientTests {

    @Test("Mock stream returns canned interim and final results")
    func mockStreamReturnsCannedResults() async {
        let mock = MockDeepgramTransport()
        await mock.setCannedResults([
            .interim("Hello"),
            .interim("Hello world"),
            .final("Hello world.")
        ])

        let audioStream = AsyncStream<Data> { continuation in
            continuation.yield(Data([0x00, 0x00]))
            continuation.yield(Data([0x01, 0x00]))
            continuation.finish()
        }

        let results = mock.streamTranscription(audioStream: audioStream, apiKey: "test-key")
        var collected: [TranscriptionResult] = []
        for await result in results {
            collected.append(result)
        }

        #expect(collected.count == 3)
        #expect(collected[0] == .interim("Hello"))
        #expect(collected[1] == .interim("Hello world"))
        #expect(collected[2] == .final("Hello world."))
    }

    @Test("Mock file transcription returns canned transcript")
    func mockFileTranscriptionReturnsCannedString() async throws {
        let mock = MockDeepgramTransport()
        await mock.setCannedFileTranscript("This is a test transcript.")

        let url = URL(fileURLWithPath: "/tmp/dummy.wav")
        let transcript = try await mock.transcribeFile(fileURL: url, apiKey: "test-key")

        #expect(transcript == "This is a test transcript.")
    }

    @Test("Mock file transcription throws when configured")
    func mockFileTranscriptionThrows() async {
        let mock = MockDeepgramTransport()
        await mock.setShouldThrow(DeepgramError.invalidResponse)

        let url = URL(fileURLWithPath: "/tmp/dummy.wav")
        do {
            _ = try await mock.transcribeFile(fileURL: url, apiKey: "test-key")
            #expect(Bool(false), "Expected throw but got success")
        } catch let error as DeepgramError {
            #expect(error == .invalidResponse)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("TranscriptionResult equatable")
    func transcriptionResultEquatable() {
        #expect(TranscriptionResult.interim("a") != TranscriptionResult.final("a"))
        #expect(TranscriptionResult.interim("a") == TranscriptionResult.interim("a"))
        #expect(TranscriptionResult.final("b") == TranscriptionResult.final("b"))
    }
}
