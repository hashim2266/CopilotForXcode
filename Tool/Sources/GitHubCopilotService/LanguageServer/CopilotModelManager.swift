import ConversationServiceProvider
import Foundation

public extension Notification.Name {
    static let gitHubCopilotModelsDidChange = Notification
        .Name("com.github.CopilotForXcode.CopilotModelsDidChange")
}

public class CopilotModelManager {
    private static var availableLLMs: [CopilotModel] = []
    
    public static func updateLLMs(_ models: [CopilotModel]) {
        let sortedModels = models.sorted(by: { $0.modelName.lowercased() < $1.modelName.lowercased() })
        guard sortedModels != availableLLMs else { return }
        availableLLMs = sortedModels
        NotificationCenter.default.post(name: .gitHubCopilotModelsDidChange, object: nil)
    }

    public static func getAvailableLLMs() -> [CopilotModel] {
        return availableLLMs
    }

    public static func hasLLMs() -> Bool {
        return !availableLLMs.isEmpty
    }

    public static func clearLLMs() {
        availableLLMs = []
        NotificationCenter.default.post(name: .gitHubCopilotModelsDidChange, object: nil)
    }
}
