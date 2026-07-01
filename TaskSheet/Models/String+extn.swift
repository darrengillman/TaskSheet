//
//  String+extn.swift
//  TaskSheet
//
//  Created by Darren Gillman on 15/09/2025.
//

import Foundation
import RegexBuilder

extension String {
   static let tab = "\t"
   
   /// Removes a specific tag by name from the string
   /// - Parameter tagName: The name of the tag to remove (without @ prefix)
   /// - Returns: String with the specified tag removed
   func removingTag(_ tagName: String) -> String {
      // Swift regex literal: matches @tagName or @tagName(value) with specific tag name
      let tagRegex = try! Regex("@\(tagName)(?:\\([^)]+\\))?")
      
      let updatedText = self.replacing(tagRegex, with: "")
         .replacingOccurrences(of: "  ", with: " ") // Clean up double spaces
         .trimmingCharacters(in: .whitespaces)
      
      return updatedText
   }
   
   /// Sanitises a user-entered string for use as a TaskPaper tag name.
   /// Spaces become underscores; any character not matched by \w (letters, digits, _) is removed.
   /// Returns "inbox" if the result would be empty.
   func sanitisedAsTagName() -> String {
      let sanitised = self.trimmingCharacters(in: .whitespaces)
         .components(separatedBy: .whitespaces).joined(separator: "_")
         .filter { $0.isLetter || $0.isNumber || $0 == "_" }
      return sanitised.isEmpty ? "inbox" : sanitised
   }

   /// Removes all tags from the string
   /// - Returns: String with all @tag and @tag(value) patterns removed
   /// - Note: Tags MUST have a leading space to avoid matching emails, URLs, etc.
   func removingTagNamesAndWhitespace() -> String {
      // Swift regex: matches space + @tagname or space + @tagname(value)
      // Tags require a leading space to distinguish from emails, etc.
      let tagWithLeadingSpace = /\s@\w+(?:\([^)]+\))?/
      
      return self
         .replacing(tagWithLeadingSpace, with: "")
         .trimmingCharacters(in: .whitespaces)
   }
}

extension Character {
   static let tab: Character = Character(String.tab)
}
