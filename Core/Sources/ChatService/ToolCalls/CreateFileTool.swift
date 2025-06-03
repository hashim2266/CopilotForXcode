import JSONRPC
import ConversationServiceProvider
import Foundation
import Logger

public class CreateFileTool: ICopilotTool {
    public static let name = ToolName.createFile
    
    public func invokeTool(
        _ request: InvokeClientToolRequest,
        completion: @escaping (AnyJSONRPCResponse) -> Void,
        chatHistoryUpdater: ChatHistoryUpdater?,
        contextProvider: (any ToolContextProvider)?
    ) -> Bool {
        guard let params = request.params,
              let input = params.input,
              let filePath = input["filePath"]?.value as? String,
              let content = input["content"]?.value as? String
        else {
            completeResponse(request, response: "Invalid parameters", completion: completion)
            return true
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        
        guard !FileManager.default.fileExists(atPath: filePath)
        else {
            completeResponse(request, response: "File already exists at \(filePath)", completion: completion)
            return true
        }
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            completeResponse(request, response: "Failed to write content to file: \(error)", completion: completion)
            return true
        }
        
        guard FileManager.default.fileExists(atPath: filePath),
              let writtenContent = try? String(contentsOf: fileURL, encoding: .utf8),
              !writtenContent.isEmpty
        else {
            completeResponse(request, response: "Failed to verify file creation.", completion: completion)
            return true
        }
        
        contextProvider?.updateFileEdits(by: .init(
            fileURL: URL(fileURLWithPath: filePath),
            originalContent: "",
            modifiedContent: content,
            toolName: CreateFileTool.name
        ))
        
        do {
            if let workspacePath = contextProvider?.chatTabInfo.workspacePath,
               let xcodeIntance = Utils.getXcode(by: workspacePath) {
                try Utils.openFileInXcode(fileURL: URL(fileURLWithPath: filePath), xcodeInstance: xcodeIntance)
            }
        } catch {
            Logger.client.info("Failed to open file in Xcode, \(error)")
        }
        
        let editAgentRounds: [AgentRound] = [
            .init(
                roundId: params.roundId,
                reply: "",
                toolCalls: [
                    .init(
                        id: params.toolCallId,
                        name: params.name,
                        status: .completed,
                        invokeParams: params
                    )
                ]
            )
        ]

        if let chatHistoryUpdater {
            chatHistoryUpdater(params.turnId, editAgentRounds)
        }
        
        completeResponse(
            request,
            response: "File created at \(filePath).",
            completion: completion
        )
        return true
    }
    
    public static func undo(for fileURL: URL) throws {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory),
              !isDirectory.boolValue
        else { return }
        
        try FileManager.default.removeItem(at: fileURL)
    }
}
