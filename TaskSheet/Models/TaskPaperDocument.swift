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
   
   var allTags: [Tag] {
      items
         .reduce(Set<Tag>()) { set, item in
            set.union(item.tags)
         }
         .sorted(using: SortDescriptor(\.displayText))
   }
   
   func quickAdd(_ text: String, type: ItemType) {
      let newItem = TaskPaperItem(type: type, text: text, indentLevel: 1)
      if let inboxIndex = items.firstIndex(where: {$0.text.prefix(6) == "Inbox:" && $0.type == .project && $0.indentLevel == 0}) {
         
         
         let insertIndex = items[(inboxIndex+1)...].firstIndex(where: {$0.indentLevel == 0}) ?? inboxIndex + 1
         
         items.insert(newItem, at: insertIndex)
      } else {
         let inboxProject = TaskPaperItem(type: .project, text: "Inbox", indentLevel: 0)
         items.insert(contentsOf: [inboxProject, newItem], at: 0)
      }
   }
   
   func insert(_ newItem: TaskPaperItem, after task: TaskPaperItem) {
      guard let currentIndex = items.firstIndex(of: task) else {
         items.append(newItem)
         return
      }
      let nextIndex = items.index(after: currentIndex)
      items.insert(newItem, at: nextIndex)
   }
   
   func delete(_ item: TaskPaperItem) {
      guard let index = items.firstIndex(of: item) else { return }
      items.remove(at: index)
   }
   
      // MARK: - Task Completion
   
   func toggleTaskCompletion(item: TaskPaperItem) {
      guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
      items[index].toggleCompletion()
   }
   
   func indent(_ item: TaskPaperItem ) {
      guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
      let originalIndent = items[index].indentLevel
      items[index].indentLevel += 1
      var childIndex = index + 1
      while childIndex < items.endIndex && items[childIndex].indentLevel > originalIndent {
         items[childIndex].indentLevel += 1
         childIndex += 1
      }
   }
   
   func outdent(_ item: TaskPaperItem ) {
      guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
      let originalIndent = items[index].indentLevel
      guard originalIndent > 0 else { return }
      items[index].indentLevel -= 1
      var childIndex = index + 1
      while childIndex < items.endIndex && items[childIndex].indentLevel > originalIndent {
         items[childIndex].indentLevel -= 1
         childIndex += 1
      }
   }
   
   func isAtTop(_ item: TaskPaperItem) -> Bool {
      items.firstIndex(of: item) == items.startIndex
   }
   
   func isAtBottom(_ item: TaskPaperItem) -> Bool {
      let destination = moveDownDestination(for: item)
      return destination == nil
   }
   
   func moveDownDestination(for item: TaskPaperItem) -> (moving: IndexSet, after: Int)? {
      guard !items.isEmpty,  let itemIndex = items.firstIndex(of: item) else {return nil}
      let enumerated = items.enumerated()
      let firstMatchingIndent = enumerated.first(where: {$0 > itemIndex && $1.indentLevel <= item.indentLevel})?.offset
      let secondMatchingIndent = firstMatchingIndent == nil ? nil  : enumerated.first(where: {$0 > firstMatchingIndent! && $1.indentLevel <= item.indentLevel})?.offset
      
      switch (firstMatchingIndent, secondMatchingIndent) {
         case (nil, _):
            return nil
         case (.some(let first), nil):
            return (IndexSet(itemIndex..<first), enumerated.last!.offset)
         case let (.some(first), .some(second)):
            return (IndexSet(itemIndex..<first), second - 1)
      }
   }

   func moveDown(_ item: TaskPaperItem) {
      guard let moveDef = moveDownDestination(for: item) else { return }
      items.move(fromOffsets: IndexSet(moveDef.moving), toOffset: moveDef.after + 1)
   }
   
   func moveUpDestination(for item: TaskPaperItem) -> (moving: IndexSet, insertAt: Int)? {
      guard let itemIndex = items.firstIndex(of: item) else {return nil}
      let enumerated = items.enumerated()
      let blockToMoveEndIndex = (enumerated.first(where: {$0 > itemIndex && $1.indentLevel <= item.indentLevel})?.offset)?.advanced(by: -1)
      let insertionIndex = enumerated.last(where:{$0 < itemIndex && $1.indentLevel <= item.indentLevel})?.offset
      
      switch(blockToMoveEndIndex, insertionIndex) {
         case (.none, .none):
            return (IndexSet(integer: itemIndex), items.startIndex)
         case let (.none, .some(insertion)):
            return (IndexSet(integer: itemIndex), insertion)
         case let (.some(blockEnd), .none):
            return (IndexSet(itemIndex...blockEnd), items.startIndex )
         case let (.some(blockEnd), .some(insertion)):
            return (IndexSet(itemIndex...blockEnd), insertion)
      }
   }

   func moveUp(_ item: TaskPaperItem) {
      guard let moveDef = moveUpDestination(for: item) else {return}
      items.move(fromOffsets: moveDef.moving, toOffset: moveDef.insertAt)
   }
   
   func hierarchy(for item: TaskPaperItem) -> IndexSet? {
      guard let itemIndex = items.firstIndex(of: item) else {return nil}
      let blockEndIndex = items.enumerated().first(where: {$0 > itemIndex && $1.indentLevel <= item.indentLevel})?.offset.advanced(by: -1) ?? items.endIndex

      return IndexSet(itemIndex...blockEndIndex)
   }
   
   func moveHierarchy(for item: TaskPaperItem, onto destination : TaskPaperItem ) throws {
      guard let moving = hierarchy(for: item), moving.isEmpty == false
      else {throw DocumentError.itemsNotFound}
      guard let insertion = items.firstIndex(of: destination)
      else { throw DocumentError.noValidDestination}
      
      let extraIndent = destination.indentLevel - item.indentLevel
      if extraIndent > 0 {
         for index in moving {
            items[index].indentLevel += extraIndent
         }
      }
      
      items.move(fromOffsets: moving, toOffset: insertion)
   }
   
   enum DocumentError: Error {
      case itemsNotFound, noValidDestination
   }
   
}
