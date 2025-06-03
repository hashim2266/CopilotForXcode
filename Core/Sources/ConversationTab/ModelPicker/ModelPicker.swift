import SwiftUI
import ChatService
import Persist
import ComposableArchitecture
import GitHubCopilotService
import Combine
import ConversationServiceProvider

public let SELECTED_LLM_KEY = "selectedLLM"
public let SELECTED_CHATMODE_KEY = "selectedChatMode"

extension AppState {
    func getSelectedModelFamily() -> String? {
        if let savedModel = get(key: SELECTED_LLM_KEY),
           let modelFamily = savedModel["modelFamily"]?.stringValue {
            return modelFamily
        }
        return nil
    }

    func getSelectedModelName() -> String? {
        if let savedModel = get(key: SELECTED_LLM_KEY),
           let modelName = savedModel["modelName"]?.stringValue {
            return modelName
        }
        return nil
    }

    func setSelectedModel(_ model: LLMModel) {
        update(key: SELECTED_LLM_KEY, value: model)
    }

    func modelScope() -> PromptTemplateScope {
        return isAgentModeEnabled() ? .agentPanel : .chatPanel
    }
    
    func getSelectedChatMode() -> String {
        if let savedMode = get(key: SELECTED_CHATMODE_KEY),
           let modeName = savedMode.stringValue {
            return convertChatMode(modeName)
        }
        return "Ask"
    }

    func setSelectedChatMode(_ mode: String) {
        update(key: SELECTED_CHATMODE_KEY, value: mode)
    }

    func isAgentModeEnabled() -> Bool {
        return getSelectedChatMode() == "Agent"
    }

    private func convertChatMode(_ mode: String) -> String {
        switch mode {
        case "Agent":
            return "Agent"
        default:
            return "Ask"
        }
    }
}

class CopilotModelManagerObservable: ObservableObject {
    static let shared = CopilotModelManagerObservable()
    
    @Published var availableChatModels: [LLMModel] = []
    @Published var availableAgentModels: [LLMModel] = []
    @Published var defaultChatModel: LLMModel?
    @Published var defaultAgentModel: LLMModel?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initial load
        availableChatModels = CopilotModelManager.getAvailableChatLLMs(scope: .chatPanel)
        availableAgentModels = CopilotModelManager.getAvailableChatLLMs(scope: .agentPanel)
        defaultChatModel = CopilotModelManager.getDefaultChatModel(scope: .chatPanel)
        defaultAgentModel = CopilotModelManager.getDefaultChatModel(scope: .agentPanel)
        
        // Setup notification to update when models change
        NotificationCenter.default.publisher(for: .gitHubCopilotModelsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.availableChatModels = CopilotModelManager.getAvailableChatLLMs(scope: .chatPanel)
                self?.availableAgentModels = CopilotModelManager.getAvailableChatLLMs(scope: .agentPanel)
                self?.defaultChatModel = CopilotModelManager.getDefaultChatModel(scope: .chatPanel)
                self?.defaultAgentModel = CopilotModelManager.getDefaultChatModel(scope: .agentPanel)
            }
            .store(in: &cancellables)
    }
}

extension CopilotModelManager {
    static func getAvailableChatLLMs(scope: PromptTemplateScope = .chatPanel) -> [LLMModel] {
        let LLMs = CopilotModelManager.getAvailableLLMs()
        return LLMs.filter(
            { $0.scopes.contains(scope) }
        ).map {
            LLMModel(modelName: $0.modelName, modelFamily: $0.modelFamily)
        }
    }

    static func getDefaultChatModel(scope: PromptTemplateScope = .chatPanel) -> LLMModel? {
        let LLMs = CopilotModelManager.getAvailableLLMs()
        let LLMsInScope = LLMs.filter({ $0.scopes.contains(scope) })
        let defaultModel = LLMsInScope.first(where: { $0.isChatDefault })
        // If a default model is found, return it
        if let defaultModel = defaultModel {
            return LLMModel(modelName: defaultModel.modelName, modelFamily: defaultModel.modelFamily)
        }

        // Fallback to gpt-4.1 if available
        let gpt4_1 = LLMsInScope.first(where: { $0.modelFamily == "gpt-4.1" })
        if let gpt4_1 = gpt4_1 {
            return LLMModel(modelName: gpt4_1.modelName, modelFamily: gpt4_1.modelFamily)
        }

        // If no default model is found, fallback to the first available model
        if let firstModel = LLMsInScope.first {
            return LLMModel(modelName: firstModel.modelName, modelFamily: firstModel.modelFamily)
        }

        return nil
    }
}

