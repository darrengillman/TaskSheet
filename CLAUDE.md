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
- **TaskPaperManager** (`TaskSheet/Managers/TaskPaperManager.swift`): Handles file loading, error states, and provides sample data. Manages security-scoped file access for sandboxed environment
- **Task Completion** (`TaskSheet/Models/TaskPaperDocument.swift`): Methods for toggling task completion by adding/removing @done tags with dates

### Views
- **ContentView**: Main entry point with file picker integration
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

## File Structure
- `TaskSheet/` - Main application code
  - `Models/` - Data models and parsing logic
  - `Views/` - SwiftUI view components
  - `Managers/` - Business logic and file handling
- `TaskSheetTests/` - Unit tests
- `TaskSheet.xcodeproj` - Xcode project configuration