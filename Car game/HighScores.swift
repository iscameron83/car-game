//
//  HighScores.swift
//  Car game — persistent top-5 leaderboard
//

import Foundation

struct HighScoreStore {

    struct Entry: Codable {
        let name: String
        let score: Int
    }

    // v2: bumped to wipe the board clean; old "highScores" data is ignored
    private static let key         = "highScores.v2"
    private static let lastNameKey = "lastPlayerName"
    static let maxEntries          = 5
    static let maxNameLength       = 6

    static func load() -> [Entry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([Entry].self, from: data)
        else { return [] }
        return entries
    }

    static func qualifies(_ score: Int) -> Bool {
        guard score > 0 else { return false }
        let entries = load()
        return entries.count < maxEntries || score > entries.last!.score
    }

    /// Saves the entry (name trimmed to 6 chars, uppercased) and returns the new list.
    @discardableResult
    static func add(name: String, score: Int) -> [Entry] {
        let clean = String(name.trimmingCharacters(in: .whitespaces)
                               .prefix(maxNameLength)).uppercased()
        let final = clean.isEmpty ? "RIDER" : clean
        var entries = load()
        entries.append(Entry(name: final, score: score))
        entries.sort { $0.score > $1.score }
        entries = Array(entries.prefix(maxEntries))
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
        UserDefaults.standard.set(final, forKey: lastNameKey)
        return entries
    }

    static var lastName: String {
        UserDefaults.standard.string(forKey: lastNameKey) ?? ""
    }
}
