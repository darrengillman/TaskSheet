import XCTest
@testable import TaskSheet

final class TaskSheetTagTests: XCTestCase {

    func testTagParsing() {
        // Test various tag formats
        let testCases = [
            ("- Task with simple tag @next", [Tag(name: "next", value: nil)]),
            ("- Task with value tag @done(2025-06-23)", [Tag(name: "done", value: "2025-06-23")]),
            ("- Multiple tags @next @urgent @due(today)", [
                Tag(name: "next", value: nil),
                Tag(name: "urgent", value: nil),
                Tag(name: "due", value: "today")
            ]),
            ("- Complex value @project(SwiftUI App Development)", [Tag(name: "project", value: "SwiftUI App Development")]),
            ("- Task with BUG tag @BUG", [Tag(name: "BUG", value: nil)]),
            ("- No tags here", [])
        ]

        for (input, expectedTags) in testCases {
            let items = TaskPaperParser.parse(input)
            XCTAssertEqual(items.count, 1, "Should parse one item for: \(input)")

            let item = items[0]
            XCTAssertEqual(item.tags.count, expectedTags.count, "Tag count mismatch for: \(input)")

            for (index, expectedTag) in expectedTags.enumerated() {
                XCTAssertEqual(item.tags[index].name, expectedTag.name, "Tag name mismatch at index \(index) for: \(input)")
                XCTAssertEqual(item.tags[index].value, expectedTag.value, "Tag value mismatch at index \(index) for: \(input)")
            }
        }
    }

    func testCompletionDetection() {
        let testCases = [
            ("- Completed task @done", true),
            ("- Completed with date @done(2025-06-23)", true),
            ("- Multiple tags @next @done @urgent", true),
            ("- Not completed @next", false),
            ("- Case sensitive @DONE", false),
            ("- Case sensitive @Done", false),
            ("- Finished but not done @finished", false),
            ("- No tags", false)
        ]

        for (input, expectedCompleted) in testCases {
            let items = TaskPaperParser.parse(input)
            XCTAssertEqual(items.count, 1, "Should parse one item for: \(input)")

            let item = items[0]
            XCTAssertEqual(item.isCompleted, expectedCompleted, "Completion detection failed for: \(input)")
        }
    }

    func testDisplayTextTagRemoval() {
        let testCases = [
            ("- Simple task @done", "Simple task"),
            ("- Task with date @done(2025-06-23)", "Task with date"),
            ("- Multiple tags @next @urgent @due(today)", "Multiple tags"),
            ("System:", "System"),
            ("Just a note with @tag", "Just a note with"),
            ("- No tags here", "No tags here")
        ]

        for (input, expectedDisplayText) in testCases {
            let items = TaskPaperParser.parse(input)
            XCTAssertEqual(items.count, 1, "Should parse one item for: \(input)")

            let item = items[0]
            XCTAssertEqual(item.displayText, expectedDisplayText, "Display text mismatch for: \(input)")
        }
    }

    func testItemTypeDetection() {
        let testCases = [
            ("Project Name:", ItemType.project),
            ("- Task item @done", ItemType.task),
            ("Just a note", ItemType.note),
            ("\t- Indented task", ItemType.task),
            ("\tIndented note @tag", ItemType.note)
        ]

        for (input, expectedType) in testCases {
            let items = TaskPaperParser.parse(input)
            XCTAssertEqual(items.count, 1, "Should parse one item for: \(input)")

            let item = items[0]
            XCTAssertEqual(item.type, expectedType, "Type detection failed for: \(input)")
        }
    }

