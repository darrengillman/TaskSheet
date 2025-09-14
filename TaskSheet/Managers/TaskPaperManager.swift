import Foundation
import SwiftUI

class TaskPaperManager: ObservableObject {
    @Published var document: TaskPaperDocument?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadFile(result: Result<[URL], Error>) {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                errorMessage = "No file selected"
                isLoading = false
                return
            }

            loadFile(from: url)

        case .failure(let error):
            errorMessage = "File selection failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func loadFile(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Unable to access file"
            isLoading = false
            return
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let fileName = url.deletingPathExtension().lastPathComponent

            DispatchQueue.main.async {
                self.document = TaskPaperDocument(content: content, fileName: fileName)
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to read file: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func loadSampleFile() {
        let sampleContent = """
System:
\t- add entry for items on ignore list @next @done(2025-06-23)
\t- importing Boxes multiple tiimes for a week creates multiple instances in the week @next @BUG @done(2025-07-23)
\t- Finish importing weekly data @next @done(2025-06-25)
\t\t- remove all other import buttons @done(2025-06-25)
\t- Ensure that all BoxItems are deleted when a box is deleted as there are no date records in BoxItem to otherwise link it to the Week @done(2025-06-23)
\t\tThere is a delete cascade rule from Box -> BoxItems which will take care of this (in theory)

Packing Screen:
\t- alter swaps listing so that it only highlights changes relevant to your station( i.e. station, all, notSet) @next @done(2025-07-29)
\t- add split navigation @done(2025-07-23)
\t- move toolbar into mian Nav bar @today @done(2025-09-03)
\t- fix the layout bug where the supposedly static view scrolls up with the list view. @next @BUG
"""

        document = TaskPaperDocument(content: sampleContent, fileName: "Sample")
    }
}