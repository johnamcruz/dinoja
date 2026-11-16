//
//  GameModel.swift
//  Dinoja
//

import Foundation
import Observation

/// The game's state and rules. `GameScene` reports what happens in play, and
/// SwiftUI reads this model to draw the score, hearts and overlays.
@MainActor
@Observable
final class GameModel {
    enum Phase {
        case playing
        case paused
        case gameOver
    }

    // MARK: Rules

    static let startingLives = 3
    static let sushiPoints = 10
    static let comboPoints = 30
    static let wasabiPoints = 5

    /// Score at which the difficulty stops ramping up.
    static let maxDifficultyScore = 1000

    // MARK: State

    private(set) var score = 0
    private(set) var lives = GameModel.startingLives
    private(set) var phase = Phase.playing

    // MARK: Difficulty

    /// 0 at the start of the game, rising to 1 at `maxDifficultyScore`.
    var difficulty: Double {
        min(Double(score) / Double(Self.maxDifficultyScore), 1)
    }

    /// Chance that a newly spawned item is wasabi instead of sushi.
    var wasabiChance: Double { ramp(easy: 0.15, hard: 0.35) }

    /// Seconds an item takes to fall from the top of the screen to the bottom.
    var fallDuration: TimeInterval { ramp(easy: 4.5, hard: 2.0) }

    /// Average seconds between spawns.
    var spawnInterval: TimeInterval { ramp(easy: 1.1, hard: 0.6) }

    private func ramp(easy: Double, hard: Double) -> Double {
        easy + (hard - easy) * difficulty
    }

    // MARK: Events

    func catchSushi(isCombo: Bool) {
        guard phase == .playing else { return }
        score += isCombo ? Self.comboPoints : Self.sushiPoints
    }

    func destroyWasabi() {
        guard phase == .playing else { return }
        score += Self.wasabiPoints
    }

    /// Removes a life, ending the game when none are left.
    func takeHit() {
        guard phase == .playing else { return }
        lives = max(lives - 1, 0)
        if lives == 0 {
            phase = .gameOver
        }
    }

    func pause() {
        if phase == .playing {
            phase = .paused
        }
    }

    func resume() {
        if phase == .paused {
            phase = .playing
        }
    }
}
