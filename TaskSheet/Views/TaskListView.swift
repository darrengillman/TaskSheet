import SwiftUI

struct TaskListView: View {
   @StateObject var tagSchemeManager = TagSchemaManager()
   @ObservedObject var document: TaskPaperDocument
   @Binding var syncStatus: TaskPaperManager.iCloudSyncStatus
   @State private var isShowingQuickAddPopover: Bool = false
   @State var subViewIsEditing: Bool = false
   
   private var showQuickAddButton: Bool {
      !subViewIsEditing && !isShowingQuickAddPopover
   }

   var body: some View {
      VStack(alignment: .leading, spacing: 0) {
         DocumentHeader(document: document, syncStatus: $syncStatus)

         List($document.items) { item in
            ItemRowView(item: item,
                        tagSchemaManager: tagSchemeManager,
                        document: document,
                        isEditing: $subViewIsEditing)
            .listRowInsets(EdgeInsets())
         }
         .listStyle(.plain)
      }.toolbar{
         ToolbarItem(placement: .confirmationAction) {
            Button(role: .close) {
            } label:{
               Image(systemName: "ellipsis")
            }
         }
      }
      .overlay(alignment: .bottomTrailing) {
         if showQuickAddButton {
            Button {
               withAnimation {
                  isShowingQuickAddPopover = true
               }
            } label: {
               Image(systemName: "square.and.pencil")
                  .font(.title)
                  .padding(6)
                  .shadow(color: .primary.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .offset(x: -20, y: 0)
            .buttonStyle(.glass)
         }
      }
      .popover(isPresented: $isShowingQuickAddPopover, attachmentAnchor: .point(.init(x: -30, y: -30))) {
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

