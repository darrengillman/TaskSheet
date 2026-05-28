//
//  TaskPaperItem.Icom.swift
//  TaskSheet
//
//  Created by Darren Gillman on 13/10/2025.
//

import SwiftUI

extension TaskPaperItem {
   var icon: some View {
      switch (type, isCompleted, isFolded) {
         case (.project, true , true):
            Text(Image(systemName: type.completedFoldedIcon))
               .foregroundColor(.blue)
               .font(.headline.weight(.medium))

         case (.project, true, false):
            Text(Image(systemName: type.completedIcon))
               .foregroundColor(.blue)
               .font(.headline.weight(.medium))

         case (.project, false, false):
            Text(Image(systemName: type.baseIcon))
               .foregroundColor(.blue)
               .font(.headline.weight(.medium))

         case (.project, false, true):
            Text(Image(systemName: type.foldedIcon))
               .foregroundColor(.blue)
               .font(.headline.weight(.medium))

         case (.task, true, _):
            Text(Image(systemName: type.completedIcon))
               .foregroundColor(isCompleted ? .green : .secondary)
               .font(.body)
         case (.task, false, _):
            Text(Image(systemName: type.baseIcon))
               .foregroundColor(isCompleted ? .green : .secondary)
               .font(.body)
         case (.note, _ , _):
            Text(Image(systemName: type.baseIcon))
               .foregroundColor(isCompleted ? .secondary: .gray)
               .font(.footnote)
      }
   }
}
