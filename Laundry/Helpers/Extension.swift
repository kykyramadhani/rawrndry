//
//  Extension.swift
//  TrialRawrndry
//
//  Created by Kyky on 01/07/26.
//


import SpriteKit

extension SKScene {
    func transitionTo(scene: SKScene) {
        scene.scaleMode = .aspectFill
        let transition = SKTransition.push(with: .right, duration: 0.5)
        self.view?.presentScene(scene, transition: transition)
    }

    func createPlaceholderButton(text: String, name: String, position: CGPoint) -> SKLabelNode {
        let btn = SKLabelNode(text: text)
        btn.name = name
        btn.fontSize = 30
        btn.fontColor = .black
        btn.position = position

        let bg = SKSpriteNode(color: .white, size: CGSize(width: 150, height: 60))
        bg.position = CGPoint(x: 0, y: 10)
        bg.zPosition = -1
        btn.addChild(bg)

        return btn
    }
}
