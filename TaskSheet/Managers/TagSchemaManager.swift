//
//  TagSchemaManager.swift
//  TaskSheet
//
//  Created by Darren Gillman on 23/09/2025.
//
import SwiftUI

class TagSchemaManager: ObservableObject {
   @AppStorage("customTagColors") private var customTagColorsData: Data = Data()
   
   var customColors: [String: Int] {
      get {
         (try? JSONDecoder().decode([String: Int].self, from: customTagColorsData)) ?? [:]
      }
      set {
         customTagColorsData = (try? JSONEncoder().encode(newValue)) ?? Data()
      }
   }
   
   func setColor(for tag: Tag, color: Color) {
      customColors[tag.name] = color.intValue
   }
   
   func getColor(for tag: Tag) -> Color {
      if let colorCode = customColors[tag.name] {
         return Color.standard(colorCode)
      } else {
         let color: Color = switch tag.name {
            case "done": Color.green
            case "next", "today": .orange
            case "someday", "maybe": .purple
            case "BUG", "bug": .red
            case "soon": .blue
            default: .blue
         }
         customColors[tag.name] = color.intValue
         return color
      }
   }
}
