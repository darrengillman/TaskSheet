import Testing
import Foundation
@testable import TaskSheet

/// Tests for drag-and-drop functionality in filtered and unfiltered views
@Suite("Drag and Drop Tests")
struct TaskPaperDragDropTests {
    
    // MARK: - Test Data Setup
    
    /// Creates a document with items that have tags for filter testing
    /// Structure:
    /// Project A: @work                (0, indent: 0)
    ///   - Task A1 @work               (1, indent: 1)
    ///     - Subtask A1.1 @work        (2, indent: 2)
    ///   - Task A2 @personal           (3, indent: 1)
    /// Project B: @personal            (4, indent: 0)
    ///   - Task B1 @work               (5, indent: 1)
    ///   - Task B2 @personal           (6, indent: 1)
    ///     - Subtask B2.1 @urgent      (7, indent: 2)
    /// Project C: @work                (8, indent: 0)
    ///   - Task C1 @work               (9, indent: 1)
    private func createTaggedDocument() -> TaskPaperDocument {
        let content = """
        Project A: @work
        \t- Task A1 @work
        \t\t- Subtask A1.1 @work
        \t- Task A2 @personal
        Project B: @personal
        \t- Task B1 @work
        \t- Task B2 @personal
        \t\t- Subtask B2.1 @urgent
        Project C: @work
        \t- Task C1 @work
        """
        return TaskPaperDocument(content: content, fileName: "Tagged")
    }
    
    // MARK: - hierarchyIndexes Extension Tests
    
    @Suite("Hierarchy Index Calculation")
    struct HierarchyIndexTests {
        @Test("Single item with no children returns single index")
        func singleItemNoChildren() {
            let document = createTaggedDocument()
            let hierarchy = document.items.hierarchyIndexes(from: 3) // Task A2
            
            #expect(hierarchy == IndexSet(integer: 3))
        }
        
        @Test("Parent with one child returns both indices")
        func itemWithChildren() {
            let document = createTaggedDocument()
            let hierarchy = document.items.hierarchyIndexes(from: 1) // Task A1 + Subtask A1.1
            
            #expect(hierarchy == IndexSet(1...2))
        }
        
        @Test("Parent with nested child returns full hierarchy")
        func itemWithMultipleLevels() {
            let document = createTaggedDocument()
            let hierarchy = document.items.hierarchyIndexes(from: 6) // Task B2 + Subtask B2.1
            
            #expect(hierarchy == IndexSet(6...7))
        }
        
        @Test("Top-level item includes all nested descendants")
        func topLevelWithAllChildren() {
            let document = createTaggedDocument()
            let hierarchy = document.items.hierarchyIndexes(from: 0) // Project A + all children
            
            #expect(hierarchy == IndexSet(0...3))
        }
        
        @Test("Last item with no children returns single index")
        func lastItem() {
            let document = createTaggedDocument()
            let hierarchy = document.items.hierarchyIndexes(from: 9) // Task C1 (last)
            
            #expect(hierarchy == IndexSet(integer: 9))
        }
        
        private func createTaggedDocument() -> TaskPaperDocument {
            let content = """
            Project A: @work
            \t- Task A1 @work
            \t\t- Subtask A1.1 @work
            \t- Task A2 @personal
            Project B: @personal
            \t- Task B1 @work
            \t- Task B2 @personal
            \t\t- Subtask B2.1 @urgent
            Project C: @work
            \t- Task C1 @work
            """
            return TaskPaperDocument(content: content, fileName: "Tagged")
        }
    }
    
    // MARK: - moveHierarchy Tests (No Filter)
    
    @Suite("Move Hierarchy (Unfiltered)")
    struct UnfilteredMoveTests {
        @Test("Single item moves forward correctly")
        func singleItemForward() throws {
            let document = createTaggedDocument()
            let movingId = document.items[3].id  // Task A2
            let destinationId = document.items[5].id  // Task B1
            
            try document.moveHierarchy(at: movingId, to: destinationId)
            
            #expect(document.items[4].displayText == "Task A2")
        }
        
        @Test("Parent with children moves as unit")
        func parentWithChildrenForward() throws {
            let document = createTaggedDocument()
            let movingId = document.items[1].id  // Task A1 (with Subtask A1.1)
            let destinationId = document.items[6].id  // Task B2
            
            try document.moveHierarchy(at: movingId, to: destinationId)
            
            #expect(document.items[4].displayText == "Task A1")
            #expect(document.items[5].displayText == "Subtask A1.1")
        }
        
        @Test("Project with all children moves backward")
        func projectWithAllChildrenBackward() throws {
            let document = createTaggedDocument()
            let movingId = document.items[8].id  // Project C
            let destinationId = document.items[4].id  // Project B
            
            try document.moveHierarchy(at: movingId, to: destinationId)
            
            #expect(document.items[6].displayText == "Project C")
            #expect(document.items[7].displayText == "Task C1")
        }
        
        @Test("Move to end places items at final position")
        func moveToEnd() throws {
            let document = createTaggedDocument()
            let movingId = document.items[1].id  // Task A1
            
            try document.moveHierarchyToEnd(at: movingId)
            
            #expect(document.items[8].displayText == "Task A1")
            #expect(document.items[9].displayText == "Subtask A1.1")
        }
        
        private func createTaggedDocument() -> TaskPaperDocument {
            let content = """
            Project A: @work
            \t- Task A1 @work
            \t\t- Subtask A1.1 @work
            \t- Task A2 @personal
            Project B: @personal
            \t- Task B1 @work
            \t- Task B2 @personal
            \t\t- Subtask B2.1 @urgent
            Project C: @work
            \t- Task C1 @work
            """
            return TaskPaperDocument(content: content, fileName: "Tagged")
        }
    }
    
