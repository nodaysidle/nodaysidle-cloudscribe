import Foundation

enum TranscriptSource: String, Codable, Sendable, Equatable {
    case microphone
    case file
}

struct TranscriptHistoryEntry: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let text: String
    let source: TranscriptSource
    let createdAt: Date

    init(id: UUID = UUID(), text: String, source: TranscriptSource, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.source = source
        self.createdAt = createdAt
    }
}

/// Opt-in local transcript history. Text only — never stores audio.
struct TranscriptHistoryStore {
    static let maxEntries = 20
    private static let filename = "transcript-history.json"

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(appSupportDirectory: URL? = nil) {
        let base = appSupportDirectory ?? FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let folder = base.appendingPathComponent("com.nodaysidle.cloudscribe", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent(Self.filename)
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() -> [TranscriptHistoryEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? decoder.decode([TranscriptHistoryEntry].self, from: data)) ?? []
    }

    func save(_ entries: [TranscriptHistoryEntry]) {
        let trimmed = Array(entries.prefix(Self.maxEntries))
        guard let data = try? encoder.encode(trimmed) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func add(text: String, source: TranscriptSource) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var entries = load()
        entries.insert(TranscriptHistoryEntry(text: trimmed, source: source), at: 0)
        save(entries)
    }

    func delete(id: UUID) {
        var entries = load()
        entries.removeAll { $0.id == id }
        save(entries)
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}