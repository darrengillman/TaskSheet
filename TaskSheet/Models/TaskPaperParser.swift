import Foundation

class TaskPaperParser {
    static func parse(_ content: String) -> [TaskPaperItem] {
        let lines = content.components(separatedBy: .newlines)
        var items: [TaskPaperItem] = []

        for (index, line) in lines.enumerated() {
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }

            let item = parseLine(line, lineNumber: index + 1)
            items.append(item)
        }

        return items
    }

    private static func parseLine(_ line: String, lineNumber: Int) -> TaskPaperItem {
        let indentLevel = countLeadingTabs(line)
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

        let tags = extractTags(from: trimmedLine)

        let type: ItemType
        if trimmedLine.hasSuffix(":") {
            type = .project
        } else if trimmedLine.hasPrefix("-") {
            type = .task
        } else {
            type = .note
        }

        return TaskPaperItem(
            type: type,
            text: trimmedLine,
            indentLevel: indentLevel,
            tags: tags,
            lineNumber: lineNumber
        )
    }

    private static func countLeadingTabs(_ line: String) -> Int {
        var count = 0
        for char in line {
            if char == "\t" {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    private static func extractTags(from text: String) -> [Tag] {
        var tags: [Tag] = []
        let pattern = "@(\\w+)(?:\\(([^)]+)\\))?"

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))

            for match in matches {
                let tagNameRange = match.range(at: 1)
                let tagValueRange = match.range(at: 2)

                if let tagNameSwiftRange = Range(tagNameRange, in: text) {
                    let tagName = String(text[tagNameSwiftRange])

                    var tagValue: String? = nil
                    if tagValueRange.location != NSNotFound,
                       let tagValueSwiftRange = Range(tagValueRange, in: text) {
                        tagValue = String(text[tagValueSwiftRange])
                    }

                    tags.append(Tag(name: tagName, value: tagValue))
                }
            }
        } catch {
            print("Regex error: \(error)")
        }

        return tags
    }
}