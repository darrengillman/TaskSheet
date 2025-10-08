import SwiftUI

struct TaskListView: View {
   @StateObject var tagSchemeManager = TagSchemaManager()
   @ObservedObject var document: TaskPaperDocument
   @Binding var syncStatus: TaskPaperManager.iCloudSyncStatus
   @State private var isShowingQuickAddPopover: Bool = false
   @State var subViewIsEditing: Bool = false
   @State fileprivate var filterState  = FilterState()
   @State var searchText: String = ""
   
   private var showQuickAddButton: Bool {
      !subViewIsEditing && !isShowingQuickAddPopover
   }

   var body: some View {
      List {
         DocumentHeader(document: document, syncStatus: $syncStatus)
            .listRowInsets(.init())
            .listRowSeparator(.hidden)
         ForEach($document.items) { item in
            ItemRowView(item: item,
                        tagSchemaManager: tagSchemeManager,
                        document: document,
                        isEditing: $subViewIsEditing)
            .listRowInsets(EdgeInsets())
         }
      }
      .listStyle(.plain)
      .searchable(text: $searchText)
      .searchToolbarBehavior(.minimize)
      .toolbar{
         ToolbarItem(placement: .confirmationAction) {
            Button(role: .close) {
            } label:{
               Image(systemName: "ellipsis")
            }
         }
            ToolbarItem(placement: .bottomBar) {
               FilterButton(filterState: $filterState)
            }
            ToolbarSpacer(.flexible, placement: .bottomBar)
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
            ToolbarSpacer( .fixed, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
               Button {
                     isShowingQuickAddPopover = true
               } label: {
                  Image(systemName: "square.and.pencil")
               }
            }
      }
      .toolbarVisibility( showQuickAddButton ? .visible : .hidden, for: .bottomBar)
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

