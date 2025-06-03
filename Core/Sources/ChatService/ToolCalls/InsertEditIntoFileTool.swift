import ConversationServiceProvider
import AppKit
import JSONRPC
import Foundation
import XcodeInspector
import Logger
import AXHelper

public class InsertEditIntoFileTool: ICopilotTool {
    public static let name = ToolName.insertEditIntoFile
    
    public func invokeTool(
        _ request: InvokeClientToolRequest,
        completion: @escaping (AnyJSONRPCResponse) -> Void,
        chatHistoryUpdater: ChatHistoryUpdater?,
        contextProvider: (any ToolContextProvider)?
    ) -> Bool {
        guard let params = request.params,
              let input = request.params?.input,
              let code = input["code"]?.value as? String,
              let filePath = input["filePath"]?.value as? String,
              let contextProvider
        else {
            return true
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        do {
            let originalContent = try String(contentsOf: fileURL, encoding: .utf8)
            
            try InsertEditIntoFileTool.applyEdit(for: fileURL, content: code, contextProvider: contextProvider)
            
            contextProvider.updateFileEdits(
                by: .init(fileURL: fileURL, originalContent: originalContent, modifiedContent: code, toolName: InsertEditIntoFileTool.name)
            )
            
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
            
            completeResponse(request, response: code, completion: completion)
        } catch {
            Logger.client.error("Failed to apply edits, \(error)")
            completeResponse(request, response: error.localizedDescription, completion: completion)
        }
        
        return true
    }
    
    public static func applyEdit(for fileURL: URL, content: String, contextProvider: (any ToolContextProvider), xcodeInstance: XcodeAppInstanceInspector) throws {
        
        /// wait a while for opening file in xcode. (3 seconds)
        var retryCount = 6
        while retryCount > 0 {
            guard xcodeInstance.realtimeDocumentURL != fileURL else { break }
            
            retryCount -= 1
            
            /// Failed to get the target documentURL
            if retryCount == 0 {
                return
            }
            
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        guard xcodeInstance.realtimeDocumentURL == fileURL
        else { throw NSError(domain: "The file \(fileURL) is not opened in Xcode", code: 0)}
        
        /// keep change
        guard let element: AXUIElement = try? xcodeInstance.appElement.copyValue(key: kAXFocusedUIElementAttribute)
        else {
            throw NSError(domain: "Failed to access xcode element", code: 0)
        }
        let value: String = (try? element.copyValue(key: kAXValueAttribute)) ?? ""
        let lines = value.components(separatedBy: .newlines)
        
        var isInjectedSuccess = false
        try AXHelper().injectUpdatedCodeWithAccessibilityAPI(
            .init(
                content: content,
                newSelection: nil,
                modifications: [
                    .deletedSelection(
                        .init(start: .init(line: 0, character: 0), end: .init(line: lines.count - 1, character: (lines.last?.count ?? 100) - 1))
                    ),
                    .inserted(0, [content])
                ]
            ),
            focusElement: element,
            onSuccess: {
                isInjectedSuccess = true
            }
        )
        
        if !isInjectedSuccess {
            throw NSError(domain: "Failed to apply edit", code: 0)
        }

    }
    
    public static func applyEdit(for fileURL: URL, content: String, contextProvider: (any ToolContextProvider)) throws {
        guard let xcodeInstance = Utils.getXcode(by: contextProvider.chatTabInfo.workspacePath)
        else {
            throw NSError(domain: "The workspace \(contextProvider.chatTabInfo.workspacePath) is not opened in xcode", code: 0, userInfo: nil)
        }
        
        try Utils.openFileInXcode(fileURL: fileURL, xcodeInstance: xcodeInstance)
        try applyEdit(for: fileURL, content: content, contextProvider: contextProvider, xcodeInstance: xcodeInstance)
    }
}
