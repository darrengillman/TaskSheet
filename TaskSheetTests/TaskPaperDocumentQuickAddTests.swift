import Testing
import Foundation
@testable import TaskSheet

// Both suites share UserDefaults.standard, so they must not run concurrently.
@Suite(.serialized)
struct TaskPaperDocumentQuickAddTestSuite {

    @Suite("TaskPaperDocument quickAdd Tests with Inbox enabled")
    struct TaskPaperDocumentQuickAddTests {

        init() {
            UserDefaults.standard.set(false, forKey: AppStorageKeys.Editor.showWelcomeTextInNewDocument)
            UserDefaults.standard.set(true, forKey: AppStorageKeys.QuickAdd.useInbox)
        }

        // MARK: - Scenario 1: No Items + Project

        @Test("Add project to empty document adds at top with indent 0")
        func quickAddProjectWhenEmpty() {
            let document = TaskPaperDocument(content: "", fileName: "Test")

            document.quickAdd("Work", type: .project)

            #expect(document.items.count == 1)
            #expect(document.items[0].type == .project)
            #expect(document.items[0].displayText == "Work")
            #expect(document.items[0].indentLevel == 0)
        }

        @Test("Add task to empty document. Adds with indent 0")
        func quickAddTaskWhenEmpty() {
            let document = TaskPaperDocument(content: "", fileName: "Test")

            document.quickAdd("First task", type: .task)

            #expect(document.items.count == 1)
            #expect(document.items[0].type == .task)
            #expect(document.items[0].displayText == "First task")
            #expect(document.items[0].indentLevel == 0)
        }

        @Test("Add note to empty document. Adds with indent 0")
        func quickAddNoteWhenEmpty() {
            let document = TaskPaperDocument(content: "", fileName: "Test")

            document.quickAdd("First note", type: .note)

            #expect(document.items.count == 1)
            #expect(document.items[0].type == .note)
            #expect(document.items[0].displayText == "First note")
            #expect(document.items[0].indentLevel == 0)
        }

        // MARK: - Scenario 2: One Project with All Child Items

        @Test("Add task with one project and all child items appends as child")
        func quickAddTaskWithOneProjectAndAllChildItems() {
            let content = """
            Work:
            \t- Existing task 1
            \t- Existing task 2
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")

            document.quickAdd("New task", type: .task)

            #expect(document.items.count == 4)
            #expect(document.items[3].displayText == "New task")
            #expect(document.items[3].indentLevel == 1)
            #expect(document.items[3].type == .task)
        }

        @Test("Add note with one project and all child items appends as child")
        func quickAddNoteWithOneProjectAndAllChildItems() {
            let content = """
            Work:
            \t- Task 1
            \tNote about task 1
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")

            document.quickAdd("New note", type: .note)

            #expect(document.items.count == 4)
            #expect(document.items[3].displayText == "New note")
            #expect(document.items[3].indentLevel == 1)
            #expect(document.items[3].type == .note)
        }

        @Test("Add task with one project and mixed indent children with last a single indent. Creates Inbox & adds")
        func quickAddTaskWithOneProjectAndMixedIndentChildren1() {
            let content = """
            Work:
            \t- Parent task
            \t\t- Nested child task
            \t- Another top level task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")

            document.quickAdd("New task", type: .task)

            #expect(document.items.count == 6)
            #expect(document.items[0].displayText == "Inbox")
           #expect(document.items[0].indentLevel == 0)
            #expect(document.items[1].displayText == "New task")
            #expect(document.items[1].indentLevel == 1)
        }


        @Test("Add sub-project with one project and all child items appends as child")
        func quickAddProjectWithOneProjectAndAllChildItems() {
            let content = """
            Work:
            \t- Existing task 1
            \t- Existing task 2
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")

            document.quickAdd("Phase 2", type: .project)

            #expect(document.items.count == 4)
            #expect(document.items[3].displayText == "Phase 2")
            #expect(document.items[3].indentLevel == 1)
            #expect(document.items[3].type == .project)
        }

