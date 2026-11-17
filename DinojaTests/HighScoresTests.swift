//
//  HighScoresTests.swift
//  DinojaTests
//

import Foundation
import Testing
@testable import Dinoja

@MainActor
struct HighScoresTests {
    /// Each test gets its own empty UserDefaults suite so tests don't share saved scores.
    private let defaults: UserDefaults

    init() {
        let suite = "HighScoresTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
    }

    @Test func startsEmpty() {
        let scores = HighScores(defaults: defaults)
        #expect(scores.entries.isEmpty)
    }

    @Test func keepsTheTopFiveHighestFirst() {
        let scores = HighScores(defaults: defaults)
        for (name, score) in [("a", 59), ("b", 273), ("c", 109), ("d", 210), ("e", 189), ("f", 12)] {
            scores.save(name: name, score: score)
        }
        #expect(scores.entries.map(\.score) == [273, 210, 189, 109, 59])
        #expect(scores.entries.map(\.name) == ["b", "d", "e", "c", "a"])
    }

    @Test func aScoreQualifiesUntilTheListIsFull() {
        let scores = HighScores(defaults: defaults)
        #expect(scores.qualifies(1))
        for score in [50, 40, 30, 20, 10] {
            scores.save(name: "x", score: score)
        }
        #expect(scores.qualifies(11))
        #expect(!scores.qualifies(10), "Ties with the lowest score don't push it out")
        #expect(!scores.qualifies(5))
    }

    @Test func zeroNeverQualifies() {
        let scores = HighScores(defaults: defaults)
        #expect(!scores.qualifies(0))
    }

    @Test func savingANonQualifyingScoreChangesNothing() {
        let scores = HighScores(defaults: defaults)
        for score in [50, 40, 30, 20, 10] {
            scores.save(name: "x", score: score)
        }
        scores.save(name: "late", score: 3)
        #expect(!scores.entries.contains { $0.name == "late" })
    }

    @Test func namesAreTrimmedAndBlankNamesGetADefault() {
        let scores = HighScores(defaults: defaults)
        scores.save(name: "  cruz24  ", score: 10)
        scores.save(name: "   ", score: 5)
        #expect(scores.entries.map(\.name) == ["cruz24", HighScores.defaultName])
    }

    @Test func longNamesAreShortened() {
        let scores = HighScores(defaults: defaults)
        scores.save(name: String(repeating: "n", count: 40), score: 10)
        #expect(scores.entries.first?.name.count == HighScores.maxNameLength)
    }

    @Test func scoresPersistAcrossLaunches() {
        HighScores(defaults: defaults).save(name: "nurdy8", score: 210)
        let reloaded = HighScores(defaults: defaults)
        #expect(reloaded.entries == [HighScores.Entry(name: "nurdy8", score: 210)])
    }

    @Test func equalScoresKeepTheEarlierOneFirst() {
        let scores = HighScores(defaults: defaults)
        scores.save(name: "first", score: 100)
        scores.save(name: "second", score: 100)
        #expect(scores.entries.map(\.name) == ["first", "second"])
    }
}
