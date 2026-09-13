//
//  TaskDocumentView.swift
//  TaskSheet
//
//  Main view for TaskPaper documents in DocumentGroup architecture
//

import SwiftUI

struct TaskDocumentView: View {
    @ObservedObject var document: TaskPaperDocument
    let fileURL: URL?
    @Environment(\.undoManager) var undoManager

    var body: some View {
        NavigationStack {
            TaskListView(document: document, fileURL: fileURL)
                .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            document.undoManager = undoManager
        }
    }
}

#Preview {
    TaskDocumentView(document: SampleContent.sampleDocument, fileURL: nil)
}
