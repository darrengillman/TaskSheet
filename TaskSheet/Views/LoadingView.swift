//
//  LoadingView.swift
//  TaskSheet
//
//  Created by Darren Gillman on 16/09/2025.
//

import SwiftUI

struct LoadingView: View {
   var body: some View {
      Text("TaskSheet")
         .font(.largeTitle)
         .padding(12)
      Text("Loading...")
         .font(.title)
         .foregroundColor(.secondary)
         .padding()
      ProgressView()
         .scaleEffect(2.5)
   }
}
