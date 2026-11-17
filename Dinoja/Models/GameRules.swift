//
//  GameRules.swift
//  Dinoja
//
//  Every Dinoja rule lives here. To change how the game plays, edit the values
//  in this file; GameModel, GameScene and the collision setup all read from it.
//  The numbered comments match the rules in the README.
//

import Foundation

struct GameRules: Sendable {
    /// The rules the game ships with.
    static let standard = GameRules()

    // MARK: Controls (rules 1 and 2)

    /// How far a touch must move sideways, in scene points, before it counts as a
    /// swipe (move the dino) instead of a tap (throw a star).
    var swipeThreshold: CGFloat = 12

    // MARK: Ninja stars (rules 3 and 4)

    /// Throw angle above horizontal, toward the side the dino faces. Stars bounce off the side walls.
    var starAngleDegrees: CGFloat = 45
    /// Scene points per second.
    var starSpeed: CGFloat = 900
    /// A new star can't be thrown until one in flight hits something or leaves the screen.
    var maxStarsInFlight = 1

    // MARK: Hearts (rules 5, 11 and 12)

    var maxLives = 3
    /// Lives lost when wasabi lands on the dino.
    var wasabiHitLifeChange = -1
    var redHeartLifeChange = 1
    var blackHeartLifeChange = -1
    /// Seconds after a wasabi hit during which further wasabi passes through.
    var invincibilityDuration: TimeInterval = 1.5

    // MARK: Scoring (rules 6 and 7)

    var sushiPoints = 1
    var comboPoints = 2

    // MARK: Levels (rules 8 and 9)

    var pointsPerLevel = 25
    /// Seconds an item takes to fall the full screen at level 1.
    var startingFallDuration: TimeInterval = 4.5
    /// Each level, items take this fraction of the previous level's fall time.
    var fallDurationPerLevel = 0.85
    /// Items never fall faster than this.
    var minimumFallDuration: TimeInterval = 1.5

    // MARK: Spawning

    /// Average seconds between spawns.
    var spawnInterval: TimeInterval = 1.0
    /// Relative chance of each item spawning (out of 100 here). Items not listed never spawn.
    var spawnWeights: [FallingItem: Int] = [
        .sushi(.ahi): 20,
        .sushi(.avocado): 20,
        .sushi(.salmon): 20,
        .sushi(.combo): 6,
        .wasabi: 24,
        .redHeart: 5,
        .blackHeart: 5,
    ]

    // MARK: Rule logic

    /// Rule 10: wasabi can't be shot; stars pass through it.
    func canBeShot(_ item: FallingItem) -> Bool {
        item != .wasabi
    }

    /// Rules 6 and 7.
    func points(forShooting item: FallingItem) -> Int {
        switch item {
        case .sushi(.combo): comboPoints
        case .sushi: sushiPoints
        case .wasabi, .redHeart, .blackHeart: 0
        }
    }

    /// Rules 11 and 12.
    func lifeChange(forShooting item: FallingItem) -> Int {
        switch item {
        case .redHeart: redHeartLifeChange
        case .blackHeart: blackHeartLifeChange
        case .sushi, .wasabi: 0
        }
    }

    /// Rule 8: level 1 at 0 points, then up one level every `pointsPerLevel` points.
    func level(forScore score: Int) -> Int {
        score / pointsPerLevel + 1
    }

    /// Rule 9: items fall faster each level, down to `minimumFallDuration`.
    func fallDuration(atLevel level: Int) -> TimeInterval {
        let duration = startingFallDuration * pow(fallDurationPerLevel, Double(level - 1))
        return max(duration, minimumFallDuration)
    }

    func spawnWeight(for item: FallingItem) -> Int {
        spawnWeights[item, default: 0]
    }

    /// Picks the next item to spawn, weighted by `spawnWeights`.
    func randomItem(using rng: inout some RandomNumberGenerator) -> FallingItem {
        // Walk `allCases` (not the dictionary) so results are repeatable with a seeded generator.
        let candidates = FallingItem.allCases.filter { spawnWeight(for: $0) > 0 }
        let totalWeight = candidates.reduce(0) { $0 + spawnWeight(for: $1) }
        guard totalWeight > 0 else { return .sushi(.ahi) }

        var roll = Int.random(in: 0..<totalWeight, using: &rng)
        for item in candidates {
            if roll < spawnWeight(for: item) {
                return item
            }
            roll -= spawnWeight(for: item)
        }
        return candidates[candidates.count - 1]
    }

    func randomItem() -> FallingItem {
        var rng = SystemRandomNumberGenerator()
        return randomItem(using: &rng)
    }
}
