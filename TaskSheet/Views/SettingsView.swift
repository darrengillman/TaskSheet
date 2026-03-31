import OSLog
import SwiftUI
import TelemetryDeck

private enum SettingsRoute: Hashable {
   case fileTypes
}

struct SettingsView: View {
   @Environment(\.dismiss) private var dismiss
   @State private var enabledFileTypeCount = FileTypeRegistry.enabledTypes.count
   @AppStorage(AppStorageKeys.Display.noteIcon) private var showNoteIcons = true
   @AppStorage(AppStorageKeys.Editor.deleteRemovesChildren) private var deleteRemovesChildren = true
   @AppStorage(AppStorageKeys.Editor.includeDateWhenMarkingDone) private var includeDateWhenMarkingDone = true
   @AppStorage(AppStorageKeys.Editor.showWelcomeTextInNewDocument) private var showWelcomeTextInNewDocument = true
   @AppStorage(AppStorageKeys.Editor.alwaysUseMainEditingSheet) private var alwaysUseMainEditingSheet = false
   
      // Alert state for under-development features
   @State private var isShowingAlert = false
   @State private var alertMessage: String? = nil
   @State private var alertTitle: String = "Not Implemented"
   
   private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TaskSheet", category: "SettingsView")
   
   var body: some View {
      NavigationStack {
         List {
            Section("Display") {
               Toggle("Display icon for notes", isOn: $showNoteIcons)
                  .onChange(of: showNoteIcons, initial: false) { _, newValue in
                     let state = newValue ? "enabled" : "disabled"
                     logger.info("Note icons \(state)")
                     TelemetryDeck.signal("SettingsView.Display.NoteIcon.toggle",
                                          parameters: ["enabled": "\(newValue)"])
                  }
            }
            
            Section("Documents") {
               NavigationLink(value: SettingsRoute.fileTypes) {
                  LabeledContent {
                     Text("\(enabledFileTypeCount) enabled")
                        .foregroundStyle(.secondary)
                  } label: {
                     Label("File Types", systemImage: "doc.badge.gearshape")
                  }
               }
            }
            
            Section("Editor") {
               Toggle("Delete removes child items", isOn: $deleteRemovesChildren)
                  .onChange(of: deleteRemovesChildren, initial: false) { _, newValue in
                     let state = newValue ? "enabled" : "disabled"
                     logger.info("Delete removes children \(state)")
                     TelemetryDeck.signal("SettingsView.Editor.DeleteRemovesChildren.toggle",
                                          parameters: ["enabled": "\(newValue)"])
                  }
               
               Toggle("Include date with @done", isOn: $includeDateWhenMarkingDone)
                  .onChange(of: includeDateWhenMarkingDone, initial: false) { _, newValue in
                     let state = newValue ? "enabled" : "disabled"
                     logger.info("Include date when marking done \(state)")
                     alertMessage = "Editing preference not yet implemented"
                     isShowingAlert = true
                     TelemetryDeck.signal("SettingsView.Editor.IncludeDateWhenMarkingDone.toggle",
                                          parameters: ["enabled": "\(newValue)"])
                  }
               
               Toggle("Add Welcome text to new document", isOn: $showWelcomeTextInNewDocument)
                  .onChange(of: showWelcomeTextInNewDocument, initial: false) { _, newValue in
                     let state = newValue ? "enabled" : "disabled"
                     logger.info("Show welcome text \(state)")
                     TelemetryDeck.signal("SettingsView.Editor.ShowWelcomeText.toggle",
                                          parameters: ["enabled": "\(newValue)"])
                  }
               
               Toggle("Always use main editing sheet", isOn: $alwaysUseMainEditingSheet)
                  .onChange(of: alwaysUseMainEditingSheet, initial: false) { _, newValue in
                     alertMessage = "Editing preference not yet implemented"
                     isShowingAlert = true
                     TelemetryDeck.signal("SettingsView.Editor.AlwaysUseMainEditingSheet.toggle",
                                          parameters: ["enabled": "\(newValue)"])
                  }
            }
         }
         .navigationTitle("Settings")
         .navigationBarTitleDisplayMode(.inline)
         .navigationDestination(for: SettingsRoute.self) { route in
            switch route {
               case .fileTypes:
                  FileTypesSettingsView()
            }
         }
         .onAppear { enabledFileTypeCount = FileTypeRegistry.enabledTypes.count }
         .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
               Button("Done") { dismiss() }
            }
         }
         .alert(alertTitle,
                isPresented: $isShowingAlert,
                actions: { Button(role: .cancel, action: { alertMessage = nil }) { Text("OK") } },
                message: { alertMessage == nil ? nil : Text(alertMessage!) }
         )
      }
   }
}

#Preview {
   SettingsView()
}
