import Foundation
import SwiftUI
import AppKit

// MARK: - Recording State

enum RecordingState: Equatable, Sendable {
    case idle
    case recording
    case transcribing
    case done(String)
    case error(String)
}

// MARK: - ViewModel

/// Main view model for the CloudScribe app. Manages transcription state
/// and coordinates between audio capture and Deepgram transport.
@MainActor
final class TranscriptionViewModel: ObservableObject {
    @Published var state: RecordingState = .idle
    @Published var interimText: String = ""
    @Published var finalText: String = ""
    @Published var apiKeyStatus: ApiKeyStatus = .notSet
    @Published var cloudIndicatorVisible: Bool = false
    @Published var historyEntries: [TranscriptHistoryEntry] = []
    @Published var historyEnabled: Bool = UserPreferences.historyEnabled
    @Published var polishEnabled: Bool = UserPreferences.polishEnabled
    @Published var hotkeyEnabled: Bool = UserPreferences.hotkeyEnabled
    @Published var hotkeyBinding: HotkeyBinding = UserPreferences.hotkeyBinding
    @Published var autoPasteEnabled: Bool = UserPreferences.autoPasteEnabled
    @Published var pillEnabled: Bool = UserPreferences.pillEnabled

    enum ApiKeyStatus: Equatable {
        case notSet
        case valid
        case checking
    }

    private let keychain: KeychainManager
    private let deepgram: any DeepgramTransport
    private let audioCapture: any AudioCaptureProtocol
    private let historyStore: TranscriptHistoryStore
    private let polisher: OpenRouterPolisher
    private let deepgramAccount = "DEEPGRAM_API_KEY"
    private let openRouterAccount = "OPENROUTER_API_KEY"

    private var captureTask: Task<Void, Never>?
    private var transcriptionTask: Task<Void, Never>?
    private nonisolated(unsafe) var hotkeyObserver: NSObjectProtocol?

