//
//  ContactEventTests.swift
//  DinojaTests
//

import Testing
@testable import Dinoja

struct ContactEventTests {
    @Test func wasabiTouchingTheDinoIsAHit() {
        #expect(ContactEvent(.dino, .wasabi) == .hitByWasabi)
    }

    @Test func starTouchingATargetIsAShot() {
        #expect(ContactEvent(.star, .target) == .shotTarget)
    }

    @Test(arguments: [
        (Collider.dino, Collider.wasabi),
        (.star, .target),
    ])
    func orderDoesNotMatter(a: Collider, b: Collider) {
        #expect(ContactEvent(a, b) == ContactEvent(b, a))
    }

    @Test(arguments: [
        (Collider.star, Collider.wasabi),   // Rule 10: wasabi can't be shot.
        (.dino, .target),                   // Sushi and hearts only count when shot.
        (.dino, .star),
        (.target, .wasabi),
        (.target, .target),
    ])
    func otherPairsAreIgnored(a: Collider, b: Collider) {
        #expect(ContactEvent(a, b) == nil)
    }

    @Test func bitMasksAreUniqueSingleBits() {
        let masks = Collider.allCases.map(\.bitMask)
        #expect(Set(masks).count == masks.count)
        for mask in masks {
            #expect(mask.nonzeroBitCount == 1)
        }
    }

    @Test func colliderRoundTripsThroughItsBitMask() {
        for collider in Collider.allCases {
            #expect(Collider(bitMask: collider.bitMask) == collider)
        }
        #expect(Collider(bitMask: 0) == nil)
    }

    @Test func starsOnlyReportTargetsAndTheDinoOnlyReportsWasabi() {
        #expect(Collider.star.contactTestBitMask == Collider.target.bitMask)
        #expect(Collider.dino.contactTestBitMask == Collider.wasabi.bitMask)
    }

    @Test func wasabiIsItsOwnColliderAndEverythingElseIsATarget() {
        #expect(Collider(for: .wasabi) == .wasabi)
        for item in FallingItem.allCases where item != .wasabi {
            #expect(Collider(for: item) == .target)
        }
    }
}
