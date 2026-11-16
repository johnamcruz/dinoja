//
//  GameModelTests.swift
//  DinojaTests
//

import Testing
@testable import Dinoja

@MainActor
struct GameModelTests {
    // MARK: Starting state

    @Test func startsPlayingWithFullLivesAndNoScore() {
        let model = GameModel()
        #expect(model.phase == .playing)
        #expect(model.score == 0)
        #expect(model.lives == GameModel.startingLives)
        #expect(!model.isInvincible)
    }

    // MARK: Scoring

    @Test(arguments: [SushiKind.ahi, .avocado, .salmon])
    func regularSushiScoresTenPoints(kind: SushiKind) {
        let model = GameModel()
        model.collect(kind)
        #expect(model.score == 10)
    }

    @Test func comboSushiScoresThirtyPoints() {
        let model = GameModel()
        model.collect(.combo)
        #expect(model.score == 30)
    }

    @Test func shootingWasabiScoresFivePoints() {
        let model = GameModel()
        model.destroyWasabi()
        #expect(model.score == 5)
    }

    @Test func nothingScoresWhilePaused() {
        let model = GameModel()
        model.pause()
        model.collect(.combo)
        model.destroyWasabi()
        #expect(model.score == 0)
    }

    // MARK: Hits and invincibility

    @Test func hitCostsOneLifeAndStartsInvincibility() {
        let model = GameModel()
        model.takeHit()
        #expect(model.lives == GameModel.startingLives - 1)
        #expect(model.isInvincible)
    }

    @Test func hitsAreIgnoredWhileInvincible() {
        let model = GameModel()
        model.takeHit()
        model.takeHit()
        #expect(model.lives == GameModel.startingLives - 1)
    }

    @Test func endingInvincibilityAllowsTheNextHit() {
        let model = GameModel()
        model.takeHit()
        model.endInvincibility()
        model.takeHit()
        #expect(model.lives == GameModel.startingLives - 2)
    }

    @Test func losingTheLastLifeEndsTheGame() {
        let model = GameModel()
        for _ in 0..<GameModel.startingLives {
            model.takeHit()
            model.endInvincibility()
        }
        #expect(model.lives == 0)
        #expect(model.phase == .gameOver)
    }

    @Test func gameOverIsFinal() {
        let model = GameModel()
        for _ in 0..<GameModel.startingLives {
            model.takeHit()
            model.endInvincibility()
        }
        model.resume()
        model.collect(.ahi)
        #expect(model.phase == .gameOver)
        #expect(model.score == 0)
    }

    // MARK: Pause

    @Test func pauseAndResume() {
        let model = GameModel()
        model.pause()
        #expect(model.phase == .paused)
        model.resume()
        #expect(model.phase == .playing)
    }

    // MARK: Difficulty

    @Test func difficultyStartsEasy() {
        let model = GameModel()
        #expect(model.difficulty == 0)
        #expect(model.wasabiChance == 0.15)
        #expect(model.fallDuration == 4.5)
        #expect(model.spawnInterval == 1.1)
    }

    @Test func difficultyMaxesOutAtTheThresholdScore() {
        let model = GameModel()
        // 34 combos = 1020 points, just past the 1000-point threshold.
        for _ in 0..<34 { model.collect(.combo) }
        #expect(model.difficulty == 1)
        #expect(abs(model.wasabiChance - 0.35) < 0.0001)
        #expect(abs(model.fallDuration - 2.0) < 0.0001)
        #expect(abs(model.spawnInterval - 0.6) < 0.0001)
    }

    @Test func difficultyRampsLinearly() {
        let model = GameModel()
        // 500 points = halfway.
        for _ in 0..<50 { model.collect(.ahi) }
        #expect(model.difficulty == 0.5)
        #expect(abs(model.fallDuration - 3.25) < 0.0001)
    }
}
