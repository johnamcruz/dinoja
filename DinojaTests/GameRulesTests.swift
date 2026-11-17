//
//  GameRulesTests.swift
//  DinojaTests
//
//  Every game rule lives in GameRules. These tests pin the standard rules,
//  numbered as in the README.
//

import Foundation
import Testing
@testable import Dinoja

struct GameRulesTests {
    private let rules = GameRules.standard

    // MARK: Rule 3: 45° throws

    @Test func starsAreThrownAtFortyFiveDegrees() {
        #expect(rules.starAngleDegrees == 45)
    }

    // MARK: Rule 4: one star at a time

    @Test func onlyOneStarCanBeInFlight() {
        #expect(rules.maxStarsInFlight == 1)
    }

    // MARK: Rule 5: three hearts

    @Test func dinoHasThreeHearts() {
        #expect(rules.maxLives == 3)
    }

    @Test func wasabiCostsOneHeart() {
        #expect(rules.wasabiHitLifeChange == -1)
    }

    // MARK: Rules 6 and 7: points

    @Test(arguments: [SushiKind.ahi, .avocado, .salmon])
    func sushiIsWorthOnePoint(kind: SushiKind) {
        #expect(rules.points(forShooting: .sushi(kind)) == 1)
    }

    @Test func comboSushiIsWorthTwoPoints() {
        #expect(rules.points(forShooting: .sushi(.combo)) == 2)
    }

    @Test(arguments: [FallingItem.wasabi, .redHeart, .blackHeart])
    func onlySushiScores(item: FallingItem) {
        #expect(rules.points(forShooting: item) == 0)
    }

    // MARK: Rules 8 and 9: levels and speed

    @Test(arguments: [(0, 1), (24, 1), (25, 2), (49, 2), (50, 3), (250, 11)])
    func levelUpEveryTwentyFivePoints(score: Int, level: Int) {
        #expect(rules.level(forScore: score) == level)
    }

    @Test func eachLevelFallsFaster() {
        for level in 1..<10 {
            #expect(rules.fallDuration(atLevel: level + 1) < rules.fallDuration(atLevel: level)
                    || rules.fallDuration(atLevel: level + 1) == rules.minimumFallDuration)
        }
        #expect(rules.fallDuration(atLevel: 2) < rules.fallDuration(atLevel: 1))
    }

    @Test func levelOneUsesTheStartingFallDuration() {
        #expect(rules.fallDuration(atLevel: 1) == rules.startingFallDuration)
    }

    @Test func fallSpeedHasAFloor() {
        #expect(rules.fallDuration(atLevel: 1_000) == rules.minimumFallDuration)
    }

    // MARK: Rule 10: wasabi can't be shot

    @Test func wasabiCannotBeShot() {
        #expect(!rules.canBeShot(.wasabi))
    }

    @Test func everythingElseCanBeShot() {
        for item in FallingItem.allCases where item != .wasabi {
            #expect(rules.canBeShot(item))
        }
    }

    // MARK: Rules 11 and 12: hearts

    @Test func redHeartIsPlusOneLife() {
        #expect(rules.lifeChange(forShooting: .redHeart) == 1)
    }

    @Test func blackHeartIsMinusOneLife() {
        #expect(rules.lifeChange(forShooting: .blackHeart) == -1)
    }

    @Test(arguments: SushiKind.allCases.map { FallingItem.sushi($0) } + [.wasabi])
    func otherItemsDoNotChangeLives(item: FallingItem) {
        #expect(rules.lifeChange(forShooting: item) == 0)
    }

    // MARK: Spawning

    @Test func everyItemCanSpawn() {
        for item in FallingItem.allCases {
            #expect(rules.spawnWeight(for: item) > 0, "\(item) never spawns")
        }
    }

    @Test func sushiIsMostCommonAndHeartsAreRare() {
        let sushi = SushiKind.allCases.map { rules.spawnWeight(for: .sushi($0)) }.reduce(0, +)
        #expect(sushi > rules.spawnWeight(for: .wasabi))
        #expect(rules.spawnWeight(for: .redHeart) < rules.spawnWeight(for: .wasabi))
        #expect(rules.spawnWeight(for: .blackHeart) < rules.spawnWeight(for: .wasabi))
        #expect(rules.spawnWeight(for: .sushi(.combo)) < rules.spawnWeight(for: .sushi(.ahi)))
    }

    @Test func randomItemsFollowTheSpawnWeights() {
        var rng = SeededGenerator(seed: 7)
        let draws = 20_000
        var counts: [FallingItem: Int] = [:]
        for _ in 0..<draws {
            counts[rules.randomItem(using: &rng), default: 0] += 1
        }
        let total = Double(FallingItem.allCases.map { rules.spawnWeight(for: $0) }.reduce(0, +))
        for item in FallingItem.allCases {
            let expected = Double(rules.spawnWeight(for: item)) / total
            let actual = Double(counts[item, default: 0]) / Double(draws)
            #expect(abs(actual - expected) < 0.015, "\(item) appeared \(actual), expected \(expected)")
        }
    }

    @Test func zeroWeightItemsNeverSpawn() {
        var custom = GameRules.standard
        custom.spawnWeights = [.wasabi: 1]
        var rng = SeededGenerator(seed: 9)
        for _ in 0..<200 {
            #expect(custom.randomItem(using: &rng) == .wasabi)
        }
    }

    // MARK: Customizing

    @Test func rulesCanBeCustomized() {
        var custom = GameRules.standard
        custom.pointsPerLevel = 10
        custom.comboPoints = 5
        #expect(custom.level(forScore: 10) == 2)
        #expect(custom.points(forShooting: .sushi(.combo)) == 5)
        // The standard rules are unaffected.
        #expect(GameRules.standard.pointsPerLevel == 25)
    }
}
