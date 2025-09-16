import Foundation
import RegexBuilder

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

        // Tags are now extracted on-demand from the raw text
        _ = extractTags(from: trimmedLine) // Keep for validation during parsing

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
            text: trimmedLine, // Keep original text with tags
            indentLevel: indentLevel,
            lineNumber: lineNumber
        )
    }

    private static func countLeadingTabs(_ line: String) -> Int {
        var count = 0
        for char in line {
           if char == .tab {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    static func extractTags(from text: String) -> [Tag] {
        var tags: [Tag] = []

        // Swift regex literal with capture groups: @(tagname) and optional (value)
        let tagRegex = /@(\w+)(?:\(([^)]+)\))?/

        /* Regex builder version (kept for reference):
        let tagRegex = Regex {
            "@"
            Capture {
                OneOrMore(.word)
            }
            Optionally {
                "("
                Capture {
                    OneOrMore(.noneOf(")"))
                }
                ")"
            }
        }
        */

        let matches = text.matches(of: tagRegex)

        for match in matches {
            let tagName = String(match.1)
            let tagValue = match.2.map(String.init)

            tags.append(Tag(name: tagName, value: tagValue))
        }

        return tags
    }
}
