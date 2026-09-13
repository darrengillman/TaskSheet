//
//  EditMethod.swift
//  TaskSheet
//
//  Created by Darren Gillman on 05/07/2026.
//

enum EditMethod: String, Identifiable, Codable, CaseIterable {
   var id: Self {
      self
   }

   case inline = "inline"
   case sheet = "with Editor"
   case popover = "in Popover"
}
