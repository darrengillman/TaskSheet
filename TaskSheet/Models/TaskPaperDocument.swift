import Foundation

class TaskPaperDocument: ObservableObject {
    @Published var content: String
    @Published var items: [TaskPaperItem] = []
    @Published var fileName: String

    init(content: String, fileName: String = "Untitled") {
        self.content = content
        self.fileName = fileName
        self.items = TaskPaperParser.parse(content)
    }

    func refresh() {
        items = TaskPaperParser.parse(content)
    }

    var projectCount: Int {
        items.filter { $0.type == .project }.count
    }

    var taskCount: Int {
        items.filter { $0.type == .task }.count
    }

    var completedTaskCount: Int {
        items.filter { $0.type == .task && $0.isCompleted }.count
    }

    var noteCount: Int {
        items.filter { $0.type == .note }.count
    }
}