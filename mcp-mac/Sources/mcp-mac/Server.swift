import EventKit
import Contacts
import Foundation
import MCP

final class MCPMacServer: @unchecked Sendable {
    private let server: Server
    nonisolated(unsafe) let eventStore = EKEventStore()
    nonisolated(unsafe) let contactStore = CNContactStore()

    nonisolated init() {
        self.server = Server(
            name: "mcp-mac",
            version: "0.1.0",
            title: "macOS Calendar, Contacts & Notifications",
            capabilities: Server.Capabilities(
                tools: .init(listChanged: false)
            )
        )
    }

    func run() async throws {
        // Request permissions upfront (best-effort)
        await requestCalendarAccess()
        await requestContactsAccess()
        // Note: notification access is requested lazily on first notify call
        // because UNUserNotificationCenter crashes outside an app bundle

        let tools = allTools()
        let handleFn: @Sendable (CallTool.Parameters) async throws -> CallTool.Result = { [self] params in
            await self.handle(params)
        }

        // Register tool list
        await server.withMethodHandler(ListTools.self) { _ in
            ListTools.Result(tools: tools)
        }

        // Dispatch tool calls
        await server.withMethodHandler(CallTool.self, handler: handleFn)

        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }

    // MARK: - Tool Registry

    private func allTools() -> [Tool] {
        [
            calendarListEventsTool(),
            calendarCreateEventTool(),
            calendarListCalendarsTool(),
            contactsSearchTool(),
            contactsGetTool(),
            notifyTool(),
        ]
    }

    private func handle(_ params: CallTool.Parameters) async -> CallTool.Result {
        let args = params.arguments ?? [:]
        do {
            let content: [Tool.Content] = switch params.name {
            case "calendar_list_events":   try await calendarListEvents(args)
            case "calendar_create_event":  try await calendarCreateEvent(args)
            case "calendar_list_calendars": try await calendarListCalendars(args)
            case "contacts_search":        try await contactsSearch(args)
            case "contacts_get":           try await contactsGet(args)
            case "notify":                 try await notify(args)
            default:
                throw ToolError.unknownTool(params.name)
            }
            return CallTool.Result(content: content)
        } catch {
            return CallTool.Result(content: [.text("Error: \(error)")], isError: true)
        }
    }

    // MARK: - Permissions

    private func requestCalendarAccess() async {
        if #available(macOS 14.0, *) {
            _ = try? await eventStore.requestFullAccessToEvents()
        } else {
            _ = try? await eventStore.requestAccess(to: .event)
        }
    }

    private func requestContactsAccess() async {
        _ = try? await contactStore.requestAccess(for: .contacts)
    }

}

// MARK: - Error

enum ToolError: Error {
    case unknownTool(String)
    case missingArg(String)
    case notFound(String)
}
