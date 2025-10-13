//
//  ItemType.swift
//  TaskSheet
//
//  Created by Darren Gillman on 19/09/2025.
//


enum ItemType: String, CaseIterable, Codable {
    case project
    case task
    case note
}

extension ItemType {
    var baseIcon: String {
        switch self {
        case .project: "folder"
        case .task: "circle"
        case .note: "doc.text"
        }
    }
   
   var completedIcon: String {
      switch self {
         case .project: "folder.fill"
         case .task: "checkmark.circle.fill"
         case .note: "doc.text.fill"
      }
   }
   
   var foldedIcon: String {
      switch self {
         case .project: "folder.badge.plus"
         case .task: "circle.circle"
         case .note: "doc.text.fill"
      }
      
   }

   var completedFoldedIcon: String {
      switch self {
         case .project: "folder.fill.badge.plus"
         case .task: "circle.circle.fill"
         case .note: "doc.text.fill"
      }
   }
}