    // MARK: - moveHierarchy Tests (With Filter)
    
    @Suite("Move Hierarchy (Filtered Views)")
    struct FilteredMoveTests {
        @Test("Only visible items reflect move in filtered view")
        func onlyVisibleItemsMoveInView() throws {
            let document = createTaggedDocument()
            
            // Simulate filtering by @work tag
            let workItems = document.items.filter { item in
                item.cachedTags?.contains(where: { $0.name == "work" }) ?? false
            }
            var filteredIds = workItems.map { $0.id }
            
            #expect(filteredIds.count == 6) // Should have 6 @work items
            
            // Move Task A1 (with child) to before Project C in filtered view
            let movingId = filteredIds[1]  // Task A1
            let destinationId = filteredIds[4]  // Project C
            
            try document.moveHierarchy(at: movingId, to: destinationId)
            
            // Recompute filtered view
            let updatedWorkItems = document.items.filter { item in
                item.cachedTags?.contains(where: { $0.name == "work" }) ?? false
            }
            filteredIds = updatedWorkItems.map { $0.id }
            
            let taskA1Index = filteredIds.firstIndex(of: movingId)!
            let projectCIndex = filteredIds.firstIndex(of: destinationId)!
            #expect(taskA1Index < projectCIndex)
        }
        
        @Test("Hidden children move with visible parent")
        func partialHierarchyVisible() throws {
            let document = createTaggedDocument()
            
            // Project A has Task A1 @work and Task A2 @personal
            // When filtering by @work, only Project A and Task A1 (+ child) are visible
            let workItems = document.items.filter { item in
                item.cachedTags?.contains(where: { $0.name == "work" }) ?? false
            }
            let filteredIds = workItems.map { $0.id }
            
            // Move Project A (in document, this moves ALL children including Task A2)
            let movingId = filteredIds[0]  // Project A
            let destinationId = document.items[8].id  // Project C
            
            try document.moveHierarchy(at: movingId, to: destinationId)
            
            // In document.items, Task A2 @personal should have moved with Project A
            let taskA2Index = document.items.firstIndex { $0.displayText == "Task A2" }!
            let projectCIndex = document.items.firstIndex { $0.displayText == "Project C" }!
            #expect(taskA2Index < projectCIndex)
        }
        
        private func createTaggedDocument() -> TaskPaperDocument {
            let content = """
            Project A: @work
            \t- Task A1 @work
            \t\t- Subtask A1.1 @work
            \t- Task A2 @personal
            Project B: @personal
            \t- Task B1 @work
            \t- Task B2 @personal
            \t\t- Subtask B2.1 @urgent
            Project C: @work
            \t- Task C1 @work
            """
            return TaskPaperDocument(content: content, fileName: "Tagged")
        }
    }
    
    // MARK: - Persistence Tests
    
    @Suite("Persistence and State")
    struct PersistenceTests {
        @Test("Move triggers document content change")
        func triggersDocumentChange() throws {
            let document = createTaggedDocument()
            let originalContent = document.content
            
            let movingId = document.items[1].id
            let destinationId = document.items[5].id
            
            try document.moveHierarchy(at: movingId, to: destinationId)
            
            let newContent = document.content
            #expect(originalContent != newContent)
        }
        
        @Test("Indentation is preserved after move")
        func preservesIndentation() throws {
            let document = createTaggedDocument()
            
            let taskA1OriginalIndent = document.items[1].indentLevel
            let subtaskOriginalIndent = document.items[2].indentLevel
            
            let movingId = document.items[1].id
            let destinationId = document.items[5].id  // Task B1 (also indent 1)
            
            try document.moveHierarchy(at: movingId, to: destinationId)
            
            let movedTaskIndex = document.items.firstIndex { $0.id == movingId }!
            let movedSubtaskIndex = movedTaskIndex + 1
            
            #expect(document.items[movedTaskIndex].indentLevel == taskA1OriginalIndent)
            #expect(document.items[movedSubtaskIndex].indentLevel == subtaskOriginalIndent)
        }
        
        private func createTaggedDocument() -> TaskPaperDocument {
            let content = """
            Project A: @work
            \t- Task A1 @work
            \t\t- Subtask A1.1 @work
            \t- Task A2 @personal
            Project B: @personal
            \t- Task B1 @work
            \t- Task B2 @personal
            \t\t- Subtask B2.1 @urgent
            Project C: @work
            \t- Task C1 @work
            """
            return TaskPaperDocument(content: content, fileName: "Tagged")
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Suite("Error Handling")
    struct ErrorTests {
        @Test("Invalid moving ID throws itemsNotFound")
        func invalidMovingId() {
            let document = createTaggedDocument()
            let invalidId = UUID()
            let destinationId = document.items[0].id
            
            #expect(throws: TaskPaperDocument.DocumentError.itemsNotFound) {
                try document.moveHierarchy(at: invalidId, to: destinationId)
            }
        }
        
        @Test("Invalid destination ID throws noValidDestination")
        func invalidDestinationId() {
            let document = createTaggedDocument()
            let movingId = document.items[0].id
            let invalidId = UUID()
            
            #expect(throws: TaskPaperDocument.DocumentError.noValidDestination) {
                try document.moveHierarchy(at: movingId, to: invalidId)
            }
        }
        
        private func createTaggedDocument() -> TaskPaperDocument {
            let content = """
            Project A: @work
            \t- Task A1 @work
            \t\t- Subtask A1.1 @work
            \t- Task A2 @personal
            Project B: @personal
            \t- Task B1 @work
            \t- Task B2 @personal
            \t\t- Subtask B2.1 @urgent
            Project C: @work
            \t- Task C1 @work
            """
            return TaskPaperDocument(content: content, fileName: "Tagged")
        }
    }
}
