//
//  PersistedFilter.swift
//  TaskSheet
//
//  Created by Darren Gillman on 13/09/2026.
//

/// The subset of FilterState worth remembering between sessions for a given file.
/// Deliberately decoupled from FilterState so transient UI fields (e.g. isShowingFilterBuilder)
/// never get persisted, and the on-disk shape can evolve independently of the live view state.
struct PersistedFilter: Codable, Equatable {
   var text: String = ""
   var isNegated: Bool = false
   var isFiltering: Bool = false
}
