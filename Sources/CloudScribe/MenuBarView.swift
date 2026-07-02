import SwiftUI
import UniformTypeIdentifiers

// MARK: - Design Tokens

enum CloudScribeDesign {
    static let volt = Color(red: 200/255, green: 255/255, blue: 0/255)
    static let darkBackground = Color(red: 18/255, green: 18/255, blue: 18/255)
    static let darkCard = Color(red: 28/255, green: 28/255, blue: 30/255)
    static let darkSecondary = Color(red: 44/255, green: 44/255, blue: 46/255)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)
    static let errorColor = Color(red: 255/255, green: 69/255, blue: 58/255)
}

// MARK: - Menu Bar Popover View

@MainActor
struct MenuBarView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()
                .background(CloudScribeDesign.darkSecondary)

            cloudPrivacyStrip

            // Main content
            VStack(spacing: 12) {
                statusIndicatorView
                transcriptScrollView
                actionButtonsView
                if viewModel.historyEnabled {
                    TranscriptHistoryView(viewModel: viewModel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .background(CloudScribeDesign.darkSecondary)

            footerView
        }
        .frame(width: 320)
        .background(CloudScribeDesign.darkBackground)
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("CloudScribe")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(CloudScribeDesign.volt)

            Spacer()

            apiKeyBadge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(CloudScribeDesign.darkCard)
    }

    private var apiKeyBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(viewModel.apiKeyStatus == .valid ? Color.green : CloudScribeDesign.textSecondary)
                .frame(width: 6, height: 6)
            Text(viewModel.apiKeyStatus == .valid ? "Key ready" : "No key")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(CloudScribeDesign.textSecondary)
        }
    }

    private var cloudPrivacyStrip: some View {
        HStack(spacing: 6) {
            Image(systemName: "icloud.and.arrow.up.fill")
                .font(.system(size: 10))
                .foregroundColor(CloudScribeDesign.volt)
            Text("Audio sent to cloud for transcription")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(CloudScribeDesign.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if viewModel.cloudIndicatorVisible {
                ProgressView()
                    .scaleEffect(0.55)
                    .frame(width: 12, height: 12)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background(CloudScribeDesign.darkCard.opacity(0.85))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Audio sent to cloud for transcription")
    }

    // MARK: - Status

    private var statusIndicatorView: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.system(size: 12))
                .foregroundColor(CloudScribeDesign.textSecondary)
            Spacer()
        }
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .idle:         return CloudScribeDesign.textSecondary
        case .recording:    return .red
        case .transcribing: return CloudScribeDesign.volt
        case .done:         return .green
        case .error:        return CloudScribeDesign.errorColor
        }
    }

    private var statusText: String {
        switch viewModel.state {
        case .idle:         return "Ready"
        case .recording:    return "Recording…"
        case .transcribing: return "Transcribing…"
        case .done:         return "Done"
        case .error(let m): return "Error: \(m)"
        }
    }

    // MARK: - Transcript

    private var transcriptScrollView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            transcriptContent
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 60, maxHeight: 220)
        .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
            handleDroppedFiles(providers)
        }
    }

    private var transcriptContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !viewModel.interimText.isEmpty {
                Text(viewModel.interimText)
                    .font(.system(size: 13))
                    .foregroundColor(CloudScribeDesign.textSecondary)
                    .italic()
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(CloudScribeDesign.darkSecondary)
                    .cornerRadius(6)
            }

            if !displayedFinalText.isEmpty {
                Text(displayedFinalText)
                    .font(.system(size: 13))
                    .foregroundColor(CloudScribeDesign.textPrimary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(CloudScribeDesign.darkSecondary)
                    .cornerRadius(6)
            }

            if viewModel.interimText.isEmpty && displayedFinalText.isEmpty && viewModel.state == .idle {
                Text("Tap Record for live mic, import a file, or drop audio here.\nTranscription appears in real time.")
                    .font(.system(size: 12))
                    .foregroundColor(CloudScribeDesign.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
    }

    private var displayedFinalText: String {
        if !viewModel.finalText.isEmpty {
            return viewModel.finalText
        }
        if case .done(let transcript) = viewModel.state {
            return transcript
        }
        return ""
    }

    private func handleDroppedFiles(_ providers: [NSItemProvider]) -> Bool {
        guard viewModel.state != .recording, viewModel.state != .transcribing else {
            return false
        }

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    let resolvedURL: URL?
                    if let url = item as? URL {
                        resolvedURL = url
                    } else if let nsurl = item as? NSURL {
                        resolvedURL = nsurl as URL
                    } else if let data = item as? Data {
                        resolvedURL = URL(dataRepresentation: data, relativeTo: nil)
                    } else {
                        resolvedURL = nil
                    }
                    guard let resolvedURL else { return }
                    Task { @MainActor in
                        viewModel.transcribeFile(at: resolvedURL)
                    }
                }
                return true
            }
        }
        return false
    }

    // MARK: - Action Buttons

    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            // Record / Stop
            recordButton

            // File import
            importButton

            // Copy
            copyButton

            // Paste
            pasteButton
        }
    }

    private var recordButton: some View {
        Button(action: {
            switch viewModel.state {
            case .idle, .done, .error:
                viewModel.startRecording()
            case .recording:
                viewModel.stopRecording()
            case .transcribing:
                break
            }
        }) {
            Image(systemName: recordButtonIcon)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.borderless)
        .background(recordButtonColor)
        .foregroundColor(.white)
        .cornerRadius(8)
        .disabled(viewModel.state == .transcribing)
        .help(recordButtonHelp)
    }

    private var recordButtonIcon: String {
        switch viewModel.state {
        case .recording: return "stop.fill"
        default:         return "mic.fill"
        }
    }

    private var recordButtonColor: Color {
        switch viewModel.state {
        case .recording:    return .red
        case .transcribing: return CloudScribeDesign.darkSecondary
        default:            return CloudScribeDesign.volt.opacity(0.8)
        }
    }

    private var recordButtonHelp: String {
        switch viewModel.state {
        case .recording: return "Stop Recording"
        default:         return "Start Recording"
        }
    }

    private var importButton: some View {
        Button(action: { viewModel.importAudioFile() }) {
            Image(systemName: "doc.badge.plus")
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.borderless)
        .background(CloudScribeDesign.darkSecondary)
        .foregroundColor(CloudScribeDesign.volt)
        .cornerRadius(8)
        .disabled(viewModel.state == .recording || viewModel.state == .transcribing)
        .help("Import Audio File")
    }

    private var copyButton: some View {
        Button(action: { viewModel.copyToClipboard() }) {
            Image(systemName: "doc.on.doc")
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.borderless)
        .background(CloudScribeDesign.darkSecondary)
        .foregroundColor(CloudScribeDesign.volt)
        .cornerRadius(8)
        .disabled(!hasTranscript)
        .help("Copy to Clipboard")
    }

    private var pasteButton: some View {
        Button(action: { viewModel.pasteToFrontmostApp() }) {
            Image(systemName: "arrow.turn.down.left")
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.borderless)
        .background(CloudScribeDesign.darkSecondary)
        .foregroundColor(CloudScribeDesign.volt)
        .cornerRadius(8)
        .disabled(!hasTranscript)
        .help("Paste to Frontmost App")
    }

    private var hasTranscript: Bool {
        if viewModel.finalText.isEmpty {
            if case .done(let t) = viewModel.state {
                return !t.isEmpty
            }
            return false
        }
        return true
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Text("Quit")
                    .font(.system(size: 10))
                    .foregroundColor(CloudScribeDesign.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Quit CloudScribe")

            if viewModel.hotkeyEnabled {
                Text(viewModel.hotkeyBinding.displayString)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(CloudScribeDesign.textSecondary)
                    .help("Global hotkey toggles recording")
            }

            Spacer()

            Button(action: { openSettings() }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 12))
                    .foregroundColor(CloudScribeDesign.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(CloudScribeDesign.darkCard)
    }
}

// MARK: - Preview

#if DEBUG
struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = TranscriptionViewModel()
        MenuBarView(viewModel: vm)
    }
}
#endif