    func testProjectWithTrailingTags() {
        // Test that projects with trailing tags are correctly identified as projects
        let testCases = [
            ("MyProject:", ItemType.project, "MyProject"),
            ("MyProject: @next", ItemType.project, "MyProject"),
            ("Work Project: @urgent @active", ItemType.project, "Work Project"),
            ("Archive: @done(2025-12-31)", ItemType.project, "Archive"),
            ("\tSubproject: @next", ItemType.project, "Subproject"),
            ("\t\tDeep Project: @tag1 @tag2(value)", ItemType.project, "Deep Project")
        ]

        for (input, expectedType, expectedDisplayText) in testCases {
            let items = TaskPaperParser.parse(input)
            XCTAssertEqual(items.count, 1, "Should parse one item for: \(input)")

            let item = items[0]
            XCTAssertEqual(item.type, expectedType, "Type detection failed for: \(input)")
            XCTAssertEqual(item.displayText, expectedDisplayText, "Display text mismatch for: \(input)")
            
            // Verify tags are still present in the raw text
            XCTAssertTrue(item.text.contains(":"), "Project should retain colon in text: \(input)")
            if input.contains("@") {
                XCTAssertTrue(item.tags.count > 0, "Tags should be preserved for: \(input)")
            }
        }
    }

    func testIndentationLevel() {
        let testCases = [
            ("Top level", 0),
            ("\tOne level", 1),
            ("\t\tTwo levels", 2),
            ("\t\t\tThree levels", 3)
        ]

        for (input, expectedLevel) in testCases {
            let items = TaskPaperParser.parse(input)
            XCTAssertEqual(items.count, 1, "Should parse one item for: \(input)")

            let item = items[0]
            XCTAssertEqual(item.indentLevel, expectedLevel, "Indentation level mismatch for: \(input)")
        }
    }

    func testComplexScenarios() {
        let input = """
        System:
        \t- add entry for items on ignore list @next @done(2025-06-23)
        \t- importing Boxes multiple times @next @BUG @done(2025-07-23)
        \t\tThis is a note about the bug

        Packing Screen:
        \t- fix layout bug @next @BUG
        \t- add split navigation @done
        """

        let items = TaskPaperParser.parse(input)

        // Should parse 7 items (excluding empty lines)
        XCTAssertEqual(items.count, 7, "Should parse 7 non-empty items")

        // Check first item is project
        XCTAssertEqual(items[0].type, .project)
        XCTAssertEqual(items[0].displayText, "System")
        XCTAssertEqual(items[0].indentLevel, 0)

        // Check completed task with multiple tags
        XCTAssertEqual(items[1].type, .task)
        XCTAssertEqual(items[1].isCompleted, true)
        XCTAssertEqual(items[1].tags.count, 2)  // @next @done(2025-06-23)
        XCTAssertEqual(items[1].indentLevel, 1)

        // Check note item
        XCTAssertEqual(items[3].type, .note)
        XCTAssertEqual(items[3].indentLevel, 2)

        // Check incomplete task with BUG tag
        XCTAssertEqual(items[5].type, .task)
        XCTAssertEqual(items[5].isCompleted, false)
        XCTAssertTrue(items[5].tags.contains { $0.name == "next" })
        XCTAssertTrue(items[5].tags.contains { $0.name == "BUG" })

        // Check completed task without date
        XCTAssertEqual(items[6].type, .task)
        XCTAssertEqual(items[6].isCompleted, true)
        XCTAssertEqual(items[6].tags.count, 1)
        XCTAssertEqual(items[6].tags[0].name, "done")
        XCTAssertNil(items[6].tags[0].value)
    }

    // MARK: - Task Completion Tests

    func testToggleTaskCompletion() {
        let testContent = """
        Project:
        \t- Incomplete task @next
        \t- Already completed @done(2025-06-23)
        \tJust a note
        """

        let document = TaskPaperDocument(content: testContent, fileName: "Test")
        let initialItems = document.items

        // Find the incomplete task
        let incompleteTask = initialItems.first { $0.type == .task && !$0.isCompleted }!
        XCTAssertFalse(incompleteTask.isCompleted, "Task should start incomplete")

        // Toggle to complete
        document.toggleTaskCompletion(item: incompleteTask)

        // Verify task is now completed with today's date
        let updatedIncompleteTask = document.items.first { $0.id == incompleteTask.id }!
        XCTAssertTrue(updatedIncompleteTask.isCompleted, "Task should now be completed")
        XCTAssertTrue(updatedIncompleteTask.tags.contains { $0.name == "done" }, "Should have @done tag")

        // Find the already completed task
        let completedTask = initialItems.first { $0.type == .task && $0.isCompleted }!
        XCTAssertTrue(completedTask.isCompleted, "Task should start completed")

        // Toggle to incomplete
        document.toggleTaskCompletion(item: completedTask)

        // Verify task is now incomplete
        let updatedCompletedTask = document.items.first { $0.id == completedTask.id }!
        XCTAssertFalse(updatedCompletedTask.isCompleted, "Task should now be incomplete")
        XCTAssertFalse(updatedCompletedTask.tags.contains { $0.name == "done" }, "Should not have @done tag")
    }


 

