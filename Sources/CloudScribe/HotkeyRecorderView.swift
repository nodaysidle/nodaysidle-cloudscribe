import SwiftUI
import AppKit

/// Captures a new global hotkey binding from the next key press.
struct HotkeyRecorderView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    @State private var isCapturing = false
    @State private var eventMonitor: Any?

    var body: some View {
        HStack(spacing: 8) {
            Text(viewModel.hotkeyBinding.displayString)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(CloudScribeDesign.volt)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(CloudScribeDesign.darkSecondary)
                .cornerRadius(6)

            Button(isCapturing ? "Press keys…" : "Change") {
                if isCapturing {
                    stopCapture()
                } else {
                    startCapture()
                }
            }
            .font(.system(size: 11, weight: .semibold))
            .buttonStyle(.plain)
            .foregroundColor(isCapturing ? CloudScribeDesign.volt : CloudScribeDesign.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(CloudScribeDesign.darkSecondary)
            .cornerRadius(4)

            if isCapturing {
                Button("Cancel") { stopCapture() }
                    .font(.system(size: 10))
                    .buttonStyle(.plain)
                    .foregroundColor(CloudScribeDesign.textSecondary)
            }
        }
    }

    private func startCapture() {
        stopCapture()
        isCapturing = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                stopCapture()
                return nil
            }

            let modifiers = HotkeyBinding.carbonModifiers(from: event.modifierFlags)
            guard modifiers != 0 else { return event }

            let binding = HotkeyBinding(keyCode: UInt32(event.keyCode), carbonModifiers: modifiers)
            viewModel.setHotkeyBinding(binding)
            stopCapture()
            return nil
        }
    }

    private func stopCapture() {
        isCapturing = false
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }
}