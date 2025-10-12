//
//  ItemEditorView.swift
//  TaskSheet
//
//  Created by Darren Gillman on 11/10/2025.
//

import SwiftUI

struct ItemEditorView: View {
   @Environment(\.dismiss) private var dismiss
   @Binding var text: String
   @State private var itemType: ItemType = .task
   
   var onSave: (String, ItemType) -> Void

   var body: some View {
      NavigationView {
         VStack(alignment: .leading){
            HStack {
               Text("Add:")
                  .font(.headline)
               Picker("Type", selection: $itemType) {
                  ForEach(ItemType.allCases, id: \.self) {
                     Text("\($0.rawValue.capitalized)" )
                        .foregroundStyle(.tint)
                  }
               }
               .pickerStyle(.menu)
            }
            .padding(.horizontal)
            .frame(alignment: .leading)
            TextEditor(text: $text)
               .lineLimit(6, reservesSpace: true)
               .padding(.horizontal)
               .clipShape(RoundedRectangle(cornerRadius: 8))
               .border(.secondary, width: 1)
               .padding(.bottom, 12)
         }
         .toolbar{
            ToolbarItem(placement: .cancellationAction) {
               Button(role: .cancel) {dismiss()} label: {
                  Image(systemName: "xmark")
               }
            }
            ToolbarItem(placement: .principal) {

            }
            ToolbarItem(placement: .confirmationAction) {
               Button("Save") {
                  onSave(text, itemType)
                  dismiss()
               }
            }
         }
      }
   }
}

#Preview {
   @Previewable @State var text = ""
   ItemEditorView(text: $text) {_, _ in }
}
