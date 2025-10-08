//
//  FilterButton.swift
//  TaskSheet
//
//  Created by Darren Gillman on 08/10/2025.
//
import SwiftUI

struct FilterButton: View {
   @Binding var filterState: FilterState
   var body: some View {
      Button{
         filterState.isOn.toggle()
      } label: {
         if filterState.isOn == false {
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
                           .fontWeight(filterState.negated ? .bold : .light)
                           .foregroundStyle(.white)
                           .padding(.horizontal, 4)
                           .padding(.vertical, 2)
                           .background(filterState.negated ? .blue : .gray.opacity(0.4))
                           .clipShape(RoundedRectangle(cornerRadius: 4))
                           .onTapGesture {
                              filterState.negated.toggle()
                           }
                        Text(filterState.text)
                           .font(.caption)
                           .foregroundStyle(.blue)
                           .fontWeight(.semibold)
                     }
                  }
               }
            }
         }
      }
   }
}
