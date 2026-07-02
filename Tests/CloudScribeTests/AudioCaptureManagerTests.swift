import Testing
import Foundation
@testable import CloudScribe

// MARK: - AudioCaptureManager Tests

@Suite struct AudioCaptureManagerTests {

    @Test("AudioCaptureManager initializes without error")
    func initialization() {
        _ = AudioCaptureManager()
        #expect(Bool(true))
    }

    @Test("AudioCaptureError equatable conformance")
    func audioCaptureErrorEquatable() {
        #expect(AudioCaptureError.microphoneAccessDenied == .microphoneAccessDenied)
        #expect(AudioCaptureError.captureAlreadyActive == .captureAlreadyActive)
        #expect(AudioCaptureError.engineConfigurationFailed("test") == .engineConfigurationFailed("test"))
        #expect(AudioCaptureError.engineConfigurationFailed("a") != .engineConfigurationFailed("b"))
        #expect(AudioCaptureError.engineStartFailed("x") == .engineStartFailed("x"))
        #expect(AudioCaptureError.microphoneAccessDenied.errorDescription?.contains("Microphone") == true)
    }

    @Test("DeepgramError equatable conformance")
    func deepgramErrorEquatable() {
        #expect(DeepgramError.invalidURL == .invalidURL)
        #expect(DeepgramError.invalidResponse == .invalidResponse)
        #expect(DeepgramError.httpError(400, "bad") == .httpError(400, "bad"))
        #expect(DeepgramError.httpError(400, "a") != .httpError(400, "b"))
        #expect(DeepgramError.noAPIKey == .noAPIKey)
        #expect(DeepgramError.decodingError("x") == .decodingError("x"))
    }

    @Test("KeychainError equatable conformance")
    func keychainErrorEquatable() {
        #expect(KeychainError.itemNotFound == .itemNotFound)
        #expect(KeychainError.encodingFailed == .encodingFailed)
        #expect(KeychainError.decodingFailed == .decodingFailed)
    }
}