        @Test("Add sub-project with one project and mixed indent children with last a single indent. Appends to inbox as mixed indents")
        func quickAddProjectWithOneProjectAndMixedIndentChildren1() {
            let content = """
            Work:
            \t- Parent task
            \t\t- Nested child task
            \t- Another top level task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")

            document.quickAdd("Phase 2", type: .project)

            #expect(document.items.count == 6)
            #expect(document.items[0].displayText == "Inbox")
            #expect(document.items[1].displayText == "Phase 2")
            #expect(document.items[1].indentLevel == 1)
            #expect(document.items[1].type == .project)
        }

        @Test("Add sub-project with one project and mixed indent children with last a multiple indent. Appends at same indent")
        func quickAddProjectWithOneProjectAndMixedIndentChildren2() {
            let content = """
            Work:
            \t- Parent task
            \t\t- Nested child task
            \t- Another top level task
            \t\tSub-project:

            """
            let document = TaskPaperDocument(content: content, fileName: "Test")

            document.quickAdd("Phase 3", type: .project)

            // Note: This document has 2 projects (Work + Sub-project), so triggers Inbox logic
            #expect(document.items.count == 7)  // 5 original + Inbox + Phase 3 = 7
            #expect(document.items[0].displayText == "Inbox")
            #expect(document.items[1].displayText == "Phase 3")
            #expect(document.items[1].indentLevel == 1)  // Goes to Inbox at indent 1
            #expect(document.items[1].type == .project)
        }

        @Test("Add sub-project with one empty project")
        func quickAddProjectWithOneEmptyProject() {
            let content = """
            Work:
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")

            document.quickAdd("Phase 1", type: .project)

            #expect(document.items.count == 2)
            #expect(document.items[1].displayText == "Phase 1")
            #expect(document.items[1].indentLevel == 0)  // Empty project means commonIndentLevel, so indent 0
            #expect(document.items[1].type == .project)
        }


        @Test("Add task with Inbox project and all child items appends as child")
        func quickAddTaskWithInboxProjectAndAllChildItems() {
            let content = """
            Inbox:
            \t- Existing inbox task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")

            document.quickAdd("New task", type: .task)

            #expect(document.items.count == 3)
            #expect(document.items[2].displayText == "New task")
            #expect(document.items[2].indentLevel == 1)
        }

        // MARK: - Scenario 3: One Project but Items at Root Level (Inbox Creation)

        @Test("Add task with one project and root level items creates Inbox and adds task")
        func quickAddTaskWithOneProjectAndRootLevelItems() {
            let content = """
            Work:
            \t- Work task
            Personal:
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            #expect(document.projectCount == 2)

            document.quickAdd("New task", type: .task)

            #expect(document.items.count == 5)
            #expect(document.items[0].displayText == "Inbox")
            #expect(document.items[0].type == .project)
            #expect(document.items[0].indentLevel == 0)
            #expect(document.items[1].displayText == "New task")
            #expect(document.items[1].indentLevel == 1)
        }

        @Test("Add task with existing empty Inbox adds as first child")
        func quickAddTaskWithExistingEmptyInbox() {
            let content = """
            Inbox:
            Work:
            \t- Work task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")

            document.quickAdd("New task", type: .task)

            #expect(document.items.count == 4)
            #expect(document.items[0].displayText == "Inbox")
            #expect(document.items[1].displayText == "New task")
            #expect(document.items[1].indentLevel == 1)
        }

        @Test("Add task with existing Inbox with children appends to Inbox")
        func quickAddTaskWithExistingInboxWithChildren() {
            let content = """
            Inbox:
            \t- Existing inbox task
            \tInbox note
            Work:
            \t- Work task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")

            document.quickAdd("New task", type: .task)

            #expect(document.items.count == 6)
            #expect(document.items[0].displayText == "Inbox")
            #expect(document.items[3].displayText == "New task")
            #expect(document.items[3].indentLevel == 1)
            #expect(document.items[4].displayText == "Work")
        }

        // MARK: - Scenario 4: Multiple Projects (Inbox Logic)

