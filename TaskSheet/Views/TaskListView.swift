import OSLog
import SwiftUI

struct TaskListView: View {
   @Environment(\.undoManager) private var undoManager
   @StateObject var tagSchemeManager = TagSchemaManager()
   @ObservedObject var document: TaskPaperDocument
   @State private var isShowingTextEntryPopover: TextEntryRole? = nil
   @State private var isShowingTextEntrySheet: TextEntryRole? = nil
   @State var subViewIsEditing: Bool = false
   @State fileprivate var filterState  = FilterState()
   @State var searchText: String = ""
   @State private var debouncedSearchText: String = ""
   @State private var searchTask: Task<Void, Never>? = nil
   @State private var editTextBuffer: String = ""
   @State private var refreshId: UUID = UUID()
   
   let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TaskSheet", category: "TaskLostView")
   
   private var showQuickAddButton: Bool {
      !subViewIsEditing && isShowingTextEntryPopover == nil
   }

   var filteredItemsBinding: [Binding<TaskPaperItem>] {
      let filter = filterState.text.prefix(1) == "@" ? filterState.text.dropFirst().asString : filterState.text
      return document
         .items
         .compactMap { item in
            if (filterState.isFiltering == false
                || filterState.text.isEmpty
                || (item.cachedTags ?? []).contains(where: {$0.name == filter}) == (filterState.isNegated ? false : true)
            ) && (
               searchText.isEmpty || item.text.localizedCaseInsensitiveContains(searchText)
            ) {
               Binding(
                  get: {item},
                  set: { newValue in
                     guard let index = document.items.firstIndex(where: {$0.id == newValue.id}) else { return }
                     let oldValue = document.items[index]

                     // Register undo for binding-based mutations (icon tap, tag edits, text edits)
                     document.undoManager?.registerUndo(withTarget: document) { doc in
                        doc.items[index] = oldValue
                        doc.items[index].refreshTagCache()
                     }

                     document.items[index] = newValue
                     document.items[index].refreshTagCache()
                  }
               )
            } else {
               nil
            }
         }
   }
   
   var body: some View {
      List {
         DocumentHeader(document: document)
            .listRowInsets(.init())
            .listRowSeparator(.hidden)
         ForEach(filteredItemsBinding) { item in
            ItemRowView(item: item,
                        tagSchemaManager: tagSchemeManager,
                        document: document,
                        isEditing: $subViewIsEditing)
            .listRowInsets(EdgeInsets())
         }
         .onMove(perform: move)
      }
      .id(refreshId) //trigger a redraw after drag action as it doesn't update the list order. Something to do with basing it on a calc var and that not being triggered when underlying changes?
      .listStyle(.plain)
      .searchable(text: $searchText)
      .searchToolbarBehavior(.minimize)
      .toolbar{
         ToolbarItem(placement: .bottomBar) {
            FilterButton(filterState: $filterState)
         }
         ToolbarSpacer(.flexible, placement: .bottomBar)
         DefaultToolbarItem(kind: .search, placement: .bottomBar)
         ToolbarSpacer( .fixed, placement: .bottomBar)
         ToolbarItem(placement: .bottomBar) {
            Button {
               isShowingTextEntryPopover = .add(indent: 0)
            } label: {
               Image(systemName: "square.and.pencil")
            }
         }
         ToolbarSpacer( .fixed, placement: .bottomBar)
         ToolbarItem(placement: .bottomBar) {
            Button(role: .close) {
            } label:{
               Image(systemName: "ellipsis")
            }
         }
      }
      .toolbarVisibility( showQuickAddButton ? .visible : .hidden, for: .bottomBar)
      .popover(item: $isShowingTextEntryPopover, attachmentAnchor: .point(.init(x: -30, y: -30))) { role in
         AddItemPopOver(
            showPopover: $isShowingTextEntryPopover,
            showSheet: $isShowingTextEntrySheet,
            text: $editTextBuffer,
            role: role
         ) { text, type in
            document.quickAdd(text, type: type)
            resetInput()
         } onCancel: {
            resetInput()
         }
         .presentationCompactAdaptation(.popover)
      }
      .sheet(item: $isShowingTextEntrySheet) { role in
         ItemEditorSheet(text: $editTextBuffer, role: role) { text, type in
            document.quickAdd(text, type: type)
            resetInput()
         } onCancel: {
            resetInput()
         }
         .presentationDetents([.fraction(0.35), .medium, .large])
      }
   }
   
      /// Move an item on drag/drop
      /// - Parameters:
      ///   - indexSet: the rows being dragged. In this case should be a single row.  The first item in set is the index on screen of the row
      ///   - destination: where the dragged row is being dropped.
      ///   This is the index of the row the dropped item is being inserted before. On a drag to last place therefore it's `endIndex`, so trying to use it to access the underlying dataset will cause a crash if you;re dragging to the bottom.
   func move(indexSet: IndexSet, to destination: Int) {
      guard
         indexSet.isEmpty == false,
         let firstIndex = indexSet.first
      else {return}
      print("\(firstIndex) -> \(destination)")
      let movingId = filteredItemsBinding[firstIndex].wrappedValue.id
//      let destinationId = filteredItemsBinding[destination].wrappedValue.id
      let destinationId = switch (destination == filteredItemsBinding.endIndex, destination == document.items.endIndex) {
         case (false, ): filteredItemsBinding[destination].wrappedValue.id
         case (true, false): document.items[document.items.firstIndex{$0.id == filteredItemsBinding[destination-1].w.id}.advanced(by: 1)].wrappedValue.id
         case (true, true):
            
      }
      do {
         try withAnimation {
            try document.moveHierarchy(at: movingId, to: destinationId)
            triggerRefresh()
         }
      } catch {
         logger.error("tried to perform invalid drag/drop")
      }
   }
   
   private func triggerRefresh() {
      refreshId = UUID()
   }
 
   func resetInput() {
      editTextBuffer = ""
      subViewIsEditing = false
      isShowingTextEntrySheet = nil
      isShowingTextEntryPopover = nil
   }
}

#Preview {
   TaskListView(document: SampleContent.sampleDocument)
}

