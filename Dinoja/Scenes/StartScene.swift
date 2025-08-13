//
//  StartScene.swift
//  Dinoja
//
//  Created by John M Cruz on 4/30/23.
//

import SpriteKit

class StartScene: SKScene {
    override func didMove(to view: SKView) {
        createBackground()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    func createBackground() {
        let background = SKSpriteNode(imageNamed: Images.background)
        background.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        addChild(background)
    }
}
