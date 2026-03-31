import Foundation

/// Centralized registry for all UserDefaults/AppStorage keys used throughout the application.
/// Organized by functional category for discoverability and maintainability.
///
/// Usage:
/// ```swift
/// @AppStorage(AppStorageKeys.Editor.deleteRemovesChildren) private var deleteRemovesChildren = true
/// @AppStorage(AppStorageKeys.Display.noteIcon) private var showNoteIcons = true
/// ```
enum AppStorageKeys {
    
    // MARK: - Editor Settings
    
    /// Settings related to document editing behavior
    enum Editor {
        /// Whether to show welcome text in newly created documents
        static let showWelcomeTextInNewDocument = "editor.showWelcomeTextInNewDocument"
        
        /// Whether deleting a parent item should also remove its children
        static let deleteRemovesChildren = "editor.deleteRemovesChildren"
        
        /// Whether to include timestamp when marking tasks as @done
        static let includeDateWhenMarkingDone = "editor.includeDateWhenMarkingDone"
        
        /// Whether to always use the main editing sheet instead of inline editing
        static let alwaysUseMainEditingSheet = "editor.alwaysUseMainEditingSheet"
    }
    
    // MARK: - Display Settings
    
    /// Settings related to visual presentation
    enum Display {
        /// Whether to show icons next to note items
        static let noteIcon = "display.noteIcon"
    }
    
    // MARK: - File Type Settings
    
    /// Settings for enabled import/export file types
    enum FileTypes {
        /// Whether plain text (.txt) files are enabled
        static let plainText = "fileTypes.plainText"
        
        /// Whether Markdown (.md) files are enabled
        static let markdown = "fileTypes.markdown"
        
        /// Whether OPML (.opml) files are enabled
        static let opml = "fileTypes.opml"
    }
    
    // MARK: - Tag Settings
    
    /// Settings related to tag customization
    enum Tags {
        /// Serialized custom tag color mappings
        static let customTagColors = "customTagColors"
    }
}
