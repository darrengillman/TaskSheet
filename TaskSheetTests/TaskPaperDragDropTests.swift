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
            
            // After moving Project C (was at 8-9) to before Project B (was at 4),
            // Project C should now be at index 4, followed by Task C1 at index 5
            #expect(document.items[4].displayText == "Project C")
            #expect(document.items[5].displayText == "Task C1")
            #expect(document.items[4].indentLevel == 0)
            #expect(document.items[5].indentLevel == 1)
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
            
            guard let taskA1Index = filteredIds.firstIndex(of: movingId),
                  let projectCIndex = filteredIds.firstIndex(of: destinationId) else {
                Issue.record("Task A1 or Project C not found in filtered view after move")
                return
            }
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
            guard let taskA2Index = document.items.firstIndex(where: { $0.displayText == "Task A2" }),
                  let projectCIndex = document.items.firstIndex(where: { $0.displayText == "Project C" }) else {
                Issue.record("Task A2 or Project C not found after move")
                return
            }
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
            
            guard let movedTaskIndex = document.items.firstIndex(where: { $0.id == movingId }) else {
                Issue.record("Task A1 not found after move")
                return
            }
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

        @Test("Drag onto direct child throws noValidDestination")
        func dragOntoDirectChild() {
            let document = createTaggedDocument()
            // Project A(0) → Task A1(1), its direct child
            #expect(throws: TaskPaperDocument.DocumentError.noValidDestination) {
                try document.moveHierarchy(at: document.items[0].id, to: document.items[1].id)
            }
        }

        @Test("Drag onto grandchild throws noValidDestination")
        func dragOntoGrandchild() {
            let document = createTaggedDocument()
            // Project A(0) → Subtask A1.1(2), a grandchild
            #expect(throws: TaskPaperDocument.DocumentError.noValidDestination) {
                try document.moveHierarchy(at: document.items[0].id, to: document.items[2].id)
            }
        }

        @Test("Drag onto last child in hierarchy throws noValidDestination")
        func dragOntoLastChild() {
            let document = createTaggedDocument()
            // Project A(0) → Task A2(3), the last direct child
            #expect(throws: TaskPaperDocument.DocumentError.noValidDestination) {
                try document.moveHierarchy(at: document.items[0].id, to: document.items[3].id)
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

    // MARK: - Indent Adjustment Tests

    @Suite("Drag Indent Adjustment")
    struct IndentAdjustmentTests {

        // Document used in these tests:
        //   0  Level0ProjectA:    indent 0  project
        //   1    Level1SubProjA:  indent 1  project
        //   2      - taskDeep     indent 2  task
        //   3    - taskA          indent 1  task
        //   4  Level0ProjectB:    indent 0  project
        //   5    Level1SubProjB:  indent 1  project
        //   6      - taskDeepB    indent 2  task
        //   7    - taskB          indent 1  task
        //   8  Level0ProjectC:    indent 0  project
        //   9    - taskC          indent 1  task
        private func makeDoc() -> TaskPaperDocument {
            let content = """
            Level0ProjectA:
            \tLevel1SubProjA:
            \t\t- taskDeep
            \t- taskA
            Level0ProjectB:
            \tLevel1SubProjB:
            \t\t- taskDeepB
            \t- taskB
            Level0ProjectC:
            \t- taskC
            """
            return TaskPaperDocument(content: content, fileName: "IndentTest")
        }

        // Flat document — three peer projects, no children:
        //   0  ProjectFlat1:  level 0
        //   1  ProjectFlat2:  level 0
        //   2  ProjectFlat3:  level 0
        private func makeFlatDoc() -> TaskPaperDocument {
            TaskPaperDocument(content: "ProjectFlat1:\nProjectFlat2:\nProjectFlat3:", fileName: "Flat")
        }

        private func index(of displayText: String, in doc: TaskPaperDocument) -> Int? {
            doc.items.firstIndex(where: { $0.displayText == displayText })
        }

        // MARK: Drag Up — Project, peer project as destination

        @Test("Project up: peer below, deep task above — peer rule prevents wrong indent")
        func projectUp_peerBelow_deepTaskAbove() throws {
            // ProjectC(8,L0) → before ProjectB(4,L0). Item above = taskA(3,L1).
            // Without peer rule aboveItem(task,L1) → targetIndent=1. Peer rule → L0.
            let doc = makeDoc()
            try doc.moveHierarchy(at: doc.items[8].id, to: doc.items[4].id)
            let idx = try #require(index(of: "Level0ProjectC", in: doc))
            #expect(doc.items[idx].indentLevel == 0)
            #expect(doc.items[idx + 1].indentLevel == 1)
        }

        @Test("Project up: peer below, peer project above (flat) — peer rule overrides project+1")
        func projectUp_peerBelow_peerProjectAbove() throws {
            // ProjectFlat3(2,L0) → before ProjectFlat2(1,L0). Above = ProjectFlat1(0,L0,project).
            // Without peer rule: project above → L0+1=1 (wrong). Peer rule → L0.
            let doc = makeFlatDoc()
            try doc.moveHierarchy(at: doc.items[2].id, to: doc.items[1].id)
            let idx = try #require(index(of: "ProjectFlat3", in: doc))
            #expect(doc.items[idx].indentLevel == 0)
        }

        @Test("Project up: peer below, no item above (drop at top) — stays level 0")
        func projectUp_peerBelow_noItemAbove() throws {
            // ProjectC(8,L0) → before Level0ProjectA(0). aboveIndex=nil → targetIndent=0.
            let doc = makeDoc()
            try doc.moveHierarchy(at: doc.items[8].id, to: doc.items[0].id)
            #expect(doc.items[0].displayText == "Level0ProjectC")
            #expect(doc.items[0].indentLevel == 0)
        }

        @Test("Project up: deeper sub-project below, project above — adopts child-of-parent level")
        func projectUp_deeperProjectBelow_projectAbove() throws {
            // ProjectC(8,L0) → before SubProjA(1,L1). Above = Level0ProjectA(0,L0,project).
            // Peer rule: L0≠L1 → no. aboveItem=project(L0) → targetIndent=L0+1=1.
            let doc = makeDoc()
            try doc.moveHierarchy(at: doc.items[8].id, to: doc.items[1].id)
            let idx = try #require(index(of: "Level0ProjectC", in: doc))
            #expect(doc.items[idx].indentLevel == 1)
            #expect(doc.items[idx + 1].indentLevel == 2)
        }

        @Test("Project up: shallower project below, task above — level stays with task context")
        func projectUp_shallowerProjectBelow_taskAbove() throws {
            // SubProjA(1,L1) → before Level0ProjectB(4,L0). Above = taskA(3,L1,task).
            // Peer rule: L1≠L0 → no. aboveItem=task(L1) → targetIndent=1.
            let doc = makeDoc()
            try doc.moveHierarchy(at: doc.items[1].id, to: doc.items[4].id)
            let idx = try #require(index(of: "Level1SubProjA", in: doc))
            #expect(doc.items[idx].indentLevel == 1)
        }

        @Test("Sub-project up: peer sub-project below, peer sub-project above — peer rule prevents over-indent")
        func subProjectUp_peerBelow_peerProjectAbove() throws {
            // SubC(3,L1) → before SubB(2,L1). Above=SubA(1,L1,project).
            // Without peer rule: project above → L1+1=L2 (wrong). Peer rule → L1.
            let content = """
            ParentProject:
            \tSubA:
            \tSubB:
            \tSubC:
            """
            let doc = TaskPaperDocument(content: content, fileName: "SubFlat")
            try doc.moveHierarchy(at: doc.items[3].id, to: doc.items[2].id)
            let idx = try #require(index(of: "SubC", in: doc))
            #expect(doc.items[idx].indentLevel == 1)
        }

        // MARK: Drag Down — Project, peer project as destination

        @Test("Project down: peer below, deep task above — peer rule prevents wrong indent")
        func projectDown_peerBelow_deepTaskAbove() throws {
            // ProjectA(0,L0) → before ProjectC(8,L0). moving={0..3}. Above = taskB(7,L1).
            // Without peer rule aboveItem(task,L1) → targetIndent=1. Peer rule → L0.
            let doc = makeDoc()
            try doc.moveHierarchy(at: doc.items[0].id, to: doc.items[8].id)
            let idx = try #require(index(of: "Level0ProjectA", in: doc))
            #expect(doc.items[idx].indentLevel == 0)
            #expect(doc.items[idx + 1].indentLevel == 1)
        }

        @Test("Project down: peer below, peer project above (flat) — peer rule overrides project+1")
        func projectDown_peerBelow_peerProjectAbove() throws {
            // ProjectFlat1(0,L0) → before ProjectFlat3(2,L0). Above = ProjectFlat2(1,L0,project).
            // Without peer rule: project above → L0+1=1. Peer rule → L0.
            let doc = makeFlatDoc()
            try doc.moveHierarchy(at: doc.items[0].id, to: doc.items[2].id)
            let idx = try #require(index(of: "ProjectFlat1", in: doc))
            #expect(doc.items[idx].indentLevel == 0)
        }

        @Test("Project down: deeper sub-project below, project above — adopts child-of-parent level")
        func projectDown_deeperProjectBelow_projectAbove() throws {
            // ProjectA(0,L0) → before SubProjB(5,L1). moving={0..3}. Above = Level0ProjectB(4,L0,project).
            // Peer rule: L0≠L1 → no. aboveItem=project(L0) → targetIndent=L0+1=1.
            let doc = makeDoc()
            try doc.moveHierarchy(at: doc.items[0].id, to: doc.items[5].id)
            let idx = try #require(index(of: "Level0ProjectA", in: doc))
            #expect(doc.items[idx].indentLevel == 1)
        }

        // MARK: Drag — Non-Project Items

        @Test("Task up: to top of list — becomes level 0")
        func taskUp_toTop() throws {
            // taskC(9,L1) → before Level0ProjectA(0). aboveIndex=nil → targetIndent=0.
            let doc = makeDoc()
            try doc.moveHierarchy(at: doc.items[9].id, to: doc.items[0].id)
            let idx = try #require(doc.items.firstIndex(where: { $0.displayText == "taskC" }))
            #expect(doc.items[idx].indentLevel == 0)
        }

        @Test("Task up: dropped right after project header — becomes direct child level")
        func taskUp_rightAfterProjectHeader() throws {
            // taskC(9,L1) → before SubProjA(1). Above = Level0ProjectA(0,project,L0) → targetIndent=1.
            let doc = makeDoc()
            try doc.moveHierarchy(at: doc.items[9].id, to: doc.items[1].id)
            let idx = try #require(doc.items.firstIndex(where: { $0.displayText == "taskC" }))
            #expect(doc.items[idx].indentLevel == 1)
        }

        @Test("Task: dragged between peer tasks at same level — level unchanged")
        func taskBetweenPeerTasks() throws {
            // task3(3,L1) → before task2(2,L1). Above = task1(1,L1,task) → targetIndent=1.
            let content = """
            Project:
            \t- task1
            \t- task2
            \t- task3
            """
            let doc = TaskPaperDocument(content: content, fileName: "PeerTasks")
            try doc.moveHierarchy(at: doc.items[3].id, to: doc.items[2].id)
            let idx = try #require(doc.items.firstIndex(where: { $0.displayText == "task3" }))
            #expect(doc.items[idx].indentLevel == 1)
        }

        // MARK: Hierarchy Integrity

        @Test("Children shift by same delta as parent when indent increases")
        func childrenShiftWithParent() throws {
            // ProjectC(8,L0)+taskC(9,L1) → before SubProjA(1,L1). ProjectC→L1, taskC→L2.
            let doc = makeDoc()
            let taskCId = doc.items[9].id
            try doc.moveHierarchy(at: doc.items[8].id, to: doc.items[1].id)
            let idx = try #require(doc.items.firstIndex(where: { $0.id == taskCId }))
            #expect(doc.items[idx].indentLevel == 2)
        }

        @Test("Children preserve relative indent when peer rule produces no delta")
        func childrenPreserveRelativeIndent() throws {
            // SubProjA(1,L1)+taskDeep(2,L2) → before SubProjB(5,L1). Peer rule → no delta. taskDeep stays L2.
            let doc = makeDoc()
            let taskDeepId = doc.items[2].id
            try doc.moveHierarchy(at: doc.items[1].id, to: doc.items[5].id)
            let idx = try #require(doc.items.firstIndex(where: { $0.id == taskDeepId }))
            #expect(doc.items[idx].indentLevel == 2)
        }
    }
}
