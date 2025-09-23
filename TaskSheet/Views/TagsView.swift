//
//  TagsView.swift
//  TaskSheet
//
//  Created by Darren Gillman on 23/09/2025.
//

import SwiftUI

struct TagsView: View {
   let tags: [Tag]
   @ObservedObject var schema: TagSchemaManager
   let deleteAction: (Tag) -> Void
   
   var body: some View {
      HStack(spacing: 6) {
         ForEach(tags, id: \.self) { tag in
            TagView(tag: tag, schema: schema, deleteAction: deleteAction)
         }
      }
   }
}
