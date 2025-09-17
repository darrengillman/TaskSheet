import SwiftUI

struct TaskPaperView: View {
   @ObservedObject var document: TaskPaperDocument
   @Binding var syncStatus: TaskPaperManager.iCloudSyncStatus

   var body: some View {
      VStack(alignment: .leading, spacing: 0) {
         DocumentHeader(document: document, syncStatus: $syncStatus)

         List(document.items) { item in
            ItemRow(item: item) { item in
               document.toggleTaskCompletion(item: item)
            }
            .listRowInsets(EdgeInsets())
         }
         .listStyle(.plain)
      }
   }
}
