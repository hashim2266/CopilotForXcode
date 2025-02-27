import ComposableArchitecture
import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage(\.extensionPermissionShown) var extensionPermissionShown: Bool
    @AppStorage(\.quitXPCServiceOnXcodeAndAppQuit) var quitXPCServiceOnXcodeAndAppQuit: Bool
    @State private var shouldPresentExtensionPermissionAlert = false

    let store: StoreOf<General>

    var accessibilityPermissionSubtitle: String {
        switch store.isAccessibilityPermissionGranted {
        case .granted:
            return "Granted"
        case .notGranted:
            return "Not Granted. Required to run. Click to open System Preferences."
        case .unknown:
            return ""
        }
    }

    var body: some View {
        SettingsSection(title: "General") {
            SettingsToggle(
                title: "Quit GitHub Copilot when Xcode App is closed",
                isOn: $quitXPCServiceOnXcodeAndAppQuit
            )
            Divider()
            SettingsLink(
                url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
                title: "Accessibility Permission",
                subtitle: accessibilityPermissionSubtitle,
                badge: store.isAccessibilityPermissionGranted == .notGranted ?
                    .init(
                        text: "Not Granted",
                        level: .danger
                    ) : nil
            )
            Divider()
            SettingsLink(
                url: "x-apple.systempreferences:com.apple.ExtensionsPreferences",
                title: "Extension Permission",
                subtitle: """
                Check for GitHub Copilot in Xcode's Editor menu. \
                Restart Xcode if greyed out.
                """
            )
        } footer: {
            HStack {
                Spacer()
                Button("?") {
                    NSWorkspace.shared.open(
                        URL(string: "https://github.com/github/CopilotForXcode/blob/main/TROUBLESHOOTING.md")!
                    )
                }
                .clipShape(Circle())
            }
        }
        .alert(
            "Enable Extension Permission",
            isPresented: $shouldPresentExtensionPermissionAlert
        ) {
            Button("Open System Preferences", action: {
                let url = "x-apple.systempreferences:com.apple.ExtensionsPreferences"
                NSWorkspace.shared.open(URL(string: url)!)
            }).keyboardShortcut(.defaultAction)
            Button("Close", role: .cancel, action: {})
        } message: {
            Text("Enable GitHub Copilot under Xcode Source Editor extensions")
        }
        .task {
            if extensionPermissionShown { return }
            extensionPermissionShown = true
            shouldPresentExtensionPermissionAlert = true
        }
    }
}

#Preview {
    GeneralSettingsView(
        store: .init(initialState: .init(), reducer: { General() })
    )
}
