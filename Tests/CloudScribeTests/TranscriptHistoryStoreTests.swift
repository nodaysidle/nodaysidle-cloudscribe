import Testing
import Foundation
@testable import CloudScribe

@Suite struct TranscriptHistoryStoreTests {
    @Test("History add, cap, delete, and clear")
    func historyLifecycle() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cloudscribe-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = TranscriptHistoryStore(appSupportDirectory: tempDir)
        store.add(text: "First transcript", source: .microphone)
        store.add(text: "Second transcript", source: .file)

        let entries = store.load()
        #expect(entries.count == 2)
        #expect(entries.first?.text == "Second transcript")
        #expect(entries.first?.source == .file)

        if let id = entries.last?.id {
            store.delete(id: id)
            #expect(store.load().count == 1)
        }

        store.clear()
        #expect(store.load().isEmpty)
    }

    @Test("History ignores empty text")
    func ignoresEmptyText() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cloudscribe-tests-\(UUID().uuidString)", isDirectory: true)
        let store = TranscriptHistoryStore(appSupportDirectory: tempDir)
        store.add(text: "   ", source: .microphone)
        #expect(store.load().isEmpty)
    }
}