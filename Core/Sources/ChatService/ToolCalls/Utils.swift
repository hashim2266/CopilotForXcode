import Foundation
import XcodeInspector
import AppKit
import Logger

class Utils {
    public static func openFileInXcode(fileURL: URL, xcodeInstance: XcodeAppInstanceInspector) throws {
        /// TODO: when xcode minimized, the activate not work.
        guard xcodeInstance.activate(options: [.activateAllWindows, .activateIgnoringOtherApps]) else {
            throw NSError(domain: "Failed to activate xcode instance", code: 0)
        }
    
        /// wait for a while to allow activation (especially un-minimizing) to complete
        Thread.sleep(forTimeInterval: 0.3)
        
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        
        NSWorkspace.shared.open(
            [fileURL],
            withApplicationAt: xcodeInstance.runningApplication.bundleURL!,
            configuration: configuration) { app, error in
                if error != nil {
                    Logger.client.error("Failed to open file \(String(describing: error))")
                }
            }
    }
    
    public static func getXcode(by workspacePath: String) -> XcodeAppInstanceInspector? {
        return XcodeInspector.shared.xcodes.first(
            where: {
                return $0.workspaceURL?.path == workspacePath
            })
    }
}
