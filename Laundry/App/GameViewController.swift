//
//  GameViewController.swift
//  Laundry
//
//  Created by Kyky on 04/07/26.
//


import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        #if DEBUG
        // The spotlight tutorials are meant to show once ever in production, but that same
        // persisted flag would otherwise make them permanently disappear the moment a developer
        // sees one once — replay them on every debug launch instead.
        TutorialFlag.allCases.forEach { UserDefaults.standard.removeObject(forKey: $0.rawValue) }
        #endif

        if let view = self.view as! SKView? {
            let scene = StartScene(size: CGSize(width: 844, height: 390))
            scene.scaleMode = .aspectFit
            
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
