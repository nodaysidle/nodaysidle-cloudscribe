import SwiftUI
import AppKit

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate, @unchecked Sendable {
    let hotkeyManager = GlobalHotkeyManager()
    private nonisolated(unsafe) var pillControllerStorage: FloatingPillWindowController?
    private nonisolated(unsafe) var preferencesObserver: NSObjectProtocol?
    private nonisolated(unsafe) var didBootstrap = false

    @MainActor
    private func pillController() -> FloatingPillWindowController {
        if let pillControllerStorage { return pillControllerStorage }
        let controller = FloatingPillWindowController()
        pillControllerStorage = controller
        return controller
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        reloadHotkey()
        preferencesObserver = NotificationCenter.default.addObserver(
            forName: .cloudScribePreferencesChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadHotkey()
            Task { @MainActor in
                if let viewModel = CloudScribeApp.sharedViewModel {
                    self?.reloadPill(viewModel: viewModel)
                }
            }
        }
    }

    @MainActor
    private func reloadPill(viewModel: TranscriptionViewModel) {
        if UserPreferences.pillEnabled {
            pillController().configure(viewModel: viewModel)
        } else {
            pillController().hide()
        }
    }

    private func reloadHotkey() {
        hotkeyManager.setEnabled(UserPreferences.hotkeyEnabled, binding: UserPreferences.hotkeyBinding)
    }

    @MainActor
    func bootstrapIfNeeded(viewModel: TranscriptionViewModel) {
        guard !didBootstrap else { return }
        didBootstrap = true
        CloudScribeApp.sharedViewModel = viewModel
        reloadPill(viewModel: viewModel)
    }

    deinit {
        if let preferencesObserver {
            NotificationCenter.default.removeObserver(preferencesObserver)
        }
    }
}

// MARK: - Main App

@main
struct CloudScribeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = TranscriptionViewModel()
    @MainActor static weak var sharedViewModel: TranscriptionViewModel?

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
                .task {
                    // Defer pill/hotkey wiring until after MenuBarExtra finishes its first layout pass.
                    try? await Task.sleep(for: .milliseconds(500))
                    await appDelegate.bootstrapIfNeeded(viewModel: viewModel)
                }
        } label: {
            MenuBarLabel(isRecording: viewModel.isRecording)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(viewModel: viewModel, isPresented: .constant(true))
                .frame(width: 400, height: 560)
        }
    }
}