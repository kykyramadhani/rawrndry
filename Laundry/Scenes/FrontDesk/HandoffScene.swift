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

    private let thankYouTexts: [LocKey] = [
        .handoffThankYouClean,
        .handoffThankYouFresh,
        .handoffThankYouPay,
        .handoffThankYouSmell
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
        bubbleLabel.text = Loc.t(thankYouTexts.randomElement() ?? .handoffThankYouFresh)
        let popUp = SKAction.scale(to: 1.0, duration: 0.3)
        let popBounce = SKAction.scale(to: 0.95, duration: 0.1)
        bubbleContainer.run(.sequence([popUp, popBounce, SKAction.scale(to: 1.0, duration: 0.1)]))

        calculateCoins()

        run(.sequence([
            .wait(forDuration: 1.0),
            .run { [weak self] in
                guard let self else { return }
                // The reward popup is the end-of-day summary — shown once the day's last
                // customer is done, or once the 8AM–6PM shift clock has hit closing time
                // (no *new* customer past 6PM, but whatever order was already in progress
                // still gets to finish normally). Earlier handoffs move straight to the
                // next customer.
                if CustomerManager.shared.remainingCustomersForToday.isEmpty || GameState.shared.isPastClosingTime {
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
        GameState.shared.completeCurrentOrder()
        goTo(CustomerScene(size: size))
    }

    private func calculateCoins() {
        // The payout is fixed by the day's level design (see LevelDesign), not derived from
        // clothes count here, so it can't drift from what the front desk quoted the player.
        let base = GameState.shared.currentOrderReward
        let deduction = GameState.shared.wrongSoapCount * 50
        GameState.shared.coinsEarned = max(0, base - deduction)

        if GameState.shared.wrongSoapCount == 0 {
            GameCenterManager.shared.unlock(.flawlessOrder)
        }
        GameCenterManager.shared.advance(.rawrTycoon, by: Double(GameState.shared.coinsEarned))
    }

    // MARK: - Reward popup

    //Remove "private" keyword when DEBUG testing for preview
    private func showRewardPopup() {
        playSound("complete")

        let center = sceneCenter
        let panelSize = CGSize(width: 348, height: 248)
        let innerContentSize = CGSize(width: 270, height: 157)

        let overlay = SKNode()
        overlay.name = "rewardPopupOverlay"
        overlay.zPosition = 500
        addChild(overlay)

        let panel = SKSpriteNode(imageNamed: AssetName.UI.popUpFrame)
        panel.size = panelSize
        panel.position = center
        overlay.addChild(panel)

        // Stones earned
        let earned = starCount()
        let stoneOffsets: [CGFloat] = [-60, 0, 60]
        for (index, offsetX) in stoneOffsets.enumerated() {
            let stone = SKSpriteNode(imageNamed: index < earned ? AssetName.UI.iconStoneOn : AssetName.UI.iconStoneOff)
            stone.size = CGSize(width: 55, height: 55)
            stone.position = CGPoint(x: offsetX, y: panelSize.height / 2)
            stone.zPosition = 10
            panel.addChild(stone)
        }

        // "DAY # REWARD"
        let dayRewardLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        dayRewardLabel.text = Loc.t(.dayReward, GameState.shared.currentDay)
        dayRewardLabel.fontSize = 30
        dayRewardLabel.fontColor = plainTextColor
        dayRewardLabel.verticalAlignmentMode = .center
        dayRewardLabel.horizontalAlignmentMode = .center
        dayRewardLabel.position = CGPoint(x: 0, y: panelSize.height * 0.33)
        dayRewardLabel.zPosition = 2
        panel.addChild(dayRewardLabel)

        // content beige bg
        let innerContentBg = SKSpriteNode(imageNamed: "rewardContentBg")
        innerContentBg.size = innerContentSize
        innerContentBg.position = CGPoint(x: 0, y: -panelSize.height * 0.05)
        innerContentBg.zPosition = 1
        panel.addChild(innerContentBg)

        let sidePadding: CGFloat = 14
        let topPadding: CGFloat = 14
        let rowHeight: CGFloat = 18
        let rowSpacing: CGFloat = 3
        let dividerGap: CGFloat = 3

        var cursorY = innerContentSize.height / 2 - topPadding
        let leftX = -innerContentSize.width / 2 + sidePadding
        let rightX = innerContentSize.width / 2 - sidePadding

        // TODO: replace with real data from GameState once per-day tracking exists
        let clothesFinishedCount = 8 // TODO: replace with GameState.shared.clothesFinishedCount
        let baseIncome = 1600 // TODO: replace with GameState.shared.baseIncome

        struct MistakeEntry {
            let count: Int
            let label: String
            let pointsLost: Int
        }
        // TODO: replace with real data GameState.shared.mistakeLog, empty array should just skip the MISTAKES section entirely
        let mistakes: [MistakeEntry] = [
            MistakeEntry(count: 2, label: Loc.t(.wrongFragrance), pointsLost: 200),
            MistakeEntry(count: 3, label: Loc.t(.clothesFlewAway), pointsLost: 150)
        ]

        let clothesIcon = SKSpriteNode(imageNamed: "packagingFoldedClothes3")
        clothesIcon.size = CGSize(width: 30, height: 22)
        clothesIcon.position = CGPoint(x: leftX + 15, y: cursorY - 4)
        clothesIcon.zPosition = 1
        innerContentBg.addChild(clothesIcon)

        let clothesLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        clothesLabel.text = Loc.t(.clothesFinished)
        clothesLabel.fontSize = 14
        clothesLabel.fontColor = plainTextBrown
        clothesLabel.horizontalAlignmentMode = .left
        clothesLabel.verticalAlignmentMode = .center
        clothesLabel.position = CGPoint(x: leftX + 36, y: cursorY - 4)
        clothesLabel.zPosition = 1
        innerContentBg.addChild(clothesLabel)

        let clothesCountLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        clothesCountLabel.text = "\(clothesFinishedCount)"
        clothesCountLabel.fontSize = 18
        clothesCountLabel.fontColor = plainTextBrown
        clothesCountLabel.horizontalAlignmentMode = .right
        clothesCountLabel.verticalAlignmentMode = .center
        clothesCountLabel.position = CGPoint(x: rightX, y: cursorY - 4)
        clothesCountLabel.zPosition = 1
        innerContentBg.addChild(clothesCountLabel)

        cursorY -= (rowHeight + dividerGap)

        // Divider
        let topDivider = SKSpriteNode(imageNamed: "rewardDivider")
        topDivider.size = CGSize(width: innerContentSize.width - sidePadding * 2, height: 2)
        topDivider.position = CGPoint(x: 0, y: cursorY)
        topDivider.zPosition = 1
        innerContentBg.addChild(topDivider)

        cursorY -= (rowHeight * 0.4 + rowSpacing)

        // Row: BASE INCOME
        let baseIncomeLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        baseIncomeLabel.text = Loc.t(.baseIncome)
        baseIncomeLabel.fontSize = 12
        baseIncomeLabel.fontColor = plainTextBrown
        baseIncomeLabel.horizontalAlignmentMode = .left
        baseIncomeLabel.verticalAlignmentMode = .center
        baseIncomeLabel.position = CGPoint(x: leftX, y: cursorY)
        baseIncomeLabel.zPosition = 1
        innerContentBg.addChild(baseIncomeLabel)

        let baseIncomeAmount = SKLabelNode(fontNamed: AssetName.Font.comica)
        baseIncomeAmount.text = "\(baseIncome)"
        baseIncomeAmount.fontSize = 18
        baseIncomeAmount.fontColor = plainTextBrown
        baseIncomeAmount.horizontalAlignmentMode = .right
        baseIncomeAmount.verticalAlignmentMode = .center
        baseIncomeAmount.position = CGPoint(x: rightX, y: cursorY)
        baseIncomeAmount.zPosition = 1
        innerContentBg.addChild(baseIncomeAmount)

        cursorY -= (rowHeight * 0.5 + rowSpacing)

        //divider
        let midDivider = SKSpriteNode(imageNamed: "rewardDivider")
        midDivider.size = CGSize(width: innerContentSize.width - sidePadding * 2, height: 2)
        midDivider.position = CGPoint(x: 0, y: cursorY)
        midDivider.zPosition = 1
        innerContentBg.addChild(midDivider)

        cursorY -= (rowHeight * 0.6 + rowSpacing)
        
        // MISTAKES section
        
        let mistakesLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        mistakesLabel.text = Loc.t(.mistakes)
        mistakesLabel.fontSize = 12
        mistakesLabel.fontColor = plainTextBrown
        mistakesLabel.horizontalAlignmentMode = .left
        mistakesLabel.verticalAlignmentMode = .center
        mistakesLabel.position = CGPoint(x: leftX, y: cursorY)
        mistakesLabel.zPosition = 1
        innerContentBg.addChild(mistakesLabel)

        cursorY -= (rowHeight * 0.8 + rowSpacing * 0.5)

        let mistakeCountColor = UIColor(red: 173.0/255.0, green: 77.0/255.0, blue: 54.0/255.0, alpha: 1.0) // AD4D36
        
        for mistake in mistakes {
            let countLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
                countLabel.text = "\(mistake.count)X"
                countLabel.fontSize = 12
                countLabel.fontColor = mistakeCountColor
                countLabel.horizontalAlignmentMode = .left
                countLabel.verticalAlignmentMode = .center
                countLabel.position = CGPoint(x: leftX, y: cursorY)
                countLabel.zPosition = 1
                innerContentBg.addChild(countLabel)

                let nameLabel = SKLabelNode(fontNamed: roundedSystemFontName(size: 10))
                nameLabel.text = mistake.label // TODO: localize
                nameLabel.fontSize = 10
                nameLabel.fontColor = plainTextBrown
                nameLabel.horizontalAlignmentMode = .left
                nameLabel.verticalAlignmentMode = .center
                nameLabel.position = CGPoint(x: leftX + countLabel.frame.width + 4, y: cursorY)
                nameLabel.zPosition = 1
                innerContentBg.addChild(nameLabel)

            let mistakeAmount = SKLabelNode(fontNamed: AssetName.Font.comica)
            mistakeAmount.text = mistake.pointsLost > 0 ? "-\(mistake.pointsLost)" : "\(mistake.pointsLost)"
            mistakeAmount.fontSize = 14
            mistakeAmount.fontColor = plainTextBrown
            mistakeAmount.horizontalAlignmentMode = .right
            mistakeAmount.verticalAlignmentMode = .center
            mistakeAmount.position = CGPoint(x: rightX, y: cursorY)
            mistakeAmount.zPosition = 1
            innerContentBg.addChild(mistakeAmount)

            cursorY -= (rowHeight * 0.8 + rowSpacing * 0.5)
        }

        cursorY -= (dividerGap - rowSpacing * 0.5)
        

        // Divider before total
        let bottomDivider = SKSpriteNode(imageNamed: "rewardDivider")
        bottomDivider.size = CGSize(width: innerContentSize.width - sidePadding * 2, height: 2)
        bottomDivider.position = CGPoint(x: 0, y: cursorY)
        bottomDivider.zPosition = 1
        innerContentBg.addChild(bottomDivider)

        cursorY -= (rowHeight * 0.6 + rowSpacing)

        // Row: TOTAL INCOME + gem + amount
        let totalLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        totalLabel.text = Loc.t(.totalIncome)
        totalLabel.fontSize = 14
        totalLabel.fontColor = plainTextBrown
        totalLabel.horizontalAlignmentMode = .left
        totalLabel.verticalAlignmentMode = .center
        totalLabel.position = CGPoint(x: leftX, y: cursorY)
        totalLabel.zPosition = 1
        innerContentBg.addChild(totalLabel)

        let gemIcon = SKSpriteNode(imageNamed: AssetName.UI.gemIcon)
        gemIcon.size = CGSize(width: 20, height: 20)
        gemIcon.zPosition = 1

        let totalAmountLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        totalAmountLabel.text = formattedCoins(GameState.shared.coinsEarned)
        totalAmountLabel.fontSize = 20
        totalAmountLabel.fontColor = plainTextBrown
        totalAmountLabel.verticalAlignmentMode = .center
        totalAmountLabel.horizontalAlignmentMode = .right
        totalAmountLabel.zPosition = 1

        let gemLabelSpacing: CGFloat = 6
        totalAmountLabel.position = CGPoint(x: rightX, y: cursorY)
        gemIcon.position = CGPoint(x: rightX - totalAmountLabel.frame.width - gemLabelSpacing - gemIcon.size.width / 2, y: cursorY)

        innerContentBg.addChild(gemIcon)
        innerContentBg.addChild(totalAmountLabel)

        // NEXT button
        let okButton = SKSpriteNode(imageNamed: "main-button")
        okButton.name = "rewardOk"
        okButton.size = CGSize(width: 93, height: 38)
        okButton.position = CGPoint(x: 0, y: -panelSize.height / 2)
        okButton.zPosition = 1
        panel.addChild(okButton)

        let okLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        okLabel.text = Loc.t(.next)
        fitLabelToButton(okLabel, maxWidth: okButton.size.width * 0.8, baseFontSize: 20)
        okLabel.fontColor = plainTextColor
        okLabel.verticalAlignmentMode = .center
        okLabel.zPosition = 1
        okButton.addChild(okLabel)
    }

    //helper to adjust text
    private func fitLabelToButton(_ label: SKLabelNode, maxWidth: CGFloat, baseFontSize: CGFloat) {
        label.fontSize = baseFontSize
        let width = label.frame.width
        if width > maxWidth {
            label.fontSize = baseFontSize * (maxWidth / width)
        }
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
                if self.starCount() == 3 { GameCenterManager.shared.unlock(.threeStarDay) }

                GameState.shared.currentDay += 1
                if GameState.shared.currentDay > LevelDesign.days.count {
                    GameCenterManager.shared.unlock(.fullCycle)
                }
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
    
    private func roundedSystemFontName(size: CGFloat, weight: UIFont.Weight = .light) -> String {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        guard let roundedDescriptor = systemFont.fontDescriptor.withDesign(.rounded) else {
            return systemFont.fontName
        }
        return UIFont(descriptor: roundedDescriptor, size: size).fontName
    }
}


//MARK: - Debug

//////un comment to test, and remove "private" from showrewardpopup
//#if DEBUG
//import SwiftUI
//import SpriteKit
//
///// Debug-only subclass: skips the whole handoff flow and jumps straight
///// to the reward popup so #Preview can render it without playing.
//private final class RewardPopupPreviewScene: HandoffScene {
//
//    override func didMove(to view: SKView) {
//        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
//
//        let background = SKSpriteNode(imageNamed: AssetName.Background.frontDesk)
//        background.size = self.size
//        background.position = .zero
//        background.zPosition = -10
//        addChild(background)
//
//        seedDebugGameState()
//        showRewardPopup()
//    }
//
//    private func seedDebugGameState() {
//        GameState.shared.currentDay = 1
//        GameState.shared.currentOrderReward = 1600 // adjust to test different star counts
//        GameState.shared.coinsEarned = 1250 // adjust to test different totals
//        GameState.shared.wrongSoapCount = 0
//    }
//}
//
//struct RewardPopupPreview: View {
//    var body: some View {
//        SpriteView(scene: RewardPopupPreviewScene(size: CGSize(width: 390, height: 844)))
//            .frame(width: 390, height: 844)
//            .ignoresSafeArea()
//    }
//}
//
//#Preview {
//    RewardPopupPreview()
//}
//#endif
