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
   @State private var filteredIds: [UUID] = []
   
   let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TaskSheet", category: "TaskLostView")
   
   private var showQuickAddButton: Bool {
      !subViewIsEditing && isShowingTextEntryPopover == nil
   }

   /// Produces a live Binding<TaskPaperItem> for a given item ID.
   private func makeBinding(for id: UUID) -> Binding<TaskPaperItem>? {
      guard let index = document.items.firstIndex(where: { $0.id == id }) else { return nil }
      return Binding(
         get: { document.items[index] },
         set: { newValue in
            let oldValue = document.items[index]
            document.undoManager?.registerUndo(withTarget: document) { doc in
               doc.items[index] = oldValue
               doc.items[index].refreshTagCache()
            }
            document.items[index] = newValue
            document.items[index].refreshTagCache()
         }
      )
   }

   /// Recomputes the stable ordered list of visible item IDs from the current filter and search state.
   private func recomputeFilteredIds() {
      let filter = filterState.text.prefix(1) == "@"
         ? filterState.text.dropFirst().asString
         : filterState.text
      filteredIds = document.items.compactMap { item in
         let passesFilter = !filterState.isFiltering
            || filterState.text.isEmpty
            || (item.cachedTags ?? []).contains(where: { $0.name == filter }) == (filterState.isNegated ? false : true)
         let passesSearch = debouncedSearchText.isEmpty
            || item.text.localizedCaseInsensitiveContains(debouncedSearchText)
         return (passesFilter && passesSearch) ? item.id : nil
      }
   }
   
   var body: some View {
      List {
         DocumentHeader(document: document)
            .listRowInsets(.init())
            .listRowSeparator(.hidden)
         ForEach(filteredIds, id: \.self) { id in
            if let binding = makeBinding(for: id) {
               ItemRowView(item: binding,
                           tagSchemaManager: tagSchemeManager,
                           document: document,
                           isEditing: $subViewIsEditing)
               .listRowInsets(EdgeInsets())
            }
         }
         .onMove(perform: move)
      }
      .listStyle(.plain)
      .searchable(text: $searchText)
      .searchToolbarBehavior(.minimize)
      .task { recomputeFilteredIds() }
      .onChange(of: document.items) { recomputeFilteredIds() }
      .onChange(of: filterState.isFiltering) { recomputeFilteredIds() }
      .onChange(of: filterState.text) { recomputeFilteredIds() }
      .onChange(of: filterState.isNegated) { recomputeFilteredIds() }
      .onChange(of: debouncedSearchText) { recomputeFilteredIds() }
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
   
   /// Move an item on drag/drop.
   ///
   /// SwiftUI gives indices into the *filtered* list. We:
   /// 1. Capture the destination ID BEFORE mutating filteredIds (indices become invalid after)
   /// 2. Determine the full hierarchy (parent + children) being moved
   /// 3. Count how many hierarchy items are visible in filteredIds
   /// 4. Move that many consecutive items in filteredIds (preserves view order)
   /// 5. Propagate the move to document.items using the captured destination ID
   func move(indexSet: IndexSet, to destination: Int) {
      guard let firstIndex = indexSet.first else { return }
      let movingId = filteredIds[firstIndex]

      // Capture destination ID BEFORE mutating filteredIds
      let destinationId: UUID? = destination < filteredIds.endIndex ? filteredIds[destination] : nil

      // Get full hierarchy from document
      guard let docIndex = document.items.firstIndex(where: { $0.id == movingId }) else { return }
      let hierarchyIndexes = document.items.hierarchyIndexes(from: docIndex)
      let hierarchyIds = hierarchyIndexes.map { document.items[$0].id }

      // Count how many hierarchy items are visible in filteredIds
      let visibleCount = hierarchyIds.filter { filteredIds.contains($0) }.count

      // Move that many consecutive items starting at firstIndex
      let indicesToMove = IndexSet(firstIndex..<(firstIndex + visibleCount))
      filteredIds.move(fromOffsets: indicesToMove, toOffset: destination)

      // Propagate to document using the captured ID
      do {
         if let destId = destinationId {
            try document.moveHierarchy(at: movingId, to: destId)
         } else {
            try document.moveHierarchyToEnd(at: movingId)
         }
      } catch {
         logger.error("tried to perform invalid drag/drop")
         recomputeFilteredIds()
      }
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

