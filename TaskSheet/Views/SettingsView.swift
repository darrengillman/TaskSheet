import OSLog
import SwiftUI
import TelemetryDeck

private enum SettingsRoute: Hashable {
    case fileTypes
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var enabledFileTypeCount = FileTypeRegistry.enabledTypes.count
    @AppStorage("display.noteIcon") private var showNoteIcons = true

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
        }
    }
}

#Preview {
    SettingsView()
}
