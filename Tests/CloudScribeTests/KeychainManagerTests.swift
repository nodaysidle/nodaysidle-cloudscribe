import Testing
import Foundation
@testable import CloudScribe

// MARK: - Keychain Manager Tests

@Suite struct KeychainManagerTests {

    @Test("Keychain can save, read, and delete values")
    func saveReadDelete() throws {
        // Use a unique service name to avoid collisions
        let service = "com.nodaysidle.cloudscribe.tests.\(UUID().uuidString)"
        let keychain = KeychainManager(service: service)
        let account = "TEST_KEY"
        let value = "«test-placeholder»"

        // Should not exist initially
        do {
            _ = try keychain.read(account: account)
            // If we get here, delete any leftover first
            try? keychain.delete(account: account)
        } catch KeychainError.itemNotFound {
            // Expected
        }

        // Save
        try keychain.save(key: value, account: account)

        // Read
        let readValue = try keychain.read(account: account)
        #expect(readValue == value)

        // Update
        let newValue = "«test-placeholder»"
        try keychain.save(key: newValue, account: account)
        let updatedValue = try keychain.read(account: account)
        #expect(updatedValue == newValue)

        // Delete
        try keychain.delete(account: account)

        // Verify deleted
        do {
            _ = try keychain.read(account: account)
            #expect(Bool(false), "Expected itemNotFound after delete")
        } catch KeychainError.itemNotFound {
            // Expected
        }
    }

    @Test("Keychain read throws itemNotFound for missing key")
    func readMissingThrowsNotFound() throws {
        let service = "com.nodaysidle.cloudscribe.tests.\(UUID().uuidString)"
        let keychain = KeychainManager(service: service)

        do {
            _ = try keychain.read(account: "NONEXISTENT")
            #expect(Bool(false), "Expected itemNotFound")
        } catch KeychainError.itemNotFound {
            // Expected
        }
    }

    @Test("Keychain delete nonexistent does not throw")
    func deleteNonexistentDoesNotThrow() throws {
        let service = "com.nodaysidle.cloudscribe.tests.\(UUID().uuidString)"
        let keychain = KeychainManager(service: service)

        // Should not throw
        try keychain.delete(account: "NONEXISTENT")
    }
}