struct LLMModel: Codable, Hashable {
    let modelName: String
    let modelFamily: String
}

struct ModelPicker: View {
    @State private var selectedModel = ""
    @State private var isHovered = false
    @State private var isPressed = false
    @ObservedObject private var modelManager = CopilotModelManagerObservable.shared
    static var lastRefreshModelsTime: Date = .init(timeIntervalSince1970: 0)

    @State private var chatMode = "Ask"
    @State private var isAgentPickerHovered = false

    init() {
        let initialModel = AppState.shared.getSelectedModelName() ?? CopilotModelManager.getDefaultChatModel()?.modelName ?? ""
        self._selectedModel = State(initialValue: initialModel)
        updateAgentPicker()
    }

    var models: [LLMModel] {
        AppState.shared.isAgentModeEnabled() ? modelManager.availableAgentModels : modelManager.availableChatModels
    }

    var defaultModel: LLMModel? {
        AppState.shared.isAgentModeEnabled() ? modelManager.defaultAgentModel : modelManager.defaultChatModel
    }

    func updateCurrentModel() {
        selectedModel = AppState.shared.getSelectedModelName() ?? defaultModel?.modelName ?? ""
    }
    
    func updateAgentPicker() {
        self.chatMode = AppState.shared.getSelectedChatMode()
    }
    
    func switchModelsForScope(_ scope: PromptTemplateScope) {
        let newModeModels = CopilotModelManager.getAvailableChatLLMs(scope: scope)
        
        if let currentModel = AppState.shared.getSelectedModelName() {
            if !newModeModels.isEmpty && !newModeModels.contains(where: { $0.modelName == currentModel }) {
                let defaultModel = CopilotModelManager.getDefaultChatModel(scope: scope)
                if let defaultModel = defaultModel {
                    selectedModel = defaultModel.modelName
                    AppState.shared.setSelectedModel(defaultModel)
                } else {
                    selectedModel = newModeModels[0].modelName
                    AppState.shared.setSelectedModel(newModeModels[0])
                }
            }
        }
        
        // Force refresh models
        self.updateCurrentModel()
    }

    var body: some View {
        WithPerceptionTracking {
            HStack(spacing: 0) {
                // Custom segmented control with color change
                ChatModePicker(chatMode: $chatMode, onScopeChange: switchModelsForScope)
                    .onAppear() {
                        updateAgentPicker()
                    }
                
                Group{
                    // Model Picker
                    if !models.isEmpty && !selectedModel.isEmpty {
                        
                        Menu(selectedModel) {
                            ForEach(models, id: \.self) { option in
                                Button {
                                    selectedModel = option.modelName
                                    AppState.shared.setSelectedModel(option)
                                } label: {
                                    if selectedModel == option.modelName {
                                        Text("✓ \(option.modelName)")
                                    } else {
                                        Text("    \(option.modelName)")
                                    }
                                }
                            }
                        }
                        .menuStyle(BorderlessButtonMenuStyle())
                        .frame(maxWidth: labelWidth())
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isHovered ? Color.gray.opacity(0.1) : Color.clear)
                        )
                        .onHover { hovering in
                            isHovered = hovering
                        }
                    } else {
                        EmptyView()
                    }
                }
            }
            .onAppear() {
                updateCurrentModel()
                Task {
                    await refreshModels()
                }
            }
            .onChange(of: defaultModel) { _ in
                updateCurrentModel()
            }
            .onChange(of: models) { _ in
                updateCurrentModel()
            }
            .onChange(of: chatMode) { _ in
                updateCurrentModel()
            }
        }
    }

    func labelWidth() -> CGFloat {
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let attributes = [NSAttributedString.Key.font: font]
        let width = selectedModel.size(withAttributes: attributes).width
        return CGFloat(width + 20)
    }

    func agentPickerLabelWidth() -> CGFloat {
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let attributes = [NSAttributedString.Key.font: font]
        let width = chatMode.size(withAttributes: attributes).width
        return CGFloat(width + 20)
    }

    @MainActor
    func refreshModels() async {
        let now = Date()
        if now.timeIntervalSince(Self.lastRefreshModelsTime) < 60 {
            return
        }

        Self.lastRefreshModelsTime = now
        let copilotModels = await SharedChatService.shared.copilotModels()
        if !copilotModels.isEmpty {
            CopilotModelManager.updateLLMs(copilotModels)
        }
    }
}

struct ModelPicker_Previews: PreviewProvider {
    static var previews: some View {
        ModelPicker()
    }
}
