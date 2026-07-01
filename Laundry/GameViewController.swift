//
//  GameViewController.swift
//  Laundry
//
//  Created by Aulia Agus on 30/06/26.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    private var hasPresentedScene = false

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = self.view as? SKView else { return }
        skView.ignoresSiblingOrder = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // viewDidLoad runs before the view has its final (rotated) frame, so building the
        // scene there can capture a stale portrait size — or even zero — on a locked-landscape
        // app. Presenting here, once, guarantees skView.bounds already reflects the real layout.
        guard !hasPresentedScene,
              let skView = self.view as? SKView,
              skView.bounds.size != .zero else { return }
        hasPresentedScene = true

        let scene = MainMenuScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
