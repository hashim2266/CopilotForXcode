import SwiftUI
import Persist
import ConversationServiceProvider

public extension Notification.Name {
    static let gitHubCopilotChatModeDidChange = Notification
        .Name("com.github.CopilotForXcode.ChatModeDidChange")
}

public struct ChatModePicker: View {
    @Binding var chatMode: String
    @Environment(\.colorScheme) var colorScheme
    var onScopeChange: (PromptTemplateScope) -> Void
    
    public init(chatMode: Binding<String>, onScopeChange: @escaping (PromptTemplateScope) -> Void = { _ in }) {
        self._chatMode = chatMode
        self.onScopeChange = onScopeChange
    }

    public var body: some View {
        HStack(spacing: -1) {
            ModeButton(
                title: "Ask",
                isSelected: chatMode == "Ask",
                activeBackground: colorScheme == .dark ? Color.white.opacity(0.25) : Color.white,
                activeTextColor: Color.primary,
                inactiveTextColor: Color.primary.opacity(0.5),
                action: {
                    chatMode = "Ask"
                    AppState.shared.setSelectedChatMode("Ask")
                    onScopeChange(.chatPanel)
                    NotificationCenter.default.post(
                        name: .gitHubCopilotChatModeDidChange,
                        object: nil
                    )
                }
            )
            
            ModeButton(
                title: "Agent",
                isSelected: chatMode == "Agent",
                activeBackground: Color.blue,
                activeTextColor: Color.white,
                inactiveTextColor: Color.primary.opacity(0.5),
                action: {
                    chatMode = "Agent"
                    AppState.shared.setSelectedChatMode("Agent")
                    onScopeChange(.agentPanel)
                    NotificationCenter.default.post(
                        name: .gitHubCopilotChatModeDidChange,
                        object: nil
                    )
                }
            )
        }
        .padding(1)
        .frame(height: 20, alignment: .topLeading)
        .background(.primary.opacity(0.1))
        .cornerRadius(5)
        .padding(4)
        .help("Set Mode")
    }
}
