//
//  ItemEditorView.swift
//  TaskSheet
//
//  Created by Darren Gillman on 11/10/2025.
//

import SwiftUI

struct ItemEditorView: View {
   @Environment(\.dismiss) private var dismiss
   @FocusState private var isTextEditorFocused: Bool
   @Binding var text: String
   @State private var itemType: ItemType = .task

   var onSave: (String, ItemType) -> Void
   var onCancel: ( () -> Void )?

   var body: some View {
      NavigationView {
         VStack(spacing: 0) {
            Picker("Type", selection: $itemType) {
               ForEach(ItemType.allCases, id: \.self) { type in
                  Label(type.rawValue.capitalized, systemImage: type.baseIcon)
               }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            TextEditor(text: $text)
               .frame(minHeight: 120)
               .padding(12)
               .background(.background)
               .cornerRadius(12)
               .overlay(
                  RoundedRectangle(cornerRadius: 12)
                     .stroke(Color(.systemGray4), lineWidth: 1)
               )
               .focused($isTextEditorFocused)
               .padding()
         }
         .onAppear {
            Task {
               try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
               isTextEditorFocused = true
            }
         }
         .toolbar{
            ToolbarItem(placement: .cancellationAction) {
               Button(role: .cancel) {
                  cancel()
               } label: {
                  Image(systemName: "xmark")
               }
            }
            ToolbarItem(placement: .principal) {
               Text("Quick Add \(itemType.rawValue.capitalized)")
            }
            ToolbarItem(placement: .confirmationAction) {
               Button("Add") {
                  onSave(text, itemType)
                  dismiss()
               }
               .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
               .fontWeight(.semibold)
            }
         }
         .toolbarTitleDisplayMode(.inline)
      }
   }
   
   private func cancel() {
      onCancel?() ?? dismiss()
   }
}

#Preview {
   @Previewable @State var text = ""
   ItemEditorView(text: $text) {_, _ in }
}
