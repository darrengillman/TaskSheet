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
   @State private var itemType: ItemType
   let role: TextEntryRole
   let onSave: (String, ItemType) -> Void
   let onCancel: (() -> Void)?

   init(
      showPopover: Binding<TextEntryRole?>,
      showSheet: Binding<TextEntryRole?>,
      text: Binding<String>,
      role: TextEntryRole,
      onSave: @escaping (String, ItemType) -> Void,
      onCancel: (() -> Void)?
   ) {
      self._showPopover = showPopover
      self._showSheet = showSheet
      self._text = text
      self.role = role
      self.onSave = onSave
      self.onCancel = onCancel
      self._itemType = State(initialValue: role.itemType)
   }

   var body: some View {
      VStack(spacing: 16) {
         HStack {
            if case .add = role {
               HStack {
                  Text(role.popOverTitleString)
                     .font(.headline)
                     .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                  Picker("Type", selection: $itemType) {
                     ForEach(ItemType.allCases, id: \.self) {
                        Text($0.rawValue.capitalized)
                     }
                  }
                  .pickerStyle(.menu)
                  .dynamicTypeSize(...DynamicTypeSize.accessibility1)
               }
               .frame(maxWidth: .infinity, alignment: .leading)
            } else {
               Text("\(role.popOverTitleString) \(role.itemType.rawValue.capitalized)")
                  .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button{
               withAnimation {
                  let newRole: TextEntryRole = switch role {
                     case .add:
                           .add(type: itemType, indent: role.indent)
                     case .edit:
                           .edit(type: itemType, indent: role.indent)
                  }
                  showPopover = nil
                  Task {
                     try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                     showSheet = newRole
                  }
               }
            } label: {
               Image(systemName: "chevron.down")
                  .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                  .padding(.horizontal, 6)
            }
            .foregroundColor(.secondary)
            .accessibilityLabel(Text("Edit in larger edit window"))

            Button(role: .cancel) {
               cancel()
            } label: {
               Image(systemName: "xmark")
                  .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                  .padding(.horizontal, 6)
            }
            .foregroundColor(.secondary)
         }
         
         TextField("Description...", text: $text/*, axis: .vertical*/)
            .textFieldStyle(.roundedBorder)
            .focused($isTextFieldFocused)
            .accessibilityLabel(Text("Placeholder text for item"))
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
      .frame(minWidth: 352, maxWidth: 400)
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
   @Previewable @State var role = TextEntryRole.add(type: .task, indent: 0)
   AddItemPopOver(showPopover: $showPopover, showSheet: $showSheet, text: $text, role: role) { text, type in
   } onCancel: {}
}

