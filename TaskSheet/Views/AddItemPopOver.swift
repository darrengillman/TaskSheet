//
//  AddTagPopOver 2.swift
//  TaskSheet
//
//  Created by Darren Gillman on 06/10/2025.
//


import SwiftUI

struct AddItemPopOver: View {
   @Environment(\.dismiss) private var dismiss
   @State private var text: String = ""
   @State private var itemType: ItemType = .task
   @FocusState private var isTextFieldFocused: Bool
   var onSave: (String, ItemType) -> Void

   var body: some View {
      VStack(spacing: 16) {
         HStack {
            HStack {
               Text("Add")
                  .font(.headline)
               Picker("Type", selection: $itemType) {
                  ForEach(ItemType.allCases, id: \.self) {
                     Text($0.rawValue.capitalized)
                  }
               }
               .pickerStyle(.menu)
               .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(alignment: .leading)
            Button {
               cancel()
            } label: {
               Image(systemName: "xmark.circle")
            }
            .foregroundColor(.secondary)
         }
         
         TextField("Description...", text: $text)
            .textFieldStyle(.roundedBorder)
            .lineLimit(3, reservesSpace: true)
            .focused($isTextFieldFocused)
            .submitLabel(.done)
            .onSubmit {
               if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                  save()
               }
            }
      }
      .padding()
      .background(Color(.systemBackground))
      .cornerRadius(12)
      .shadow(color: .primary.opacity(0.2), radius: 10, x: 0, y: 5)
      .frame(width: 380)
      .onAppear {
         isTextFieldFocused = true
      }
   }
   
   private func save() {
      let trimmedText = text.trimmingCharacters(in: .whitespaces)
      guard !trimmedText.isEmpty else { return }
      onSave(trimmedText, itemType)
      dismiss()
   }

   private func cancel() {
      dismiss()
   }
}

#Preview {
   AddItemPopOver(onSave: { _ , _ in })
}
