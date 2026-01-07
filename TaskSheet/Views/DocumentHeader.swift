   //
   //  DocumentHeader.swift
   //  TaskSheet
   //
   //  Created by Darren Gillman on 16/09/2025.
   //
import SwiftUI

struct DocumentHeader: View {
   @ObservedObject var document: TaskPaperDocument

   var body: some View {
      HStack {
         HStack(spacing: 12) {
            StatItem(icon: "folder", count: document.projectCount, label: "Projects")
            StatItem(icon: "circle", count: document.taskCount - document.completedTaskCount, label: "Tasks")
            StatItem(icon: "checkmark.circle", count: document.completedTaskCount, label: "Done")
            StatItem(icon: "doc.text", count: document.noteCount, label: "Notes")
         }
         .frame(maxWidth: .infinity, alignment: .leading)
         
      }
      .padding(.vertical)
      .padding(.leading)
      .frame(maxWidth: .infinity, alignment: .leading)
      .border(Color(.separator), width: 1)
   }
}

fileprivate
struct StatItem: View {
   let icon: String
   let count: Int
   let label: String
   
   var body: some View {
         HStack(spacing: 4) {
            Image(systemName: icon)
               .foregroundColor(.secondary)
               .font(.caption)
            
            Text("\(count)")
               .fontWeight(.medium)
               .font(.caption)
            
            Text(label)
               .foregroundColor(.secondary)
               .font(.caption)
         }
   }
}

#Preview {
   DocumentHeader(document: SampleContent.sampleDocument)
}


struct TopBottomBorder: Shape {
   var lineWidth: CGFloat = 1
   
   func path(in rect: CGRect) -> Path {
      var path = Path()
      
         // Top border
      path.move(to: CGPoint(x: rect.minX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
      
         // Bottom border
      path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
      
      return path
   }
}
