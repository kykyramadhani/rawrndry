import SpriteKit

class CustomerScene: SKScene {

    /// The dirty-order pickup scene when there's still work to do, or the polished
    /// HandoffScene once the current order is fully processed and ready to return.
    static func makeCurrent(size: CGSize) -> SKScene {
        GameState.shared.isReadyForHandoff ? HandoffScene(size: size) : CustomerScene(size: size)
    }

    // Core Nodes
    private var customerNode: SKSpriteNode!
    private var laundryBag: SKSpriteNode!
    private var bubbleContainer: SKNode!
    private var bubbleBg: SKSpriteNode!
    
    // UI Nodes
    private var chevronBtn: SKSpriteNode!
    private var dayHud: SKSpriteNode!
    private var currencyHud: SKSpriteNode!
    private var instructionBtn: SKSpriteNode!
    
    private var currentCustomer: CustomerModel?
    
    private let finalCustomerPosition = CGPoint(x: -0.28, y: -0.22)
    private let finalBagPosition = CGPoint(x: 0.24, y: -0.18)
    
    private let plainTextColor = UIColor(red: 255.0/255.0, green: 247.0/255.0, blue: 234.0/255.0, alpha: 1.0)
    private let plainTextBrown = UIColor(red: 143.0/255.0, green: 43.0/255.0, blue: 18.0/255.0, alpha: 1.0)
    
    /// Set once ever when the very first customer of Day 1 shows the auto-opened spotlight
    /// tutorial, so revisiting this scene later never shows it again.
    private static let tutorialSeenKey = TutorialFlag.frontDeskSpotlight.rawValue

    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        // There's no designed content past the last day yet — bounce back to StartScene,
        // which shows the "more levels coming soon" state instead of a broken empty order.
        guard LevelDesign.config(forDay: GameState.shared.currentDay) != nil else {
            goTo(StartScene(size: self.size))
            return
        }

        if let resumed = Self.resumingCustomer() {
            // An order is already in progress for today (the player navigated back/forward
            // via the station arrows before finishing it) — keep serving the same customer
            // instead of popping a new one off the queue.
            currentCustomer = resumed
        } else {
            currentCustomer = CustomerManager.shared.getNextCustomer()
            if currentCustomer == nil {
                CustomerManager.shared.generateCustomers(forDay: GameState.shared.currentDay)
                currentCustomer = CustomerManager.shared.getNextCustomer()
            }
        }

        setupBackground()
        setupUI()
        setupCustomer()
        setupForeground()
        setupLaundryBag()
        setupSpeechBubble()

        animateArrival { [weak self] in
            self?.showFirstTimeTutorialIfNeeded()
        }

