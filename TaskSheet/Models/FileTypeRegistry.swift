import UniformTypeIdentifiers

struct FileTypeDefinition: Identifiable {
    let id: String              // UTI string, used as stable identity
    let displayName: String
    let fileExtension: String
    let utType: UTType
    let defaultsKey: String
}

enum FileTypeRegistry {

    // MARK: - Type catalogue

    /// All user-configurable file types, in display order.
    static let configurableTypes: [FileTypeDefinition] = [
        .init(id: "public.plain-text",           displayName: "Plain Text", fileExtension: "txt",  utType: .plainText, defaultsKey: AppStorageKeys.FileTypes.plainText),
        .init(id: "net.daringfireball.markdown", displayName: "Markdown",   fileExtension: "md",   utType: .markdown,  defaultsKey: AppStorageKeys.FileTypes.markdown),
        .init(id: "org.opml.opml",               displayName: "OPML",       fileExtension: "opml", utType: .opml,      defaultsKey: AppStorageKeys.FileTypes.opml),
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
