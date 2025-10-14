import Foundation
import RegexBuilder

struct TaskPaperItem: Identifiable, Codable, Equatable {
   static let projectSuffix = ":"
   static let taskPrefix = "- "
   static let completedTagText = "done"
   var id = UUID()
   var type: ItemType
   var text: String // Raw text including tags: "- Buy milk @urgent tomorrow @due(2025-12-25)"
   var isFolded: Bool = false
   var indentLevel: Int
   
   var iconName: String {
      switch type {
         case .note: "note"
         case .project: "folder"
         case .task: "checkmark"
      }
   }

    // Cached parsed tags for performance
    var cachedTags: [Tag]?

    init(type: ItemType, text: String, indentLevel: Int) {
       let rawText = switch type {
          case .note: text
          case .project: text.hasSuffix(Self.projectSuffix) ? text : text + Self.projectSuffix
          case .task: text.hasPrefix(Self.taskPrefix) ? text : Self.taskPrefix + text
       }
        self.id = UUID()
        self.type = type
        self.text = rawText
        self.indentLevel = indentLevel
        self.cachedTags = TaskPaperParser.extractTags(from: text)
    }

    // Legacy initializer for backward compatibility during transition
    init(type: ItemType, text: String, indentLevel: Int = 0, tags: [Tag] = []) {
        self.id = UUID()
        self.type = type
        self.indentLevel = indentLevel

        // If tags are provided separately, reconstruct the text with tags
        if tags.isEmpty {
            self.text = text
        } else {
           let tagsText = tags.map { $0.displayText }.filter{text.contains($0) == false}.joined(separator: " ")
            self.text = text + " " + tagsText
        }
        self.cachedTags = tags
    }


    // Non-cached tags for read-only access from computed props
    var tags: [Tag] {
        return cachedTags ?? TaskPaperParser.extractTags(from: text)
    }

    var isCompleted: Bool {
       tags.contains { $0.name == Self.completedTagText }
    }

    var displayText: String {
        let cleanText = text
          .removingTagNames()
          .trimmingCharacters(in: .whitespacesAndNewlines)

       return switch type {
          case .project:
             cleanText.hasSuffix(Self.projectSuffix)
             ? String(cleanText.dropLast()).trimmingCharacters(in: .whitespaces)
             : cleanText
          case .task:
             cleanText.hasPrefix(Self.taskPrefix)
             ? String(cleanText.dropFirst(2)).trimmingCharacters(in: .whitespaces)
             : cleanText
          case .note:
             cleanText
       }
    }
   
   mutating func refreshTagCache() {
      cachedTags = TaskPaperParser.extractTags(from: text)
   }

    // MARK: - Smart Tag Manipulation

    enum TagInsertionPosition {
        case beginning
        case end
        case at(String.Index)                    // Insert at specific index
        case after(String.Index)                 // Insert after specific index
    }

   mutating func addTag(_ tag: Tag, at position: TagInsertionPosition = .end) {
      guard !tags.contains(tag) else {
         removeTag(tag)
         return
      }
      
      text = text.removingTag(tag.name)
      let tagText = tag.displayText
      
      switch position {
         case .beginning:
               // Insert after type prefix (-, project:, etc.)
            let prefixEnd = getTypePrefixEndIndex()
            let insertIndex = text.index(text.startIndex, offsetBy: prefixEnd)
            text.insert(contentsOf: tagText + " ", at: insertIndex)
            
         case .end:
            text += " " + tagText
            
         case .at(let index):
            guard index <= text.endIndex else {
               text += " " + tagText
               return
            }
            let insertText  = if index == text.startIndex {
               tagText + " "
            } else {
               (text[text.index(before: index)] == " " ? "" : " ") + tagText + (text[index] == " " ? "" : " ")
            }
            text.insert(contentsOf: insertText, at: index)
            
         case .after(let index):
            guard index < text.endIndex else {
               text += " " + tagText
               return
            }
            let insertIndex = text.index(after: index)
            addTag(tag, at: .at(insertIndex))
      }
      refreshTagCache()
   }
   
   mutating func removeTag(_ tag: Tag) {
      text = text.removingTag(tag.name)
      refreshTagCache()
   }
   
   private func getTypePrefixEndIndex() -> Int {
      switch type {
         case .task:
            text.hasPrefix(Self.taskPrefix) ? 2 : 0
         case .project, .note: 0
      }
   }

    // MARK: - Task Completion Methods

    mutating func toggleCompletion() {
        if isCompleted {
           text = text.removingTag("done")
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
           let dateString = dateFormatter.string(from: .now)
            addTag(Tag(name: "done", value: dateString))
        }
       refreshTagCache()
    }
   
   mutating func setCompletion(_ completed: Bool, date: Date = .now) {
      if completed {
         let dateFormatter = DateFormatter()
         dateFormatter.dateFormat = "yyyy-MM-dd"
         let dateString = dateFormatter.string(from: date)
         addTag(Tag(name: "done", value: dateString))
      } else {
         text = text.removingTag("done")
      }
      refreshTagCache()
   }
}

// MARK: - TaskPaper Content Generation

extension TaskPaperItem {
    /// Generate the TaskPaper format line for this item
    var taskPaperLine: String {
        let indentation = String(repeating: String.tab, count: indentLevel)
        return indentation + text
    }
}

extension Array where Element == TaskPaperItem {
    /// Generate complete TaskPaper content from an array of items
    var taskPaperContent: String {
        return self.map { $0.taskPaperLine }.joined(separator: "\n")
    }
}

private extension String {
   func removingTag(_ tagName: String) -> String {
         // Swift regex literal: matches @tagName or @tagName(value) with specific tag name
      let tagRegex = try! Regex("@\(tagName)(?:\\([^)]+\\))?")
      
      let updatedText = self.replacing(tagRegex, with: "")
         .replacingOccurrences(of: "  ", with: " ") // Clean up double spaces
         .trimmingCharacters(in: .whitespaces)
      
      return updatedText
   }

   func removingTagNames() -> String {
         // Swift regex: matches @tagname or @tagname(value)
      let tagRegexWithWhiteSpace = /\s@\w+(?:\([^)]+\))?\s/
      let tagRegex = /@\w+(?:\([^)]+\))?/
      
      return self
         .replacing(tagRegexWithWhiteSpace, with: " ")
         .replacing(tagRegex, with: "")
         .trimmingCharacters(in: .whitespaces)
   }
}