        AudioManager.shared.stopRiverAmbience()
        AudioManager.shared.playThemeBGM()
    }

    /// Rebuilds the CustomerModel for an order already in progress today, from the data
    /// Washing/Drying/Folding have been persisting into GameState all along — used instead
    /// of `CustomerManager.getNextCustomer()`, which is destructive (pops the queue) and
    /// must only run when actually starting a brand-new order.
    private static func resumingCustomer() -> CustomerModel? {
        let state = GameState.shared
        guard state.orderGeneratedDay == state.currentDay, !state.currentOrderItems.isEmpty else { return nil }

        return CustomerModel(
            characterImage: state.currentCustomerImage,
            itemsToWash: state.currentOrderItems,
            requestedSoap: state.currentOrderItems.first?.requestedSoap ?? .rose,
            reward: state.currentOrderReward,
            customerIndexInDay: -1
        )
    }

    /// Auto-opens the same help popup the "i" button shows, but only once ever — for the
    /// very first customer of Day 1, so brand-new players get walked through the flow.
    private func showFirstTimeTutorialIfNeeded() {
        guard GameState.shared.currentDay == 1, currentCustomer?.customerIndexInDay == 0 else { return }
        guard !UserDefaults.standard.bool(forKey: Self.tutorialSeenKey) else { return }

        UserDefaults.standard.set(true, forKey: Self.tutorialSeenKey)
        showSpotlightTutorial(around: laundryBag, caption: Loc.t(.tutorialFrontDeskDirtyClothes))
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: AssetName.Background.frontDesk)
        background.size = self.size
        background.position = CGPoint.zero
        background.zPosition = -10
        addChild(background)
    }
    
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

        // --- Chevron Button --- (right only; this is the start of the station loop)
        chevronBtn = addStationArrows(current: .customer, showLeft: false).right!

        addSettingsButton()
        addHomeButton()
    }
    
    private func setupCustomer() {
        let characterImage = currentCustomer?.characterImage ?? AssetName.Character.customer1
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
        // Below the interactive UI (chevron/settings sit at zPosition 10) so it never
        // steals settings-button taps that go through atPoint hit-testing.
        foreground.zPosition = 5
        addChild(foreground)
    }
    
    private func setupLaundryBag() {
        let bagTexture = SKTexture(imageNamed: AssetName.Item.dirtyClothesBag)
        laundryBag = SKSpriteNode(texture: bagTexture)
        
        let targetWidth: CGFloat = 250.0
        let bagScaleFactor = targetWidth / bagTexture.size().width
        laundryBag.setScale(bagScaleFactor)
        
        laundryBag.position = CGPoint(x: self.size.width * finalBagPosition.x, y: self.size.height * finalBagPosition.y)
        laundryBag.zPosition = 20
        laundryBag.alpha = 0
        addChild(laundryBag)
        
        setupFlies()
    }
        
    private func setupFlies() {
        let fly1 = SKSpriteNode(imageNamed: AssetName.Item.fly1)
        fly1.setScale(1)
        fly1.position = CGPoint(x: -90, y: -20)
        fly1.zPosition = 1
        laundryBag.addChild(fly1)
        
        let fly2 = SKSpriteNode(imageNamed: AssetName.Item.fly2)
        fly2.setScale(1)
        fly2.position = CGPoint(x: 50, y: 20)
        fly2.zPosition = 1
        laundryBag.addChild(fly2)
        
        animateFly(fly: fly1, duration: 0.15, offset: 5)
        animateFly(fly: fly2, duration: 0.2, offset: -7)
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
        
        let text = currentCustomer?.orderText ?? "WASH PLS."
        
        let textLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        textLabel.text = text.uppercased()
        textLabel.fontSize = 32
        textLabel.fontColor = plainTextBrown
        textLabel.verticalAlignmentMode = .center
        textLabel.horizontalAlignmentMode = .center
        textLabel.position = CGPoint.zero
        textLabel.zPosition = 1
        
        bubbleContainer.addChild(textLabel)
        addChild(bubbleContainer)
    }
    
    private func animateArrival(completion: @escaping () -> Void = {}) {
        let walkIn = SKAction.moveTo(x: self.size.width * finalCustomerPosition.x, duration: 1.0)
        walkIn.timingMode = .easeOut

        let bagAppear = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        let bagDrop = SKAction.moveBy(x: 0, y: -20, duration: 0.2)
        let bagSpawn = SKAction.group([bagAppear, bagDrop])

        let popUp = SKAction.scale(to: 1.0, duration: 0.3)
        let popBounce = SKAction.scale(to: 0.95, duration: 0.1)
        let bubbleAnim = SKAction.sequence([popUp, popBounce, SKAction.scale(to: 1.0, duration: 0.1)])

        customerNode.run(SKAction.sequence([walkIn]))

        let sceneAnimations = SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { self.laundryBag.run(bagSpawn) },
            SKAction.wait(forDuration: 0.3),
            SKAction.run { self.bubbleContainer.run(bubbleAnim) },
            // Matches bubbleAnim's own duration (0.3 + 0.1 + 0.1) so `completion` only fires
            // once the customer/bag/bubble arrival is fully settled on screen.
            SKAction.wait(forDuration: 0.5)
        ])
        
        self.run(sceneAnimations, completion: completion)
    }

    private func animateFly(fly: SKSpriteNode, duration: TimeInterval, offset: CGFloat) {
        let moveUp = SKAction.moveBy(x: offset, y: offset, duration: duration)
        let moveDown = SKAction.moveBy(x: -offset, y: -offset, duration: duration)
        let sequence = SKAction.sequence([moveUp, moveDown])
        let hover = SKAction.repeatForever(sequence)
        
        fly.run(hover)
    }
    
    private func transitionToWashingScene() {
        guard let customer = currentCustomer else { return }

        GameState.shared.startOrder(items: customer.itemsToWash, customerImage: customer.characterImage, reward: customer.reward)

        let washingScene = WashingScene(size: self.size)
        washingScene.itemsToWash = customer.itemsToWash
        SceneManager.shared.transition(to: washingScene, from: self.view)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if handleSettingsPopupTouchesBegan(at: location) { return }
        if handleTipPopupTap(at: location) { return }
        if handleHomeConfirmPopupTap(at: location) { return }
        if handleSettingsButtonTap(nodeName: tappedNodeName(at: location)) { return }
        if handleHomeButtonTap(nodeName: tappedNodeName(at: location)) { return }

        dismissSpotlightTutorialIfTargetTapped(at: location)

        if chevronBtn.contains(location) {
            self.isUserInteractionEnabled = false
            runButtonTapAnimation(on: chevronBtn) {
                self.transitionToWashingScene()
            }
        }

        if instructionBtn.contains(location) {
            runButtonTapAnimation(on: instructionBtn) {
                self.showTipPopup(text: Loc.t(.infoCustomer))
            }
            return
        }

        if laundryBag.contains(location) {
            self.isUserInteractionEnabled = false
            let currentScale = laundryBag.xScale
            let scaleDown = SKAction.scale(to: currentScale * 0.9, duration: 0.1)
            let scaleUp = SKAction.scale(to: currentScale, duration: 0.1)
            
            laundryBag.run(SKAction.sequence([scaleDown, scaleUp])) {
                self.transitionToWashingScene()
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
}
