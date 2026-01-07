//
//  TaskDocumentView.swift
//  TaskSheet
//
//  Main view for TaskPaper documents in DocumentGroup architecture
//

import SwiftUI

struct TaskDocumentView: View {
    @ObservedObject var document: TaskPaperDocument
    @Environment(\.undoManager) var undoManager

    var body: some View {
        NavigationStack {
            TaskListView(document: document)
                .navigationTitle(document.fileName)
        }
    }
}

#Preview {
    TaskDocumentView(document: SampleContent.sampleDocument)
}
