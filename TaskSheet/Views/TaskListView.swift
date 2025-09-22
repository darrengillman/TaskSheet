import SwiftUI

struct TaskListView: View {
   @ObservedObject var document: TaskPaperDocument
   @Binding var syncStatus: TaskPaperManager.iCloudSyncStatus

   var body: some View {
      VStack(alignment: .leading, spacing: 0) {
         DocumentHeader(document: document, syncStatus: $syncStatus)

         List($document.items) { item in
            ItemRowView(tags: document.tags, item: item) { item in
               document.toggleTaskCompletion(item: item)
            }
            .listRowInsets(EdgeInsets())
         }
         .listStyle(.plain)
      }
      .navigationTitle(document.fileName)
   }
}

#Preview {
   TaskListView(document: SampleContent.sampleDocument, syncStatus: .constant(.current))
}

