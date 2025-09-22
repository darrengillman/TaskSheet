import Foundation

class TaskPaperDocument: ObservableObject {
   @Published var items: [TaskPaperItem] = []
   @Published var fileName: String
   
   var content: String {
      return items.taskPaperContent
   }
   
   init(content: String, fileName: String = "Untitled") {
      self.fileName = fileName
      self.items = TaskPaperParser.parse(content)
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
   
   var tags: [Tag] {
      items
         .reduce(Set<Tag>()) { set, item in
            set.union(item.tags)
         }
         .sorted(using: SortDescriptor(\.displayText))
   }
   
      // MARK: - Task Completion
   
   func toggleTaskCompletion(item: TaskPaperItem) {
      guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
      items[index].toggleCompletion()
   }
}
