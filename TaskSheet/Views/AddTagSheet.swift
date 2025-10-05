//
//  AddTagSheet.swift
//  TaskSheet
//
//  Created by Darren Gillman on 05/10/2025.
//
import SwiftUI

struct AddTagSheet: View {
   @Environment(\.dismiss) private var dismiss
   @State private var tagName: String = ""
   @FocusState private var isTextFieldFocused: Bool
   var onSave: (String) -> Void

   var body: some View {
      VStack(spacing: 16) {
         HStack {
            Text("Add Tag")
               .font(.headline)
               .frame(maxWidth: .infinity, alignment: .leading)
            Button {
               cancel()
            } label: {
               Image(systemName: "xmark.circle")
            }
            .foregroundColor(.secondary)
         }

         TextField("Tag name", text: $tagName)
            .textFieldStyle(.roundedBorder)
            .focused($isTextFieldFocused)
            .submitLabel(.done)
            .onSubmit {
               if !tagName.trimmingCharacters(in: .whitespaces).isEmpty {
                  save()
               }
            }
      }
      .padding()
      .background(Color(.systemBackground))
      .cornerRadius(12)
      .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
      .frame(width: 280)
      .onAppear {
         isTextFieldFocused = true
      }
   }
   
   private func save() {
      let trimmedName = tagName.trimmingCharacters(in: .whitespaces)
      guard !trimmedName.isEmpty else { return }
      onSave(trimmedName)
      dismiss()
   }

   private func cancel() {
      dismiss()
   }
}

#Preview {
   AddTagSheet(onSave: { _ in })
}
