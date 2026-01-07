//
//  Int+extn.swift
//  TaskSheet
//
//  Created by Darren Gillman on 15/10/2025.
//


extension Int: @retroactive Identifiable {
   public var id: Int {self}
}