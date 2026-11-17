//
//  GameModelTests.swift
//  DinojaTests
//

import Testing
@testable import Dinoja

@MainActor
struct GameModelTests {
    // MARK: Starting state

    @Test func startsPlayingAtLevelOneWithThreeHearts() {
        let model = GameModel()
        #expect(model.phase == .playing)
        #expect(model.score == 0)
        #expect(model.level == 1)
        #expect(model.lives == 3)
        #expect(!model.isInvincible)
        #expect(!model.isStarInFlight)
    }

    // MARK: Rule 4: one ninja star at a time

    @Test func throwingAStarSucceedsWhenNoneIsInFlight() {
        let model = GameModel()
        #expect(model.throwStar())
        #expect(model.isStarInFlight)
    }

    @Test func cannotThrowASecondStarWhileOneIsInFlight() {
        let model = GameModel()
        model.throwStar()
        #expect(!model.throwStar())
    }

    @Test func canThrowAgainOnceTheStarIsDone() {
        let model = GameModel()
        model.throwStar()
        model.starFinished()
        #expect(!model.isStarInFlight)
        #expect(model.throwStar())
    }

    @Test func cannotThrowWhilePaused() {
        let model = GameModel()
        model.pause()
        #expect(!model.throwStar())
    }

    // MARK: Rules 6 and 7: shooting sushi

    @Test(arguments: [SushiKind.ahi, .avocado, .salmon])
    func shootingSushiScoresOnePoint(kind: SushiKind) {
        let model = GameModel()
        model.shoot(.sushi(kind))
        #expect(model.score == 1)
    }

    @Test func shootingComboSushiScoresTwoPoints() {
        let model = GameModel()
        model.shoot(.sushi(.combo))
        #expect(model.score == 2)
    }

    // MARK: Rule 10: wasabi can't be shot

    @Test func shootingWasabiDoesNothing() {
        let model = GameModel()
        model.shoot(.wasabi)
        #expect(model.score == 0)
        #expect(model.lives == 3)
    }

    // MARK: Rule 5: three hits and the game is over

    @Test func wasabiHitCostsOneHeartAndStartsInvincibility() {
        let model = GameModel()
        model.takeHit()
        #expect(model.lives == 2)
        #expect(model.isInvincible)
    }

    @Test func hitsAreIgnoredWhileInvincible() {
        let model = GameModel()
        model.takeHit()
        model.takeHit()
        #expect(model.lives == 2)
    }

    @Test func threeHitsEndTheGame() {
        let model = GameModel()
        for _ in 0..<3 {
            model.takeHit()
            model.endInvincibility()
        }
        #expect(model.lives == 0)
        #expect(model.phase == .gameOver)
    }

    // MARK: Rules 11 and 12: hearts

    @Test func shootingARedHeartAddsALife() {
        let model = GameModel()
        model.takeHit()
        model.shoot(.redHeart)
        #expect(model.lives == 3)
    }

    @Test func livesNeverExceedThree() {
        let model = GameModel()
        model.shoot(.redHeart)
        #expect(model.lives == model.rules.maxLives)
    }

    @Test func shootingABlackHeartCostsALife() {
        let model = GameModel()
        model.shoot(.blackHeart)
        #expect(model.lives == 2)
    }

    @Test func blackHeartCostsALifeEvenWhileInvincible() {
        // Invincibility protects against wasabi hits, not against your own shots.
        let model = GameModel()
        model.takeHit()
        model.shoot(.blackHeart)
        #expect(model.lives == 1)
    }

    @Test func blackHeartOnTheLastLifeEndsTheGame() {
        let model = GameModel()
        model.shoot(.blackHeart)
        model.shoot(.blackHeart)
        model.shoot(.blackHeart)
        #expect(model.phase == .gameOver)
    }

    @Test func heartsDoNotScore() {
        let model = GameModel()
        model.shoot(.redHeart)
        model.shoot(.blackHeart)
        #expect(model.score == 0)
    }

    // MARK: Rules 8 and 9: levels and speed

    @Test(arguments: [(0, 1), (24, 1), (25, 2), (49, 2), (50, 3), (100, 5)])
    func levelGoesUpEveryTwentyFivePoints(score: Int, level: Int) {
        let model = GameModel()
        for _ in 0..<score { model.shoot(.sushi(.ahi)) }
        #expect(model.level == level)
    }

    @Test func itemsFallFasterEachLevel() {
        let model = GameModel()
        var previous = model.fallDuration
        for _ in 0..<5 {
            for _ in 0..<25 { model.shoot(.sushi(.ahi)) }
            #expect(model.fallDuration < previous)
            previous = model.fallDuration
        }
    }

    @Test func fallSpeedHasAFloor() {
        let model = GameModel()
        for _ in 0..<2_000 { model.shoot(.sushi(.ahi)) }
        #expect(model.fallDuration == model.rules.minimumFallDuration)
    }

    // MARK: Custom rules

    @Test func modelFollowsTheRulesItIsGiven() {
        var rules = GameRules.standard
        rules.maxLives = 5
        rules.pointsPerLevel = 2
        rules.sushiPoints = 2
        let model = GameModel(rules: rules)
        #expect(model.lives == 5)
        model.shoot(.sushi(.ahi))
        #expect(model.score == 2)
        #expect(model.level == 2)
    }

    // MARK: Pause and game over

    @Test func nothingHappensWhilePaused() {
        let model = GameModel()
        model.pause()
        model.shoot(.sushi(.combo))
        model.takeHit()
        #expect(model.score == 0)
        #expect(model.lives == 3)
    }

    @Test func pauseAndResume() {
        let model = GameModel()
        model.pause()
        #expect(model.phase == .paused)
        model.resume()
        #expect(model.phase == .playing)
    }

    @Test func gameOverIsFinal() {
        let model = GameModel()
        for _ in 0..<3 { model.shoot(.blackHeart) }
        model.resume()
        model.shoot(.sushi(.ahi))
        #expect(model.phase == .gameOver)
        #expect(model.score == 0)
        #expect(!model.throwStar())
    }
}
