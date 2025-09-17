# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TaskSheet is an iOS SwiftUI application that provides a viewer and parser for TaskPaper format files. TaskPaper is a plain text task management format where projects end with ":", tasks start with "-", and notes are plain text. Items can be tagged with @tagname or @tagname(value) syntax.

## Architecture

The app follows a standard SwiftUI MVVM architecture:

### Core Models
- **TaskPaperItem** (`TaskSheet/Models/TaskPaperModels.swift`): Represents individual items (projects, tasks, notes) with support for indentation levels and tags
- **Tag** (`TaskSheet/Models/TaskPaperModels.swift`): Represents TaskPaper tags with optional values
- **TaskPaperDocument** (`TaskSheet/Models/TaskPaperDocument.swift`): Observable document model that manages parsed items and provides statistics

### Parser
- **TaskPaperParser** (`TaskSheet/Models/TaskPaperParser.swift`): Static parser that converts TaskPaper text format into structured data. Handles tab-based indentation, item type detection, and tag extraction using regex

### Manager
- **TaskPaperManager** (`TaskSheet/Managers/TaskPaperManager.swift`): Handles file loading, error states, and provides sample data. Features comprehensive iCloud Drive integration with security-scoped file access, bookmark persistence, sync status monitoring, and file coordination
- **Task Completion** (`TaskSheet/Models/TaskPaperDocument.swift`): Methods for toggling task completion by adding/removing @done tags with dates

### Views
- **ContentView**: Main entry point with file picker integration and iCloud sync status indicators
- **TaskPaperView**: Document display with header statistics
- **TaskPaperItemRow**: Individual item rendering with indentation, icons, and tag display. Supports task completion via circle icon tap and context menu
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

### File Security
Uses `startAccessingSecurityScopedResource()` and `stopAccessingSecurityScopedResource()` for proper sandboxed file access when loading TaskPaper files.

### State Management
Uses SwiftUI's @StateObject and @ObservableObject for reactive state management between the manager, document, and views.

## iCloud Drive Integration

### Capabilities & Entitlements
The app includes full iCloud Drive integration with:
- **iCloud Documents capability** (`TaskSheet.entitlements`): Enables iCloud Drive document access
- **Document Type Declaration** (`Info.plist`): Registers TaskPaper file type (.taskpaper) with custom UTI `uk.co.hotpuffin.taskpaper`
- **Document Browser Support**: Enables "Open with TaskSheet" from Files app and other document browsers

### Security-Scoped Resources
- **Bookmark Persistence**: Creates security bookmarks that survive app restarts
- **File Coordination**: Uses NSFileCoordinator for safe concurrent access during iCloud sync
- **Resource Management**: Proper cleanup with automatic resource release in deinit

### Sync Status Monitoring
The app provides real-time iCloud sync status:
- **Downloading** (blue cloud with down arrow + progress): File downloading from iCloud
- **Uploading** (blue cloud with up arrow + progress): Changes uploading to iCloud
- **Current** (green cloud): File is up-to-date and synced
- **Conflict** (orange exclamation cloud): Merge conflicts need resolution
- **Not in Cloud** (document icon): Local file not stored in iCloud
- **Unknown** (question mark): Sync status unavailable

### File Operations
- **Automatic Download**: Triggers download of iCloud files that aren't locally available
- **Progress Monitoring**: Real-time download progress with 0.5s polling intervals
- **Safe Writing**: File coordination prevents corruption during simultaneous sync operations
- **Error Recovery**: Comprehensive error handling for common iCloud scenarios

### User Experience
- Files appear in a "TaskSheet" folder in iCloud Drive
- Documents sync automatically across all user devices
- Users can organize TaskPaper files in the Files app alongside other documents
- TaskSheet appears in "Open with..." menus for .taskpaper files

## File Structure
- `TaskSheet/` - Main application code
  - `Models/` - Data models and parsing logic
  - `Views/` - SwiftUI view components
  - `Managers/` - Business logic, file handling, and iCloud integration
  - `TaskSheet.entitlements` - iCloud capabilities and container identifiers
  - `Info.plist` - Document types, UTI declarations, and iCloud container configuration
- `TaskSheetTests/` - Unit tests
- `TaskSheet.xcodeproj` - Xcode project configuration