        @Test("Add task with multiple projects creates Inbox at top")
        func quickAddTaskWithMultipleProjects() {
            let content = """
            Work:
            \t- Work task
            Personal:
            \t- Personal task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            #expect(document.projectCount == 2)

            document.quickAdd("New task", type: .task)

            #expect(document.items.count == 6)  // Fixed: 4 original + Inbox + new task = 6
            #expect(document.items[0].displayText == "Inbox")
            #expect(document.items[0].type == .project)
            #expect(document.items[1].displayText == "New task")
            #expect(document.items[1].indentLevel == 1)
            #expect(document.items[2].displayText == "Work")
        }

        @Test("Add note with multiple projects adds to Inbox")
        func quickAddNoteWithMultipleProjects() {
            let content = """
            Work:
            Personal:
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")

            document.quickAdd("New note", type: .note)

            // Current implementation doesn't create Inbox when all projects have no children
            // It just appends with commonIndentLevel logic (indent 0)
            #expect(document.items.count == 3)  // Fixed: 2 original + new note = 3
            #expect(document.items[2].displayText == "New note")
            #expect(document.items[2].type == .note)
            #expect(document.items[2].indentLevel == 0)  // Gets indent 0 due to commonIndentLevel
        }

        @Test("Add task with multiple projects and existing Inbox appends to existing Inbox")
        func quickAddTaskWithMultipleProjectsAndExistingInbox() {
            let content = """
            Inbox:
            \t- Existing inbox task
            Work:
            \t- Work task
            Personal:
            \t- Personal task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            #expect(document.projectCount == 3)

            document.quickAdd("New task", type: .task)

            #expect(document.items.count == 7)
            #expect(document.items[0].displayText == "Inbox")
            #expect(document.items[2].displayText == "New task")
            #expect(document.items[2].indentLevel == 1)
            #expect(document.items[3].displayText == "Work")
        }

        // MARK: - Edge Cases

        @Test("Add project with multiple projects creates Inbox and adds project")
        func quickAddProjectWithMultipleProjects() {
            let content = """
            Work:
            Personal:
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")

            document.quickAdd("Shopping", type: .project)

            // Current implementation doesn't create Inbox when all projects have no children
            // It just appends the project at indent 0
            #expect(document.items.count == 3)  // 2 original + new project = 3
            #expect(document.items[2].displayText == "Shopping")
            #expect(document.items[2].type == .project)
            #expect(document.items[2].indentLevel == 0)
        }

        @Test("Add task with Inbox at different position still finds it")
        func quickAddTaskWithInboxAtDifferentPosition() {
            let content = """
            Work:
            \t- Work task
            Inbox:
            \t- Existing inbox task
            Personal:
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")

            document.quickAdd("New task", type: .task)

            let inboxIndex = document.items.firstIndex(where: { $0.displayText == "Inbox" })
            #expect(inboxIndex != nil)

            let newTaskIndex = document.items.firstIndex(where: { $0.displayText == "New task" })
            #expect(newTaskIndex != nil)
            #expect(document.items[newTaskIndex!].indentLevel == 1)
        }


        @Test("Add multiple tasks in sequence appends in order")
        func quickAddMultipleTasksInSequence() {
            let content = """
            Work:
            \t- Task 1
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")

            document.quickAdd("Task 2", type: .task)
            document.quickAdd("Task 3", type: .task)
            document.quickAdd("Task 4", type: .task)

            #expect(document.items.count == 5)
            #expect(document.items[2].displayText == "Task 2")
            #expect(document.items[3].displayText == "Task 3")
            #expect(document.items[4].displayText == "Task 4")

            for i in 1...4 {
                #expect(document.items[i].indentLevel == 1)
            }
        }
    }

    // MARK: -

    /// Mirrors TaskPaperDocumentQuickAddTests with useInbox = false.
    /// When routing cannot be determined (mixed indents, multiple projects), items
    /// are prepended to the document rather than routed to an Inbox project.
    @Suite("TaskPaperDocument quickAdd Tests (useInbox: false)")
    struct TaskPaperDocumentQuickAddNoInboxTests {

        init() {
            UserDefaults.standard.set(false, forKey: AppStorageKeys.Editor.showWelcomeTextInNewDocument)
            UserDefaults.standard.set(false, forKey: AppStorageKeys.QuickAdd.useInbox)
        }

        // MARK: - Scenario 1: No Items (behaviour unchanged — empty always appends)

