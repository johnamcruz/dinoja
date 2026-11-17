//
//  Images.swift
//  Dinoja
//

import Foundation

enum Images {
    static let background = "background"
    static let gameTitle = "text-dinoja"
    static let startGame = "bttn-startgame"
    static let gameScene = "GameScene"

    // Dino
    static let dinoLeftStand = "dino-left-stand"
    static let dinoLeftWalkA = "dino-left-walk-a"
    static let dinoLeftWalkB = "dino-left-walk-b"
    static let dinoLeftHit = "dino-left-hit"
    static let dinoRightStand = "dino-right-stand"
    static let dinoRightWalkA = "dino-right-walk-a"
    static let dinoRightWalkB = "dino-right-walk-b"
    static let dinoRightHit = "dino-right-hit"

    // Falling items and projectiles
    static let sushiAhi = "sushi-ahi"
    static let sushiAvocado = "sushi-avocado"
    static let sushiSalmon = "sushi-salmon"
    static let sushiCombo = "sushi-combo"
    static let wasabi = "wasabi"
    static let heartRed = "heart-red"
    static let heartBlack = "heart-black"
    static let ninjaStar = "ninja-star"
    static let blastPurple = "blast-purple"
    static let blastRed = "blast-red"

    // HUD and overlays
    static let pauseButton = "bttn-pause"
    static let continueButton = "bttn-continue"
    static let saveButton = "bttn-save"
    static let pauseText = "text-pause"
    static let gameOverText = "text-gameover"

    /// Lives indicator texture, where `count` is the number of filled hearts (0...3).
    static func life(_ count: Int) -> String {
        "life-\(count)"
    }
}
