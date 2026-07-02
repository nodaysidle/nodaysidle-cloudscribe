import SwiftUI

struct FloatingPillView: View {
    @ObservedObject var viewModel: TranscriptionViewModel

    var body: some View {
        HStack(spacing: 10) {
            recordButton
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(CloudScribeDesign.volt)
                Text(previewText)
                    .font(.system(size: 11))
                    .foregroundColor(previewTextColor)
                    .lineLimit(previewLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Image(systemName: "icloud.and.arrow.up.fill")
                .font(.system(size: 11))
                .foregroundColor(CloudScribeDesign.volt.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(CloudScribeDesign.darkCard)
                .overlay(
                    Capsule()
                        .strokeBorder(borderColor, lineWidth: viewModel.isRecording ? 2 : 1)
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
        .frame(minWidth: 300, maxWidth: 380)
    }

    private var recordButton: some View {
        Button(action: toggleRecording) {
            Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(viewModel.isRecording ? Color.red : CloudScribeDesign.volt.opacity(0.85))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.state == .transcribing)
        .help(viewModel.isRecording ? "Stop recording" : "Start recording")
    }

    private var statusTitle: String {
        switch viewModel.state {
        case .idle: return "CloudScribe"
        case .recording: return "Recording"
        case .transcribing: return "Transcribing"
        case .done: return "Done"
        case .error: return "Error"
        }
    }

    private var previewText: String {
        if case .error(let message) = viewModel.state { return message }
        if viewModel.isRecording || viewModel.state == .transcribing {
            let live = combinedLiveText
            if !live.isEmpty { return live }
            if viewModel.isRecording { return "Listening… audio sent to cloud" }
        }
        if !viewModel.finalText.isEmpty { return viewModel.finalText }
        return "Tap mic or use \(viewModel.hotkeyBinding.displayString)"
    }

    private var combinedLiveText: String {
        let committed = viewModel.finalText.trimmingCharacters(in: .whitespacesAndNewlines)
        let pending = viewModel.interimText.trimmingCharacters(in: .whitespacesAndNewlines)
        if committed.isEmpty { return pending }
        if pending.isEmpty { return committed }
        return committed + " " + pending
    }

    private var previewLineLimit: Int? {
        if case .error = viewModel.state { return 4 }
        return 2
    }

    private var previewTextColor: Color {
        if case .error = viewModel.state { return CloudScribeDesign.errorColor }
        return CloudScribeDesign.textPrimary
    }

    private var borderColor: Color {
        if case .error = viewModel.state { return CloudScribeDesign.errorColor.opacity(0.8) }
        if viewModel.isRecording { return .red.opacity(0.8) }
        return CloudScribeDesign.volt.opacity(0.35)
    }

    private func toggleRecording() {
        switch viewModel.state {
        case .recording:
            viewModel.stopRecording()
        case .idle, .done, .error:
            viewModel.startRecording()
        case .transcribing:
            break
        }
    }
}