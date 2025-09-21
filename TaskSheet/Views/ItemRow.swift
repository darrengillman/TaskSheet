import SwiftUI

struct ItemRow: View {
   @State private var folded = false
   @State private var isShowingAddTabSheet = false
   @State private var alertMessage: String? = nil
   @State private var isShowingAlert = false
   @State private var alertTitle: String = "Not Implemented"

   var tags: [Tag]

    @Binding var item: TaskPaperItem
    let onToggleCompletion: ((TaskPaperItem) -> Void)?

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

                if !item.tags.isEmpty {
                    TagsView(tags: item.tags)
                }
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .padding(.horizontal)
        .contextMenu {
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
        .sheet(isPresented: $isShowingAddTabSheet) {
           AddTabsSheet
        }
        .alert(
         alertTitle,
         isPresented: $isShowingAlert,
         actions: {
            Button(role: .confirm, action: {alertMessage = nil})
         },
         message: {alertMessage == nil ? nil : Text(alertMessage!)} )

    }
   
   private var AddTabsSheet: some View {
      Menu("Tags") {
         ForEach(tags, id: \.displayText) { tag in
            Text(tag.name)
         }
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

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                TagView(tag: tag)
            }
        }
    }
}

struct TagView: View {
    let tag: Tag

    var body: some View {
        Text(tag.displayText)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tagColor.opacity(0.2))
            .foregroundColor(tagColor)
            .cornerRadius(4)
    }

    private var tagColor: Color {
        switch tag.name {
        case "done":
            return .green
        case "next", "today":
            return .orange
        case "someday", "maybe":
            return .purple
        case "BUG", "bug":
            return .red
        case "soon":
            return .blue
        default:
            return .secondary
        }
    }
}