    func testCompletionPreservesIndentation() {
        let testContent = """
        Project:
        \t- Level 1 task
        \t\t- Level 2 task
        \t\t\t- Level 3 task
        """

        let document = TaskPaperDocument(content: testContent, fileName: "Test")

        // Complete all tasks
        for item in document.items where item.type == .task {
            document.toggleTaskCompletion(item: item)
        }

        // Verify indentation is preserved
        let lines = document.content.components(separatedBy: .newlines)
        XCTAssertTrue(lines[1].hasPrefix("\t-"), "Level 1 task should maintain 1 tab")
        XCTAssertTrue(lines[2].hasPrefix("\t\t-"), "Level 2 task should maintain 2 tabs")
        XCTAssertTrue(lines[3].hasPrefix("\t\t\t-"), "Level 3 task should maintain 3 tabs")

        // Verify all are completed
        for item in document.items where item.type == .task {
            XCTAssertTrue(item.isCompleted, "All tasks should be completed")
        }
    }

    func testCompletionWithExistingDoneTags() {
        let testContent = "- Task already @done(2024-01-01) with date"

        let document = TaskPaperDocument(content: testContent, fileName: "Test")
        let task = document.items.first { $0.type == .task }!

        XCTAssertTrue(task.isCompleted, "Task should start completed")

        // Toggle to add new completion (should replace old tag)
        document.toggleTaskCompletion(item: task) // Remove
        document.toggleTaskCompletion(item: task) // Add new

        let updatedTask = document.items.first { $0.type == .task }!
        XCTAssertTrue(updatedTask.isCompleted, "Task should be completed")

        // Should only have one @done tag with today's date
        let doneTags = updatedTask.tags.filter { $0.name == "done" }
        XCTAssertEqual(doneTags.count, 1, "Should only have one @done tag")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        XCTAssertEqual(doneTags.first?.value, today, "Should have today's date")
    }

    // MARK: - Tag Insertion Position Tests

    func testTagInsertionAtSpecificIndex() {
        var item = TaskPaperItem(type: .task, text: "- Buy groceries", indentLevel: 0)

        // Insert tag at index 5 (after "- Buy")
        let insertIndex = item.text.index(item.text.startIndex, offsetBy: 5)
        item.addTag(Tag(name: "urgent"), at: .at(insertIndex))

        XCTAssertEqual(item.text, "- Buy @urgent groceries", "Tag should be inserted at specific index")
    }

    func testTagInsertionAfterSpecificIndex() {
        var item = TaskPaperItem(type: .task, text: "- Buy groceries", indentLevel: 0)

        // Insert tag after index 4 (after "- Bu")
        let afterIndex = item.text.index(item.text.startIndex, offsetBy: 4)
        item.addTag(Tag(name: "urgent"), at: .after(afterIndex))

        XCTAssertEqual(item.text, "- Buy @urgent groceries", "Tag should be inserted after specific index")
    }

    func testTagInsertionAfterTextWithManualIndex() {
        var item = TaskPaperItem(type: .task, text: "- Buy buy groceries", indentLevel: 0)

        // Insert after first occurrence of "buy" using manual index calculation
        if let range = item.text.range(of: "buy") {
            item.addTag(Tag(name: "urgent"), at: .after(range.upperBound))
            XCTAssertEqual(item.text, "- Buy buy @urgent groceries", "Tag should be inserted after first occurrence")
        } else {
            XCTFail("Should find first occurrence of 'buy'")
        }

        // Reset and test second occurrence
        item = TaskPaperItem(type: .task, text: "- buy buy groceries", indentLevel: 0)
        if let firstRange = item.text.range(of: "buy"),
           let secondRange = item.text.range(of: "buy", range: firstRange.upperBound..<item.text.endIndex) {
            item.addTag(Tag(name: "urgent"), at: .after(secondRange.upperBound))
            XCTAssertEqual(item.text, "- buy buy @urgent groceries", "Tag should be inserted after second occurrence")
        } else {
            XCTFail("Should find second occurrence of 'buy'")
        }
    }

