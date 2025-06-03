import Client
import Foundation
import Logger
import SharedUIComponents
import SwiftUI
import Toast

struct MCPIntroView: View {
    var exampleConfig: String {
        """
        {
            "servers": {
                "my-mcp-server": {
                    "type": "stdio",
                    "command": "my-command",
                    "args": [],
                    "env": {
                        "TOKEN": "my_token"
                    }
                }
            }
        }
        """
    }

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GroupBox(
                label: Text("Model Context Protocol (MCP) Configuration")
                    .fontWeight(.bold)
            ) {
                Text(
                    "MCP is an open standard that connects AI models to external tools. In Xcode, it enhances GitHub Copilot's agent mode by connecting to any MCP server and integrating its tools into your workflow. [Learn More](https://modelcontextprotocol.io/introduction)"
                )
            }.groupBoxStyle(CardGroupBoxStyle())
            
            DisclosureGroup(isExpanded: $isExpanded) {
                exampleConfigView()
            } label: {
                sectionHeader()
            }
            .padding(.horizontal, 0)
            .padding(.vertical, 10)
            
            Button {
                openConfigFile()
            } label: {
                HStack(spacing: 0) {
                    Image(systemName: "square.and.pencil")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12, alignment: .center)
                        .padding(4)
                    Text("Edit Config")
                }
                .conditionalFontWeight(.semibold)
            }
            .buttonStyle(.borderedProminentWhite)
            .help("Configure your MCP server")
        }
    }
    
    @ViewBuilder
    private func exampleConfigView() -> some View {
        Text(exampleConfig)
            .font(.system(.body, design: .monospaced))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(nsColor: .textBackgroundColor).opacity(0.5)
            )
            .textSelection(.enabled)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                .inset(by: 0.5)
                .stroke(Color("GroupBoxStrokeColor"), lineWidth: 1)
            )
    }
    
    @ViewBuilder
    private func sectionHeader() -> some View {
        HStack(spacing: 8) {
            Text("Example Configuration").foregroundColor(.primary.opacity(0.85))
            
            CopyButton(
                copy:  {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(exampleConfig, forType: .string)
                },
                foregroundColor: .primary.opacity(0.85),
                fontWeight: .semibold
            )
            .frame(width: 10, height: 10)
        }
        .padding(.leading, 4)
    }
    
    private func openConfigFile() {
        let url = URL(fileURLWithPath: mcpConfigFilePath)
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    MCPIntroView()
        .frame(width: 800)
}
