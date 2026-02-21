import Contacts
import Foundation
import MCP

extension MCPMacServer {

    func contactsSearchTool() -> Tool {
        Tool(
            name: "contacts_search",
            description: "Search contacts by name, email, or phone number",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "query": .object(["type": .string("string"), "description": .string("Name, email, or phone to search for")]),
                    "limit": .object(["type": .string("integer"), "description": .string("Max results (default 10)")]),
                ]),
                "required": .array([.string("query")]),
            ]),
            annotations: .init(readOnlyHint: true)
        )
    }

    func contactsGetTool() -> Tool {
        Tool(
            name: "contacts_get",
            description: "Get full details for a contact by identifier",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "identifier": .object(["type": .string("string"), "description": .string("Contact identifier from contacts_search")]),
                ]),
                "required": .array([.string("identifier")]),
            ]),
            annotations: .init(readOnlyHint: true)
        )
    }

    // MARK: - Handlers

    func contactsSearch(_ args: [String: Value]) async throws -> [Tool.Content] {
        guard case .string(let query) = args["query"] else {
            throw ToolError.missingArg("query")
        }
        var limit = 10
        if case .int(let l) = args["limit"] { limit = l }

        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
        ]

        let request = CNContactFetchRequest(keysToFetch: keys)
        request.predicate = CNContact.predicateForContacts(matchingName: query)

        var contacts: [CNContact] = []
        try contactStore.enumerateContacts(with: request) { contact, stop in
            contacts.append(contact)
            if contacts.count >= limit { stop.pointee = true }
        }

        if contacts.isEmpty {
            return [.text("No contacts found matching '\(query)'.")]
        }

        var lines = ["Contacts matching '\(query)':\n"]
        for c in contacts {
            let name = [c.givenName, c.familyName].filter { !$0.isEmpty }.joined(separator: " ")
            let emails = c.emailAddresses.map { $0.value as String }.joined(separator: ", ")
            let phones = c.phoneNumbers.map { $0.value.stringValue }.joined(separator: ", ")
            var line = "• \(name.isEmpty ? "(no name)" : name)"
            if !c.organizationName.isEmpty { line += " (\(c.organizationName))" }
            if !emails.isEmpty { line += "  email: \(emails)" }
            if !phones.isEmpty { line += "  phone: \(phones)" }
            line += "  id: \(c.identifier)"
            lines.append(line)
        }
        return [.text(lines.joined(separator: "\n"))]
    }

    func contactsGet(_ args: [String: Value]) async throws -> [Tool.Content] {
        guard case .string(let id) = args["identifier"] else {
            throw ToolError.missingArg("identifier")
        }

        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactMiddleNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactNoteKey as CNKeyDescriptor,
            CNContactUrlAddressesKey as CNKeyDescriptor,
        ]

        let contact = try contactStore.unifiedContact(withIdentifier: id, keysToFetch: keys)
        var lines: [String] = []

        let name = [contact.givenName, contact.middleName, contact.familyName]
            .filter { !$0.isEmpty }.joined(separator: " ")
        lines.append("Name: \(name.isEmpty ? "(no name)" : name)")
        if !contact.organizationName.isEmpty { lines.append("Org: \(contact.organizationName)") }

        for e in contact.emailAddresses {
            lines.append("Email (\(e.label ?? "")): \(e.value)")
        }
        for p in contact.phoneNumbers {
            lines.append("Phone (\(p.label ?? "")): \(p.value.stringValue)")
        }
        for a in contact.postalAddresses {
            let addr = CNPostalAddressFormatter().string(from: a.value)
            lines.append("Address (\(a.label ?? "")): \(addr.replacingOccurrences(of: "\n", with: ", "))")
        }
        for u in contact.urlAddresses {
            lines.append("URL (\(u.label ?? "")): \(u.value)")
        }
        if let bday = contact.birthday,
           let date = Calendar.current.date(from: bday) {
            let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .none
            lines.append("Birthday: \(df.string(from: date))")
        }
        if !contact.note.isEmpty { lines.append("Note: \(contact.note)") }
        lines.append("ID: \(contact.identifier)")

        return [.text(lines.joined(separator: "\n"))]
    }
}
