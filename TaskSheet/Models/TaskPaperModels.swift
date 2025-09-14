import Foundation

enum ItemType: String, CaseIterable, Codable {
    case project
    case task
    case note
}

struct Tag: Codable, Hashable {
    let name: String
    let value: String?

    init(name: String, value: String? = nil) {
        self.name = name
        self.value = value
    }

    var displayText: String {
        if let value = value {
            return "@\(name)(\(value))"
        } else {
            return "@\(name)"
        }
    }
}

struct TaskPaperItem: Identifiable, Codable {
    var id = UUID()
    var type: ItemType
    var text: String
    var indentLevel: Int
    var tags: [Tag]
    var lineNumber: Int

    init(type: ItemType, text: String, indentLevel: Int = 0, tags: [Tag] = [], lineNumber: Int) {
        self.id = UUID()
        self.type = type
        self.text = text
        self.indentLevel = indentLevel
        self.tags = tags
        self.lineNumber = lineNumber
    }

    var isCompleted: Bool {
        tags.contains { $0.name == "done" }
    }

    var displayText: String {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch type {
        case .project:
            let projectText =  cleanText.hasSuffix(":") ? String(cleanText.dropLast()) : cleanText
              return removeTagsFromText(projectText)
        case .task:
            let taskText = cleanText.hasPrefix("-") ? String(cleanText.dropFirst()).trimmingCharacters(in: .whitespaces) : cleanText
            return removeTagsFromText(taskText)
        case .note:
            return removeTagsFromText(cleanText)
        }
    }

    private func removeTagsFromText(_ text: String) -> String {
        var result = text
        for tag in tags {
            result = result.replacingOccurrences(of: tag.displayText, with: "").trimmingCharacters(in: .whitespaces)
        }
        return result
    }
}
