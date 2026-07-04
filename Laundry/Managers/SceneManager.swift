//
//  SceneManager.swift
//  TrialRawrndry
//
//  Created by Kyky on 01/07/26.
//


import SpriteKit

class SceneManager {
    static let shared = SceneManager()
    
    private init() {}
    
    func transition(to scene: SKScene, from view: SKView?, transitionType: SKTransition = .fade(withDuration: 0.5)) {
        guard let view = view else { return }
        
        scene.scaleMode = .aspectFit
        view.presentScene(scene, transition: transitionType)
    }
}
