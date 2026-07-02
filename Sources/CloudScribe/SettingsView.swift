import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    @Binding var isPresented: Bool

    @State private var apiKeyInput: String = ""
    @State private var openRouterKeyInput: String = ""
    @State private var showKey: Bool = false
    @State private var showOpenRouterKey: Bool = false
    @State private var saveConfirmation: Bool = false
    @State private var openRouterSaveConfirmation: Bool = false
    @State private var micStatus: MicrophonePermissionStatus = .notDetermined
    @State private var micRequestInFlight: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView
                Divider().background(CloudScribeDesign.darkSecondary)
                contentView
            }
        }
        .frame(width: 380)
        .background(CloudScribeDesign.darkBackground)
        .preferredColorScheme(.dark)
        .onAppear {
            loadExistingKeys()
            refreshMicrophoneStatus()
        }
    }

    private var headerView: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(CloudScribeDesign.volt)
            Spacer()
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(CloudScribeDesign.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(CloudScribeDesign.darkCard)
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            microphoneSection
            Divider().background(CloudScribeDesign.darkSecondary)
            deepgramSection
            Divider().background(CloudScribeDesign.darkSecondary)
            workflowSection
            Divider().background(CloudScribeDesign.darkSecondary)
            openRouterSection
            Divider().background(CloudScribeDesign.darkSecondary)
            aboutSection
        }
        .padding(20)
    }

    private var microphoneSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Microphone")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CloudScribeDesign.textPrimary)
                Spacer()
                micStatusBadge
            }

            Text(micStatus.settingsHint)
                .font(.system(size: 10))
                .foregroundColor(CloudScribeDesign.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if micStatus == .notDetermined {
                    Button(action: requestMicrophoneAccess) {
                        actionLabel(micRequestInFlight ? "Requesting…" : "Request Access", primary: true)
                    }
                    .buttonStyle(.plain)
                    .disabled(micRequestInFlight)
                }

                if micStatus != .granted {
                    Button(action: { MicrophonePermissionManager.openSystemSettings() }) {
                        actionLabel("Open System Settings", primary: false)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var micStatusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(micStatusBadgeColor)
                .frame(width: 6, height: 6)
            Text(micStatus.displayName)
                .font(.system(size: 10))
                .foregroundColor(micStatusBadgeColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(micStatusBadgeColor.opacity(0.15))
        .cornerRadius(4)
    }

    private var micStatusBadgeColor: Color {
        switch micStatus {
        case .notDetermined: return CloudScribeDesign.volt
        case .granted:       return .green
        case .denied:        return CloudScribeDesign.errorColor
        }
    }

    private var deepgramSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Deepgram API Key")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CloudScribeDesign.textPrimary)
                Spacer()
                statusBadge
            }

            keyField(text: $apiKeyInput, showKey: $showKey, placeholder: "Enter Deepgram API key")

            HStack(spacing: 8) {
                Button(action: saveDeepgramKey) {
                    actionLabel("Save", primary: true)
                }
                .buttonStyle(.plain)
                .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)

                Button(action: deleteDeepgramKey) {
                    actionLabel("Delete", primary: false, destructive: true)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.apiKeyStatus == .notSet)
            }

            if saveConfirmation {
                confirmationText("Deepgram API key saved to Keychain.")
            }
        }
    }

    private var workflowSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Workflow")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(CloudScribeDesign.textPrimary)

            Toggle(isOn: Binding(
                get: { viewModel.pillEnabled },
                set: { viewModel.setPillEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Floating pill")
                        .font(.system(size: 11))
                        .foregroundColor(CloudScribeDesign.textPrimary)
                    Text("Always-visible dictation surface. Drag to reposition.")
                        .font(.system(size: 10))
                        .foregroundColor(CloudScribeDesign.textSecondary)
                }
            }
            .toggleStyle(.switch)

            Toggle(isOn: Binding(
                get: { viewModel.autoPasteEnabled },
                set: { viewModel.setAutoPasteEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-paste on completion")
                        .font(.system(size: 11))
                        .foregroundColor(CloudScribeDesign.textPrimary)
                    Text("Copies transcript and sends ⌘V to the frontmost app when done.")
                        .font(.system(size: 10))
                        .foregroundColor(CloudScribeDesign.textSecondary)
                }
            }
            .toggleStyle(.switch)

            Toggle(isOn: Binding(
                get: { viewModel.hotkeyEnabled },
                set: { viewModel.setHotkeyEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Global hotkey")
                        .font(.system(size: 11))
                        .foregroundColor(CloudScribeDesign.textPrimary)
                    Text("Toggle recording from any app while CloudScribe is running.")
                        .font(.system(size: 10))
                        .foregroundColor(CloudScribeDesign.textSecondary)
                }
            }
            .toggleStyle(.switch)

            if viewModel.hotkeyEnabled {
                HotkeyRecorderView(viewModel: viewModel)
            }

            Toggle(isOn: Binding(
                get: { viewModel.historyEnabled },
                set: { viewModel.setHistoryEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Local transcript history")
                        .font(.system(size: 11))
                        .foregroundColor(CloudScribeDesign.textPrimary)
                    Text("Off by default. Saves text only on this Mac. Disabling clears saved transcripts.")
                        .font(.system(size: 10))
                        .foregroundColor(CloudScribeDesign.textSecondary)
                }
            }
            .toggleStyle(.switch)

            Toggle(isOn: Binding(
                get: { viewModel.polishEnabled },
                set: { viewModel.setPolishEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("OpenRouter text polish")
                        .font(.system(size: 11))
                        .foregroundColor(CloudScribeDesign.textPrimary)
                    Text("Optional grammar cleanup after transcription. Text only — never sends audio.")
                        .font(.system(size: 10))
                        .foregroundColor(CloudScribeDesign.textSecondary)
                }
            }
            .toggleStyle(.switch)
        }
    }

    private var openRouterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OpenRouter API Key")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(CloudScribeDesign.textPrimary)

            keyField(text: $openRouterKeyInput, showKey: $showOpenRouterKey, placeholder: "Optional — for text polish only")

            HStack(spacing: 8) {
                Button(action: saveOpenRouterKey) {
                    actionLabel("Save", primary: true)
                }
                .buttonStyle(.plain)
                .disabled(openRouterKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)

                Button(action: deleteOpenRouterKey) {
                    actionLabel("Delete", primary: false, destructive: true)
                }
                .buttonStyle(.plain)
            }

            if openRouterSaveConfirmation {
                confirmationText("OpenRouter key saved to Keychain.")
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("About")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(CloudScribeDesign.textPrimary)

            Text("CloudScribe uses Deepgram nova-3 for speech-to-text. Audio is sent to Deepgram's cloud servers for processing. Optional OpenRouter polish receives transcript text only.")
                .font(.system(size: 11))
                .foregroundColor(CloudScribeDesign.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Components

    private func keyField(text: Binding<String>, showKey: Binding<Bool>, placeholder: String) -> some View {
        HStack(spacing: 8) {
            Group {
                if showKey.wrappedValue {
                    TextField(placeholder, text: text)
                } else {
                    SecureField(placeholder, text: text)
                }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(CloudScribeDesign.textPrimary)
            .padding(8)
            .background(CloudScribeDesign.darkSecondary)
            .cornerRadius(6)

            Button(action: { showKey.wrappedValue.toggle() }) {
                Image(systemName: showKey.wrappedValue ? "eye.slash" : "eye")
                    .font(.system(size: 12))
                    .foregroundColor(CloudScribeDesign.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func actionLabel(_ title: String, primary: Bool, destructive: Bool = false) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(primary ? .black : (destructive ? CloudScribeDesign.errorColor : CloudScribeDesign.textPrimary))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(primary ? CloudScribeDesign.volt : CloudScribeDesign.darkSecondary)
            .cornerRadius(4)
    }

    private func confirmationText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundColor(.green)
            .transition(.opacity)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusBadgeColor)
                .frame(width: 6, height: 6)
            Text(statusBadgeText)
                .font(.system(size: 10))
                .foregroundColor(statusBadgeColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(statusBadgeColor.opacity(0.15))
        .cornerRadius(4)
    }

    private var statusBadgeColor: Color {
        switch viewModel.apiKeyStatus {
        case .notSet:   return CloudScribeDesign.textSecondary
        case .valid:    return .green
        case .checking: return CloudScribeDesign.volt
        }
    }

    private var statusBadgeText: String {
        switch viewModel.apiKeyStatus {
        case .notSet:   return "Not set"
        case .valid:    return "Saved"
        case .checking: return "Checking…"
        }
    }

    // MARK: - Actions

    private func refreshMicrophoneStatus() {
        micStatus = MicrophonePermissionManager.status
    }

    private func requestMicrophoneAccess() {
        micRequestInFlight = true
        Task { @MainActor in
            _ = await MicrophonePermissionManager.requestAccess(activateApp: true, showExplanation: true)
            refreshMicrophoneStatus()
            micRequestInFlight = false
        }
    }

    private func loadExistingKeys() {
        if let existing = viewModel.getAPIKey() {
            apiKeyInput = existing
        }
        if let openRouter = viewModel.getOpenRouterAPIKey() {
            openRouterKeyInput = openRouter
        }
    }

    private func saveDeepgramKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.saveAPIKey(trimmed)
        withAnimation { saveConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { saveConfirmation = false }
        }
    }

    private func deleteDeepgramKey() {
        viewModel.deleteAPIKey()
        apiKeyInput = ""
        saveConfirmation = false
    }

    private func saveOpenRouterKey() {
        let trimmed = openRouterKeyInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.saveOpenRouterAPIKey(trimmed)
        withAnimation { openRouterSaveConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { openRouterSaveConfirmation = false }
        }
    }

    private func deleteOpenRouterKey() {
        viewModel.deleteOpenRouterAPIKey()
        openRouterKeyInput = ""
        openRouterSaveConfirmation = false
    }
}