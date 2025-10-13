import SwiftUI

struct TaskListView: View {
   @StateObject var tagSchemeManager = TagSchemaManager()
   @ObservedObject var document: TaskPaperDocument
   @Binding var syncStatus: TaskPaperManager.iCloudSyncStatus
   @State private var isShowingQuickAddPopover: Bool = false
   @State private var isShowingEditSheet: Bool = false
   @State var subViewIsEditing: Bool = false
   @State fileprivate var filterState  = FilterState()
   @State var searchText: String = ""
   @State private var editTextBuffer: String = ""
   
   private var showQuickAddButton: Bool {
      !subViewIsEditing && !isShowingQuickAddPopover
   }

   var filteredItemsBinding: [Binding<TaskPaperItem>] {
      document.items.compactMap { item in
         if filterState.isFiltering == false
               || filterState.text.isEmpty
               || (item.cachedTags ?? []).contains(where: {$0.name == filterState.text}) == (filterState.isNegated ? false : true)
         {
            Binding(
               get: {item},
               set: {
                  let index = document.items.firstIndex(of: item)
                  document.items[index!] = $0
               }
            )
         } else {
            nil
         }
      }
   }
   
   var body: some View {
      List {
         DocumentHeader(document: document, syncStatus: $syncStatus)
            .listRowInsets(.init())
            .listRowSeparator(.hidden)
         ForEach(filteredItemsBinding) { item in
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
         AddItemPopOver(showPopover: $isShowingQuickAddPopover, showSheet: $isShowingEditSheet, text: $editTextBuffer) { text, type in
            document.quickAdd(text, type: type)
            editTextBuffer = ""
         } onCancel: {
            resetInput()
         }
         .presentationCompactAdaptation(.popover)
      }
      .sheet(isPresented: $isShowingEditSheet) {
         ItemEditorView(text: $editTextBuffer) { text, type in
            document.quickAdd(text, type: type)
            editTextBuffer = ""
         } onCancel: {
            resetInput()
         }
         .presentationDetents([.fraction(0.35), .medium, .large])
      }
      .navigationTitle(document.fileName)
   }
   
   func resetInput() {
      editTextBuffer = ""
      isShowingEditSheet = false
      isShowingQuickAddPopover = false
   }
   
}

#Preview {
   TaskListView(document: SampleContent.sampleDocument, syncStatus: .constant(.current))
}

