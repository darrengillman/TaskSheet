import SwiftUI

struct ItemRowView: View {
   var tags: [Tag]
   @Binding var item: TaskPaperItem
   @ObservedObject var tagSchemaManager: TagSchemaManager
   let onToggleCompletion: ((TaskPaperItem) -> Void)?
   
   @State private var folded = false
   @State private var isShowingAddTabSheet = false
   @State private var alertMessage: String? = nil
   @State private var isShowingAlert = false
   @State private var alertTitle: String = "Not Implemented"
   

   
   var body: some View {
      HStack(alignment: .top, spacing: 8) {
            // Indentation
         HStack(spacing: 0) {
            ForEach(0..<item.indentLevel, id: \.self) { _ in
               Rectangle()
                  .fill(Color.clear)
                  .frame(width: 20)
            }
         }
         
         itemIcon
            .onTapGesture {
               onToggleCompletion?(item)
            }
         
            // Content
         VStack(alignment: .leading, spacing: 4) {
            Text(item.displayText)
               .lineLimit(folded ? 1 : nil)
               .font(font(for: item.type))
               .fontWeight(item.type == .project ? .semibold : .regular)
               .strikethrough(item.isCompleted)
               .foregroundColor(item.isCompleted ? .secondary : .primary)
               .contextMenu {
                  MainContextMenu
               }
            
            if !item.tags.isEmpty {
               TagsView(
                  tags: item.tags,
                  schema: tagSchemaManager,
                  deleteAction: {tag in item.removeTag(tag)}
               )
            }
         }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 4)
      .padding(.horizontal)
      .sheet(isPresented: $isShowingAddTabSheet) {
         AddTabsSheet
      }
      .alert(alertTitle,
             isPresented: $isShowingAlert,
             actions: {Button(role: .confirm, action: {alertMessage = nil})},
             message: {alertMessage == nil ? nil : Text(alertMessage!)}
      )
   }
   
   private var AddTabsSheet: some View {
      Menu("Tags") {
         ForEach(tags, id: \.displayText) { tag in
            Text(tag.name)
         }
      }
   }
   
   @ViewBuilder
   private var MainContextMenu: some View {
      Button {
         onToggleCompletion?(item)
      } label: {
         Label( item.isCompleted ? "Mark as Incomplete" : "Mark as Complete",
                systemImage: item.isCompleted ?  "circle" : "checkmark.circle.fill")
      }
      
      if folded {
         Button {
            folded = false
         } label: {
            Label( "Expand", systemImage: "rectangle.expand.vertical")
         }
      } else {
         Button {
            folded = true
         } label: {
            Label( "Fold", systemImage: "rectangle.compress.vertical")
         }
      }
      
      if !item.isCompleted {
         Button {
            alertMessage = "Focus not implemented"
            isShowingAlert = true
         } label: {
            Label( "Focus", systemImage: "plus.magnifyingglass")
         }
         Divider()
         Menu {
            Button{
               alertMessage = "Add Item not implemented"
               isShowingAlert = true
            } label: {
               Label( "Add item", systemImage: "plus.circle")
            }
            
            Button{
               alertMessage = "Add Item not implemented"
               isShowingAlert = true
            } label: {
               Label( "Add child", systemImage: "circle.badge.plus")
            }
            Menu{
               ForEach(tags.filter{$0.name  != "done"}, id: \.displayText) { tag in
                  Button{ item.addTag(tag, at: .end) } label: { Text(tag.name) }
               }
            } label: {
               Label( "Add tag", systemImage: "at.circle")
            }
         } label: {
            Label("Add...", systemImage: "plus.circle")
         }
      }
      
      Menu("Move...") {
         Label("Move Actions", systemImage: "list.bullet")
            .foregroundColor(.secondary)
            .font(.caption)
      }
   }
   
   @ViewBuilder
   private var itemIcon: some View {
      switch item.type {
         case .project:
            Image(systemName: "folder")
               .foregroundColor(.blue)
               .font(.system(size: 16, weight: .medium))
         case .task:
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
               .foregroundColor(item.isCompleted ? .green : .secondary)
               .font(.system(size: 16))
         case .note:
            Image(systemName: "doc.text")
               .foregroundColor(item.isCompleted ? .secondary: .gray)
               .font(.system(size: 14))
      }
   }
   
   private func font(for itemType: ItemType) -> Font {
      switch itemType {
         case .project:
            return .headline
         case .task:
            return .body
         case .note:
            return .body.scaled(by: 0.8)
      }
   }
}

struct TagsView: View {
   let tags: [Tag]
   @ObservedObject var schema: TagSchemaManager
   let deleteAction: (Tag) -> Void
   
   var body: some View {
      HStack(spacing: 6) {
         ForEach(tags, id: \.self) { tag in
            TagView(tag: tag, schema: schema, deleteAction: deleteAction)
         }
      }
   }
}

struct TagView: View {
   @State private var showingTagActions = false
   @State var tag: Tag
   @ObservedObject var schema: TagSchemaManager
   let deleteAction: (Tag) -> Void
   @State var colorRefreshID = UUID()
   

   var body: some View {
      Text(tag.displayText)
         .font(.caption)
         .padding(.horizontal, 6)
         .padding(.vertical, 2)
         .background(schema.getColor(for: tag).opacity(0.2))
         .foregroundColor(schema.getColor(for: tag))
         .id(colorRefreshID)
         .cornerRadius(4)
         .contentShape(Rectangle())
         .onTapGesture {
            if tag.name != "done" {
               showingTagActions = true
            }
         }
         .popover(isPresented: $showingTagActions) {
            VStack(spacing: 0) {
               Button {
                  deleteAction(tag)
                  showingTagActions = false
               } label: {
                  Label("Delete Tag", systemImage: "trash")
                     .foregroundColor(.red)
                     .frame(maxWidth: .infinity, alignment: .leading)
                     .padding()
               }
               colorMenu
            }
            .frame(width: 160)
            .background(Color(.systemBackground))
            .presentationCompactAdaptation(.popover)
         }
   }
   
   private var colorMenu: some View {
      Menu{
         Button("Black") { recolor(.black) }
         Button("Blue") { recolor(.blue) }
         Button("Brown") { recolor(.brown) }
         Button("Cyan") { recolor(.cyan) }
         Button("Gray") { recolor(.gray) }
         Button("Green") { recolor(.green) }
         Button("Indigo") { recolor(.indigo) }
         Button("Mint") { recolor(.mint) }
         Button("Orange") { recolor(.orange) }
         Button("Pink") { recolor(.pink) }
         Button("Purple") { recolor(.purple) }
         Button("Red") { recolor(.red) }
         Button("Teal") { recolor(.teal) }
         Button("Yellow") { recolor(.yellow) }
      } label: {
         Label("Set Colour", systemImage: "paintbrush.pointed.fill")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
      }
   }

   
   func recolor(_ color: Color) {
      schema.setColor(for: tag, color: color)
      showingTagActions = false
   }
}
