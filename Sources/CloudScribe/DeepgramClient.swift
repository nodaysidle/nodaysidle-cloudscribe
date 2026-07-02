import Foundation

// MARK: - Models

/// A single transcription result from Deepgram.
enum TranscriptionResult: Equatable, Sendable {
    case interim(String)
    case final(String)
}

/// Errors that can occur during Deepgram operations.
enum DeepgramError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case websocketError(String)
    case httpError(Int, String)
    case noAPIKey
    case decodingError(String)
    case encodingError(String)
    case connectionFailed(String)
}

// MARK: - Protocol

/// Abstract transport for Deepgram API, enabling testability with mocks.
@preconcurrency protocol DeepgramTransport: Sendable {
    /// Stream audio to Deepgram via WebSocket for live transcription.
    /// - Parameters:
    ///   - audioStream: An async stream of raw 16-bit mono PCM audio chunks.
    ///   - apiKey: The Deepgram API key.
    /// - Returns: An async stream of transcription results.
    func streamTranscription(
        audioStream: AsyncStream<Data>,
        apiKey: String
    ) -> AsyncStream<TranscriptionResult>

    /// Transcribe a prerecorded audio file via Deepgram REST API.
    /// - Parameters:
    ///   - fileURL: URL to the audio file.
    ///   - apiKey: The Deepgram API key.
    /// - Returns: The final transcript string.
    func transcribeFile(fileURL: URL, apiKey: String) async throws -> String
}

// MARK: - Real Implementation

/// Real Deepgram client using URLSession for WebSocket streaming and REST file uploads.
actor DeepgramClient: DeepgramTransport {

    private let streamingURLTemplate = "wss://api.deepgram.com/v1/listen?model=nova-3&language=en&smart_format=true&punctuate=true&interim_results=true&encoding=linear16&sample_rate=16000&channels=1&endpointing=500&utterance_end_ms=1500"
    private let fileURLTemplate = "https://api.deepgram.com/v1/listen?model=nova-3&language=en&smart_format=true&punctuate=true"

    nonisolated func streamTranscription(
        audioStream: AsyncStream<Data>,
        apiKey: String
    ) -> AsyncStream<TranscriptionResult> {
        AsyncStream { continuation in
            let task = Task {
                await self.performStreaming(
                    audioStream: audioStream,
                    apiKey: apiKey,
                    continuation: continuation
                )
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    private func performStreaming(
        audioStream: AsyncStream<Data>,
        apiKey: String,
        continuation: AsyncStream<TranscriptionResult>.Continuation
    ) async {
        guard let url = URL(string: streamingURLTemplate) else {
            continuation.finish()
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        let session = URLSession(configuration: .default)
        let webSocketTask = session.webSocketTask(with: request)
        webSocketTask.resume()

        // Receive transcript results from WebSocket
        let receiveTask = Task {
            while !Task.isCancelled {
                do {
                    let message = try await webSocketTask.receive()
                    switch message {
                    case .string(let text):
                        if let result = Self.parseStreamingResponse(text) {
                            continuation.yield(result)
                        }
                    case .data:
                        break // Binary messages not expected for transcription results
                    @unknown default:
                        break
                    }
                } catch {
                    if !Task.isCancelled {
                        continuation.finish()
                    }
                    break
                }
            }
        }

        // Send audio chunks
        let sendTask = Task {
            for await chunk in audioStream {
                if Task.isCancelled { break }
                do {
                    try await webSocketTask.send(.data(chunk))
                } catch {
                    break
                }
            }

            // Send Finalize
            let finalizeMessage = #"{"type": "Finalize"}"#
            try? await webSocketTask.send(.string(finalizeMessage))

            // Give a moment for final results to arrive
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            // Send CloseStream
            let closeMessage = #"{"type": "CloseStream"}"#
            try? await webSocketTask.send(.string(closeMessage))
        }

        await sendTask.value
        receiveTask.cancel()
        await receiveTask.value

        webSocketTask.cancel(with: .normalClosure, reason: nil)
        continuation.finish()
    }

    nonisolated func transcribeFile(fileURL: URL, apiKey: String) async throws -> String {
        guard let url = URL(string: fileURLTemplate) else {
            throw DeepgramError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        let mimeType = Self.mimeType(for: fileURL)
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")

        let audioData = try Data(contentsOf: fileURL)
        request.httpBody = audioData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepgramError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw DeepgramError.httpError(httpResponse.statusCode, body)
        }

        return try Self.parseFileResponse(data)
    }

    // MARK: - Parsing

    private static func parseStreamingResponse(_ jsonString: String) -> TranscriptionResult? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let channel = json["channel"] as? [String: Any],
              let alternatives = channel["alternatives"] as? [[String: Any]],
              let first = alternatives.first,
              let transcript = first["transcript"] as? String,
              !transcript.isEmpty
        else {
            return nil
        }

        let isFinal = (json["is_final"] as? Bool) ?? false
        return isFinal ? .final(transcript) : .interim(transcript)
    }

    private static func parseFileResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [String: Any],
              let channels = results["channels"] as? [[String: Any]],
              let firstChannel = channels.first,
              let alternatives = firstChannel["alternatives"] as? [[String: Any]],
              let firstAlt = alternatives.first,
              let transcript = firstAlt["transcript"] as? String
        else {
            throw DeepgramError.decodingError("Failed to parse Deepgram file response")
        }
        return transcript
    }

    private static func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "wav":  return "audio/wav"
        case "mp3":  return "audio/mpeg"
        case "m4a":  return "audio/mp4"
        case "ogg":  return "audio/ogg"
        case "flac": return "audio/flac"
        case "aac":  return "audio/aac"
        case "webm": return "audio/webm"
        default:     return "audio/wav"
        }
    }
}

// MARK: - Mock for Testing

/// Mock transport that returns canned responses for testing.
actor MockDeepgramTransport: DeepgramTransport {
    private var _cannedResults: [TranscriptionResult] = []
    private var _cannedFileTranscript: String = ""
    private var _shouldThrow: (any Error)?

    func setCannedResults(_ results: [TranscriptionResult]) {
        _cannedResults = results
    }

    func setCannedFileTranscript(_ transcript: String) {
        _cannedFileTranscript = transcript
    }

    func setShouldThrow(_ error: (any Error)?) {
        _shouldThrow = error
    }

    nonisolated func streamTranscription(
        audioStream: AsyncStream<Data>,
        apiKey: String
    ) -> AsyncStream<TranscriptionResult> {
        AsyncStream { continuation in
            Task {
                let results = await self._cannedResults
                let error = await self._shouldThrow

                // Drain the audio stream so the caller's send loop doesn't block
                for await _ in audioStream { }

                if let _ = error {
                    continuation.finish()
                    return
                }

                for result in results {
                    continuation.yield(result)
                }
                continuation.finish()
            }
        }
    }

    nonisolated func transcribeFile(fileURL: URL, apiKey: String) async throws -> String {
        if let error = await _shouldThrow {
            throw error
        }
        return await _cannedFileTranscript
    }
}
