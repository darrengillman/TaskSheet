import SwiftUI

struct TaskPaperItemRow: View {
    let item: TaskPaperItem

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

            // Item icon
            itemIcon

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayText)
                    .font(item.type == .project ? .headline : .body)
                    .fontWeight(item.type == .project ? .semibold : .regular)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)

                if !item.tags.isEmpty {
                    TagsView(tags: item.tags)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
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
                .foregroundColor(.secondary)
                .font(.system(size: 14))
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