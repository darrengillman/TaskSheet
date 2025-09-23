   //
   //  +extn.swift
   //  TaskSheet
   //
   //  Created by Darren Gillman on 22/09/2025.
   //
import SwiftUI

extension Color {
   var intValue: Int {
      return switch self {
         case .black: 0
         case .blue: 1
         case .brown: 2
         case .clear: 3
         case .cyan: 4
         case .gray: 5
         case .green: 6
         case .indigo: 7
         case .mint: 8
         case .orange: 9
         case .pink: 10
         case .purple: 11
         case .red: 12
         case .teal: 13
         case .white: 14
         case .yellow: 15
         default: 1
      }
   }
   
   static func standard( _ int: Int) -> Color {
      switch int {
         case 0 : .black
         case 1 : .blue
         case 2 : .brown
         case 3 : .clear
         case 4 : .cyan
         case 5 : .gray
         case 6 : .green
         case 7 : .indigo
         case 8 : .mint
         case 9 : .orange
         case 10 : .pink
         case 11 : .purple
         case 12 : .red
         case 13 : .teal
         case 14 : .white
         case 15 : .yellow
         default: .blue
      }
   }
}
