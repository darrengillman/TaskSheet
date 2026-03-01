import Foundation
import SwiftUI
import UniformTypeIdentifiers
import OSLog

class TaskPaperDocument: ReferenceFileDocument, ObservableObject {
   private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TaskSheet", category: "TaskPaperDocument")
   
      // Required by ReferenceFileDocument
   static var readableContentTypes: [UTType] { [.taskPaper] }
   static var writableContentTypes: [UTType] { [.taskPaper] }
   
   @Published var items: [TaskPaperItem] = []
   @Published var fileName: String
   
   var undoManager: UndoManager?
   
   var content: String {
      return items.taskPaperContent
   }
   
      // Required initializer for loading documents
   required init(configuration: ReadConfiguration) throws {
      guard let data = configuration.file.regularFileContents,
            let content = String(data: data, encoding: .utf8)
      else {
         throw CocoaError(.fileReadCorruptFile)
      }
      self.fileName = configuration.file.filename ?? "Untitled"
      self.items = TaskPaperParser.parse(content)
   }
   
      // Existing init for sample data and new documents
   init(content: String, fileName: String = "Untitled") {
      self.fileName = fileName
      self.items = TaskPaperParser.parse(content)
   }
   
      // Required method for saving - creates a snapshot of document data
   func snapshot(contentType: UTType) throws -> Data {
      let content = items.taskPaperContent
      
      logger.info("snapshot: writing \(self.items.count) items to disk (\(content.count) bytes)")
      
      guard let data = content.data(using: .utf8) else {
         throw CocoaError(.fileWriteUnknown)
      }
      return data
   }
   
      // Required method for writing snapshot to file
   func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
      return FileWrapper(regularFileWithContents: snapshot)
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
      
         // Register undo
      undoManager?.registerUndo(withTarget: self) { document in
         document.delete(newItem)
      }
      
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
            // Register undo for append
         undoManager?.registerUndo(withTarget: self) { document in
            document.delete(newItem)
         }
         items.append(newItem)
         return
      }
      let nextIndex = items.index(after: currentIndex)
      
         // Register undo for insert
      undoManager?.registerUndo(withTarget: self) { document in
         document.delete(newItem)
      }
      
      items.insert(newItem, at: nextIndex)
   }
   
   func delete(_ item: TaskPaperItem) {
      guard let index = items.firstIndex(of: item) else { return }
      
         // Register undo
      undoManager?.registerUndo(withTarget: self) { document in
         document.items.insert(item, at: index)
      }
      
      items.remove(at: index)
   }
   
      // MARK: - Task Completion
   
   func toggleTaskCompletion(item: TaskPaperItem) {
      guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
      
         // Register undo
      undoManager?.registerUndo(withTarget: self) { document in
         document.toggleTaskCompletion(item: item)
      }
      
      items[index].toggleCompletion()
   }
   
   func indent(_ item: TaskPaperItem ) {
      guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
      let originalIndent = items[index].indentLevel
      
         // Register undo
      undoManager?.registerUndo(withTarget: self) { document in
         document.outdent(item)
      }
      
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
      
         // Register undo
      undoManager?.registerUndo(withTarget: self) { document in
         document.indent(item)
      }
      
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
      
         // Register undo
      undoManager?.registerUndo(withTarget: self) { document in
         document.moveUp(item)
      }
      
      var copy = items
      copy.move(fromOffsets: IndexSet(moveDef.moving), toOffset: moveDef.after + 1)
      items = copy
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
      
         // Register undo
      undoManager?.registerUndo(withTarget: self) { document in
         document.moveDown(item)
      }
      
      var copy = items
      copy.move(fromOffsets: moveDef.moving, toOffset: moveDef.insertAt)
      items = copy
   }
   
   
   func moveHierarchy(at firstItemId: UUID, to destinationId: UUID) throws {
      guard let startIndex = items.firstIndex(where:{$0.id == firstItemId })
      else {throw DocumentError.itemsNotFound}
      let moving = items.hierarchyIndexes(from: startIndex)
      guard moving.isEmpty == false else {throw DocumentError.itemsNotFound}
      guard let destinationIndex = items.firstIndex(where: {$0.id == destinationId}) else {throw DocumentError.noValidDestination}
      
      // register  undo
      let oldItems = items
      undoManager?.registerUndo(withTarget: self) { document in
         document.items = oldItems
      }
      
      logger.info("moveHierarchy: registered undo, moving \(moving.count) items from index \(startIndex) to \(destinationIndex)")
      
      // Match indent to destination level, then move — all on a copy so @Published fires once.
      var copy = items
      if destinationIndex < copy.endIndex {
         let extraIndent = copy[destinationIndex].indentLevel - copy[startIndex].indentLevel
         if extraIndent > 0 {
            for index in moving {
               copy[index].indentLevel += extraIndent
            }
         }
      }
      copy.move(fromOffsets: moving, toOffset: destinationIndex)
      items = copy
      
      logger.info("moveHierarchy: items assigned, objectWillChange should have fired")
   }

   func moveHierarchyToEnd(at firstItemId: UUID) throws {
      guard let startIndex = items.firstIndex(where: { $0.id == firstItemId })
      else { throw DocumentError.itemsNotFound }
      let moving = items.hierarchyIndexes(from: startIndex)
      guard moving.isEmpty == false else { throw DocumentError.itemsNotFound }

      let oldItems = items
      undoManager?.registerUndo(withTarget: self) { doc in doc.items = oldItems }
      
      logger.info("moveHierarchyToEnd: registered undo, moving \(moving.count) items from index \(startIndex) to end")
      
      var copy = items
      copy.move(fromOffsets: moving, toOffset: copy.endIndex)
      items = copy
      
      logger.info("moveHierarchyToEnd: items assigned, objectWillChange should have fired")
   }

   enum DocumentError: Error {
      case itemsNotFound, noValidDestination
   }
   
}
