@preconcurrency import AVFoundation
import AppKit
import Foundation

// MARK: - Status

enum MicrophonePermissionStatus: Equatable, Sendable {
    case notDetermined
    case granted
    case denied

    var displayName: String {
        switch self {
        case .notDetermined: return "Not requested"
        case .granted:       return "Allowed"
        case .denied:        return "Denied"
        }
    }

    var settingsHint: String {
        switch self {
        case .notDetermined:
            return "CloudScribe only appears in System Settings after you request access. Tap Request Access — macOS will show a permission dialog."
        case .granted:
            return "Microphone access is enabled. Live dictation can use your default input device."
        case .denied:
            return "Microphone access is off. Tap Open System Settings and enable CloudScribe. If CloudScribe is missing from the list, quit the app, tap Request Access again, or run: tccutil reset Microphone com.nodaysidle.cloudscribe"
        }
    }
}

// MARK: - Manager

enum MicrophonePermissionManager {
    /// Uses AVCaptureDevice — the macOS API that registers apps in System Settings → Microphone.
    static var status: MicrophonePermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    /// Requests microphone access. Optionally raises the app so the system prompt is visible.
    @MainActor
    @discardableResult
    static func requestAccess(activateApp: Bool = true, showExplanation: Bool = false) async -> Bool {
        let current = status
        if current == .granted { return true }
        if current == .denied { return false }

        if showExplanation {
            guard showPermissionExplanationAlert() else { return false }
        }

        if activateApp {
            raiseForPermissionPrompt()
        }

        let granted = await AVCaptureDevice.requestAccess(for: .audio)

        if activateApp {
            try? await Task.sleep(for: .milliseconds(250))
            lowerAfterPermissionPrompt()
        }

        return granted
    }

    /// Synchronous permission gate used by the audio capture path.
    static func requireAccess(activateApp: Bool = true) throws {
        switch status {
        case .granted:
            return
        case .denied:
            throw AudioCaptureError.microphoneAccessDenied
        case .notDetermined:
            let granted = requestAccessSync(activateApp: activateApp)
            guard granted else {
                throw AudioCaptureError.microphoneAccessDenied
            }
        }
    }

    @MainActor
    static func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Private

    private static func requestAccessSync(activateApp: Bool) -> Bool {
        if activateApp {
            runOnMainActorSync(raiseForPermissionPrompt)
        }

        let semaphore = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var granted = false
        AVCaptureDevice.requestAccess(for: .audio) { allowed in
            granted = allowed
            if activateApp {
                runOnMainActorAsync {
                    lowerAfterPermissionPrompt()
                }
            }
            semaphore.signal()
        }
        semaphore.wait()
        return granted
    }

    @MainActor
    private static func showPermissionExplanationAlert() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Microphone Access Required"
        alert.informativeText = """
        CloudScribe needs microphone access for live dictation.

        Click Continue, then Allow in the macOS dialog. CloudScribe will appear in System Settings → Privacy & Security → Microphone.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Continue")
        alert.addButton(withTitle: "Not Now")
        return alert.runModal() == .alertFirstButtonReturn
    }

    @MainActor
    private static func raiseForPermissionPrompt() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    @MainActor
    private static func lowerAfterPermissionPrompt() {
        NSApp.setActivationPolicy(.accessory)
    }

    private static func runOnMainActorSync(_ operation: @MainActor @Sendable () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(operation)
        } else {
            DispatchQueue.main.sync {
                MainActor.assumeIsolated(operation)
            }
        }
    }

    private static func runOnMainActorAsync(_ operation: @escaping @MainActor @Sendable () -> Void) {
        DispatchQueue.main.async {
            Task { @MainActor in
                operation()
            }
        }
    }
}