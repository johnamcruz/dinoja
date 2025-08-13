//
//  GameView.swift
//  Dinoja
//
//  Created by John M Cruz on 4/30/23.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    var scene: SKScene {
        let scene = SKScene(fileNamed: Images.gameScene)!
        scene.size = CGSize(width: 640, height: 1140)
        scene.scaleMode = .aspectFill
        return scene
    }
    
    var body: some View {
        SpriteView(scene: scene)
            .frame(minWidth: 0,
                   maxWidth: .infinity,
                   minHeight: 0,
                   maxHeight: .infinity)
            .ignoresSafeArea()
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
