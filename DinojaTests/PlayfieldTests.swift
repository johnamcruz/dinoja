//
//  PlayfieldTests.swift
//  DinojaTests
//

import CoreGraphics
import Testing
@testable import Dinoja

struct PlayfieldTests {
    private let sceneSize = CGSize(width: 640, height: 1140)

    @Test func tallPhoneCropsTheSides() {
        // 402x874 is narrower than the scene's 640x1140 aspect ratio.
        let field = Playfield(sceneSize: sceneSize, viewSize: CGSize(width: 402, height: 874))
        #expect(field.visibleSize.height == 1140)
        #expect(abs(field.visibleSize.width - 402 * 1140 / 874) < 0.001)
    }

    @Test func wideScreenCropsTopAndBottom() {
        // An iPad-like 4:3 view is wider than the scene.
        let field = Playfield(sceneSize: sceneSize, viewSize: CGSize(width: 1024, height: 1366))
        #expect(field.visibleSize.width == 640)
        #expect(abs(field.visibleSize.height - 1366 * 640 / 1024) < 0.001)
    }

    @Test func zeroViewSizeFallsBackToTheWholeScene() {
        let field = Playfield(sceneSize: sceneSize, viewSize: .zero)
        #expect(field.visibleSize == sceneSize)
    }

    @Test func clampKeepsAnObjectFullyOnScreen() {
        let field = Playfield(sceneSize: sceneSize, viewSize: .zero)
        // Visible x runs from -320 to 320; a 100-wide object's center must stay within ±270.
        #expect(field.clampedX(500, objectWidth: 100) == 270)
        #expect(field.clampedX(-500, objectWidth: 100) == -270)
        #expect(field.clampedX(42, objectWidth: 100) == 42)
    }

    @Test func spawnRangeKeepsItemsFullyOnScreen() {
        let field = Playfield(sceneSize: sceneSize, viewSize: .zero)
        let range = field.spawnXRange(objectWidth: 90)
        #expect(range == -275...275)
    }

    @Test func topAndBottomEdgesAreOffScreenByTheObjectHeight() {
        let field = Playfield(sceneSize: sceneSize, viewSize: .zero)
        let expectedTop: CGFloat = 570 + 90
        #expect(field.spawnY(objectHeight: 90) == expectedTop)
        #expect(field.despawnY(objectHeight: 90) == -expectedTop)
    }
}
