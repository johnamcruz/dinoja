//
//  FallingItemTests.swift
//  DinojaTests
//

import Testing
@testable import Dinoja

struct FallingItemTests {
    @Test func imageNamesMatchTheAssets() {
        #expect(FallingItem.wasabi.imageName == Images.wasabi)
        #expect(FallingItem.sushi(.ahi).imageName == Images.sushiAhi)
        #expect(FallingItem.sushi(.avocado).imageName == Images.sushiAvocado)
        #expect(FallingItem.sushi(.salmon).imageName == Images.sushiSalmon)
        #expect(FallingItem.sushi(.combo).imageName == Images.sushiCombo)
    }

    @Test func itemsRoundTripThroughTheirImageName() {
        let all: [FallingItem] = [.wasabi] + SushiKind.allCases.map { .sushi($0) }
        for item in all {
            #expect(FallingItem(imageName: item.imageName) == item)
        }
        #expect(FallingItem(imageName: "not-an-item") == nil)
    }

    @Test func zeroWasabiChanceNeverSpawnsWasabi() {
        var rng = SeededGenerator(seed: 1)
        for _ in 0..<500 {
            #expect(FallingItem.random(wasabiChance: 0, using: &rng) != .wasabi)
        }
    }

    @Test func fullWasabiChanceAlwaysSpawnsWasabi() {
        var rng = SeededGenerator(seed: 2)
        for _ in 0..<500 {
            #expect(FallingItem.random(wasabiChance: 1, using: &rng) == .wasabi)
        }
    }

    @Test func wasabiShareTracksTheChance() {
        var rng = SeededGenerator(seed: 3)
        let count = 10_000
        let wasabi = (0..<count).filter { _ in
            FallingItem.random(wasabiChance: 0.25, using: &rng) == .wasabi
        }.count
        #expect(abs(Double(wasabi) / Double(count) - 0.25) < 0.02)
    }

    @Test func comboIsRarerThanOtherSushi() {
        var rng = SeededGenerator(seed: 4)
        var counts: [SushiKind: Int] = [:]
        for _ in 0..<14_000 {
            if case .sushi(let kind) = FallingItem.random(wasabiChance: 0, using: &rng) {
                counts[kind, default: 0] += 1
            }
        }
        // Each regular kind is twice as likely as the combo.
        let combo = counts[.combo, default: 0]
        for kind in [SushiKind.ahi, .avocado, .salmon] {
            #expect(counts[kind, default: 0] > combo * 3 / 2)
        }
        #expect(combo > 0)
    }
}

/// A small deterministic random number generator (SplitMix64) so tests are repeatable.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
