import SwiftUI

struct TranscriptHistoryView: View {
    @ObservedObject var viewModel: TranscriptionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent transcripts")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(CloudScribeDesign.textPrimary)
                Spacer()
                if !viewModel.historyEntries.isEmpty {
                    Button("Clear") {
                        viewModel.clearHistory()
                    }
                    .font(.system(size: 10))
                    .buttonStyle(.plain)
                    .foregroundColor(CloudScribeDesign.errorColor)
                }
            }

            if viewModel.historyEntries.isEmpty {
                Text("Saved transcripts appear here when history is enabled.")
                    .font(.system(size: 10))
                    .foregroundColor(CloudScribeDesign.textSecondary)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(viewModel.historyEntries) { entry in
                            historyRow(entry)
                        }
                    }
                }
                .frame(maxHeight: 120)
            }
        }
    }

    private func historyRow(_ entry: TranscriptHistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: entry.source == .microphone ? "mic.fill" : "doc.fill")
                    .font(.system(size: 9))
                    .foregroundColor(CloudScribeDesign.volt)
                Text(entry.createdAt, style: .time)
                    .font(.system(size: 9))
                    .foregroundColor(CloudScribeDesign.textSecondary)
                Spacer()
                Button(action: { viewModel.loadHistoryEntry(entry) }) {
                    Image(systemName: "arrow.up.doc")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(CloudScribeDesign.volt)
                .help("Load into transcript")
                Button(action: { ClipboardManager.copyToClipboard(entry.text) }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(CloudScribeDesign.textSecondary)
                .help("Copy")
                Button(action: { viewModel.deleteHistoryEntry(entry) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .foregroundColor(CloudScribeDesign.errorColor)
                .help("Delete")
            }
            Text(entry.text)
                .font(.system(size: 11))
                .foregroundColor(CloudScribeDesign.textPrimary)
                .lineLimit(2)
        }
        .padding(8)
        .background(CloudScribeDesign.darkSecondary)
        .cornerRadius(6)
    }
}