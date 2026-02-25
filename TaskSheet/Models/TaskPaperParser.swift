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

        // Remove tags to accurately determine item type
        // Projects like "MyProject: @next" should be detected as projects, not notes
        let lineWithoutTags = trimmedLine.removingTagNames()

        let type: ItemType
        if lineWithoutTags.hasSuffix(TaskPaperItem.projectSuffix) {
            type = .project
        } else if trimmedLine.hasPrefix(TaskPaperItem.taskPrefix) {
            type = .task
        } else {
            type = .note
        }

        return TaskPaperItem(
            type: type,
            text: trimmedLine, // Keep original text with tags
            indentLevel: indentLevel,
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

        // Swift regex literal with capture groups: space + @(tagname) and optional (value)
        // Tags require a leading space to distinguish from emails, etc.
        let tagRegex = /\s@(\w+)(?:\(([^)]+)\))?/

        /* Regex builder version (kept for reference):
        let tagRegex = Regex {
            /\s/
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
