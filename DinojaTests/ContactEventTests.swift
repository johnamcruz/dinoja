//
//  ContactEventTests.swift
//  DinojaTests
//

import Testing
@testable import Dinoja

struct ContactEventTests {
    @Test func dinoAndSushiIsACatch() {
        #expect(ContactEvent(.dino, .sushi) == .caughtSushi)
    }

    @Test func dinoAndWasabiIsAHit() {
        #expect(ContactEvent(.dino, .wasabi) == .hitByWasabi)
    }

    @Test func starAndWasabiIsAShot() {
        #expect(ContactEvent(.star, .wasabi) == .shotWasabi)
    }

    @Test(arguments: [
        (Collider.dino, Collider.sushi),
        (.dino, .wasabi),
        (.star, .wasabi),
    ])
    func orderDoesNotMatter(a: Collider, b: Collider) {
        #expect(ContactEvent(a, b) == ContactEvent(b, a))
    }

    @Test(arguments: [
        (Collider.star, Collider.sushi),
        (.dino, .star),
        (.sushi, .wasabi),
        (.sushi, .sushi),
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

    @Test func eachColliderTestsAgainstWhatItCanHit() {
        #expect(Collider.dino.contactTestBitMask == Collider.sushi.bitMask | Collider.wasabi.bitMask)
        #expect(Collider.star.contactTestBitMask == Collider.wasabi.bitMask)
    }
}
