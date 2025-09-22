import SwiftUI

struct RootView: View {
   @Environment(\.scenePhase) private var scenePhase
   @StateObject private var taskPaperManager = TaskPaperManager()
   @State private var showingFilePicker = false
   @State private var loading = false
   
   var body: some View {
      NavigationStack {
         VStack {
            if loading {
               LoadingView()
            } else if taskPaperManager.document == nil {
               noFileSelectedView
            } else {
               TaskListView(document: taskPaperManager.document!, syncStatus: $taskPaperManager.syncStatus)
            }
         }
         .navigationTitle(taskPaperManager.document?.fileName ?? "TaskSheet")
         .toolbar {
            if taskPaperManager.document !=  nil {
               Button(role: .close) {
                  taskPaperManager.saveDocument()
                  taskPaperManager.document = nil
               } label: {
                  Image(systemName: "xmark.circle.fill")
               }
            }
         }
      }
      .onAppear {
            // Restore previous file access if available
         guard let bookmarkData = UserDefaults.standard.data(forKey: TaskPaperManager.bookmarkKey) else { return }
         loading = true
         taskPaperManager.restoreFileAccess(from: bookmarkData)
         loading = false
      }
      .onChange(of: scenePhase) { _, new in
         if new == .background || new == .inactive {
            taskPaperManager.saveDocument()
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
   
   private var noFileSelectedView: some View {
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
   }
}

#Preview {
   RootView()
}
