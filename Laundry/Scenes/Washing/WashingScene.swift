//
//  WashingScene.swift
//  Laundry
//
//  Drag a dirty item out of the basket onto the washing stone, scrub it clean,
//  then drag it into the clean basket. Items are processed one at a time from
//  the current customer's order queue.

import SpriteKit

class WashingScene: SKScene {

    private var leftBasket: SKSpriteNode!
    private var basketPiles: SKSpriteNode!
    private var pickedClothes: SKSpriteNode!
    private var spreadClothes: SKSpriteNode!
    private var rightBasket: SKSpriteNode!
    private var rightBasketPiles: SKSpriteNode!
    private var helpButton: SKSpriteNode!
    private var hintLabel: SKLabelNode!

    private var activeStains: [SKSpriteNode] = []

    var itemsToWash: [LaundryItem] = []
    private var currentItemIndex: Int = 0

    enum WashState {
        case idle, draggingDirty, washing, clean, draggingClean
    }

    private var currentState: WashState = .idle
    private var scrubAmount: CGFloat = 0.0
    private var requiredScrubAmount: CGFloat = 800.0
    private var lastTouchLocation: CGPoint?
    private var lastTouchTime: TimeInterval = 0

    private let basketSize = CGSize(width: 120, height: 120)
    private let pickedClothesSize = CGSize(width: 90, height: 90)
    private let spreadClothesSize = CGSize(width: 250, height: 250)
    private let spreadClothesPosition = CGPoint(x: -0.02, y: -0.02)

    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        GameState.shared.generateOrderIfNeeded()

        setupBackground()
        setupLeftBasket()
        setupClothesOnSteps()
        setupSoaps()
        setupRightBasket()
        addStationArrows(current: .washing)

        helpButton = makeButton(
            imageNamed: AssetName.UI.btnInstruction,
            position: CGPoint(x: self.size.width * 0.35, y: self.size.height * 0.40),
            scale: 0.8,
            nodeName: "help"
        )

        hintLabel = makeHintLabel(position: CGPoint(x: 0, y: -self.size.height * 0.42))

        addSettingsButton()

        updateBasketPile()

