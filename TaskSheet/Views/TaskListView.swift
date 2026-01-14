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
   
   private func setUndo(for item: TaskPaperItem, undoAction: @escaping (TaskPaperItem) -> Void) {
      guard let undoManager else {return}
      undoManager.registerUndo(withTarget: document) { target in
         undoAction(item)
      }
   }
   
   func move(indexSet: IndexSet, to: Int) {
      guard indexSet.isEmpty == false else {return}
      let moving = filteredItemsBinding[indexSet.first!].wrappedValue
      let droppedOn = filteredItemsBinding[to].wrappedValue
      do {
         setUndo(for: moving, undoAction: {_ in})
         try withAnimation {
            try document.moveHierarchy(for: moving, onto: droppedOn)
         }
      } catch {
         logger.error("tried to perform invalid drag/drop")
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

