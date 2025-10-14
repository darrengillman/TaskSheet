import SwiftUI

struct ItemRowView: View {
   @Binding var item: TaskPaperItem
   @ObservedObject var tagSchemaManager: TagSchemaManager
   @ObservedObject var document: TaskPaperDocument
   
   @Binding var isEditing: Bool
   
   @State private var folded = false
   @State private var isShowingAddTagPopover = false
   @State private var isShowingNewItemPopover: TextEntryRole? = nil
   @State private var isShowingEditSheet: TextEntryRole? = nil
   @State private var editTextBuffer: String = ""
   
   @State private var isShowingAlert = false
   @State private var alertMessage: String? = nil
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
         
         item.icon
            .onTapGesture {
               document.toggleTaskCompletion(item: item)
            }
         
         VStack(alignment: .leading, spacing: 4) {
            Text(item.displayText)
               .lineLimit(folded ? 1 : nil)
               .font(font(for: item.type))
               .fontWeight(item.type == .project ? .semibold : .regular)
               .strikethrough(item.isCompleted)
               .foregroundColor(item.isCompleted ? .secondary : .primary)
               .onTapGesture {
                  if item.isCompleted == false {
                     edit(item)
                  }
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
      .popover(isPresented: $isShowingAddTagPopover) {
         AddTagPopOver() { text in
            item.addTag(.init(name: text), at: .end)
            isEditing = false
         }
         .presentationCompactAdaptation(.popover)
      }
      .popover(item: $isShowingNewItemPopover) { role in
         AddItemPopOver(
            showPopover: $isShowingNewItemPopover,
            showSheet: $isShowingEditSheet,
            text: $editTextBuffer,
            role: role
         ) { text, type in
            if case .edit = role {
               item.text = text
            } else {
               let newItem = TaskPaperItem(type: type, text: text, indentLevel: role.indent)
               document.insert(newItem, after: item)
            }
            resetInput()
         } onCancel: {
            resetInput()
         }
         .presentationCompactAdaptation(.popover)
      }
      .sheet(item: $isShowingEditSheet) { role in
         ItemEditorSheet(text: $editTextBuffer, role: role) { text, type in
            if case .edit = role {
               item.text = text
            } else {
               let newItem = TaskPaperItem(type: type, text: text, indentLevel: role.indent)
               document.insert(newItem, after: item)
            }
            resetInput()
         } onCancel: {
            resetInput()
         }
         .presentationDetents([.fraction(0.35), .medium, .large])
      }
      .alert(alertTitle,
             isPresented: $isShowingAlert,
             actions: {Button(role: .confirm, action: {alertMessage = nil})},
             message: {alertMessage == nil ? nil : Text(alertMessage!)}
      )
   }
   
   private func edit(_ item: TaskPaperItem) {
      editTextBuffer = item.text
      isEditing = true
      isShowingNewItemPopover = .edit(type: item.type, indent: item.indentLevel)
   }
   
   func resetInput() {
      isEditing = false
      isShowingNewItemPopover = nil
      isShowingEditSheet = nil
      editTextBuffer = ""
   }   
}
//MARK: - Context Menu Builders
extension ItemRowView {
   @ViewBuilder
   private var MainContextMenu: some View {
      completionMenu
      deleteMenu
      foldingMenu
      if !item.isCompleted {
         focusMenu
         Divider()
      }
      addMenu
      moveMenu
   }
   
   @ViewBuilder
   private var completionMenu: some View {
      Button {
         document.toggleTaskCompletion(item: item)
      } label: {
         Label( item.isCompleted ? "Mark as Incomplete" : "Mark as Complete",
                systemImage: item.isCompleted ?  "circle" : "checkmark.circle.fill")
      }
   }
   
   private var deleteMenu: some View {
      Button {
         document.delete(item)
      } label: {
         Label( "Delete", systemImage: "minus.circle")
      }
   }
   
   @ViewBuilder
   private var focusMenu: some View {
      Button {
         alertMessage = "Focus not implemented"
         isShowingAlert = true
      } label: {
         Label( "Focus", systemImage: "plus.magnifyingglass")
      }
   }
   
   @ViewBuilder
   private var addMenu: some View {
      if item.isCompleted {
         Button {
            isShowingNewItemPopover = .add(indent: item.indentLevel)
         } label: {
            Label( "Add item", systemImage: "plus.circle")
         }
      } else {
         Menu {
            Button {
               isEditing = true
               isShowingNewItemPopover = .add(indent: item.indentLevel)
            } label: {
               Label( "Add item", systemImage: "plus.circle")
            }
            
            Button {
               isEditing = true
               isShowingNewItemPopover = .add(indent: item.indentLevel + 1)
            } label: {
               Label( "Add child", systemImage: "circle.badge.plus")
            }
            
            Menu {
               Button {
                  withAnimation {
                     isEditing = true
                     isShowingAddTagPopover = true
                  }
               } label: {
                  Label("New...", systemImage: "at.badge.plus")
               }
               Divider()
               ForEach(document.allTags.filter{$0.name  != "done"}, id: \.displayText) { tag in
                  Button{
                     item.addTag(tag, at: .end)
                  } label: {
                     HStack {
                        item.tags.contains(tag) ? Image(systemName: "checkmark.circle") : Image(systemName: "circle")
                        Text(tag.name)
                     }
                  }
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
            Label( "Compress", systemImage: "rectangle.compress.vertical")
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

extension Int: @retroactive Identifiable {
   public var id: Int {self}
}

