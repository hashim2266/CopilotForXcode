import ConversationServiceProvider
import XcodeInspector
import Foundation
import Logger
import Workspace

public struct ContextUtils {

    public static func getFilesInActiveWorkspace(workspaceURL: URL?) -> [FileReference] {
        if let workspaceURL = workspaceURL, let info = WorkspaceFile.getWorkspaceInfo(workspaceURL: workspaceURL) {
            return WorkspaceFile.getFilesInActiveWorkspace(workspaceURL: info.workspaceURL, workspaceRootURL: info.projectURL)
        }

        guard let workspaceURL = XcodeInspector.shared.realtimeActiveWorkspaceURL,
              let workspaceRootURL = XcodeInspector.shared.realtimeActiveProjectURL else {
            return []
        }
        
        let files = WorkspaceFile.getFilesInActiveWorkspace(workspaceURL: workspaceURL, workspaceRootURL: workspaceRootURL)
        
        return files
    }
}
