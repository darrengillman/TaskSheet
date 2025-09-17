//
//  ErrorView.swift
//  TaskSheet
//
//  Created by Darren Gillman on 16/09/2025.
//

import SwiftUI

struct ErrorView: View {
   let message: String
   
   var body: some View {
      Text("Error")
         .font(.title)
      Text(message)
         .font(.title)
         .padding()
   }
}
