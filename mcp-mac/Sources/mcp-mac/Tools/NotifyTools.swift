import Foundation
import MCP

extension MCPMacServer {

    func notifyTool() -> Tool {
        Tool(
            name: "notify",
            description: "Send a macOS system notification",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "title":    .object(["type": .string("string"), "description": .string("Notification title")]),
                    "body":     .object(["type": .string("string"), "description": .string("Notification body text")]),
                    "subtitle": .object(["type": .string("string"), "description": .string("Subtitle (optional)")]),
                ]),
                "required": .array([.string("title"), .string("body")]),
            ])
        )
    }

    func notify(_ args: [String: Value]) async throws -> [Tool.Content] {
        guard case .string(let title) = args["title"],
              case .string(let body)  = args["body"]
        else { throw ToolError.missingArg("title, body") }

        var script = "display notification \"\(body.escaped)\" with title \"\(title.escaped)\""
        if case .string(let sub) = args["subtitle"] {
            script += " subtitle \"\(sub.escaped)\""
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script]
        let pipe = Pipe()
        proc.standardError = pipe
        try proc.run()
        proc.waitUntilExit()

        if proc.terminationStatus != 0 {
            let err = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "unknown error"
            return [.text("Error sending notification: \(err)")]
        }
        return [.text("Notification '\(title)' sent.")]
    }
}

private extension String {
    var escaped: String {
        self.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
