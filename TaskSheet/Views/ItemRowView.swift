import SwiftUI

struct ItemRowView: View {
   @Binding var item: TaskPaperItem
   @ObservedObject var tagSchemaManager: TagSchemaManager
   @ObservedObject var document: TaskPaperDocument
   //let onToggleCompletion: ((TaskPaperItem) -> Void)?
   
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
               document.toggleTaskCompletion(item: item)
            }
         
            // Content
         VStack(alignment: .leading, spacing: 4) {
            Text(item.displayText)
               .lineLimit(folded ? 1 : nil)
               .font(font(for: item.type))
               .fontWeight(item.type == .project ? .semibold : .regular)
               .strikethrough(item.isCompleted)
               .foregroundColor(item.isCompleted ? .secondary : .primary)
               .onTapGesture {
                  alertMessage = "Editing not implemented"
                  isShowingAlert = true
               }
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
         ForEach(document.tags, id: \.displayText) { tag in
            Text(tag.name)
         }
      }
   }
   
   @ViewBuilder
   private var MainContextMenu: some View {
      Button {
         document.toggleTaskCompletion(item: item)
      } label: {
         Label( item.isCompleted ? "Mark as Incomplete" : "Mark as Complete",
                systemImage: item.isCompleted ?  "circle" : "checkmark.circle.fill")
      }
      foldingMenu
      ifCompletedMenu
      moveMenu
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
   
   @ViewBuilder
   private var ifCompletedMenu: some View {
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
               ForEach(document.tags.filter{$0.name  != "done"}, id: \.displayText) { tag in
                  Button{ item.addTag(tag, at: .end) } label: { Text(tag.name) }
               }
            } label: {
               Label( "Add tag", systemImage: "at.circle")
            }
         } label: {
            Label("Add...", systemImage: "plus.circle")
         }
      }
   }

   @ViewBuilder
   private var foldingMenu: some View {
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
   }
   
   @ViewBuilder
   private var moveMenu: some View {
      Menu {
         moveActions
      } label: {
         Label("Move Actions", systemImage: "list.bullet")
            .foregroundColor(.secondary)
            .font(.caption)
      }
   }
   
   @ViewBuilder
   private var moveActions: some View {
      if !document.isAtTop(item) {
         Button {
            withAnimation{
               document.moveUp(item)
            }
         } label: {
            Label("Up", systemImage: "arrowtriangle.up")
         }
      }

      Button {
         withAnimation {
            document.indent(item)
         }
      } label: {
         Label("Indent", systemImage: "arrowtriangle.forward")
      }
      
      if item.indentLevel > 0 {
         Button {
            withAnimation{
               document.outdent(item)
            }
         } label: {
            Label("Outdent", systemImage: "arrowtriangle.backward")
         }
      }
      
      if !document.isAtBottom(item) {
         Button {
            withAnimation{
               document.moveDown(item)
            }
         } label: {
            Label("Down", systemImage: "arrowtriangle.down")
         }
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

