//
//  DinoPoseTests.swift
//  DinojaTests
//
//  The dino art from the design sheet: standing, two walking frames and hit,
//  for each direction. In the "left" art the dino faces left and holds the star
//  in its left hand; the "right" art mirrors that.
//

import Testing
@testable import Dinoja

struct DinoPoseTests {
    @Test func standingUsesTheStandingArtForEachDirection() {
        #expect(DinoPose.standing(.left).imageName == Images.dinoLeftStand)
        #expect(DinoPose.standing(.right).imageName == Images.dinoRightStand)
    }

    @Test func hitUsesTheHitArtForEachDirection() {
        #expect(DinoPose.hit(.left).imageName == Images.dinoLeftHit)
        #expect(DinoPose.hit(.right).imageName == Images.dinoRightHit)
    }

    @Test func walkingAlternatesTheTwoWalkFrames() {
        #expect(DinoPose.walkCycle(.left).map(\.imageName) == [Images.dinoLeftWalkA, Images.dinoLeftWalkB])
        #expect(DinoPose.walkCycle(.right).map(\.imageName) == [Images.dinoRightWalkA, Images.dinoRightWalkB])
    }

    @Test(arguments: [Facing.left, .right])
    func everyPoseKeepsItsDirection(facing: Facing) {
        let poses = [DinoPose.standing(facing), .hit(facing)] + DinoPose.walkCycle(facing)
        for pose in poses {
            #expect(pose.facing == facing)
        }
    }

    @Test func facingComesFromTheSwipeDirection() {
        #expect(Facing(swipe: 30) == .right)
        #expect(Facing(swipe: -30) == .left)
        #expect(Facing(swipe: 0) == nil)
    }

    @Test func starsLeaveFromTheHandOnTheFacingSide() {
        #expect(Facing.right.sign == 1)
        #expect(Facing.left.sign == -1)
    }
}
