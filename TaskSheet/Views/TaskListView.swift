import SwiftUI

struct TaskListView: View {
   @StateObject var tagSchemeManager = TagSchemaManager()
   @ObservedObject var document: TaskPaperDocument
   @Binding var syncStatus: TaskPaperManager.iCloudSyncStatus
   @State private var isShowingQuickAdd: Bool = false

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
      .overlay(alignment: .bottomTrailing) {
         Button {
            isShowingQuickAdd = true
         } label: {
            Image(systemName: "plus.circle.fill")
               .font(.largeTitle)
               .scaleEffect(2)
               .shadow(color: .primary.opacity(0.3), radius: 10, x: 0, y: 5)
         }
         .buttonStyle(.glassProminent)
         .offset(x: -30, y: -30)
      }
      .popover(isPresented: $isShowingQuickAdd, attachmentAnchor: .point(.init(x: -30, y: -30))) {
         AddItemPopOver { text, type in
            document.quickAdd( text, type: type)
         }
         .presentationCompactAdaptation(.popover)
      }
      .navigationTitle(document.fileName)
   }
}

#Preview {
   TaskListView(document: SampleContent.sampleDocument, syncStatus: .constant(.current))
}

