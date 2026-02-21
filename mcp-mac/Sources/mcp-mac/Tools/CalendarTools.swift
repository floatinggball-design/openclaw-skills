import EventKit
import Foundation
import MCP

extension MCPMacServer {

    func calendarListEventsTool() -> Tool {
        Tool(
            name: "calendar_list_events",
            description: "List calendar events in a date range",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "start_date": .object(["type": .string("string"), "description": .string("ISO 8601 start date (e.g. 2026-02-21)")]),
                    "end_date":   .object(["type": .string("string"), "description": .string("ISO 8601 end date (inclusive)")]),
                    "calendar":   .object(["type": .string("string"), "description": .string("Calendar name filter (optional)")]),
                ]),
                "required": .array([.string("start_date"), .string("end_date")]),
            ]),
            annotations: .init(readOnlyHint: true)
        )
    }

    func calendarCreateEventTool() -> Tool {
        Tool(
            name: "calendar_create_event",
            description: "Create a new calendar event",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "title":    .object(["type": .string("string"), "description": .string("Event title")]),
                    "start":    .object(["type": .string("string"), "description": .string("ISO 8601 start datetime")]),
                    "end":      .object(["type": .string("string"), "description": .string("ISO 8601 end datetime")]),
                    "calendar": .object(["type": .string("string"), "description": .string("Calendar name (uses default if omitted)")]),
                    "notes":    .object(["type": .string("string"), "description": .string("Event notes (optional)")]),
                    "location": .object(["type": .string("string"), "description": .string("Event location (optional)")]),
                    "all_day":  .object(["type": .string("boolean"), "description": .string("All-day event (optional)")]),
                ]),
                "required": .array([.string("title"), .string("start"), .string("end")]),
            ])
        )
    }

    func calendarListCalendarsTool() -> Tool {
        Tool(
            name: "calendar_list_calendars",
            description: "List all available calendars",
            inputSchema: .object(["type": .string("object"), "properties": .object([:])]),
            annotations: .init(readOnlyHint: true)
        )
    }

    // MARK: - Handlers

    func calendarListEvents(_ args: [String: Value]) async throws -> [Tool.Content] {
        guard case .string(let startStr) = args["start_date"],
              case .string(let endStr)   = args["end_date"]
        else { throw ToolError.missingArg("start_date, end_date") }

        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        let fmtFull = ISO8601DateFormatter()

        func parse(_ s: String) -> Date? {
            fmtFull.date(from: s) ?? fmt.date(from: s)
        }

        guard let start = parse(startStr), let end = parse(endStr) else {
            throw ToolError.missingArg("invalid date format — use ISO 8601")
        }

        var calendars: [EKCalendar]? = nil
        if case .string(let calName) = args["calendar"] {
            calendars = eventStore.calendars(for: .event).filter { $0.title == calName }
        }

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end,
            calendars: calendars
        )
        let events = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        if events.isEmpty {
            return [.text("No events found in \(startStr) – \(endStr).")]
        }

        var lines = ["Events from \(startStr) to \(endStr):\n"]
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short

        for e in events {
            let timeStr = e.isAllDay
                ? df.string(from: e.startDate).components(separatedBy: ",").first ?? ""
                : "\(df.string(from: e.startDate)) → \(df.string(from: e.endDate))"
            var line = "• \(e.title ?? "(no title)") [\(timeStr)] cal:\(e.calendar.title)"
            if let loc = e.location, !loc.isEmpty { line += " @ \(loc)" }
            lines.append(line)
        }
        return [.text(lines.joined(separator: "\n"))]
    }

    func calendarCreateEvent(_ args: [String: Value]) async throws -> [Tool.Content] {
        guard case .string(let title) = args["title"],
              case .string(let startStr) = args["start"],
              case .string(let endStr)   = args["end"]
        else { throw ToolError.missingArg("title, start, end") }

        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fmtSimple = ISO8601DateFormatter()

        func parse(_ s: String) -> Date? {
            fmt.date(from: s) ?? fmtSimple.date(from: s)
        }

        guard let start = parse(startStr), let end = parse(endStr) else {
            throw ToolError.missingArg("invalid datetime — use ISO 8601 with time")
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = start
        event.endDate = end

        if case .string(let notes) = args["notes"] { event.notes = notes }
        if case .string(let loc)   = args["location"] { event.location = loc }
        if case .bool(let allDay)  = args["all_day"]  { event.isAllDay = allDay }

        if case .string(let calName) = args["calendar"],
           let cal = eventStore.calendars(for: .event).first(where: { $0.title == calName }) {
            event.calendar = cal
        } else {
            event.calendar = eventStore.defaultCalendarForNewEvents
        }

        try eventStore.save(event, span: .thisEvent)
        return [.text("Created event '\(title)' on \(startStr) in calendar '\(event.calendar.title)'")]
    }

    func calendarListCalendars(_ args: [String: Value]) async throws -> [Tool.Content] {
        let cals = eventStore.calendars(for: .event)
        if cals.isEmpty { return [.text("No calendars found.")] }
        let lines = cals.map { "• \($0.title) [\($0.type == .local ? "local" : $0.type == .calDAV ? "CalDAV" : "other")]" }
        return [.text("Calendars:\n" + lines.joined(separator: "\n"))]
    }
}
