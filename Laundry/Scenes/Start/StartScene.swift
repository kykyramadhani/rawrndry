import SpriteKit

class StartScene: SKScene {

    /// Whether there's a designed day to play — false once the player has cleared every
    /// day LevelDesign currently defines.
    private var hasMoreLevels: Bool { LevelDesign.config(forDay: GameState.shared.currentDay) != nil }

    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        setupBackground()
        if hasMoreLevels {
            setupStartButton()
        } else {
            setupComingSoon()
        }
        addSettingsButton()

        AudioManager.shared.stopRiverAmbience()
        AudioManager.shared.playThemeBGM()
    }

    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: "startBackground")
        background.size = self.size
        background.position = CGPoint.zero
        background.zPosition = -1
        addChild(background)
    }

    private func setupStartButton() {
        let button = SKSpriteNode(imageNamed: "btnMain")
        button.name = "startButton"
        button.setScale(1.0)
        button.position = CGPoint(x: 0, y: -self.size.height * 0.3)
        button.zPosition = 1

        let startLabel = SKLabelNode(text: GameState.shared.currentDay == 1 ? "START" : "CONTINUE")
        startLabel.fontName = "ValdursansComicaNo1-Regular"

        startLabel.fontSize = 35
        startLabel.fontColor = .white
        startLabel.verticalAlignmentMode = .center
        startLabel.position = CGPoint(x: 0, y: 0)
        startLabel.zPosition = 2

        button.addChild(startLabel)
        addChild(button)
    }

    /// Shown once the player has cleared every day LevelDesign currently defines — no more
    /// designed content exists, so offer a fresh run instead of a dead-end START button.
    private func setupComingSoon() {
        let messageLabel = SKLabelNode(text: "MORE LEVELS COMING SOON!")
        messageLabel.fontName = "ValdursansComicaNo1-Regular"
        messageLabel.fontSize = 28
        messageLabel.fontColor = .white
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = self.size.width * 0.8
        messageLabel.verticalAlignmentMode = .center
        messageLabel.position = CGPoint(x: 0, y: -self.size.height * 0.15)
        messageLabel.zPosition = 2
        addChild(messageLabel)

        let button = SKSpriteNode(imageNamed: "btnMain")
        button.name = "newGameButton"
        button.setScale(1.0)
        button.position = CGPoint(x: 0, y: -self.size.height * 0.3)
        button.zPosition = 1

        let newGameLabel = SKLabelNode(text: "START NEW GAME")
        newGameLabel.fontName = "ValdursansComicaNo1-Regular"
        newGameLabel.fontSize = 22
        newGameLabel.fontColor = .white
        newGameLabel.verticalAlignmentMode = .center
        newGameLabel.position = CGPoint(x: 0, y: 0)
        newGameLabel.zPosition = 2

        button.addChild(newGameLabel)
        addChild(button)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if handleSettingsPopupTouchesBegan(at: location) { return }
        if handleSettingsButtonTap(nodeName: tappedNodeName(at: location)) { return }

        let nodes = self.nodes(at: location)

        for node in nodes {
            if node.name == "startButton" {
                animateButtonThenStart(node: node)
                break
            } else if node.parent?.name == "startButton" {
                animateButtonThenStart(node: node.parent!)
                break
            } else if node.name == "newGameButton" {
                animateButtonThenStartNewGame(node: node)
                break
            } else if node.parent?.name == "newGameButton" {
                animateButtonThenStartNewGame(node: node.parent!)
                break
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        _ = handleSettingsPopupTouchesMoved(at: touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        _ = handleSettingsPopupTouchesEnded()
    }
    
    private func animateButtonThenStart(node: SKNode) {
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)

        node.run(SKAction.sequence([scaleDown, scaleUp])) {
            self.goToGameScene()
        }
    }

    /// Wipes all progress (day, score, in-flight order) and starts a fresh run from Day 1 —
    /// only reachable once the player has cleared every day LevelDesign currently defines.
    private func animateButtonThenStartNewGame(node: SKNode) {
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)

        node.run(SKAction.sequence([scaleDown, scaleUp])) {
            GameState.shared.resetAll()
            CustomerManager.shared.remainingCustomersForToday.removeAll()
            self.goToGameScene()
        }
    }

    /// Day 1's first customer is always preceded by the raptor's onboarding intro; every
    /// later day (or a resumed Day 1 after it's already begun) skips straight to the front desk.
    private func goToGameScene() {
        let nextScene: SKScene = GameState.shared.currentDay == 1
            ? OnboardingScene(size: self.size)
            : CustomerScene(size: self.size)
        nextScene.scaleMode = .aspectFit

        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(nextScene, transition: transition)
    }
}
