//
//  HighScores.swift
//  Dinoja
//

import Foundation
import Observation

/// The top scores shown on the start screen, saved in `UserDefaults`.
@MainActor
@Observable
final class HighScores {
    struct Entry: Codable, Equatable, Identifiable {
        var id = UUID()
        let name: String
        let score: Int

        init(name: String, score: Int) {
            self.name = name
            self.score = score
        }

        /// Entries compare by name and score; `id` only gives SwiftUI a stable identity.
        static func == (lhs: Entry, rhs: Entry) -> Bool {
            lhs.name == rhs.name && lhs.score == rhs.score
        }
    }

    static let maxEntries = 5
    static let maxNameLength = 12
    static let defaultName = "dinoja"
    private static let storageKey = "highScores"

    private(set) var entries: [Entry]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        entries = defaults.data(forKey: Self.storageKey)
            .flatMap { try? JSONDecoder().decode([Entry].self, from: $0) } ?? []
    }

    /// Whether `score` would make the list. Ties with the lowest entry don't count.
    func qualifies(_ score: Int) -> Bool {
        guard score > 0 else { return false }
        guard entries.count == Self.maxEntries, let lowest = entries.last else { return true }
        return score > lowest.score
    }

    /// Adds the score if it qualifies, keeping the list sorted highest first.
    func save(name: String, score: Int) {
        guard qualifies(score) else { return }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanName = trimmed.isEmpty ? Self.defaultName : String(trimmed.prefix(Self.maxNameLength))

        // Insert after any equal scores so earlier entries keep their place.
        let index = entries.firstIndex { $0.score < score } ?? entries.endIndex
        entries.insert(Entry(name: cleanName, score: score), at: index)
        entries = Array(entries.prefix(Self.maxEntries))

        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
