//
//  AddTagPopOver 2.swift
//  TaskSheet
//
//  Created by Darren Gillman on 06/10/2025.
//


import SwiftUI

struct AddItemPopOver: View {
   @Environment(\.dismiss) private var dismiss
   @FocusState private var isTextFieldFocused: Bool
   @Binding var showPopover: Bool
   @Binding var showSheet: Bool
   @Binding var text: String
   @State private var itemType: ItemType = .task
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
            Button{
               withAnimation {
                  showPopover = false
                  Task {
                     try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                     showSheet = true
                  }
               }
            } label: {
               Image(systemName: "chevron.down")
                  .padding(.horizontal, 6)
            }
            .foregroundColor(.secondary)

            Button {
               cancel()
            } label: {
               Image(systemName: "xmark")
                  .padding(.horizontal, 6)

            }
            .foregroundColor(.secondary)
         }
         
         TextField("Description...", text: $text/*, axis: .vertical*/)
            .textFieldStyle(.roundedBorder)
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
   @Previewable @State var showPopover = false
   @Previewable @State var showSheet = false
   @Previewable @State var text = ""
   AddItemPopOver(showPopover: $showPopover, showSheet: $showSheet, text: $text) { text, type in
       }
}

private struct EditView: View {
   var body: some View {
      Text("")
   }
}
