import OSLog
import SwiftUI
import TelemetryDeck

struct FileTypesSettingsView: View {
   @AppStorage(AppStorageKeys.FileTypes.plainText) private var plainTextEnabled = false
   @AppStorage(AppStorageKeys.FileTypes.markdown)  private var markdownEnabled  = false
   @AppStorage(AppStorageKeys.FileTypes.opml)      private var opmlEnabled      = false

   @State private var restartRequired = false

   private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TaskSheet", category: "FileTypesSettingsView")

   private func binding(for definition: FileTypeDefinition) -> Binding<Bool> {
      switch definition.defaultsKey {
         case AppStorageKeys.FileTypes.plainText: return $plainTextEnabled
         case AppStorageKeys.FileTypes.markdown:  return $markdownEnabled
         case AppStorageKeys.FileTypes.opml:      return $opmlEnabled
         default:                                 return .constant(false)
      }
   }

   private func handleToggle(definition: FileTypeDefinition, newValue: Bool) {
      let state = newValue ? "enabled" : "disabled"
      logger.info("File type '\(definition.id)' \(state)")
      TelemetryDeck.signal("FileTypesSettingsView.Toggle.change",
                           parameters: ["typeId": definition.id, "enabled": "\(newValue)"])
      withAnimation {
         restartRequired = true
      }
   }

    var body: some View {
        List {
            if restartRequired {
                Section {
                    Label {
                        Text("Fully quit and relaunch TaskSheet for file type changes to take effect.")
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
            Section {
                LabeledContent("TaskPaper (.taskpaper)") {
                    Text("Always On")
                        .foregroundStyle(.secondary)
                }
                ForEach(FileTypeRegistry.configurableTypes) { definition in
                    Toggle("\(definition.displayName) (.\(definition.fileExtension))", isOn: binding(for: definition))
                        .onChange(of: binding(for: definition).wrappedValue, initial: false) { _, newValue in
                            handleToggle(definition: definition, newValue: newValue)
                        }
                }
            } header: {
                Text("Supported Formats")
            }
        }
        .navigationTitle("File Types")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FileTypesSettingsView()
    }
}
