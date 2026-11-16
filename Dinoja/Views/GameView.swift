//
//  GameView.swift
//  Dinoja
//
//  Created by John M Cruz on 4/30/23.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    // Stored in @State so the scene is created once instead of on every view update.
    @State private var scene = GameScene.makeScene()

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .onAppear {
                scene.onExit = { dismiss() }
            }
    }
}

#Preview {
    GameView()
}
