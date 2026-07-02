import AppKit
import SwiftUI

enum MenuBarIcon {
    static func image() -> NSImage? {
        if let bundled = NSImage(named: "MenuBarIcon") {
            bundled.isTemplate = true
            return bundled
        }

        let fallback = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "CloudScribe")
        fallback?.isTemplate = true
        return fallback
    }
}

struct MenuBarLabel: View {
    var isRecording: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = MenuBarIcon.image() {
                Image(nsImage: image)
                    .renderingMode(.template)
            } else {
                Image(systemName: "mic.fill")
            }
            if isRecording {
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                    .offset(x: 2, y: -2)
            }
        }
    }
}