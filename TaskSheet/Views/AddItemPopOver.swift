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
   @Binding var showPopover: TextEntryRole?
   @Binding var showSheet: TextEntryRole?
   @Binding var text: String
   @State private var itemType: ItemType = .task
   var role: TextEntryRole
   var onSave: (String, ItemType) -> Void
   var onCancel: (() -> Void )?

   var body: some View {
      VStack(spacing: 16) {
         HStack {
            if case .add = role {
               HStack {
                  Text(role.titleString)
                     .font(.headline)
                  Picker("Type", selection: $itemType) {
                     ForEach(ItemType.allCases, id: \.self) {
                        Text($0.rawValue.capitalized)
                     }
                  }
                  .pickerStyle(.menu)
               }
               .frame(maxWidth: .infinity, alignment: .leading)
            } else {
               Text("\(role.titleString) \(role.itemType?.rawValue.capitalized ?? "")")
                  .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Button{
               withAnimation {
                  let role = showPopover
                  showPopover = nil
                  Task {
                     try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                     showSheet = role
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
            .accessibilityLabel(Text("Edit in larger edit window"))
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
      onCancel?() ?? dismiss()
   }
}

#Preview {
   @Previewable @State var showPopover: TextEntryRole? = nil
   @Previewable @State var showSheet: TextEntryRole? = nil
   @Previewable @State var text = ""
   @Previewable @State var role = TextEntryRole.edit(type: .task, indent: 0)
   AddItemPopOver(showPopover: $showPopover, showSheet: $showSheet, text: $text, role: role) { text, type in
       }
}

private struct EditView: View {
   var body: some View {
      Text("")
   }
}
