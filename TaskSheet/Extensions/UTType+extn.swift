//
//  UTType+extn.swift
//  TaskSheet
//
//  Created by Darren Gillman on 18/10/2025.
//
import UniformTypeIdentifiers

extension UTType {
    // UTType for individual TaskPaper items (used for drag/drop, Transferable)
    static let taskPaperItem = UTType(exportedAs: "uk.co.hotpuffin.taskpaper.item")

    // UTType for TaskPaper documents (used for DocumentGroup file type)
    static let taskPaper = UTType(exportedAs: "uk.co.hotpuffin.taskpaper")

    // UTType for Markdown documents (system UTI, but not surfaced as a static member on iOS)
    static let markdown = UTType(importedAs: "net.daringfireball.markdown")

    // UTType for OPML documents (imported — not a system-defined UTI)
    static let opml = UTType(importedAs: "org.opml.opml")
}