    func testTagInsertionAfterTextCaseSensitive() {
        var item = TaskPaperItem(type: .task, text: "- Buy buy groceries", indentLevel: 0)

        // Insert after "Buy" (capital B) using manual index calculation
        if let range = item.text.range(of: "Buy") {
            item.addTag(Tag(name: "urgent"), at: .after(range.upperBound))
            XCTAssertEqual(item.text, "- Buy @urgent buy groceries", "Tag should be inserted after exact case match")
        } else {
            XCTFail("Should find 'Buy' with capital B")
        }
    }

    func testTagInsertionFallbackToEnd() {
        var item = TaskPaperItem(type: .task, text: "- Buy groceries", indentLevel: 0)

        // Test invalid index fallback (manually create an invalid index)
       let invalidIndex = (item.text + "****").endIndex
        item.addTag(Tag(name: "urgent"), at: .at(invalidIndex))
        XCTAssertEqual(item.text, "- Buy groceries @urgent", "Should fallback to end for invalid index")

        // Reset and test adding tag at end (simplified test since .afterText was removed)
        item = TaskPaperItem(type: .task, text: "- Buy groceries", indentLevel: 0)
        item.addTag(Tag(name: "urgent"), at: .end)
        XCTAssertEqual(item.text, "- Buy groceries @urgent", "Should add tag at end")
    }

    func testComplexTagInsertionScenario() {
        var item = TaskPaperItem(type: .task, text: "- review review document", indentLevel: 0)

        // Insert after second occurrence of "review" using manual index calculation
        if let firstRange = item.text.range(of: "review"),
           let secondRange = item.text.range(of: "review", range: firstRange.upperBound..<item.text.endIndex) {
            item.addTag(Tag(name: "today"), at: .after(secondRange.upperBound))
           XCTAssertEqual(item.text, "- review review @today document", "Should handle multiple occurrences correctly")

            // Add another tag at the beginning
            item.addTag(Tag(name: "urgent"), at: .beginning)
            XCTAssertEqual(item.text, "- @urgent review review @today document", "Should maintain both tags")
        } else {
            XCTFail("Should find both occurrences of 'review' in \(item.text)")
        }
    }

    func testTagInsertionWithExistingTags() {
        var item = TaskPaperItem(type: .task, text: "- Buy groceries @next", indentLevel: 0)

        // Insert tag before existing tag
        let nextTagIndex = item.text.range(of: "@next")!.lowerBound
        item.addTag(Tag(name: "urgent"), at: .at(nextTagIndex))

        XCTAssertEqual(item.text, "- Buy groceries @urgent @next", "Should insert before existing tag")
    }

    // MARK: - DisplayText Comprehensive Tests

    func testDisplayTextForProjects() {
        let testCases: [(input: String, expected: String, description: String)] = [
            // Standard projects with ":" suffix
            ("Simple Project:", "Simple Project", "Simple project with colon"),
            ("Project With Spaces:", "Project With Spaces", "Project with spaces and colon"),
            ("Project: @tag1", "Project", "Project with trailing tag"),
            ("Project With Spaces: @tag1", "Project With Spaces", "Project with spaces and trailing tag"),
            ("Project: @tag1(value)", "Project", "Project with trailing tag with value"),
            ("Project With Spaces: @tag1(value)", "Project With Spaces", "Project with spaces and trailing tag with value"),
            ("Project @embedded Text: @tag1", "Project Text", "Project with embedded tag and trailing tag"),
            ("Start @tag1 Middle @tag2 End:", "Start Middle End", "Project with multiple embedded tags"),
            
            // Projects without ":" suffix (auto-added by initializer)
            ("Project Without Colon", "Project Without Colon", "Project without colon"),
            ("Project Without Colon @tag1", "Project Without Colon", "Project without colon with trailing tag"),
            ("Project @embedded Text", "Project Text", "Project with embedded tag, no colon"),
            ("Project @tag1 Without @tag2 Colon", "Project Without Colon", "Project with multiple embedded tags, no colon")
        ]

        for (input, expected, description) in testCases {
            let item = TaskPaperItem(type: .project, text: input, indentLevel: 0)
            XCTAssertEqual(item.displayText, expected, "Failed: \(description) - input: '\(input)'")
        }
    }

