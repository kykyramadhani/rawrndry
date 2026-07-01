//
//  MainMenuScene.swift
//  Laundry
//
//  Created by Aulia Agus on 01/07/26.
//

import SpriteKit

class MainMenuScene: SKScene {

    private var startButton: SKSpriteNode!
    private var settingsButton: SKSpriteNode!

    override func didMove(to view: SKView) {
        addBackground(imageNamed: "bg-main")
        addBackgroundMusic()

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "Laundry Day"
        title.fontSize = 48
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.85)
        title.zPosition = 10
        addChild(title)

        if GameState.shared.currentDay > 1 {
            let dayLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            dayLabel.text = "Day \(GameState.shared.currentDay)"
            dayLabel.fontSize = 28
            dayLabel.fontColor = .white
            dayLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.77)
            dayLabel.zPosition = 10
            addChild(dayLabel)
        }

        startButton = makeButton(
            imageNamed: "main-button",
            text: "START",
            position: CGPoint(x: size.width / 2, y: size.height / 2),
            nodeName: "start"
        )

        settingsButton = makeButton(
            imageNamed: "icon-settings",
            position: CGPoint(x: size.width - 50, y: size.height - 60),
            scale: 0.5,
            nodeName: "settings"
        )
    }

    private func addBackgroundMusic() {
        let music = SKAudioNode(fileNamed: "bg-music.wav")
        music.name = "bgMusic"
        music.autoplayLooped = true
        addChild(music)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        switch tappedNodeName(at: location) {
        case "start":
            runButtonTapAnimation(on: startButton) {
                self.goTo(CustomerOrderScene(size: self.size))
            }
        case "settings":
            runButtonTapAnimation(on: settingsButton)
        default:
            break
        }
    }
}
