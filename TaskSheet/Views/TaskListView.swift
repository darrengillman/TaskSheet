import SwiftUI

struct TaskListView: View {
   @StateObject var tagSchemeManager = TagSchemaManager()
   @ObservedObject var document: TaskPaperDocument
   @Binding var syncStatus: TaskPaperManager.iCloudSyncStatus

   var body: some View {
      VStack(alignment: .leading, spacing: 0) {
         DocumentHeader(document: document, syncStatus: $syncStatus)

         List($document.items) { item in
            ItemRowView(item: item,
                        tagSchemaManager: tagSchemeManager,
                        document: document)
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