    func testDisplayTextForTasks() {
        let testCases: [(input: String, expected: String, description: String)] = [
            // Standard tasks with "- " prefix
            ("- Simple Task", "Simple Task", "Simple task with prefix"),
            ("- Task With Spaces", "Task With Spaces", "Task with spaces and prefix"),
            ("- Task @tag1", "Task", "Task with trailing tag"),
            ("- Task With Spaces @tag1", "Task With Spaces", "Task with spaces and trailing tag"),
            ("- Task @tag1(value)", "Task", "Task with trailing tag with value"),
            ("- Task With Spaces @tag1(value)", "Task With Spaces", "Task with spaces and trailing tag with value"),
            ("- Task @embedded Text @tag1", "Task Text", "Task with embedded tag and trailing tag"),
            ("- Start @tag1 Middle @tag2 End", "Start Middle End", "Task with multiple embedded tags"),
            
            // Tasks without "- " prefix (auto-added by initializer)
            ("Task Without Prefix", "Task Without Prefix", "Task without prefix"),
            ("Task Without Prefix @tag1", "Task Without Prefix", "Task without prefix with trailing tag"),
            ("Task @embedded Text", "Task Text", "Task with embedded tag, no prefix"),
            ("Task @tag1 Without @tag2 Prefix", "Task Without Prefix", "Task with multiple embedded tags, no prefix")
        ]

        for (input, expected, description) in testCases {
            let item = TaskPaperItem(type: .task, text: input, indentLevel: 0)
            XCTAssertEqual(item.displayText, expected, "Failed: \(description) - input: '\(input)'")
        }
    }

    func testDisplayTextForNotes() {
        let testCases: [(input: String, expected: String, description: String)] = [
            // Notes (no prefix/suffix)
            ("Simple Note", "Simple Note", "Simple note"),
            ("Note With Spaces", "Note With Spaces", "Note with spaces"),
            ("Note @tag1", "Note", "Note with trailing tag"),
            ("Note With Spaces @tag1", "Note With Spaces", "Note with spaces and trailing tag"),
            ("Note @tag1(value)", "Note", "Note with trailing tag with value"),
            ("Note With Spaces @tag1(value)", "Note With Spaces", "Note with spaces and trailing tag with value"),
            ("Note @embedded Text @tag1", "Note Text", "Note with embedded tag and trailing tag"),
            ("Start @tag1 Middle @tag2 End", "Start Middle End", "Note with multiple embedded tags")
        ]

        for (input, expected, description) in testCases {
            let item = TaskPaperItem(type: .note, text: input, indentLevel: 0)
            XCTAssertEqual(item.displayText, expected, "Failed: \(description) - input: '\(input)'")
        }
    }

    func testDisplayTextEdgeCasesWithNonTagAtSymbols() {
        let testCases: [(type: ItemType, input: String, expected: String, description: String)] = [
            // Edge cases: @ characters without leading spaces are NOT tags
            (.note, "email@example.com is not a tag", "email@example.com is not a tag", "Email address preserved in note"),
            (.task, "- Task with email@example.com @done", "Task with email@example.com", "Email preserved, valid tag removed in task"),
            (.project, "Project: with@embedded@characters @tag1", "Project: with@embedded@characters", "@ without spaces preserved in project"),
            (.note, "Text@NoSpace but @valid tag", "Text@NoSpace but tag", "Only space-prefixed tag removed")
        ]

        for (type, input, expected, description) in testCases {
            let item = TaskPaperItem(type: type, text: input, indentLevel: 0)
            XCTAssertEqual(item.displayText, expected, "Failed: \(description) - input: '\(input)'")
        }
    }
}
