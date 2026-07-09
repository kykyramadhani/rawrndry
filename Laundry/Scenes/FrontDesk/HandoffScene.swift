import SpriteKit

/// The bookend to CustomerScene: same customer, same desk, but the player is now
/// handing back the finished laundry instead of receiving a dirty order.
class HandoffScene: SKScene {

    // Core Nodes
    private var customerNode: SKSpriteNode!
    private var packageNode: SKNode!
    private var bubbleContainer: SKNode!
    private var bubbleBg: SKSpriteNode!
    private var bubbleLabel: SKLabelNode!

    // UI Nodes
    private var dayHud: SKSpriteNode!
    private var currencyHud: SKSpriteNode!
    private var instructionBtn: SKSpriteNode!

    private var isHandedOff = false
    private var isDraggingPackage = false
    private var dragOffset = CGPoint.zero
    private var packageOriginalPosition = CGPoint.zero

    private let finalCustomerPosition = CGPoint(x: -0.28, y: -0.22)
    private let finalPackagePosition = CGPoint(x: 0.32, y: -0.18)

    private let plainTextColor = UIColor(red: 255.0/255.0, green: 247.0/255.0, blue: 234.0/255.0, alpha: 1.0)
    private let plainTextBrown = UIColor(red: 143.0/255.0, green: 43.0/255.0, blue: 18.0/255.0, alpha: 1.0)

    private let thankYouTexts = [
        "CLEAN! ME HAPPY!",
        "SO FRESH! THANK YOU!",
        "GOOD JOB! ME PAY!",
        "SMELL NICE! TAKE COIN!"
    ]

    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        setupBackground()
        setupUI()
        setupCustomer()
        setupForeground()
        setupPackage()
        setupSpeechBubble()

        animateArrival()

