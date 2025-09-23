   //
   //  TagView.swift
   //  TaskSheet
   //
   //  Created by Darren Gillman on 23/09/2025.
   //

import SwiftUI

struct TagView: View {
   @State private var showingTagActions = false
   @State var tag: Tag
   @ObservedObject var schema: TagSchemaManager
   let deleteAction: (Tag) -> Void
   
   var body: some View {
      Text(tag.displayText)
         .font(.caption)
         .padding(.horizontal, 6)
         .padding(.vertical, 2)
         .background(schema.getColor(for: tag).opacity(0.2))
         .foregroundColor(schema.getColor(for: tag))
         .cornerRadius(4)
         .contentShape(Rectangle())
         .onTapGesture {
            if tag.name != "done" {
               showingTagActions = true
            }
         }
         .popover(isPresented: $showingTagActions) {
            VStack(spacing: 0) {
               Button {
                  deleteAction(tag)
                  showingTagActions = false
               } label: {
                  Label("Delete Tag", systemImage: "trash")
                     .foregroundColor(.red)
                     .frame(maxWidth: .infinity, alignment: .leading)
                     .padding()
               }
               schema.colorMenu(for: tag, presenting: $showingTagActions)
            }
            .frame(width: 160)
            .background(Color(.systemBackground))
            .presentationCompactAdaptation(.popover)
         }
   }
}
