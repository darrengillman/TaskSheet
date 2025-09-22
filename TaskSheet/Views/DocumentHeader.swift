   //
   //  DocumentHeader.swift
   //  TaskSheet
   //
   //  Created by Darren Gillman on 16/09/2025.
   //
import SwiftUI

struct DocumentHeader: View {
   struct PopOverContent: Identifiable, ExpressibleByStringLiteral {
      var id: String {text}
      var text: String
      
      init(stringLiteral value: String) {
         self.text = value
      }
   }
   
   @ObservedObject var document: TaskPaperDocument
   @Binding var syncStatus: TaskPaperManager.iCloudSyncStatus
   @State var popOverText: PopOverContent? = nil
   
   var body: some View {
      HStack {
         syncStatusView
            .padding(.trailing, 12)
            .popover(item: $popOverText, attachmentAnchor: .point(.topTrailing)) { item in
               Text(item.text)
                  .padding(.horizontal, 12)
                  .padding(.vertical, 8)
                  .presentationCompactAdaptation(.popover)
            }
            .onTapGesture {
               popOverText = PopOverContent(stringLiteral: syncStatus.rawValue)
            }

         HStack(spacing: 12) {
            StatItem(icon: "folder", count: document.projectCount, label: "Projects")
            StatItem(icon: "circle", count: document.taskCount - document.completedTaskCount, label: "Tasks")
            StatItem(icon: "checkmark.circle", count: document.completedTaskCount, label: "Done")
            StatItem(icon: "doc.text", count: document.noteCount, label: "Notes")
         }
         .frame(maxWidth: .infinity, alignment: .leading)
         
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color(.systemGroupedBackground))
      .scrollEdgeEffectStyle(.soft, for: .bottom)
   }
   
   @ViewBuilder
   private var syncStatusView: some View {
      switch syncStatus {
         case .downloading:
            HStack(spacing: 4) {
               ProgressView()
                  .scaleEffect(0.7)
               Image(systemName: "icloud.and.arrow.down")
                  .foregroundColor(.blue)
            }
         case .uploading:
            HStack(spacing: 4) {
               ProgressView()
                  .scaleEffect(0.7)
               Image(systemName: "icloud.and.arrow.up")
                  .foregroundColor(.blue)
            }
         case .current:
            Image(systemName: "icloud")
               .foregroundColor(.green)
         case .conflict:
            Image(systemName: "exclamationmark.icloud")
               .foregroundColor(.orange)
         case .notInCloud:
            Image(systemName: "doc")
               .foregroundColor(.secondary)
         case .unknown:
            Image(systemName: "questionmark.circle")
               .foregroundColor(.secondary)
      }
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
   DocumentHeader(
      document: SampleContent.sampleDocument,
      syncStatus: .constant(.notInCloud)
   )
}
