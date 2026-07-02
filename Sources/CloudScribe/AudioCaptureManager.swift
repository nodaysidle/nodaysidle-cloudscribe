@preconcurrency import AVFoundation
import Foundation

// MARK: - Protocol

protocol AudioCaptureProtocol: Sendable {
    /// Starts capturing audio from the default microphone.
    /// Returns an AsyncStream yielding raw 16-bit little-endian mono PCM chunks.
    func startCapture() throws -> AsyncStream<Data>
    /// Stops the active capture session.
    func stopCapture()
}

// MARK: - Errors

enum AudioCaptureError: Error, Equatable, LocalizedError {
    case microphoneAccessDenied
    case engineConfigurationFailed(String)
    case captureAlreadyActive
    case engineStartFailed(String)

    var errorDescription: String? {
        switch self {
        case .microphoneAccessDenied:
            return "Microphone access denied. Enable CloudScribe under System Settings → Privacy & Security → Microphone."
        case .engineConfigurationFailed(let detail):
            return "Audio engine setup failed: \(detail)"
        case .captureAlreadyActive:
            return "Recording is already in progress."
        case .engineStartFailed(let detail):
            return "Could not start the audio engine: \(detail)"
        }
    }
}

// MARK: - Implementation

/// Captures audio from the default microphone at 16 kHz mono,
/// producing 16-bit little-endian PCM data chunks.
final class AudioCaptureManager: NSObject, AudioCaptureProtocol, @unchecked Sendable {
    private var engine: AVAudioEngine?
    private let desiredSampleRate: Double = 16000
    private let bufferSize: AVAudioFrameCount = 4096
    private var isCapturing = false
    private let lock = NSLock()

    func startCapture() throws -> AsyncStream<Data> {
        lock.lock()
        defer { lock.unlock() }

        guard !isCapturing else {
            throw AudioCaptureError.captureAlreadyActive
        }

        try MicrophonePermissionManager.requireAccess()

        stopCaptureUnlocked()

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        engine.prepare()

        let inputFormat = Self.resolvedInputFormat(for: inputNode)
        guard let converterFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: desiredSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioCaptureError.engineConfigurationFailed("Could not create 16 kHz PCM format")
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: converterFormat) else {
            throw AudioCaptureError.engineConfigurationFailed(
                "Could not convert from \(Int(inputFormat.sampleRate)) Hz input"
            )
        }

        let streamBuffer = StreamBuffer()

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { buffer, _ in
            let outputCapacity = AVAudioFrameCount(
                converterFormat.sampleRate / inputFormat.sampleRate * Double(buffer.frameLength)
            ) + 256
            guard let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: converterFormat,
                frameCapacity: max(outputCapacity, 1)
            ) else { return }

            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

            guard error == nil, outputBuffer.frameLength > 0,
                  let channelData = outputBuffer.int16ChannelData else { return }

            let frameLength = Int(outputBuffer.frameLength)
            let data = Data(
                bytes: channelData.pointee,
                count: frameLength * MemoryLayout<Int16>.size
            )
            streamBuffer.yield(data)
        }

        do {
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            throw AudioCaptureError.engineStartFailed(error.localizedDescription)
        }

        self.engine = engine
        isCapturing = true

        return AsyncStream { continuation in
            streamBuffer.continuation = continuation
            continuation.onTermination = { @Sendable [weak self] _ in
                self?.stopCapture()
            }
        }
    }

    func stopCapture() {
        lock.lock()
        defer { lock.unlock() }
        stopCaptureUnlocked()
    }

    private func stopCaptureUnlocked() {
        guard isCapturing || engine != nil else { return }
        isCapturing = false
        if let engine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        engine = nil
    }

    private static func resolvedInputFormat(for inputNode: AVAudioInputNode) -> AVAudioFormat {
        let outputFormat = inputNode.outputFormat(forBus: 0)
        if outputFormat.sampleRate > 0, outputFormat.channelCount > 0 {
            return outputFormat
        }

        let inputFormat = inputNode.inputFormat(forBus: 0)
        if inputFormat.sampleRate > 0, inputFormat.channelCount > 0 {
            return inputFormat
        }

        return AVAudioFormat(
            standardFormatWithSampleRate: 48_000,
            channels: 1
        ) ?? outputFormat
    }
}

/// Thread-safe bridge between the realtime audio tap and AsyncStream.
private final class StreamBuffer: @unchecked Sendable {
    private let lock = NSLock()
    var continuation: AsyncStream<Data>.Continuation?

    func yield(_ data: Data) {
        lock.lock()
        continuation?.yield(data)
        lock.unlock()
    }
}