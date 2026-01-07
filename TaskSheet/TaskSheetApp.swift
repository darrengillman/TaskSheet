import SwiftUI

@main
struct TaskSheetApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: { TaskPaperDocument(content: "", fileName: "Untitled") }) { file in
            TaskDocumentView(document: file.document)
        }
    }
}
