import SpriteKit

/// Welcome flow shown before Day 1's first customer — three raptor speech-bubble beats
/// introducing the wash → dry → fold loop, then straight into the front desk. StartScene
/// routes here instead of CustomerScene whenever GameState.shared.currentDay == 1.
class OnboardingScene: SKScene {

    private struct Step {
        let text: LocKey
        let buttonLabel: LocKey
    }

    private let steps: [Step] = [
        Step(text: .onboardingStep1, buttonLabel: .ok),
        Step(text: .onboardingStep2, buttonLabel: .ok),
        Step(text: .onboardingStep3, buttonLabel: .start)
    ]

    private var stepIndex = 0

    private var raptor: SKSpriteNode!
    private var bubbleContainer: SKNode!
    private var bubbleLabel: SKLabelNode!
    private var actionButton: SKSpriteNode!
    private var actionLabel: SKLabelNode!

    private let plainTextBrown = UIColor(red: 143.0/255.0, green: 43.0/255.0, blue: 18.0/255.0, alpha: 1.0)

    /// True while a line is still being typed out — gates touchesBegan so a tap fast-forwards
    /// the line instead of hitting the (still-hidden) action button.
    private var isTyping = false
    private var currentFullText = ""

    private let typingActionKey = "onboardingTypewriter"
    private let raptorWiggleKey = "onboardingRaptorWiggle"
    private let secondsPerCharacter: TimeInterval = 0.035

    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        setupBackground()
        setupRaptor()
        setupSpeechBubble()
        setupActionButton()

        showStep(0)

        AudioManager.shared.stopRiverAmbience()
        AudioManager.shared.playThemeBGM()
    }

    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: AssetName.Background.frontDesk)
        background.size = self.size
        background.position = .zero
        background.zPosition = -10
        addChild(background)
    }

    private func setupRaptor() {
        let texture = SKTexture(imageNamed: AssetName.Character.raptor)
        raptor = SKSpriteNode(texture: texture)

        let targetWidth: CGFloat = 320
        raptor.setScale(targetWidth / texture.size().width)
        raptor.position = CGPoint(x: -self.size.width * 0.33, y: -self.size.height * 0.12)
        raptor.zPosition = 5
        addChild(raptor)
    }

    private func setupSpeechBubble() {
        let size = CGSize(width: self.size.width * 0.60, height: self.size.height * 0.28)

        bubbleContainer = SKNode()
        bubbleContainer.position = CGPoint(x: self.size.width * 0.145, y: self.size.height * 0.21)
        bubbleContainer.zPosition = 10
        addChild(bubbleContainer)

        let bubbleBg = SKSpriteNode(imageNamed: AssetName.UI.speechBubble)
        bubbleBg.size = size
        bubbleBg.position = .zero
        bubbleContainer.addChild(bubbleBg)

        bubbleLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        bubbleLabel.fontSize = 24
        bubbleLabel.fontColor = plainTextBrown
        bubbleLabel.numberOfLines = 0
        bubbleLabel.preferredMaxLayoutWidth = size.width * 0.82
        bubbleLabel.verticalAlignmentMode = .center
        bubbleLabel.horizontalAlignmentMode = .center
        bubbleLabel.position = .zero
        bubbleLabel.zPosition = 1
        bubbleContainer.addChild(bubbleLabel)
    }

    private func setupActionButton() {
        actionButton = SKSpriteNode(imageNamed: AssetName.UI.btnSecondary)
        actionButton.name = "onboardingAction"
        actionButton.zPosition = 20
        addChild(actionButton)

        actionLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        actionLabel.fontSize = 20
        actionLabel.verticalAlignmentMode = .center
        actionLabel.zPosition = 1
        actionButton.addChild(actionLabel)
    }

    private func showStep(_ index: Int) {
        stepIndex = index
        let step = steps[index]
        let isLast = index == steps.count - 1

        actionButton.texture = SKTexture(imageNamed: isLast ? AssetName.UI.buttonMain : AssetName.UI.btnSecondary)
        actionButton.size = isLast ? CGSize(width: 150, height: 56) : CGSize(width: 110, height: 48)
        actionButton.position = CGPoint(
            x: self.size.width * 0.145 + self.size.width * 0.30 - actionButton.size.width * 0.3,
            y: self.size.height * 0.21 - self.size.height * 0.14 - actionButton.size.height * 0.5 - 10
        )

        actionLabel.text = Loc.t(step.buttonLabel)
        actionLabel.fontColor = isLast ? .white : .black

        startTyping(Loc.t(step.text).uppercased())
    }

    // MARK: - Typewriter effect

    /// Reveals `text` one character at a time, wiggling the raptor for the duration — the
    /// action button stays hidden until the line finishes, then fades in. Cancel early with
    /// `skipTyping()` (e.g. on tap) to jump straight to the full line.
    private func startTyping(_ text: String) {
        bubbleContainer.removeAction(forKey: typingActionKey)

        currentFullText = text
        isTyping = true
        bubbleLabel.text = ""
        actionButton.alpha = 0

        startRaptorWiggle()

        var typeActions: [SKAction] = []
        for count in 1...max(text.count, 1) {
            typeActions.append(.run { [weak self] in
                guard let self else { return }
                let endIndex = text.index(text.startIndex, offsetBy: count)
                self.bubbleLabel.text = String(text[..<endIndex])
            })
            typeActions.append(.wait(forDuration: secondsPerCharacter))
        }
        typeActions.append(.run { [weak self] in self?.finishTyping() })

        bubbleContainer.run(.sequence(typeActions), withKey: typingActionKey)
    }

    /// Jumps straight to the fully-revealed line — used when the player taps while still typing.
    private func skipTyping() {
        guard isTyping else { return }
        bubbleContainer.removeAction(forKey: typingActionKey)
        finishTyping()
    }

    private func finishTyping() {
        isTyping = false
        bubbleLabel.text = currentFullText
        stopRaptorWiggle()
        actionButton.run(.fadeIn(withDuration: 0.2))
    }

    private func startRaptorWiggle() {
        raptor.removeAction(forKey: raptorWiggleKey)
        let tiltLeft = SKAction.rotate(toAngle: -0.05, duration: 0.12, shortestUnitArc: true)
        let tiltRight = SKAction.rotate(toAngle: 0.05, duration: 0.12, shortestUnitArc: true)
        let wiggle = SKAction.sequence([tiltLeft, tiltRight])
        raptor.run(.repeatForever(wiggle), withKey: raptorWiggleKey)
    }

    private func stopRaptorWiggle() {
        raptor.removeAction(forKey: raptorWiggleKey)
        raptor.run(.rotate(toAngle: 0, duration: 0.1))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if isTyping {
            skipTyping()
            return
        }

        guard tappedNodeName(at: location) == "onboardingAction" else { return }

        self.isUserInteractionEnabled = false
        runButtonTapAnimation(on: actionButton) {
            self.isUserInteractionEnabled = true
            self.advance()
        }
    }

    private func advance() {
        if stepIndex < steps.count - 1 {
            showStep(stepIndex + 1)
        } else {
            goTo(CustomerScene(size: self.size))
        }
    }
}
