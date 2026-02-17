import Foundation
import SwiftUI
import UniformTypeIdentifiers

class TaskPaperDocument: ReferenceFileDocument, ObservableObject {
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
      
         // Register undo
      undoManager?.registerUndo(withTarget: self) { document in
         document.moveDown(item)
      }
      
      items.move(fromOffsets: moveDef.moving, toOffset: moveDef.insertAt)
   }
   
   //THIS ONE (?)
   private func hierarchy(from startIndex: Int) throws -> IndexSet {
      let topLevelIndent = items[startIndex].indentLevel
      let enumerated = items.enumerated()
      let firstEndIndex = enumerated.first(where: {$0 > startIndex && $1.indentLevel <= topLevelIndent })
      let endIndex = (firstEndIndex?.offset ?? items.endIndex)
      let blockEndIndex = endIndex.advanced(by: -1)
      let hierarchy = IndexSet(startIndex...blockEndIndex)
      return hierarchy
   }
   
      // would expect the indexset to be a single item, but checking to be safe±!
//   private func hierarchy(for topLevelIndexSet: IndexSet) throws -> IndexSet {
//      guard topLevelIndexSet.count ==  1, let itemIndex = topLevelIndexSet.first
//      else { throw DocumentError.itemsNotFound }
//      print("Moving from index: \(itemIndex)")
//      
//      let topLevelIndent = items[itemIndex].indentLevel
//      
//      let enumerated = items.enumerated()
//      
//      let firstEndIndex = enumerated.first(where: {$0 > itemIndex && $1.indentLevel <= topLevelIndent })
//      print("EndIndex \(firstEndIndex, default: "nil")")
//      
//      let endIndex = (firstEndIndex?.offset ?? items.endIndex)
//      print("InterimIndex \(endIndex)")
//      
//      let blockEndIndex = endIndex.advanced(by: -1)
//      print( "BlockEndIndex \(blockEndIndex)")
//      
//      let hierarchy = IndexSet(itemIndex...blockEndIndex)
//      print("Hierarchy \(hierarchy.debugDescription)")
//      print("--------------------")
//      return hierarchy
//   }
   
      //should be obsolete
      //   func hierarchy(for item: TaskPaperItem) -> IndexSet? {
      //      guard let itemIndex = items.firstIndex(of: item) else {return nil}
      //      let blockEndIndex = items.enumerated().first(where: {$0 > itemIndex && $1.indentLevel <= item.indentLevel})?.offset.advanced(by: -1) ?? items.endIndex
      //
      //      return IndexSet(itemIndex...blockEndIndex)
      //   }
   
   func moveHierarchy(at firstItemId: UUID, to destinationId: UUID) throws {
      guard let startIndex = items.firstIndex(where:{$0.id == firstItemId })
      else {throw DocumentError.itemsNotFound}
      let moving = try hierarchy(from: startIndex)
      guard moving.isEmpty == false else {throw DocumentError.itemsNotFound}
      guard let destinationIndex = items.firstIndex(where: {$0.id == destinationId}) else {throw DocumentError.noValidDestination}
      
      // register  undo
      let oldItems = items
      undoManager?.registerUndo(withTarget: self) { document in
         document.items = oldItems
      }
      //match indent to destination level
      if destinationIndex < items.endIndex {
         let extraIndent = items[destinationIndex].indentLevel - items[startIndex].indentLevel
         if extraIndent > 0 {
            for index in moving {
               items[index].indentLevel += extraIndent
            }
         }
      }
      
      items.move(fromOffsets: moving, toOffset: destinationIndex)
   }
   
   
//   func moveHierarchy(_ topLevel: IndexSet, to destination : Int ) throws {
//      let moving = try hierarchy(for: topLevel)
//      guard moving.isEmpty == false else {throw DocumentError.itemsNotFound}
//      // register  undo
//      let oldItems = items
//      undoManager?.registerUndo(withTarget: self) { document in
//         document.items = oldItems
//      }
//      
//      if destination < items.endIndex {
//         let extraIndent = items[destination].indentLevel - items[topLevel.first!].indentLevel
//         if extraIndent > 0 {
//            for index in moving {
//               items[index].indentLevel += extraIndent
//            }
//         }
//      }
//      items.move(fromOffsets: moving, toOffset: destination)
//   }

      //should be obsolete
//   func moveHierarchy(for item: TaskPaperItem, onto destination : TaskPaperItem ) throws {
//      guard let moving = hierarchy(for: item), moving.isEmpty == false
//      else {throw DocumentError.itemsNotFound}
//      guard let insertion = items.firstIndex(of: destination)
//      else { throw DocumentError.noValidDestination}
//
//      // register  undo
//      let oldItems = items
//      undoManager?.registerUndo(withTarget: self) { document in
//         document.items = oldItems
//      }
//
//      let extraIndent = destination.indentLevel - item.indentLevel
//      if extraIndent > 0 {
//         for index in moving {
//            items[index].indentLevel += extraIndent
//         }
//      }
//
//      items.move(fromOffsets: moving, toOffset: insertion)  //  check for last point and append not insert?
//   }
   
   enum DocumentError: Error {
      case itemsNotFound, noValidDestination
   }
   
}
