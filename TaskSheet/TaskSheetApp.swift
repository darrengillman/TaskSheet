import SwiftUI
import TelemetryDeck

@main
struct TaskSheetApp: App {
   init() {
      let config = TelemetryDeck.Config(appID: "099BC00A-6933-4CE5-BD3D-91FD3B657D32")
      config.defaultSignalPrefix = "TaskSheetApp."
      config.defaultParameterPrefix = "TaskSheet."
      TelemetryDeck.initialize(config: config)
   }
   
    var body: some Scene {
        DocumentGroup(newDocument: { TaskPaperDocument(content: "", fileName: "Untitled") }) { file in
            TaskDocumentView(document: file.document)
        }
    }
}