        AudioManager.shared.stopRiverAmbience()
        AudioManager.shared.playThemeBGM()
    }

    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: AssetName.Background.frontDesk)
        background.size = self.size
        background.position = CGPoint.zero
        background.zPosition = -10
        addChild(background)
    }

    // MARK: - Setup UI Elements
    private func setupUI() {
        let topY = self.size.height * 0.40

        let hud = addCurrencyHUD(
            topLeftOrigin: CGPoint(x: -self.size.width * 0.45, y: topY),
            day: GameState.shared.currentDay,
            coins: GameState.shared.score
        )
        dayHud = hud.day
        currencyHud = hud.gem

        // --- Instruction Button ---
        instructionBtn = SKSpriteNode(imageNamed: AssetName.UI.btnInstruction)
        instructionBtn.setScale(0.8)
        instructionBtn.position = CGPoint(x: self.size.width * 0.35, y: topY)
        instructionBtn.zPosition = 100
        addChild(instructionBtn)

        // No chevrons here — handing off the package is the only action on this screen.

        addSettingsButton()
        addHomeButton()
    }

    private func setupCustomer() {
        // Same customer who dropped the order off at the front desk — carried via GameState
        // since Washing/Drying/Folding only ever pass GameState forward, not the CustomerModel.
        let characterImage = GameState.shared.currentCustomerImage
        let texture = SKTexture(imageNamed: characterImage)
        customerNode = SKSpriteNode(texture: texture)

        let targetWidth: CGFloat = 290.0
        let scaleFactor = targetWidth / texture.size().width
        customerNode.setScale(scaleFactor)

        customerNode.position = CGPoint(x: -self.size.width, y: -self.size.height * 0.22)
        customerNode.zPosition = 0
        addChild(customerNode)
    }

    private func setupForeground() {
        let foreground = SKSpriteNode(imageNamed: AssetName.Item.foregroundDesk)
        foreground.size = self.size
        foreground.position = CGPoint.zero
        // Below the interactive UI (settings button sits at zPosition 10) so it never
        // steals settings-button taps that go through atPoint hit-testing.
        foreground.zPosition = 5
        addChild(foreground)
    }

    /// The same tied leaf-wrap bundle produced at the Folding station.
    private func setupPackage() {
        let packageSize = CGSize(width: 200, height: 200)
        packageOriginalPosition = CGPoint(x: self.size.width * finalPackagePosition.x, y: self.size.height * finalPackagePosition.y)

        packageNode = SKNode()
        packageNode.position = packageOriginalPosition
        packageNode.zPosition = 20
        packageNode.alpha = 0

        // Already sealed by this point (see FoldingScene.completePackaging) — no folded-clothes
        // sprite peeking through, and the front uses the fully-tied state6 art, not state5's
        // rope-ready-but-untied look.

        let front = SKSpriteNode(imageNamed: "frontdeskPackage")
        front.size = packageSize
        front.zPosition = 2
        packageNode.addChild(front)


        addChild(packageNode)
    }

    private func setupSpeechBubble() {
        bubbleContainer = SKNode()
        bubbleContainer.position = CGPoint(x: 100, y: 45)
        bubbleContainer.zPosition = 30
        bubbleContainer.setScale(0)

        bubbleBg = SKSpriteNode(imageNamed: AssetName.UI.speechBubble)
        bubbleBg.size = CGSize(width: 431, height: 81)
        bubbleBg.position = CGPoint.zero
        bubbleContainer.addChild(bubbleBg)

        bubbleLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        bubbleLabel.fontSize = 32
        bubbleLabel.fontColor = plainTextBrown
        bubbleLabel.verticalAlignmentMode = .center
        bubbleLabel.horizontalAlignmentMode = .center
        bubbleLabel.position = CGPoint.zero
        bubbleLabel.zPosition = 1

        bubbleContainer.addChild(bubbleLabel)
        addChild(bubbleContainer)
    }

    /// The customer arrives silently — no speech bubble — and only speaks once the package
    /// is actually handed over (see `completeHandoff`).
    private func animateArrival() {
        let walkIn = SKAction.moveTo(x: self.size.width * finalCustomerPosition.x, duration: 1.0)
        walkIn.timingMode = .easeOut

        let packageAppear = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        let packageDrop = SKAction.moveBy(x: 0, y: -20, duration: 0.2)
        let packageSpawn = SKAction.group([packageAppear, packageDrop])

        customerNode.run(SKAction.sequence([walkIn]))

        let sceneAnimations = SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { self.packageNode.run(packageSpawn) }
        ])

        self.run(sceneAnimations)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if handleSettingsPopupTouchesBegan(at: location) { return }
        if handleTipPopupTap(at: location) { return }
        if handleRewardPopupTap(at: location) { return }
        if handleHomeConfirmPopupTap(at: location) { return }
        if handleSettingsButtonTap(nodeName: tappedNodeName(at: location)) { return }
        if handleHomeButtonTap(nodeName: tappedNodeName(at: location)) { return }

        if instructionBtn.contains(location) {
            runButtonTapAnimation(on: instructionBtn) {
                self.showTipPopup(text: Loc.t(.infoHandoff))
            }
            return
        }

        guard !isHandedOff, packageNode.contains(location) else { return }
        isDraggingPackage = true
        dragOffset = CGPoint(x: packageNode.position.x - location.x, y: packageNode.position.y - location.y)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if handleSettingsPopupTouchesMoved(at: location) { return }

        guard isDraggingPackage else { return }
        packageNode.position = CGPoint(x: location.x + dragOffset.x, y: location.y + dragOffset.y)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if handleSettingsPopupTouchesEnded() { return }

        guard isDraggingPackage else { return }
        isDraggingPackage = false

        let dropZone = customerNode.frame.insetBy(dx: -40, dy: -40)
        if dropZone.contains(packageNode.position) {
            handOffPackage()
        } else {
            packageNode.run(.move(to: packageOriginalPosition, duration: 0.3))
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDraggingPackage else { return }
        isDraggingPackage = false
        packageNode.run(.move(to: packageOriginalPosition, duration: 0.3))
    }

    private func handOffPackage() {
        isHandedOff = true

        packageNode.run(.move(to: customerNode.position, duration: 0.3)) { [weak self] in
            guard let self else { return }
            // The package is now in the customer's hands — make it disappear rather than
            // leaving it sitting on top of them for the rest of the scene.
            self.packageNode.run(.sequence([
                .group([.fadeOut(withDuration: 0.25), .scale(to: 0.6, duration: 0.25)]),
                .removeFromParent()
            ]))
            self.completeHandoff()
        }
    }

    private func completeHandoff() {
        bubbleLabel.text = (thankYouTexts.randomElement() ?? "THANK YOU!").uppercased()

        let popUp = SKAction.scale(to: 1.0, duration: 0.3)
        let popBounce = SKAction.scale(to: 0.95, duration: 0.1)
        bubbleContainer.run(.sequence([popUp, popBounce, SKAction.scale(to: 1.0, duration: 0.1)]))

        calculateCoins()

        run(.sequence([
            .wait(forDuration: 1.0),
            .run { [weak self] in
                guard let self else { return }
                // The reward popup is the end-of-day summary, so only the day's last
                // customer should trigger it — earlier handoffs move straight to the next
                // customer.
                if CustomerManager.shared.remainingCustomersForToday.isEmpty {
                    self.showRewardPopup()
                } else {
                    self.goToNextCustomer()
                }
            }
        ]))
    }

    private func goToNextCustomer() {
        GameState.shared.score += GameState.shared.coinsEarned
        GameState.shared.coinsEarned = 0
        goTo(CustomerScene(size: size))
    }

    private func calculateCoins() {
        // The payout is fixed by the day's level design (see LevelDesign), not derived from
        // clothes count here, so it can't drift from what the front desk quoted the player.
        let base = GameState.shared.currentOrderReward
        let deduction = GameState.shared.tornItemsCount * 50
        GameState.shared.coinsEarned = max(0, base - deduction)
    }

    // MARK: - Reward popup

    private func showRewardPopup() {
        playSound("complete")

        let center = sceneCenter
        let panelSize = CGSize(width: min(size.width * 0.72, 280), height: 300)

        let overlay = SKNode()
        overlay.name = "rewardPopupOverlay"
        overlay.zPosition = 500
        addChild(overlay)

        let panel = SKSpriteNode(imageNamed: AssetName.UI.popUpFrame)
        panel.size = panelSize
        panel.position = center
        overlay.addChild(panel)

        let earned = starCount()
        let offsets: [CGFloat] = [-56, 0, 56]
        for (index, offset) in offsets.enumerated() {
            let star = SKSpriteNode(imageNamed: index < earned ? AssetName.UI.iconStarOn : AssetName.UI.iconStarOff)
            star.size = CGSize(width: 44, height: 44)
            star.position = CGPoint(x: center.x + offset, y: center.y + panelSize.height * 0.38)
            star.zPosition = 1
            overlay.addChild(star)
        }

        let rewardLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        rewardLabel.text = "REWARD"
        rewardLabel.fontSize = 28
        rewardLabel.fontColor = .white
        rewardLabel.verticalAlignmentMode = .center
        rewardLabel.position = CGPoint(x: center.x, y: center.y + panelSize.height * 0.20)
        rewardLabel.zPosition = 1
        overlay.addChild(rewardLabel)

        let amountBg = SKShapeNode(rectOf: CGSize(width: panelSize.width * 0.68, height: 54), cornerRadius: 16)
        amountBg.fillColor = UIColor(red: 1.0, green: 0.796, blue: 0.302, alpha: 1.0)
        amountBg.strokeColor = plainTextBrown
        amountBg.lineWidth = 2
        amountBg.position = CGPoint(x: center.x, y: center.y - 6)
        amountBg.zPosition = 1
        overlay.addChild(amountBg)

        let gemIcon = SKSpriteNode(imageNamed: AssetName.UI.gemIcon)
        gemIcon.position = CGPoint(x: -amountBg.frame.width * 0.28, y: 0)
        gemIcon.zPosition = 1
        amountBg.addChild(gemIcon)

        let amountLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        amountLabel.text = formattedCoins(GameState.shared.coinsEarned)
        amountLabel.fontSize = 26
        amountLabel.fontColor = plainTextBrown
        amountLabel.verticalAlignmentMode = .center
        amountLabel.horizontalAlignmentMode = .left
        amountLabel.position = CGPoint(x: gemIcon.position.x + gemIcon.size.width / 2 + 10, y: 0)
        amountLabel.zPosition = 1
        amountBg.addChild(amountLabel)

        let okButton = SKSpriteNode(imageNamed: "main-button")
        okButton.name = "rewardOk"
        okButton.setScale(1.6)
        okButton.position = CGPoint(x: center.x, y: center.y - panelSize.height * 0.34)
        okButton.zPosition = 1
        overlay.addChild(okButton)

        let okLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        okLabel.text = "OK"
        okLabel.fontSize = 20
        okLabel.fontColor = .white
        okLabel.verticalAlignmentMode = .center
        okLabel.zPosition = 1
        okButton.addChild(okLabel)
    }

    private func handleRewardPopupTap(at location: CGPoint) -> Bool {
        guard let overlay = childNode(withName: "rewardPopupOverlay") else { return false }
        if tappedNodeName(at: location) == "rewardOk" {
            let okButton = overlay.childNode(withName: "rewardOk")
            runButtonTapAnimation(on: okButton ?? overlay) { [weak self] in
                guard let self else { return }
                GameState.shared.score += GameState.shared.coinsEarned
                GameState.shared.coinsEarned = 0

                // The reward popup only shows for the day's last customer (see
                // completeHandoff), so tapping OK here always advances to the next day —
                // StartScene continues into it (or shows "more levels coming soon" once the
                // design table runs out).
                GameState.shared.currentDay += 1
                self.goTo(StartScene(size: self.size))
            }
        }
        return true
    }

    /// Percentage of the maximum possible payout this order could have earned, minus tears.
    private func starCount() -> Int {
        let maxPossible = max(GameState.shared.currentOrderReward, 1)
        let percentage = CGFloat(GameState.shared.coinsEarned) / CGFloat(maxPossible) * 100

        if percentage >= 80 { return 3 }
        if percentage >= 40 { return 2 }
        return 1
    }

    private func formattedCoins(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    private func playSound(_ name: String) {
        AudioManager.shared.playSFX(name)
    }
}