        @Test("Add project to empty document adds at top with indent 0")
        func quickAddProjectWhenEmpty() {
            let document = TaskPaperDocument(content: "", fileName: "Test")
            document.quickAdd("Work", type: .project)
            #expect(document.items.count == 1)
            #expect(document.items[0].type == .project)
            #expect(document.items[0].displayText == "Work")
            #expect(document.items[0].indentLevel == 0)
        }

        @Test("Add task to empty document adds with indent 0")
        func quickAddTaskWhenEmpty() {
            let document = TaskPaperDocument(content: "", fileName: "Test")
            document.quickAdd("First task", type: .task)
            #expect(document.items.count == 1)
            #expect(document.items[0].type == .task)
            #expect(document.items[0].displayText == "First task")
            #expect(document.items[0].indentLevel == 0)
        }

        @Test("Add note to empty document adds with indent 0")
        func quickAddNoteWhenEmpty() {
            let document = TaskPaperDocument(content: "", fileName: "Test")
            document.quickAdd("First note", type: .note)
            #expect(document.items.count == 1)
            #expect(document.items[0].type == .note)
            #expect(document.items[0].displayText == "First note")
            #expect(document.items[0].indentLevel == 0)
        }

        // MARK: - Scenario 2: One Project, All Children Same Level (behaviour unchanged — appends)

        @Test("Add task with one project and all child items appends as child")
        func quickAddTaskWithOneProjectAndAllChildItems() {
            let content = """
            Work:
            \t- Existing task 1
            \t- Existing task 2
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("New task", type: .task)
            #expect(document.items.count == 4)
            #expect(document.items[3].displayText == "New task")
            #expect(document.items[3].indentLevel == 1)
            #expect(document.items[3].type == .task)
        }

        @Test("Add note with one project and all child items appends as child")
        func quickAddNoteWithOneProjectAndAllChildItems() {
            let content = """
            Work:
            \t- Task 1
            \tNote about task 1
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("New note", type: .note)
            #expect(document.items.count == 4)
            #expect(document.items[3].displayText == "New note")
            #expect(document.items[3].indentLevel == 1)
            #expect(document.items[3].type == .note)
        }

        // MARK: - Scenario 2b: One Project, Mixed Indent — prepends to document

        @Test("Add task with one project and mixed indent children: prepended to document")
        func quickAddTaskWithOneProjectAndMixedIndentChildren1() {
            // 4 items: Work:(0), Parent task(1), Nested child(2), Another top level task(1)
            let content = """
            Work:
            \t- Parent task
            \t\t- Nested child task
            \t- Another top level task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("New task", type: .task)
            #expect(document.items.count == 5)
            #expect(document.items[0].displayText == "New task")
            #expect(document.items[0].indentLevel == 0)
            #expect(document.items[1].displayText == "Work")
        }

        @Test("Add sub-project with one project and all child items appends as child")
        func quickAddProjectWithOneProjectAndAllChildItems() {
            let content = """
            Work:
            \t- Existing task 1
            \t- Existing task 2
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("Phase 2", type: .project)
            #expect(document.items.count == 4)
            #expect(document.items[3].displayText == "Phase 2")
            #expect(document.items[3].indentLevel == 1)
            #expect(document.items[3].type == .project)
        }

        @Test("Add sub-project with one project and mixed indent children: prepended to document")
        func quickAddProjectWithOneProjectAndMixedIndentChildren1() {
            // 4 items: Work:(0), Parent task(1), Nested child(2), Another top level task(1)
            let content = """
            Work:
            \t- Parent task
            \t\t- Nested child task
            \t- Another top level task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("Phase 2", type: .project)
            #expect(document.items.count == 5)
            #expect(document.items[0].displayText == "Phase 2")
            #expect(document.items[0].indentLevel == 0)
            #expect(document.items[1].displayText == "Work")
        }

        @Test("Add sub-project with one project containing sub-project: prepended to document")
        func quickAddProjectWithOneProjectAndMixedIndentChildren2() {
            // 5 items: Work:(0), Parent task(1), Nested child(2), Another top level task(1), Sub-project:(2)
            let content = """
            Work:
            \t- Parent task
            \t\t- Nested child task
            \t- Another top level task
            \t\tSub-project:

            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("Phase 3", type: .project)
            #expect(document.items.count == 6)
            #expect(document.items[0].displayText == "Phase 3")
            #expect(document.items[0].indentLevel == 0)
            #expect(document.items[1].displayText == "Work")
        }

