import AppKit
import SwiftUI

@MainActor
final class FloatingPillWindowController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private weak var hostedViewModel: TranscriptionViewModel?

    func configure(viewModel: TranscriptionViewModel) {
        hostedViewModel = viewModel
        guard UserPreferences.pillEnabled else {
            hide()
            return
        }

        if let panel {
            panel.contentView = NSHostingView(rootView: FloatingPillView(viewModel: viewModel))
        } else {
            let origin = UserPreferences.pillWindowOrigin()
            let frame = NSRect(origin: origin, size: NSSize(width: 340, height: 72))
            let panel = NSPanel(
                contentRect: frame,
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered,
                defer: false
            )
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.isMovableByWindowBackground = true
            panel.hidesOnDeactivate = false
            panel.delegate = self
            panel.contentView = NSHostingView(rootView: FloatingPillView(viewModel: viewModel))
            self.panel = panel
        }
        hostedViewModel = viewModel
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func windowDidMove(_ notification: Notification) {
        guard let panel else { return }
        UserPreferences.savePillWindowOrigin(panel.frame.origin)
    }
}