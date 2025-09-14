import SwiftUI

struct ContentView: View {
    @StateObject private var taskPaperManager = TaskPaperManager()
    @State private var showingFilePicker = false

    var body: some View {
        NavigationView {
            VStack {
                if taskPaperManager.document == nil {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("Select a TaskPaper file to get started")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Button("Open TaskPaper File") {
                            showingFilePicker = true
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Load Sample") {
                            taskPaperManager.loadSampleFile()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    TaskPaperView(document: taskPaperManager.document!)
                }
            }
            .navigationTitle("TaskSheet")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Open File") {
                        showingFilePicker = true
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.plainText, .data],
                allowsMultipleSelection: false
            ) { result in
                taskPaperManager.loadFile(result: result)
            }
        }
    }
}