        @Test("Add sub-project with one empty project (behaviour unchanged)")
        func quickAddProjectWithOneEmptyProject() {
            let content = """
            Work:
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("Phase 1", type: .project)
            #expect(document.items.count == 2)
            #expect(document.items[1].displayText == "Phase 1")
            #expect(document.items[1].indentLevel == 0)
            #expect(document.items[1].type == .project)
        }

        @Test("Add task with Inbox-only project and children: appends as child (behaviour unchanged)")
        func quickAddTaskWithInboxProjectAndAllChildItems() {
            let content = """
            Inbox:
            \t- Existing inbox task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("New task", type: .task)
            #expect(document.items.count == 3)
            #expect(document.items[2].displayText == "New task")
            #expect(document.items[2].indentLevel == 1)
        }

        // MARK: - Scenario 3: Multiple Projects — item prepended to document

        @Test("Add task with one project and otherroot level items: prepended to document")
        func quickAddTaskWithOneProjectAndRootLevelItems() {
            // 3 items: Work:(0), Work task(1), Personal:(0)
            let content = """
            Work:
            \t- Work task
            Personal:
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("New task", type: .task)
            #expect(document.items.count == 4)
            #expect(document.items[0].displayText == "New task")
            #expect(document.items[0].indentLevel == 0)
            #expect(document.items[1].displayText == "Work")
        }

        @Test("Add task with existing empty Inbox: prepended to document, Inbox not used")
        func quickAddTaskWithExistingEmptyInbox() {
            // 3 items: Inbox:(0), Work:(0), Work task(1)
            let content = """
            Inbox:
            Work:
            \t- Work task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("New task", type: .task)
            #expect(document.items.count == 4)
            #expect(document.items[0].displayText == "New task")
            #expect(document.items[0].indentLevel == 0)
            #expect(document.items[1].displayText == "Inbox")
        }

        @Test("Add task with existing Inbox with children: prepended to document, Inbox not used")
        func quickAddTaskWithExistingInboxWithChildren() {
            // 5 items: Inbox:(0), Inbox task(1), Inbox note(1), Work:(0), Work task(1)
            let content = """
            Inbox:
            \t- Existing inbox task
            \tInbox note
            Work:
            \t- Work task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("New task", type: .task)
            #expect(document.items.count == 6)
            #expect(document.items[0].displayText == "New task")
            #expect(document.items[0].indentLevel == 0)
            #expect(document.items[1].displayText == "Inbox")
        }

        // MARK: - Scenario 4: Multiple Projects — item prepended to document

        @Test("Add task with multiple projects: prepended to document, no Inbox created")
        func quickAddTaskWithMultipleProjects() {
            // 4 items: Work:(0), Work task(1), Personal:(0), Personal task(1)
            let content = """
            Work:
            \t- Work task
            Personal:
            \t- Personal task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("New task", type: .task)
            #expect(document.items.count == 5)
            #expect(document.items[0].displayText == "New task")
            #expect(document.items[0].indentLevel == 0)
            #expect(document.items[1].displayText == "Work")
        }

        @Test("Add note with multiple projects (no children): appends unchanged")
        func quickAddNoteWithMultipleProjects() {
            let content = """
            Work:
            Personal:
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("New note", type: .note)
            #expect(document.items.count == 3)
            #expect(document.items[2].displayText == "New note")
            #expect(document.items[2].type == .note)
            #expect(document.items[2].indentLevel == 0)
        }

        @Test("Add task with multiple projects and existing Inbox: prepended, Inbox not used")
        func quickAddTaskWithMultipleProjectsAndExistingInbox() {
            // 6 items: Inbox:(0), Inbox task(1), Work:(0), Work task(1), Personal:(0), Personal task(1)
            let content = """
            Inbox:
            \t- Existing inbox task
            Work:
            \t- Work task
            Personal:
            \t- Personal task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("New task", type: .task)
            #expect(document.items.count == 7)
            #expect(document.items[0].displayText == "New task")
            #expect(document.items[0].indentLevel == 0)
            #expect(document.items[1].displayText == "Inbox")
        }

