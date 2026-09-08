import SpriteKit

class StartScene: SKScene {

    private var hasProgressToReset: Bool {
        GameState.shared.currentDay > 1 || GameState.shared.score > 0
    }
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        setupBackground()
        setupStartButton()
        if hasProgressToReset {
            setupNewGameButton()
        }
        addSettingsButton()
        addShopButton(at: CGPoint(x: -size.width * 0.40, y: size.height * 0.40))

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

        let startText = GameState.shared.currentDay == 1
            ? Loc.t(.start)
            : String(format: Loc.t(.startContinueDay), GameState.shared.currentDay)
        let startLabel = SKLabelNode(text: startText)
        startLabel.fontName = "ValdursansComicaNo1-Regular"
        startLabel.fontSize = 35
        startLabel.fontColor = .white
        startLabel.verticalAlignmentMode = .center
        startLabel.position = CGPoint(x: 0, y: 0)
        startLabel.zPosition = 2

        button.addChild(startLabel)
        addChild(button)
    }

    // Secondary button lets the player wipe progress and begin again voluntarily.
    private func setupNewGameButton() {
        let button = SKSpriteNode(imageNamed: AssetName.UI.btnStartNew)
        button.name = "newGameButton"
        button.position = CGPoint(x: 0, y: -self.size.height * 0.42)
        button.zPosition = 1
        button.size = CGSize(width: 174, height: 39)
        button.setScale(0.85)

        let newGameLabel = SKLabelNode(text: Loc.t(.startNewGame))
        newGameLabel.fontName = "ValdursansComicaNo1-Regular"
        newGameLabel.fontSize = 20
        newGameLabel.fontColor = .white
        newGameLabel.verticalAlignmentMode = .center
        newGameLabel.position = CGPoint(x: 0, y: 0)
        newGameLabel.zPosition = 2

        button.addChild(newGameLabel)
        addChild(button)
    }

    // MARK: - New game confirm popup

    private func showNewGameConfirmPopup() {
        childNode(withName: "newGameConfirmOverlay")?.removeFromParent()

        let center = sceneCenter
        let panelSize = CGSize(width: 348, height: 251)

        let overlay = SKNode()
        overlay.name = "newGameConfirmOverlay"
        overlay.zPosition = 600
        addChild(overlay)

        let panel = SKSpriteNode(imageNamed: AssetName.UI.popUpFrame)
        panel.size = panelSize
        panel.position = center
        overlay.addChild(panel)

        let label = SKLabelNode(fontNamed: AssetName.Font.comica)
        label.text = Loc.t(.newGameConfirmMessage).uppercased()
        label.fontSize = 20
        label.fontColor = .white
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = panelSize.width * 0.82
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: center.x, y: center.y + 30)
        label.zPosition = 1
        overlay.addChild(label)

        let buttonSpacing: CGFloat = 120
        let buttonY = center.y - panelSize.height * 0.28

        // Left: Cancel
        let cancelButton = makeConfirmButton(
            imageNamed: AssetName.UI.btnCancelGray,
            text: Loc.t(.cancel),
            textColor: .white,
            nodeName: "newGameConfirmCancel",
            position: CGPoint(x: center.x - buttonSpacing / 2, y: buttonY)
        )
        overlay.addChild(cancelButton)

        // Right: Start Over
        let startOverButton = makeConfirmButton(
            imageNamed: AssetName.UI.btnStartOver,
            text: Loc.t(.startOver),
            textColor: .white,
            nodeName: "newGameConfirmYes",
            position: CGPoint(x: center.x + buttonSpacing / 2, y: buttonY)
        )
        overlay.addChild(startOverButton)
    }

    private func makeConfirmButton(imageNamed name: String, text: String, textColor: SKColor, nodeName: String, position: CGPoint) -> SKSpriteNode {
        let button = SKSpriteNode(imageNamed: name)
        button.name = nodeName
        button.position = position
        button.zPosition = 1

        let label = SKLabelNode(fontNamed: AssetName.Font.comica)
        label.text = text
        label.fontSize = 18
        label.fontColor = textColor
        label.verticalAlignmentMode = .center
        label.zPosition = 1
        button.addChild(label)

        return button
    }

    private func handleNewGameConfirmPopupTap(at location: CGPoint) -> Bool {
        guard let overlay = childNode(withName: "newGameConfirmOverlay") else { return false }
        let name = tappedNodeName(at: location)

        if name == "newGameConfirmCancel" {
            overlay.removeFromParent()
            return true
        }

        if name == "newGameConfirmYes" {
            GameState.shared.resetAll()
            CustomerManager.shared.remainingCustomersForToday.removeAll()
            overlay.removeFromParent()
            goToGameScene()
            return true
        }

        // Tap anywhere else inside the popup just swallows the touch, same convention
        // as showTipPopup / showHomeConfirmPopup.
        return true
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if handleSettingsPopupTouchesBegan(at: location) { return }
        if handleShopPopupTap(at: location) { return }
        if handleNewGameConfirmPopupTap(at: location) { return }
        if handleSettingsButtonTap(nodeName: tappedNodeName(at: location)) { return }
        if handleShopButtonTap(nodeName: tappedNodeName(at: location)) { return }

        let nodes = self.nodes(at: location)

        for node in nodes {
            if node.name == "startButton" {
                animateButtonThenStart(node: node)
                break
            } else if node.parent?.name == "startButton" {
                animateButtonThenStart(node: node.parent!)
                break
            } else if node.name == "newGameButton" {
                runButtonTapAnimation(on: node) { self.showNewGameConfirmPopup() }
                break
            } else if node.parent?.name == "newGameButton" {
                runButtonTapAnimation(on: node.parent!) { self.showNewGameConfirmPopup() }
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

    /// The raptor's intro plays once per save, not once per Day 1 — gating it on the day
    /// meant it replayed every launch, since nothing was persisting the day in the first place.
    private func goToGameScene() {
        let hasSeenIntro = UserDefaults.standard.bool(forKey: TutorialFlag.onboarding.rawValue)
        let nextScene: SKScene = hasSeenIntro
            ? CustomerScene(size: self.size)
            : OnboardingScene(size: self.size)
        nextScene.scaleMode = .aspectFit

        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(nextScene, transition: transition)
    }
}
