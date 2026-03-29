import UniformTypeIdentifiers

struct FileTypeDefinition: Identifiable {
    let id: String              // UTI string, used as stable identity
    let displayName: String
    let fileExtension: String
    let utType: UTType
    let defaultsKey: String
}

enum FileTypeRegistry {

    // MARK: - UserDefaults keys

    enum Keys {
        static let plainText = "fileTypes.plainText"
        static let markdown  = "fileTypes.markdown"
        static let opml      = "fileTypes.opml"
    }

    // MARK: - Type catalogue

    /// All user-configurable file types, in display order.
    static let configurableTypes: [FileTypeDefinition] = [
        .init(id: "public.plain-text",           displayName: "Plain Text", fileExtension: "txt",  utType: .plainText, defaultsKey: Keys.plainText),
        .init(id: "net.daringfireball.markdown", displayName: "Markdown",   fileExtension: "md",   utType: .markdown,  defaultsKey: Keys.markdown),
        .init(id: "org.opml.opml",               displayName: "OPML",       fileExtension: "opml", utType: .opml,      defaultsKey: Keys.opml),
    ]

    // MARK: - Enabled types

    /// Returns the UTTypes currently enabled in UserDefaults.
    /// .taskPaper is always included. Called at app launch to populate readableContentTypes.
    static var enabledTypes: [UTType] {
        var types: [UTType] = [.taskPaper]
        for definition in configurableTypes where UserDefaults.standard.bool(forKey: definition.defaultsKey) {
            types.append(definition.utType)
        }
        return types
    }
}
