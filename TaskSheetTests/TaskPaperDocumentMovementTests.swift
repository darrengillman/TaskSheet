import XCTest
@testable import TaskSheet

final class TaskPaperDocumentMovementTests: XCTestCase {

    // MARK: - Test Data Setup

    /// Creates a document with hierarchical structure for testing
    /// Structure:
    /// Project A:                  (0, indent: 0)
    ///   - Task A1                 (1, indent: 1)
    ///     - Subtask A1.1          (2, indent: 2)
    ///     - Subtask A1.2          (3, indent: 2)
    ///   - Task A2                 (4, indent: 1)
    /// Project B:                  (5, indent: 0)
    ///   - Task B1                 (6, indent: 1)
    ///   - Task B2                 (7, indent: 1)
    ///     - Subtask B2.1          (8, indent: 2)
    /// Project C:                  (9, indent: 0)
    ///   - Task C1                 (10, indent: 1)
    private func createHierarchicalDocument() -> TaskPaperDocument {
        let content = """
        Project A:
        \t- Task A1
        \t\t- Subtask A1.1
        \t\t- Subtask A1.2
        \t- Task A2
        Project B:
        \t- Task B1
        \t- Task B2
        \t\t- Subtask B2.1
        Project C:
        \t- Task C1
        """
        return TaskPaperDocument(content: content, fileName: "Test")
    }

    /// Creates a simple flat document for basic testing
    /// Structure:
    /// - Task 1                    (0, indent: 0)
    /// - Task 2                    (1, indent: 0)
    /// - Task 3                    (2, indent: 0)
    /// - Task 4                    (3, indent: 0)
    private func createFlatDocument() -> TaskPaperDocument {
        let content = """
        - Task 1
        - Task 2
        - Task 3
        - Task 4
        """
        return TaskPaperDocument(content: content, fileName: "Test")
    }

    // MARK: - Move Up Tests

    func testMoveUpDestination_SingleItemSameIndentation() {
        let document = createFlatDocument()
        let itemToMove = document.items[2] // Task 3

        let destination = document.moveUpDestination(for: itemToMove)

        XCTAssertNotNil(destination, "Should find a destination for moving up")
        XCTAssertEqual(destination?.moving, IndexSet(integer: 2), "Should move item at index 2")
        XCTAssertEqual(destination?.insertAt, 1, "Should move after index 1 (between Task 1 and Task 2)")
    }

    func testMoveUpDestination_FirstItemCannotMoveUp() {
        let document = createFlatDocument()
        let itemToMove = document.items[0] // Task 1 (first item)

        let destination = document.moveUpDestination(for: itemToMove)

        XCTAssertNotNil(destination, "Should find a destination (move to start)")
        XCTAssertEqual(destination?.moving, IndexSet(integer: 0), "Should move item at index 0")
        XCTAssertEqual(destination?.insertAt, 0, "Should move to start of list")
    }

    func testMoveUpDestination_ItemAboveHasMultipleChildren() {
        let document = createHierarchicalDocument()
        let itemToMove = document.items[4] // Task A2

        let destination = document.moveUpDestination(for: itemToMove)

        XCTAssertNotNil(destination, "Should find a destination for moving up")
        XCTAssertEqual(destination?.moving, IndexSet(integer: 4), "Should move Task A2")
        XCTAssertEqual(destination?.insertAt, 1, "Should move after Project A (before its children)")
    }

    func testMoveUpDestination_ItemHasMultipleChildren() {
        let document = createHierarchicalDocument()
        let itemToMove = document.items[1] // Task A1 (has 2 children: Subtask A1.1, A1.2)

        let destination = document.moveUpDestination(for: itemToMove)

        XCTAssertNotNil(destination, "Should find a destination for moving up")
        XCTAssertEqual(destination?.moving, IndexSet(1...3), "Should move Task A1 and its children (indices 1-3)")
        XCTAssertEqual(destination?.insertAt, 0, "Should move after Project A")
    }

    func testMoveUpDestination_BothItemsHaveMultipleChildren() {
        let document = createHierarchicalDocument()
       print(document.content)
        let itemToMove = document.items[7] // Task B2 (has 1 child)
       print("---",itemToMove.text,"---")

        let destination = document.moveUpDestination(for: itemToMove)

        XCTAssertNotNil(destination, "Should find a destination for moving up")
        XCTAssertEqual(destination?.moving, IndexSet(7...8), "Should move Task B2 and its child")
        XCTAssertEqual(destination?.insertAt, 6, "Should move after Project B")
       print(document.content)
    }

