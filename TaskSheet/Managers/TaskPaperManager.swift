import Foundation

class TaskPaperManager: ObservableObject {
   @Published var document: TaskPaperDocument?
   @Published var isLoading = false
   @Published var errorMessage: String?
   @Published var isSyncing = false
   @Published var downloadProgress: Double = 0.0
   @Published var syncStatus: iCloudSyncStatus = .unknown
   
   private var fileBookmark: Data?
   private var currentFileURL: URL?
   private var isSampleDataLoaded: Bool = false
   private var fileCoordinator = NSFileCoordinator()
   private let bookmarkKey = "TaskPaperFileBookmark"
   
   enum iCloudSyncStatus {
      case unknown
      case notInCloud
      case downloading
      case uploading
      case current
      case conflict
   }
   
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
      
         // Create bookmark for persistent access
      createBookmarkForURL(url)
      
         // Check iCloud sync status
      checkiCloudSyncStatus(for: url)
      
         // Use file coordination for safe access
      var coordinatorError: NSError?
      fileCoordinator.coordinate(readingItemAt: url, options: [], error: &coordinatorError) { (readingURL) in
         do {
            let content = try String(contentsOf: readingURL, encoding: .utf8)
            let fileName = readingURL.deletingPathExtension().lastPathComponent
            isSampleDataLoaded = false
            
            Task { @MainActor in
               self.currentFileURL = url
               self.document = TaskPaperDocument(content: content, fileName: fileName)
               self.isLoading = false
            }
         } catch {
            Task { @MainActor in
               self.errorMessage = "Failed to read file: \(error.localizedDescription)"
               self.isLoading = false
            }
         }
      }
      
      if let error = coordinatorError {
         Task { @MainActor in
            self.errorMessage = "File coordination failed: \(error.localizedDescription)"
            self.isLoading = false
         }
      }
   }
   
   func loadSampleFile() {
      document = SampleContent.sampleDocument
      currentFileURL = nil
      syncStatus = .notInCloud
      isSampleDataLoaded = true
   }
   
      // MARK: - Security-Scoped Resource Management
   
   private func createBookmarkForURL(_ url: URL) {
      do {
         let bookmarkData = try url.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: nil, relativeTo: nil)
         fileBookmark = bookmarkData
         UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
      } catch {
         print("Failed to create bookmark: \(error)")
      }
   }
   
   func restoreFileAccess() {
      guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else { return }
      
      var isStale = false
      do {
         let url = try URL(resolvingBookmarkData: bookmarkData, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale)
         
         if isStale {
               // Recreate bookmark
            createBookmarkForURL(url)
         }
         
         loadFile(from: url)
      } catch {
         print("Failed to restore file access: \(error)")
         UserDefaults.standard.removeObject(forKey: bookmarkKey)
      }
   }
   
      // MARK: - iCloud Sync Status Monitoring
   
   private func checkiCloudSyncStatus(for url: URL) {
         // Basic iCloud detection based on file path
      if url.path.contains("icloud") || url.path.contains("iCloud") {
         Task { @MainActor in
            self.syncStatus = .current
            self.isSyncing = false
         }
      } else {
         Task { @MainActor in
            self.syncStatus = .notInCloud
         }
      }
   }
   
      // MARK: - File Saving
   
   func saveDocument() {
      guard isSampleDataLoaded == false else {return}
      guard let document = document,
            let url = currentFileURL else {
         errorMessage = "No document to save"
         return
      }
      
      guard url.startAccessingSecurityScopedResource() else {
         errorMessage = "Unable to access file for saving"
         return
      }
      
      defer {
         url.stopAccessingSecurityScopedResource()
      }
      
      var coordinatorError: NSError?
      fileCoordinator.coordinate(writingItemAt: url, options: [], error: &coordinatorError) { (writingURL) in
         do {
            let content = document.content
            try content.write(to: writingURL, atomically: true, encoding: .utf8)
            
            Task { @MainActor in
               self.syncStatus = .uploading
                  // File saved successfully
            }
         } catch {
            Task { @MainActor in
               self.errorMessage = "Failed to save file: \(error.localizedDescription)"
            }
         }
      }
      
      if let error = coordinatorError {
         Task { @MainActor in
            self.errorMessage = "File coordination failed during save: \(error.localizedDescription)"
         }
      }
   }
   
   // MARK: - Task Operations
   
   func toggleTaskCompletion(item: TaskPaperItem) {
      document?.toggleTaskCompletion(item: item)
   }
   
   // MARK: - Cleanup
   
   deinit {
      currentFileURL?.stopAccessingSecurityScopedResource()
   }
}