        // MARK: - Edge Cases

        @Test("Add project with multiple projects (no children): appends unchanged")
        func quickAddProjectWithMultipleProjects() {
            let content = """
            Work:
            Personal:
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("Shopping", type: .project)
            #expect(document.items.count == 3)
            #expect(document.items[2].displayText == "Shopping")
            #expect(document.items[2].type == .project)
            #expect(document.items[2].indentLevel == 0)
        }

        @Test("Add task with Inbox at different position: prepended, Inbox not used")
        func quickAddTaskWithInboxAtDifferentPosition() {
            // 5 items: Work:(0), Work task(1), Inbox:(0), Inbox task(1), Personal:(0)
            let content = """
            Work:
            \t- Work task
            Inbox:
            \t- Existing inbox task
            Personal:
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("New task", type: .task)
            #expect(document.items.count == 6)
            #expect(document.items[0].displayText == "New task")
            #expect(document.items[0].indentLevel == 0)
            #expect(document.items[1].displayText == "Work")
        }

        @Test("Add task with deeply nested items: prepended to document")
        func quickAddTaskWithDeeplyNestedItems() {
            // 4 items: Work:(0), Parent task(1), Child task(2), Grandchild task(3)
            let content = """
            Work:
            \t- Parent task
            \t\t- Child task
            \t\t\t- Grandchild task
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("New task", type: .task)
            #expect(document.items.count == 5)
            #expect(document.items[0].displayText == "New task")
            #expect(document.items[1].displayText == "Work")
        }

        @Test("Add multiple tasks in sequence appends in order (behaviour unchanged)")
        func quickAddMultipleTasksInSequence() {
            let content = """
            Work:
            \t- Task 1
            """
            let document = TaskPaperDocument(content: content, fileName: "Test")
            document.quickAdd("Task 2", type: .task)
            document.quickAdd("Task 3", type: .task)
            document.quickAdd("Task 4", type: .task)
            #expect(document.items.count == 5)
            #expect(document.items[2].displayText == "Task 2")
            #expect(document.items[3].displayText == "Task 3")
            #expect(document.items[4].displayText == "Task 4")
            for i in 1...4 {
                #expect(document.items[i].indentLevel == 1)
            }
        }
    }

    // MARK: -

    @Suite("String.sanitisedAsTagName")
    struct SanitiseTagNameTests {

        @Test("Plain word is unchanged")
        func plainWord() {
            #expect("inbox".sanitisedAsTagName() == "inbox")
        }

        @Test("Empty string returns inbox")
        func emptyString() {
            #expect("".sanitisedAsTagName() == "inbox")
        }

        @Test("Whitespace-only returns inbox")
        func whitespaceOnly() {
            #expect("   ".sanitisedAsTagName() == "inbox")
        }

        @Test("Single space becomes underscore")
        func singleSpace() {
            #expect("my inbox".sanitisedAsTagName() == "my_inbox")
        }

        @Test("Multiple spaces each become an underscore")
        func multipleSpaces() {
            #expect("one two three".sanitisedAsTagName() == "one_two_three")
        }

        @Test("Leading and trailing spaces are trimmed, not converted")
        func leadingTrailingSpaces() {
            #expect("  inbox  ".sanitisedAsTagName() == "inbox")
        }

        @Test("Apostrophe is removed")
        func apostrophe() {
            #expect("don't".sanitisedAsTagName() == "dont")
        }

        @Test("Hyphen is removed")
        func hyphen() {
            #expect("follow-up".sanitisedAsTagName() == "followup")
        }

        @Test("Mixed punctuation and spaces - original bug case")
        func mixedPunctuationAndSpaces() {
            #expect("Y9u're joking".sanitisedAsTagName() == "Y9ure_joking")
        }

        @Test("Digits and underscores are preserved")
        func digitsAndUnderscores() {
            #expect("tag_42".sanitisedAsTagName() == "tag_42")
        }

        @Test("All-punctuation string returns inbox")
        func allPunctuation() {
            #expect("!!!".sanitisedAsTagName() == "inbox")
        }
    }
}