    init(
        keychain: KeychainManager = KeychainManager(),
        deepgram: any DeepgramTransport = DeepgramClient(),
        audioCapture: any AudioCaptureProtocol = AudioCaptureManager(),
        historyStore: TranscriptHistoryStore = TranscriptHistoryStore(),
        polisher: OpenRouterPolisher = OpenRouterPolisher()
    ) {
        self.keychain = keychain
        self.deepgram = deepgram
        self.audioCapture = audioCapture
        self.historyStore = historyStore
        self.polisher = polisher
        refreshApiKeyStatus()
        reloadHistory()
        hotkeyObserver = NotificationCenter.default.addObserver(
            forName: .cloudScribeToggleRecording,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.toggleRecordingFromHotkey()
            }
        }
    }

    deinit {
        if let hotkeyObserver {
            NotificationCenter.default.removeObserver(hotkeyObserver)
        }
    }

    var isRecording: Bool {
        if case .recording = state { return true }
        return false
    }

    // MARK: - API Keys

    func getAPIKey() -> String? {
        try? keychain.read(account: deepgramAccount)
    }

    func saveAPIKey(_ key: String) {
        do {
            try keychain.save(key: key, account: deepgramAccount)
            refreshApiKeyStatus()
        } catch {
            state = .error("Failed to save API key: \(error.localizedDescription)")
        }
    }

    func deleteAPIKey() {
        try? keychain.delete(account: deepgramAccount)
        refreshApiKeyStatus()
    }

    func getOpenRouterAPIKey() -> String? {
        try? keychain.read(account: openRouterAccount)
    }

    func saveOpenRouterAPIKey(_ key: String) {
        do {
            try keychain.save(key: key, account: openRouterAccount)
        } catch {
            state = .error("Failed to save OpenRouter key: \(error.localizedDescription)")
        }
    }

    func deleteOpenRouterAPIKey() {
        try? keychain.delete(account: openRouterAccount)
    }

    private func refreshApiKeyStatus() {
        apiKeyStatus = getAPIKey() != nil ? .valid : .notSet
    }

    // MARK: - Preferences

    func setHistoryEnabled(_ enabled: Bool) {
        historyEnabled = enabled
        UserPreferences.historyEnabled = enabled
        if enabled {
            reloadHistory()
        } else {
            historyStore.clear()
            historyEntries = []
        }
        NotificationCenter.default.post(name: .cloudScribePreferencesChanged, object: nil)
    }

    func setPolishEnabled(_ enabled: Bool) {
        polishEnabled = enabled
        UserPreferences.polishEnabled = enabled
    }

    func setHotkeyEnabled(_ enabled: Bool) {
        hotkeyEnabled = enabled
        UserPreferences.hotkeyEnabled = enabled
        NotificationCenter.default.post(name: .cloudScribePreferencesChanged, object: nil)
    }

    func setHotkeyBinding(_ binding: HotkeyBinding) {
        hotkeyBinding = binding
        UserPreferences.hotkeyBinding = binding
        NotificationCenter.default.post(name: .cloudScribePreferencesChanged, object: nil)
    }

    func setAutoPasteEnabled(_ enabled: Bool) {
        autoPasteEnabled = enabled
        UserPreferences.autoPasteEnabled = enabled
    }

    func setPillEnabled(_ enabled: Bool) {
        pillEnabled = enabled
        UserPreferences.pillEnabled = enabled
        NotificationCenter.default.post(name: .cloudScribePreferencesChanged, object: nil)
    }

    // MARK: - History

    func reloadHistory() {
        guard historyEnabled else {
            historyEntries = []
            return
        }
        historyEntries = historyStore.load()
    }

    func deleteHistoryEntry(_ entry: TranscriptHistoryEntry) {
        historyStore.delete(id: entry.id)
        reloadHistory()
    }

    func clearHistory() {
        historyStore.clear()
        reloadHistory()
    }

    func loadHistoryEntry(_ entry: TranscriptHistoryEntry) {
        finalText = entry.text
        interimText = ""
        state = .done(entry.text)
    }

    // MARK: - Recording

    func startRecording() {
        guard apiKeyStatus == .valid, let apiKey = getAPIKey() else {
            state = .error("Please set your Deepgram API key in Settings first.")
            return
        }

        captureTask?.cancel()
        captureTask = nil
        audioCapture.stopCapture()

        state = .recording
        interimText = ""
        finalText = ""
        cloudIndicatorVisible = true

        do {
            let audioStream = try audioCapture.startCapture()
            captureTask = Task { [weak self] in
                guard let self else { return }
                let resultStream = self.deepgram.streamTranscription(
                    audioStream: audioStream,
                    apiKey: apiKey
                )

                for await result in resultStream {
                    if Task.isCancelled { break }
                    await self.handleTranscriptionResult(result)
                }

                await self.finishRecording()
            }
        } catch {
            state = .error(Self.recordingErrorMessage(for: error))
            cloudIndicatorVisible = false
        }
    }

    func stopRecording() {
        guard case .recording = state else { return }
        state = .transcribing
        cloudIndicatorVisible = true
        audioCapture.stopCapture()
        // Keep captureTask alive so Deepgram can return trailing finals after Finalize.
    }

    func toggleRecordingFromHotkey() {
        guard hotkeyEnabled else { return }
        switch state {
        case .recording:
            stopRecording()
        case .idle, .done, .error:
            startRecording()
        case .transcribing:
            break
        }
    }

    private func handleTranscriptionResult(_ result: TranscriptionResult) async {
        switch result {
        case .interim(let text):
            interimText = text
        case .final(let text):
            appendFinalSegment(text)
            interimText = ""
        }
    }

    func appendFinalSegmentForTesting(_ text: String) {
        appendFinalSegment(text)
    }

    func combinedTranscriptForTesting() -> String {
        combinedTranscript()
    }

    private func appendFinalSegment(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if finalText.isEmpty {
            finalText = trimmed
        } else {
            finalText += " " + trimmed
        }
    }

    private func finishRecording() async {
        captureTask = nil
        cloudIndicatorVisible = false

        if case .recording = state {
            state = .transcribing
        }
        guard case .transcribing = state else { return }

        let text = combinedTranscript()
        guard !text.isEmpty else {
            state = .idle
            return
        }
        await completeTranscript(text, source: .microphone)
    }

    private func combinedTranscript() -> String {
        let committed = finalText.trimmingCharacters(in: .whitespacesAndNewlines)
        let pending = interimText.trimmingCharacters(in: .whitespacesAndNewlines)
        if committed.isEmpty { return pending }
        if pending.isEmpty { return committed }
        return committed + " " + pending
    }

    private func completeTranscript(_ raw: String, source: TranscriptSource) async {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            cloudIndicatorVisible = false
            return
        }

        state = .transcribing
        cloudIndicatorVisible = true
        let output = await polishTranscript(trimmed)
        finalText = output
        interimText = ""
        state = .done(output)
        cloudIndicatorVisible = false

        if historyEnabled {
            historyStore.add(text: output, source: source)
            reloadHistory()
        }

        if autoPasteEnabled {
            deliverTranscript(output)
        }
    }

    private func deliverTranscript(_ text: String) {
        ClipboardManager.copyToClipboard(text)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            ClipboardManager.pasteToFrontmostApp()
        }
    }

    // MARK: - File Import

    func importAudioFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .wav, .mp3,
            .init(filenameExtension: "m4a") ?? .audio,
            .init(filenameExtension: "ogg") ?? .audio,
            .init(filenameExtension: "flac") ?? .audio,
            .init(filenameExtension: "aac") ?? .audio,
            .init(filenameExtension: "webm") ?? .audio
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        transcribeFile(at: url)
    }

    func transcribeFile(at url: URL) {
        guard let apiKey = getAPIKey() else {
            state = .error("Please set your Deepgram API key in Settings first.")
            return
        }

        state = .transcribing
        interimText = ""
        finalText = ""
        cloudIndicatorVisible = true

        transcriptionTask = Task { [weak self] in
            guard let self else { return }
            do {
                let transcript = try await self.deepgram.transcribeFile(
                    fileURL: url,
                    apiKey: apiKey
                )
                await self.completeTranscript(transcript, source: .file)
            } catch {
                self.state = .error("Transcription failed: \(error.localizedDescription)")
                self.cloudIndicatorVisible = false
            }
        }
    }

    // MARK: - Clipboard

    func copyToClipboard() {
        let text = currentTranscriptText()
        guard !text.isEmpty else { return }
        ClipboardManager.copyToClipboard(text)
    }

    func pasteToFrontmostApp() {
        let text = currentTranscriptText()
        guard !text.isEmpty else { return }
        ClipboardManager.copyToClipboard(text)
        ClipboardManager.pasteToFrontmostApp()
    }

    private func currentTranscriptText() -> String {
        switch state {
        case .done(let transcript):
            return transcript
        default:
            return finalText.isEmpty ? interimText : finalText
        }
    }

    // MARK: - Reset

    func reset() {
        state = .idle
        interimText = ""
        finalText = ""
        cloudIndicatorVisible = false
        captureTask?.cancel()
        captureTask = nil
        transcriptionTask?.cancel()
        transcriptionTask = nil
    }

    // MARK: - Text Polish

    private static func recordingErrorMessage(for error: Error) -> String {
        if let captureError = error as? AudioCaptureError {
            return captureError.localizedDescription
        }
        return "Failed to start recording: \(error.localizedDescription)"
    }

    func polishTranscript(_ text: String) async -> String {
        guard polishEnabled, let apiKey = getOpenRouterAPIKey(), !apiKey.isEmpty else {
            return text
        }
        do {
            return try await polisher.polish(text, apiKey: apiKey)
        } catch {
            return text
        }
    }
}

extension Notification.Name {
    static let cloudScribePreferencesChanged = Notification.Name("cloudScribePreferencesChanged")
}