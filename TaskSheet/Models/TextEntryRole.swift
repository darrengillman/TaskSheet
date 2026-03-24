//
//  EditState.swift
//  TaskSheet
//
//  Created by Darren Gillman on 14/10/2025.
//

enum TextEntryRole: Identifiable {
   var id: String {
      switch self {
         case .add:
            return "add"
         case .edit:
            return "edit"
      }
   }
   
   case add (type: ItemType, indent: Int)
   case edit(type: ItemType, indent: Int)
   
   var indent: Int {
      switch self {
         case let .add( _, i): i
         case let .edit( _,  i): i
      }
   }
   
   var itemType: ItemType {
      switch self {
         case let .edit( t, _): t
         case let .add( t, _): t
      }
   }
   
   var popOverTitleString: String {
      switch self {
         case .add:  "Quick Add"
         case .edit: "Edit"
      }
   }
   
   var editorTitleString: String {
      switch self {
         case .add:  "Add"
         case .edit: "Edit"
      }
   }
   
   var commitButtonString: String {
      switch self {
         case .add:  "Add"
         case .edit: "Save"
      }
   }
}
