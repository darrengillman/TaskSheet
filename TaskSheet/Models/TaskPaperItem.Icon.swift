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
            Image(systemName: type.completedFoldedIcon)
               .foregroundColor(.blue)
               .font(.system(size: 16, weight: .medium))
            
         case (.project, true, false):
            Image(systemName: type.completedIcon)
               .foregroundColor(.blue)
               .font(.system(size: 16, weight: .medium))
         
         case (.project, false, false):
            Image(systemName: type.baseIcon)
               .foregroundColor(.blue)
               .font(.system(size: 16, weight: .medium))
         
         case (.project, false, true):
            Image(systemName: type.foldedIcon)
               .foregroundColor(.blue)
               .font(.system(size: 16, weight: .medium))
            
         case (.task, true, _):
            Image(systemName:type.completedIcon)
               .foregroundColor(isCompleted ? .green : .secondary)
               .font(.system(size: 16))
         case (.task, false, _):
            Image(systemName: type.baseIcon)
               .foregroundColor(isCompleted ? .green : .secondary)
               .font(.system(size: 16))
         case (.note, _ , _):
            Image(systemName: type.baseIcon)
               .foregroundColor(isCompleted ? .secondary: .gray)
               .font(.system(size: 14))
      }
   }
}
