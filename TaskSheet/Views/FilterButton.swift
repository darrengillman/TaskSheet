//
//  FilterButton.swift
//  TaskSheet
//
//  Created by Darren Gillman on 08/10/2025.
//
import SwiftUI

struct FilterButton: View {
   @Binding var filterState: FilterState
   @Namespace var namespace
   var body: some View {
      Button{
         filterState.isFiltering.toggle()
      } label: {
         if filterState.isFiltering == false {
            Image(systemName: "line.3.horizontal.decrease")
         } else {
            HStack(alignment: .center, spacing: 0) {
               Image(systemName: "line.3.horizontal.decrease")
                  .padding(8)
                  .foregroundStyle(.white)
                  .background(.blue, in: .containerRelative)
                  .padding(.trailing, 8)
                  .contentShape(.containerRelative)
               
               Button{
                  filterState.isShowingFilterBuilder.toggle()
               } label: {
                  VStack(alignment: .leading, spacing: 0){
                     Text("Filtered by")
                        .font(.caption)
                        .fontWeight(.semibold)
                     HStack(spacing: 4) {
                        Text("Not")
                           .font(.caption)
                           .fontWeight(filterState.isNegated ? .bold : .light)
                           .foregroundStyle(.white)
                           .padding( 2)
                           .background(filterState.isNegated ? .blue : .gray.opacity(0.4))
                           .clipShape(RoundedRectangle(cornerRadius: 4))
                           .onTapGesture {
                              filterState.isNegated.toggle()
                           }
                        
                        TextField("Filter", text: $filterState.text, prompt: Text("Tag name"), axis: .horizontal)
                           .lineLimit(1)
                           .multilineTextAlignment(.leading)
                           .textFieldStyle(.plain)
                           .textInputAutocapitalization(.never)
                           .font(.caption)
                           .foregroundStyle(.blue)
                           .fontWeight(.semibold)
                           .frame(minWidth: 80, maxWidth: 140)
                     }
                  }
               }
               .matchedTransitionSource(id: IDs.filterButton, in: namespace)
            }
         }
      }
   }
}

#Preview {
   @Previewable @State var  state = FilterState(isFiltering: true)
   FilterButton(filterState: $state)
}