    func testMoveUpDestination_MoveToTop() {
        let document = createHierarchicalDocument()
        let itemToMove = document.items[0] // Project A (first item)

        let destination = document.moveUpDestination(for: itemToMove)

        XCTAssertNotNil(destination, "Should find a destination")
       XCTAssertEqual(destination?.moving, IndexSet(0...4), "Should move Project A")
        XCTAssertEqual(destination?.insertAt, 0, "Should move to start")
    }

    // MARK: - Move Down Tests

    func testMoveDownDestination_SingleItemSameIndentation() {
        let document = createFlatDocument()
        let itemToMove = document.items[1] // Task 2

        let destination = document.moveDownDestination(for: itemToMove)

        XCTAssertNotNil(destination, "Should find a destination for moving down")
        XCTAssertEqual(destination?.moving, IndexSet(integer: 1), "Should move item at index 1")
        XCTAssertEqual(destination?.after, 2, "Should move after Task 3")
    }

    func testMoveDownDestination_LastItemCannotMoveDown() {
        let document = createFlatDocument()
        let itemToMove = document.items[3] // Task 4 (last item)

        let destination = document.moveDownDestination(for: itemToMove)

        XCTAssertNil(destination, "Last item should not be able to move down")
    }

    func testMoveDownDestination_ItemBelowHasMultipleChildren() {
        let document = createHierarchicalDocument()
        let itemToMove = document.items[0] // Project A

        let destination = document.moveDownDestination(for: itemToMove)

        XCTAssertNotNil(destination, "Should find a destination for moving down")
        XCTAssertEqual(destination?.moving, IndexSet(0...4), "Should move Project A and all its children")
        XCTAssertEqual(destination?.after, 8, "Should move after Project B and its children")
    }

    func testMoveDownDestination_ItemHasMultipleChildren() {
        let document = createHierarchicalDocument()
        let itemToMove = document.items[1] // Task A1 (has 2 children)

        let destination = document.moveDownDestination(for: itemToMove)

        XCTAssertNotNil(destination, "Should find a destination for moving down")
        XCTAssertEqual(destination?.moving, IndexSet(1...3), "Should move Task A1 and its children")
        XCTAssertEqual(destination?.after, 4, "Should move after Task A2")
    }

    func testMoveDownDestination_BothItemsHaveMultipleChildren() {
        let document = createHierarchicalDocument()
        let itemToMove = document.items[6] // Task B1

        let destination = document.moveDownDestination(for: itemToMove)

        XCTAssertNotNil(destination, "Should find a destination for moving down")
        XCTAssertEqual(destination?.moving, IndexSet(integer: 6), "Should move Task B1")
        XCTAssertEqual(destination?.after, 8, "Should move after Task B2 and its child")
    }

    func testMoveDownDestination_MoveToBottom() {
        let document = createHierarchicalDocument()
        let itemToMove = document.items[9] // Project C

        let destination = document.moveDownDestination(for: itemToMove)

        XCTAssertNil(destination, "Last item should not be able to move down")
    }

    // MARK: - Edge Cases

    func testMoveUpDestination_EmptyDocument() {
        let document = TaskPaperDocument(content: "", fileName: "Empty")
        let item = TaskPaperItem(type: .task, text: "- Nonexistent", lineNumber: 1)

        let destination = document.moveUpDestination(for: item)

        XCTAssertNil(destination, "Should return nil for item not in document")
    }

    func testMoveDownDestination_EmptyDocument() {
        let document = TaskPaperDocument(content: "", fileName: "Empty")
        let item = TaskPaperItem(type: .task, text: "- Nonexistent", lineNumber: 1)

        let destination = document.moveDownDestination(for: item)

        XCTAssertNil(destination, "Should return nil for item not in document")
    }

    func testMoveUpDestination_SingleItem() {
        let document = TaskPaperDocument(content: "- Single Task", fileName: "Single")
        let itemToMove = document.items[0]

        let destination = document.moveUpDestination(for: itemToMove)

        XCTAssertNotNil(destination, "Should find a destination")
        XCTAssertEqual(destination?.moving, IndexSet(integer: 0), "Should move the only item")
        XCTAssertEqual(destination?.insertAt, 0, "Should move to start")
    }

