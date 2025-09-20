//
//  Tag.swift
//  TaskSheet
//
//  Created by Darren Gillman on 19/09/2025.
//


struct Tag: Codable, Hashable {
    let name: String
    let value: String?

    init(name: String, value: String? = nil) {
        self.name = name
        self.value = value
    }

    var displayText: String {
        if let value = value {
            return "@\(name)(\(value))"
        } else {
            return "@\(name)"
        }
    }
}