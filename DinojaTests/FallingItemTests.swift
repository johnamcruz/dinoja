//
//  FallingItemTests.swift
//  DinojaTests
//

import Testing
@testable import Dinoja

struct FallingItemTests {
    @Test func imageNamesMatchTheAssets() {
        #expect(FallingItem.wasabi.imageName == Images.wasabi)
        #expect(FallingItem.redHeart.imageName == Images.heartRed)
        #expect(FallingItem.blackHeart.imageName == Images.heartBlack)
        #expect(FallingItem.sushi(.ahi).imageName == Images.sushiAhi)
        #expect(FallingItem.sushi(.avocado).imageName == Images.sushiAvocado)
        #expect(FallingItem.sushi(.salmon).imageName == Images.sushiSalmon)
        #expect(FallingItem.sushi(.combo).imageName == Images.sushiCombo)
    }

    @Test func redHeartGetsARedSplatAndEverythingElseAPurpleOne() {
        // Matches the item legend in the design sheet.
        #expect(FallingItem.redHeart.shotBlastImageName == Images.blastRed)
        for item in FallingItem.allCases where item != .redHeart {
            #expect(item.shotBlastImageName == Images.blastPurple)
        }
    }

    @Test func itemsRoundTripThroughTheirImageName() {
        for item in FallingItem.allCases {
            #expect(FallingItem(imageName: item.imageName) == item)
        }
        #expect(FallingItem(imageName: "not-an-item") == nil)
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