    func testMoveDownDestination_SingleItem() {
        let document = TaskPaperDocument(content: "- Single Task", fileName: "Single")
        let itemToMove = document.items[0]

        let destination = document.moveDownDestination(for: itemToMove)

        XCTAssertNil(destination, "Single item should not be able to move down")
    }

    // MARK: - Complex Hierarchy Tests

    func testMoveUpDestination_DeeplyNestedItem() {
        let content = """
        Project:
        \t- Task 1
        \t\t- Subtask 1.1
        \t\t\t- Sub-subtask 1.1.1
        \t\t- Subtask 1.2
        \t- Task 2
        """
        let document = TaskPaperDocument(content: content, fileName: "Deep")
        let itemToMove = document.items[3] // Sub-subtask 1.1.1 (indent level 3)

        let destination = document.moveUpDestination(for: itemToMove)

        XCTAssertNotNil(destination, "Should find a destination for deeply nested item")
        XCTAssertEqual(destination?.moving, IndexSet(integer: 3), "Should move the nested item")
    }

    func testMoveDownDestination_ComplexHierarchy() {
        let content = """
        Project A:
        \t- Task A1
        \t\t- Subtask A1.1
        \t- Task A2
        \t\t- Subtask A2.1
        \t\t- Subtask A2.2
        Project B:
        \t- Task B1
        """
        let document = TaskPaperDocument(content: content, fileName: "Complex")
        let itemToMove = document.items[1] // Task A1

        let destination = document.moveDownDestination(for: itemToMove)

        XCTAssertNotNil(destination, "Should find a destination in complex hierarchy")
        XCTAssertEqual(destination?.moving, IndexSet(1...2), "Should move Task A1 and its child")
    }

    // MARK: - Integration Tests with Actual Move Operations

    func testActualMoveUp_IntegrationTest() {
        let document = createFlatDocument()
        let originalOrder = document.items.map { $0.displayText }
        let itemToMove = document.items[2] // Task 3

        document.moveUp(itemToMove)

        let newOrder = document.items.map { $0.displayText }
        XCTAssertEqual(newOrder, ["Task 1", "Task 3", "Task 2", "Task 4"],
                      "Task 3 should move between Task 1 and Task 2")
        XCTAssertNotEqual(originalOrder, newOrder, "Order should have changed")
    }

    func testActualMoveDown_IntegrationTest() {
        let document = createFlatDocument()
        let originalOrder = document.items.map { $0.displayText }
        let itemToMove = document.items[1] // Task 2

        document.moveDown(itemToMove)

        let newOrder = document.items.map { $0.displayText }
        XCTAssertEqual(newOrder, ["Task 1", "Task 3", "Task 2", "Task 4"],
                      "Task 2 should move between Task 3 and Task 4")
        XCTAssertNotEqual(originalOrder, newOrder, "Order should have changed")
    }

    func testMoveUpWithChildren_IntegrationTest() {
        let document = createHierarchicalDocument()
        let itemToMove = document.items[1] // Task A1 (with children)
        let originalCount = document.items.count

        document.moveUp(itemToMove)

        XCTAssertEqual(document.items.count, originalCount, "Item count should remain the same")
        // Task A1 and its children should move up past Project A
        XCTAssertEqual(document.items[0].displayText, "Task A1", "Task A1 should be first")
        XCTAssertEqual(document.items[1].displayText, "Subtask A1.1", "Children should follow")
        XCTAssertEqual(document.items[2].displayText, "Subtask A1.2", "Children should follow")
    }

    func testMoveDownWithChildren_IntegrationTest() {
        let document = createHierarchicalDocument()
        let itemToMove = document.items[6] // Task B1
        let originalItemB1Index = 6

        document.moveDown(itemToMove)

        // Task B1 should move past Task B2 and its child
        let newItemB1Index = document.items.firstIndex { $0.displayText == "Task B1" }
        XCTAssertNotNil(newItemB1Index, "Task B1 should still exist")
        XCTAssertGreaterThan(newItemB1Index!, originalItemB1Index, "Task B1 should move to a later position")
    }
}
