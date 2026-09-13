//
//  FilterStore.swift
//  TaskSheet
//
//  Created by Darren Gillman on 13/09/2026.
//

import Foundation

/// Persists the last-used filter per file, keyed on file path.
/// Not identity-stable across renames/moves - losing a remembered filter that way
/// is cosmetic (falls back to the default FilterState), not a data-loss concern.
enum FilterStore {
   private static let key = "persistedFilters"

   static func filter(forFileAt url: URL) -> PersistedFilter? {
      loadAll()[url.path]
   }

   static func setFilter(_ filter: PersistedFilter, forFileAt url: URL) {
      var all = loadAll()
      all[url.path] = filter
      save(all)
   }

   private static func loadAll() -> [String: PersistedFilter] {
      guard let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([String: PersistedFilter].self, from: data)
      else { return [:] }
      return decoded
   }

   private static func save(_ all: [String: PersistedFilter]) {
      guard let data = try? JSONEncoder().encode(all) else { return }
      UserDefaults.standard.set(data, forKey: key)
   }
}