        AudioManager.shared.stopThemeBGM()
        AudioManager.shared.playRiverAmbience()
    }

    private func setupBackground() {
        let background = SKSpriteNode(imageNamed: AssetName.Background.washing)
        background.size = self.size
        background.zPosition = -1
        addChild(background)
    }

    private func setupLeftBasket() {
        leftBasket = SKSpriteNode(imageNamed: AssetName.Item.washingBasketEmpty)
        leftBasket.size = basketSize
        leftBasket.position = CGPoint(x: -self.size.width * 0.35, y: -self.size.height * 0.35)
        leftBasket.zPosition = 10
        addChild(leftBasket)

        basketPiles = SKSpriteNode()
        basketPiles.name = "basketPiles"
        basketPiles.size = basketSize
        basketPiles.position = leftBasket.position
        basketPiles.zPosition = 11
        addChild(basketPiles)
    }

    private func setupRightBasket() {
        rightBasket = SKSpriteNode(imageNamed: AssetName.Item.washingBasketEmpty)
        rightBasket.size = basketSize
        rightBasket.position = CGPoint(x: self.size.width * 0.35, y: -self.size.height * 0.35)
        rightBasket.zPosition = 10
        addChild(rightBasket)

        rightBasketPiles = SKSpriteNode()
        rightBasketPiles.name = "rightBasketPiles"
        rightBasketPiles.size = basketSize
        rightBasketPiles.position = rightBasket.position
        rightBasketPiles.zPosition = 11
        rightBasketPiles.isHidden = true
        addChild(rightBasketPiles)
    }

    private func setupClothesOnSteps() {
        pickedClothes = SKSpriteNode()
        pickedClothes.size = pickedClothesSize
        pickedClothes.zPosition = 20
        pickedClothes.isHidden = true
        addChild(pickedClothes)

        spreadClothes = SKSpriteNode()
        spreadClothes.name = "spreadClothes"
        spreadClothes.size = spreadClothesSize
        spreadClothes.position = CGPoint(x: self.size.width * spreadClothesPosition.x, y: self.size.height * spreadClothesPosition.y)
        spreadClothes.zPosition = 4
        spreadClothes.isHidden = true
        addChild(spreadClothes)
    }

    private func setupSoaps() {
        let soap1 = SKSpriteNode(imageNamed: AssetName.Item.washingSoap(id: 1))
        soap1.setScale(0.08)
        soap1.position = CGPoint(x: self.size.width * 0.12, y: -self.size.height * 0.28)
        soap1.zPosition = 15
        addChild(soap1)

        let soap2 = SKSpriteNode(imageNamed: AssetName.Item.washingSoap(id: 2))
        soap2.setScale(0.08)
        soap2.position = CGPoint(x: self.size.width * 0.20, y: -self.size.height * 0.27)
        soap2.zPosition = 15
        addChild(soap2)
    }

    // Clothes pattern variety (patternID-based art) is disabled for now — everything
    // uses the pattern-1 assets regardless of which item is currently being washed.
    private func updateBasketPile() {
        if currentItemIndex < itemsToWash.count {
            basketPiles.texture = SKTexture(imageNamed: AssetName.Item.washingBasketPile(patternID: 1))
            basketPiles.isHidden = false

            pickedClothes.texture = SKTexture(imageNamed: AssetName.Item.washingPickedClothes(patternID: 1))
            pickedClothes.size = pickedClothesSize
        } else {
            basketPiles.isHidden = true
        }
    }

    private func setupStains(for item: LaundryItem) {
        activeStains.forEach { $0.removeFromParent() }
        activeStains.removeAll()

        requiredScrubAmount = (item.stain == .hard) ? 1200.0 : 600.0
        scrubAmount = 0.0

        let stain = SKSpriteNode(imageNamed: AssetName.Item.washingStain(id: 1))

        stain.size = CGSize(width: 60, height: 60)
        stain.zRotation = CGFloat.random(in: 0...(2 * .pi))

        let safeAreaWidth = spreadClothesSize.width * 0.1
        let safeAreaHeight = spreadClothesSize.height * 0.1

        let randomX = CGFloat.random(in: -safeAreaWidth...safeAreaWidth)
        let randomY = CGFloat.random(in: -safeAreaHeight...safeAreaHeight)

        stain.position = CGPoint(x: randomX, y: randomY)
        stain.zPosition = 1

        spreadClothes.addChild(stain)
        activeStains.append(stain)
    }

    /// Marks every item in GameState as washed once the queue is fully processed, so
    /// Drying/Folding/Handoff (which read GameState.itemProgress) see this order as clean.
    private func markGameStateFullyWashed() {
        for i in GameState.shared.itemProgress.indices {
            GameState.shared.itemProgress[i].washProgress = 1
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let name = tappedNodeName(at: location)

        if handleSettingsPopupTouchesBegan(at: location) { return }
        if handleTipPopupTap(at: location) { return }
        if handleStationArrowTap(nodeName: name, current: .washing) { return }
        if handleSettingsButtonTap(nodeName: name) { return }

        if name == "help" {
            runButtonTapAnimation(on: helpButton) {
                self.showTipPopup(text: Loc.t(.infoWashing))
            }
            return
        }

        switch currentState {
        case .idle:
            if basketPiles.contains(location) && currentItemIndex < itemsToWash.count {
                currentState = .draggingDirty
                pickedClothes.position = location
                pickedClothes.isHidden = false
            }
        case .washing:
            if spreadClothes.contains(location) {
                lastTouchLocation = location
                lastTouchTime = touch.timestamp
                HapticsManager.shared.startScrubbing()
            }
        case .clean:
            if spreadClothes.contains(location) {
                currentState = .draggingClean
                spreadClothes.isHidden = true
                pickedClothes.position = location
                pickedClothes.isHidden = false
            }
        default: break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if handleSettingsPopupTouchesMoved(at: location) { return }

        switch currentState {
        case .draggingDirty, .draggingClean:
            pickedClothes.position = location

        case .washing:
            if let lastTouch = lastTouchLocation, spreadClothes.contains(location) {
                let distance = hypot(location.x - lastTouch.x, location.y - lastTouch.y)
                scrubAmount += distance

                let timeDelta = touch.timestamp - lastTouchTime
                let velocity = timeDelta > 0 ? distance / CGFloat(timeDelta) : 0
                lastTouchTime = touch.timestamp

                lastTouchLocation = location

                let progress = min(1.0, scrubAmount / requiredScrubAmount)
                for stain in activeStains { stain.alpha = 1.0 - progress }
                AudioManager.shared.playScrubbing()
                HapticsManager.shared.updateScrubbing(velocity: velocity)

                if progress >= 1.0 {
                    currentState = .clean
                    activeStains.forEach { $0.isHidden = true }
                    AudioManager.shared.stopScrubbing()
                    HapticsManager.shared.stopScrubbing()
                    showHint(Loc.t(.washingHintClean), on: hintLabel)
                }
            }
        default: break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if handleSettingsPopupTouchesEnded() { return }

        AudioManager.shared.stopScrubbing()
        HapticsManager.shared.stopScrubbing()

        switch currentState {
        case .draggingDirty:
            let rockArea = CGRect(x: -self.size.width * 0.15, y: -self.size.height * 0.15,
                                  width: self.size.width * 0.3, height: self.size.height * 0.3)

            if rockArea.contains(pickedClothes.position) {
                currentState = .washing
                pickedClothes.isHidden = true

                if currentItemIndex < itemsToWash.count {
                    let currentItem = itemsToWash[currentItemIndex]
                    spreadClothes.texture = SKTexture(imageNamed: AssetName.Item.washingClothes(patternID: 1))
                    spreadClothes.size = spreadClothesSize
                    setupStains(for: currentItem)
                }

                spreadClothes.isHidden = false
                activeStains.forEach { $0.isHidden = false; $0.alpha = 1.0 }
                scrubAmount = 0.0
            } else {
                pickedClothes.isHidden = true
                currentState = .idle
            }

        case .draggingClean:
            if rightBasket.contains(pickedClothes.position) {
                pickedClothes.isHidden = true
                currentState = .idle

                rightBasketPiles.texture = SKTexture(imageNamed: AssetName.Item.washingBasketPile(patternID: 1))
                rightBasketPiles.isHidden = false

                spreadClothes.position = CGPoint(x: self.size.width * spreadClothesPosition.x,
                                                 y: self.size.height * spreadClothesPosition.y)
                spreadClothes.zPosition = 4

                currentItemIndex += 1
                updateBasketPile()

                if currentItemIndex >= itemsToWash.count {
                    markGameStateFullyWashed()
                    showHint(Loc.t(.washingHintNiceClean), on: hintLabel)
                }

            } else {
                pickedClothes.isHidden = true
                spreadClothes.isHidden = false
                currentState = .clean
            }

        default: break
        }

        lastTouchLocation = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
