# Changelog

## [Unreleased] — 2026-04-29

### New Features
- **Settings panel** — new Settings view with Display and Documents sections
- **Configurable file types** — toggle support for plain text, Markdown, and OPML files (requires restart)
- **Welcome text** — customisable welcome/empty-state message shown in new documents
- **Note icon toggle** — option to hide the note icon on note rows for a cleaner look

### Improvements
- **Quick Add** — more reliable behaviour when the document is empty or contains only a single project
- **Deleting items** — deleting a parent item now removes its children too
- **@done tag** — automatically includes the current date when an item is marked done
- **Editor view** — back button hidden in the item editor sheet for a cleaner navigation experience
- **Item list** — removed divider lines between rows
- **Version numbers** — corrected for Beta program
- **Code quality** — all `AppStorage` keys consolidated into a single `AppStorageKeys` enum; `SettingsView` open/close animation improved

### Bug Fixes
- Fixed incorrect UTI declarations for Markdown (`net.daringfireball.markdown`) and OPML (`org.opml.opml`) that caused a launch-time warning
