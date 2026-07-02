//
//  ItemEditorView.swift
//  TaskSheet
//
//  Created by Darren Gillman on 11/10/2025.
//

import SwiftUI

struct ItemEditorSheet: View {
   @Environment(\.dismiss) private var dismiss
   @FocusState private var isTextEditorFocused: Bool
   @Binding var text: String
   @State private var itemType: ItemType

   var addOrEdit: TextEntryRole
   var onSave: (String, ItemType) -> Void
   var onCancel: ( () -> Void )?

   init(text: Binding<String>, addOrEdit: TextEntryRole, onSave: @escaping (String, ItemType) -> Void, onCancel: (() -> Void)? = nil) {
      self._text = text
      self.addOrEdit = addOrEdit
      self.onSave = onSave
      self.onCancel = onCancel
      self._itemType = State(initialValue: addOrEdit.itemType)
   }

   var body: some View {
      VStack(spacing: 0) {
         if case .add = addOrEdit {
            Picker("Type", selection: $itemType) {
               ForEach(ItemType.allCases, id: \.self) { type in
                  Label(type.rawValue.capitalized, systemImage: type.baseIcon)
               }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])
         }

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
      .navigationBarBackButtonHidden()
      .onAppear {
         Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            isTextEditorFocused = true
         }
      }
      .toolbar {
         ToolbarItem(placement: .principal) {
            Text("\(addOrEdit.editorTitleString) \(addOrEdit.itemType.rawValue.capitalized)")
         }
         ToolbarItem(placement: .confirmationAction) {
            Button(role: .confirm) {
               onSave(text, itemType)
               dismiss()
            } label: {
               Image(systemName: "checkmark")
            }
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
         }
      }
      .toolbarTitleDisplayMode(.inline)
   }
   
   private func cancel() {
      onCancel?() ?? dismiss()
   }
}

#Preview {
   @Previewable @State var text = ""
   @Previewable @State var role: TextEntryRole  = .edit(type: .task, indent: 1)
   ItemEditorSheet(text: $text, addOrEdit: role) {_, _ in }
}
