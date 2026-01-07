# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TaskSheet is an iOS SwiftUI application that provides a viewer and parser for TaskPaper format files. TaskPaper is a plain text task management format where projects end with ":", tasks start with "-", and notes are plain text. Items can be tagged with @tagname or @tagname(value) syntax.

## Architecture

The app uses SwiftUI's **DocumentGroup** architecture for native document management with automatic iCloud sync:

### Document Model
- **TaskPaperDocument** (`TaskSheet/Models/TaskPaperDocument.swift`): ReferenceFileDocument-conforming class that manages TaskPaper documents
  - Conforms to ReferenceFileDocument protocol for automatic file loading/saving
  - Uses @Published properties to trigger autosave when items change
  - Provides snapshot() method for serialization to disk
  - Contains 14 mutation methods (quickAdd, insert, delete, toggle, indent, outdent, move operations)
  - Computed statistics: projectCount, taskCount, completedTaskCount, noteCount, allTags

### Core Models
- **TaskPaperItem** (`TaskSheet/Models/TaskPaperModels.swift`): Represents individual items (projects, tasks, notes) with support for indentation levels and tags
- **Tag** (`TaskSheet/Models/TaskPaperModels.swift`): Represents TaskPaper tags with optional values

### Parser
- **TaskPaperParser** (`TaskSheet/Models/TaskPaperParser.swift`): Static parser that converts TaskPaper text format into structured data. Handles tab-based indentation, item type detection, and tag extraction using regex

### App Structure
- **TaskSheetApp**: Uses DocumentGroup scene for multi-document support
- **TaskDocumentView**: Main view for individual documents, provides NavigationStack wrapper
- **TaskListView**: Displays and edits document items with filtering, search, and quick-add
- **ItemRowView**: Individual item rendering with indentation, icons, and tag display. Supports task completion via circle icon tap and context menu
- **DocumentHeader**: Shows document statistics (projects, tasks, notes counts)
- **TagView**: Colored tag rendering with predefined color schemes for common tags (done=green, next/today=orange, bug=red, etc.)

## Development Commands

### Building
```bash
xcodebuild -project TaskSheet.xcodeproj -scheme TaskSheet -configuration Debug -destination 'platform=iOS Simulator' build
```

### Testing
Run tests on iOS Simulator (required due to iOS deployment target):
```bash
xcodebuild -project TaskSheet.xcodeproj -scheme TaskSheet -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0' test
```
Or use any available iOS Simulator:
```bash
xcodebuild -project TaskSheet.xcodeproj -scheme TaskSheet -destination 'platform=iOS Simulator' test
```

### Running
Open `TaskSheet.xcodeproj` in Xcode and run on iOS Simulator, or use:
```bash
xcodebuild -project TaskSheet.xcodeproj -scheme TaskSheet -configuration Debug -destination 'platform=iOS Simulator'
```

## Key Design Patterns

### Tag Parsing
The parser uses regex pattern `@(\\w+)(?:\\(([^)]+)\\))?` to extract tags from text. Tags are displayed separately from main text content and have semantic meaning (e.g., @done marks completion).

### Indentation Handling
TaskPaper uses tabs for indentation levels. The parser counts leading tabs to determine hierarchy, which is visually represented in the UI with spacing.

### ReferenceFileDocument Pattern
TaskPaperDocument is a class (reference type) conforming to ReferenceFileDocument. Views use @ObservedObject to observe the same document instance, and @Published properties trigger automatic saves. This differs from FileDocument (value types) which use Binding<Document> for modifications.

### State Management
Uses SwiftUI's @ObservedObject for document observation across views. DocumentGroup manages file coordination, security-scoped resources, and persistence automatically. No manual bookmark or file access management needed.

## iCloud Drive Integration

DocumentGroup provides native iCloud integration with automatic sync, conflict resolution, and version management.

### Capabilities & Entitlements
The app includes full iCloud Drive integration with:
- **iCloud Documents capability** (`TaskSheet.entitlements`): Enables iCloud Drive document access via CloudDocuments service
- **Document Type Declaration** (`Info.plist`): Registers TaskPaper file type (.taskpaper) with custom UTI `uk.co.hotpuffin.taskpaper`
- **Document Browser Support**: Enables "Open with TaskSheet" from Files app and other document browsers

### Automatic Features via DocumentGroup
DocumentGroup handles these automatically:
- **File Coordination**: NSFileCoordinator managed by system for safe concurrent access
- **Security-Scoped Resources**: Automatic bookmark persistence and access management
- **Sync Status**: System displays sync indicators in document browser
- **Conflict Resolution**: Native UI for resolving iCloud conflicts
- **Version Management**: Built-in version browsing and restoration
- **Autosave**: Changes save automatically when @Published properties change
- **Multiple Windows**: Support for multiple open documents (iPad/Mac)

### User Experience
- Native document browser shows iCloud and local files
- Files appear in "TaskSheet" folder in iCloud Drive
- Documents sync automatically across all user devices
- System shows sync status indicators (downloading, uploading, current, conflict)
- Users can organize TaskPaper files in Files app alongside other documents
- TaskSheet appears in "Open with..." menus for .taskpaper files
- Offline changes queue and sync when connection returns

## File Structure
- `TaskSheet/` - Main application code
  - `Models/` - Data models (TaskPaperDocument, TaskPaperItem, Tag) and parsing logic
  - `Views/` - SwiftUI view components (TaskDocumentView, TaskListView, ItemRowView, etc.)
  - `Extensions/` - Swift extensions (UTType, String, Int)
  - `TaskSheet.entitlements` - iCloud capabilities and container identifiers
  - `Info.plist` - Document types, UTI declarations, and iCloud container configuration
  - `TaskSheetApp.swift` - App entry point with DocumentGroup scene
- `TaskSheetTests/` - Unit tests
- `TaskSheet.xcodeproj` - Xcode project configuration