import SwiftUI

struct TaskPaperItemRow: View {
    let item: TaskPaperItem
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
           Button {
              
           } label: {
              Label( "Edit...", systemImage: "text.page")
           }
           Button {
              
           } label: {
              Label( "Add tag...", systemImage: "at.circle")
           }
           Divider()
           Menu("Move...") {
              Label("Task Actions", systemImage: "list.bullet")
                 .foregroundColor(.secondary)
                 .font(.caption)
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
