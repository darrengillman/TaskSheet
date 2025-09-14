import SwiftUI

struct TaskPaperView: View {
    @ObservedObject var document: TaskPaperDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DocumentHeader(document: document)

            List(document.items) { item in
                TaskPaperItemRow(item: item)
                    .listRowInsets(EdgeInsets())
            }
            .listStyle(.plain)
        }
    }
}

struct DocumentHeader: View {
    @ObservedObject var document: TaskPaperDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(document.fileName)
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                StatItem(icon: "folder", count: document.projectCount, label: "Projects")
                StatItem(icon: "checkmark.circle", count: document.completedTaskCount, label: "Done")
                StatItem(icon: "circle", count: document.taskCount - document.completedTaskCount, label: "Tasks")
                StatItem(icon: "doc.text", count: document.noteCount, label: "Notes")
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

struct StatItem: View {
    let icon: String
    let count: Int
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.caption)

            Text("\(count)")
                .fontWeight(.medium)
                .font(.caption)

            Text(label)
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
}