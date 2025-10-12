//
//  TagSchemaManager.swift
//  TaskSheet
//
//  Created by Darren Gillman on 23/09/2025.
//
import SwiftUI

class TagSchemaManager: ObservableObject {
   @AppStorage("customTagColors") private var customTagColorsData: Data = Data()

   struct ColorOption: Hashable, Identifiable {
      var id: String { name }
      let name: String
      let color: Color
      let value: Int
   }
   
   let tagColors: [ColorOption] = [
      .init(name:"Black", color: .black, value: 0),
      .init(name:"Blue", color: .blue, value: 1),
      .init(name:"Brown", color: .brown, value: 2),
      .init(name:"Cyan", color: .cyan, value: 3),
      .init(name:"Gray", color: .gray, value: 4),
      .init(name:"Green", color: .green, value: 5),
      .init(name:"Indigo", color: .indigo, value: 6),
      .init(name:"Mint", color: .mint, value: 7),
      .init(name:"Orange", color: .orange, value: 8),
      .init(name:"Pink", color: .pink, value: 9),
      .init(name:"Purple", color: .purple, value: 10),
      .init(name:"Red", color: .red, value: 11),
      .init(name:"Teal", color: .teal, value: 12),
      .init(name:"Yellow", color: .yellow, value: 13),
   ]
   
   var defaultColorOption: ColorOption { tagColors.first! }
   
   var customColors: [String: Int] {
      get {
         (try? JSONDecoder().decode([String: Int].self, from: customTagColorsData)) ?? [:]
      }
      set {
         customTagColorsData = (try? JSONEncoder().encode(newValue)) ?? Data()
      }
   }
   
   func setColor(for tag: Tag, option: ColorOption) {
      customColors[tag.name] = option.value
   }
   
   func getColor(for tag: Tag) -> Color {
      if let colorCode = customColors[tag.name] {
         return tagColors.first{$0.value == colorCode}?.color ?? tagColors.first!.color
      } else {
         let colorOption: ColorOption = switch tag.name {
            case "done": tagColors.first{$0.color == .green} ?? defaultColorOption
            case "next", "today": tagColors.first{$0.color == .orange} ?? defaultColorOption
            case "someday", "maybe": tagColors.first{$0.color == .purple} ?? defaultColorOption
            case "BUG", "bug": tagColors.first{$0.color == .red} ?? defaultColorOption
            case "soon": tagColors.first{$0.color == .blue} ?? defaultColorOption
            default: tagColors.first{$0.color == .blue} ?? defaultColorOption
         }
         customColors[tag.name] = colorOption.value
         return colorOption.color
      }
   }
   
   func colorMenu(for tag: Tag, presenting: Binding<Bool>) -> some View {
      Menu {
         ForEach(tagColors) { colorOption in
            Button{
               self.setColor(for: tag, option: colorOption)
               presenting.wrappedValue = false
            } label: {
               Label(colorOption.name, systemImage: "square.fill").tint(colorOption.color)
            }
         }
      } label: {
         Label("Colour", systemImage: "paintbrush.pointed.fill")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
      }
   }
}
