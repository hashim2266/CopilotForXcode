import CopilotForXcodeKit
import Foundation
import ConversationServiceProvider
import BuiltinExtension
import Workspace
import LanguageServerProtocol

public final class GitHubCopilotConversationService: ConversationServiceType {

    private let serviceLocator: ServiceLocator
    
    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
    }

    private func getWorkspaceFolders(workspace: WorkspaceInfo) -> [WorkspaceFolder] {
        let projects = WorkspaceFile.getProjects(workspace: workspace)
        return projects.map { project in
            WorkspaceFolder(uri: project.uri, name: project.name)
        }
    }

    public func createConversation(_ request: ConversationRequest, workspace: WorkspaceInfo) async throws {
        guard let service = await serviceLocator.getService(from: workspace) else { return }
        
        return try await service.createConversation(request.content,
                                                    workDoneToken: request.workDoneToken,
                                                    workspaceFolder: workspace.projectURL.absoluteString,
                                                    workspaceFolders: getWorkspaceFolders(workspace: workspace),
                                                    activeDoc: request.activeDoc,
                                                    skills: request.skills,
                                                    ignoredSkills: request.ignoredSkills,
                                                    references: request.references ?? [],
                                                    model: request.model,
                                                    turns: request.turns,
                                                    agentMode: request.agentMode)
    }
    
    public func createTurn(with conversationId: String, request: ConversationRequest, workspace: WorkspaceInfo) async throws {
        guard let service = await serviceLocator.getService(from: workspace) else { return }
        
        return try await service.createTurn(request.content,
                                            workDoneToken: request.workDoneToken,
                                            conversationId: conversationId,
                                            activeDoc: request.activeDoc,
                                            ignoredSkills: request.ignoredSkills,
                                            references: request.references ?? [],
                                            model: request.model,
                                            workspaceFolder: workspace.projectURL.absoluteString,
                                            workspaceFolders: getWorkspaceFolders(workspace: workspace),
                                            agentMode: request.agentMode)
    }
    
    public func cancelProgress(_ workDoneToken: String, workspace: WorkspaceInfo) async throws {
        guard let service = await serviceLocator.getService(from: workspace) else { return }
        
        await service.cancelProgress(token: workDoneToken)
    }
    
    public func rateConversation(turnId: String, rating: ConversationRating, workspace: WorkspaceInfo) async throws {
        guard let service = await serviceLocator.getService(from: workspace) else { return }
        try await service.rateConversation(turnId: turnId, rating: rating)
    }
    
    public func copyCode(request: CopyCodeRequest, workspace: WorkspaceInfo) async throws {
        guard let service = await serviceLocator.getService(from: workspace) else { return }
        try await service.copyCode(turnId: request.turnId, codeBlockIndex: request.codeBlockIndex, copyType: request.copyType, copiedCharacters: request.copiedCharacters, totalCharacters: request.totalCharacters, copiedText: request.copiedText)
    }

    public func templates(workspace: WorkspaceInfo) async throws -> [ChatTemplate]? {
        guard let service = await serviceLocator.getService(from: workspace) else { return nil }
        return try await service.templates()
    }

    public func models(workspace: WorkspaceInfo) async throws -> [CopilotModel]? {
        guard let service = await serviceLocator.getService(from: workspace) else { return nil }
        return try await service.models()
    }
    
    public func notifyDidChangeWatchedFiles(_ event: DidChangeWatchedFilesEvent, workspace: WorkspaceInfo) async throws {
        guard let service = await serviceLocator.getService(from: workspace) else {
            return
        }
        
        return try await service.notifyDidChangeWatchedFiles(.init(workspaceUri: event.workspaceUri, changes: event.changes))
    }
    
    public func agents(workspace: WorkspaceInfo) async throws -> [ChatAgent]? {
        guard let service = await serviceLocator.getService(from: workspace) else { return nil }
        return try await service.agents()
    }
}

