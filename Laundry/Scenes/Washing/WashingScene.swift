//
//  WashingScene.swift
//  Laundry
//
//  Drag a dirty item out of the basket onto the washing stone, apply the customer's
//  requested soap from a holder, scrub it clean, then drag it into the clean basket.
//  Items are processed one at a time from the current customer's order queue.

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

    // Soap holders (static) and the node currently being dragged from one
    private var soapHolder1: SKSpriteNode!
    private var soapHolder2: SKSpriteNode!
    private var draggedSoap: SKSpriteNode?
    private var selectedSoapType: SoapFragrance?

    private var activeStains: [SKSpriteNode] = []

    var itemsToWash: [LaundryItem] = []
    private var currentItemIndex: Int = 0

    enum WashState {
        case idle
        case draggingDirty
        case waitingSoap    // Waiting for soap to be dragged from a holder
        case draggingSoap   // Player is dragging a picked-up soap
        case readyToScrub   // Soap applied, ready to scrub
        case scrubbing      // Player is scrubbing
        case clean
        case draggingClean
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

        // GameState is the persistent source of truth for the current order — restore from
        // it whenever this scene wasn't handed itemsToWash directly (e.g. arriving here via
        // the station chevron from Drying instead of fresh from CustomerScene). Never the
        // other way around: overwriting GameState from an empty local list is what used to
        // wipe real in-progress orders when navigating away mid-wash and back.
        if itemsToWash.isEmpty {
            itemsToWash = GameState.shared.currentOrderItems
        }

        // Resume at the first item that isn't washed yet, instead of always restarting from
        // index 0 — so leaving mid-order and coming back doesn't re-offer already-clean items.
        currentItemIndex = GameState.shared.itemProgress.firstIndex(where: { !$0.isWashed }) ?? itemsToWash.count

        setupBackground()
        
        // STANDARD HUD
//        addCurrencyHUD(
//            topLeftOrigin: CGPoint(x: size.width * 0.05, y: size.height * 0.90),
//            day: GameState.shared.currentDay,
//            coins: GameState.shared.score
//        )
        addCurrencyHUD(topLeftOrigin: CGPoint(x: size.width * 0.05, y: size.height * 0.90), day: GameState.shared.currentDay, coins: GameState.shared.score)
        
        setupLeftBasket()
        setupClothesOnSteps()
        setupSoaps()
        setupRightBasket()
        addStationArrows(current: .washing)

        // STANDARD INSTRUCTION BUTTON
        helpButton = makeButton(
            imageNamed: AssetName.UI.btnInstruction,
            position: CGPoint(x: size.width * 0.85, y: size.height * 0.90),
            scale: 0.8,
            nodeName: "help"
        )

        // STANDARD HINT LABEL
        hintLabel = makeHintLabel(position: CGPoint(x: size.width / 2, y: size.height * 0.08))

        // STANDARD SETTINGS BUTTON
        addSettingsButton()

        updateBasketPile()
        restoreCleanBasketIfNeeded()

        AudioManager.shared.stopThemeBGM()
        AudioManager.shared.playRiverAmbience()
    }

    /// Re-shows the clean-basket pile art for whichever item was washed most recently, so
    /// returning to this scene after already finishing some items doesn't show an empty
    /// clean basket even though items really are done.
    private func restoreCleanBasketIfNeeded() {
        guard currentItemIndex > 0, currentItemIndex - 1 < itemsToWash.count else { return }
        let lastWashed = itemsToWash[currentItemIndex - 1]
        rightBasketPiles.texture = SKTexture(imageNamed: AssetName.Item.washingBasketPile(patternID: lastWashed.patternID))
        rightBasketPiles.isHidden = false
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
        soapHolder1 = SKSpriteNode(imageNamed: AssetName.Item.washingSoap(id: 1))
        soapHolder1.name = "soapHolder1"
        soapHolder1.setScale(0.08)
        soapHolder1.position = CGPoint(x: self.size.width * 0.12, y: -self.size.height * 0.28)
        soapHolder1.zPosition = 15
        addChild(soapHolder1)

        soapHolder2 = SKSpriteNode(imageNamed: AssetName.Item.washingSoap(id: 2))
        soapHolder2.name = "soapHolder2"
        soapHolder2.setScale(0.08)
        soapHolder2.position = CGPoint(x: self.size.width * 0.20, y: -self.size.height * 0.27)
        soapHolder2.zPosition = 15
        addChild(soapHolder2)
    }

    private func updateBasketPile() {
        if currentItemIndex < itemsToWash.count {
            let currentItem = itemsToWash[currentItemIndex]

            basketPiles.texture = SKTexture(imageNamed: AssetName.Item.washingBasketPile(patternID: currentItem.patternID))
            basketPiles.isHidden = false

            pickedClothes.texture = SKTexture(imageNamed: AssetName.Item.washingPickedClothes(patternID: currentItem.patternID))
            pickedClothes.size = pickedClothesSize
        } else {
            basketPiles.isHidden = true
        }
    }

    /// Updates the dirty basket's pile the instant the current item leaves it for the washing
    /// stone — shows whatever's next in the queue, or hides the pile entirely if this was the
    /// last item, instead of leaving the just-picked-up item's pattern showing until it's clean.
    private func revealNextBasketItem() {
        let nextIndex = currentItemIndex + 1
        if nextIndex < itemsToWash.count {
            basketPiles.texture = SKTexture(imageNamed: AssetName.Item.washingBasketPile(patternID: itemsToWash[nextIndex].patternID))
            basketPiles.isHidden = false
        } else {
            basketPiles.isHidden = true
        }
    }

    private func setupStains(for item: LaundryItem) {
        activeStains.forEach { $0.removeFromParent() }
        activeStains.removeAll()

        requiredScrubAmount = (item.stain == .hard) ? 1200.0 : 600.0
        scrubAmount = 0.0

        let randomStainID = Int.random(in: 1...4)
        let stain = SKSpriteNode(imageNamed: AssetName.Item.washingStain(id: randomStainID))

        stain.size = CGSize(width: 60, height: 60)
        stain.zRotation = CGFloat.random(in: 0...(2 * .pi))

        let safeAreaWidth = spreadClothesSize.width * 0.3
        let safeAreaHeight = spreadClothesSize.height * 0.3

        let randomX = CGFloat.random(in: -safeAreaWidth...safeAreaWidth)
        let randomY = CGFloat.random(in: -safeAreaHeight...safeAreaHeight)

        stain.position = CGPoint(x: randomX, y: randomY)
        stain.zPosition = 1

        spreadClothes.addChild(stain)
        activeStains.append(stain)
    }

    // MARK: - Workflow Logic

    private func beginWaitingForSoap() {
        currentState = .waitingSoap
    }

    private func validateSoapDrop(_ selectedSoap: SoapFragrance, soapNode: SKSpriteNode) {
        let currentItem = itemsToWash[currentItemIndex]
        var isValid = false

        if let requested = currentItem.requestedSoap {
            isValid = (requested == selectedSoap)
        } else {
            isValid = true
        }

        if isValid {
            applySoap(selectedSoap, soapNode: soapNode)
        } else {
            soapNode.removeFromParent()
            draggedSoap = nil
            selectedSoapType = nil
            currentState = .waitingSoap
        }
    }

    private func applySoap(_ soap: SoapFragrance, soapNode: SKSpriteNode) {
        itemsToWash[currentItemIndex].usedSoap = soap

        soapNode.removeFromParent()
        draggedSoap = nil
        selectedSoapType = nil

        currentState = .readyToScrub
    }

    private func finishScrubbing() {
        currentState = .clean
        activeStains.forEach { $0.isHidden = true }
        AudioManager.shared.stopScrubbing()
        HapticsManager.shared.stopScrubbing()
        showHint(Loc.t(.washingHintClean), on: hintLabel)
    }

    private func moveToCleanBasket() {
        pickedClothes.isHidden = true
        currentState = .idle

        let washedItem = itemsToWash[currentItemIndex]
        rightBasketPiles.texture = SKTexture(imageNamed: AssetName.Item.washingBasketPile(patternID: washedItem.patternID))
        rightBasketPiles.isHidden = false

        spreadClothes.position = CGPoint(x: self.size.width * spreadClothesPosition.x,
                                         y: self.size.height * spreadClothesPosition.y)
        spreadClothes.zPosition = 4

        // Mark this specific item washed in GameState right away — not only once the whole
        // queue is done — so progress survives leaving mid-order (e.g. to peek at Drying)
        // and coming back, instead of only living in this scene's local state until the end.
        GameState.shared.itemProgress[currentItemIndex].washProgress = 1

        currentItemIndex += 1
        updateBasketPile()

        if currentItemIndex >= itemsToWash.count {
            showHint(Loc.t(.washingHintNiceClean), on: hintLabel)
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let name = tappedNodeName(at: location)

        // Settings & Popup Handlers
        if handleSettingsPopupTouchesBegan(at: location) { return }
        if handleTipPopupTap(at: location) { return }
        if handleStationArrowTap(nodeName: name, current: .washing) { return }
        if handleSettingsButtonTap(nodeName: name) { return }

        // Help Button Handler
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

        case .waitingSoap:
            if soapHolder1.contains(location) {
                currentState = .draggingSoap
                selectedSoapType = .rose

                draggedSoap = SKSpriteNode(imageNamed: AssetName.Item.washingSoapPicked(id: 1))
                draggedSoap?.setScale(0.08)
                draggedSoap?.position = location
                draggedSoap?.zPosition = 25
                if let newSoap = draggedSoap { addChild(newSoap) }

            } else if soapHolder2.contains(location) {
                currentState = .draggingSoap
                selectedSoapType = .soapFruit

                draggedSoap = SKSpriteNode(imageNamed: AssetName.Item.washingSoapPicked(id: 2))
                draggedSoap?.setScale(0.08)
                draggedSoap?.position = location
                draggedSoap?.zPosition = 25
                if let newSoap = draggedSoap { addChild(newSoap) }
            }

        case .readyToScrub, .scrubbing:
            if spreadClothes.contains(location) {
                lastTouchLocation = location
                lastTouchTime = touch.timestamp
                currentState = .scrubbing
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

        // Settings Popup Handler
        if handleSettingsPopupTouchesMoved(at: location) { return }

        switch currentState {
        case .draggingDirty, .draggingClean:
            pickedClothes.position = location

        case .draggingSoap:
            draggedSoap?.position = location

        case .scrubbing:
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
                    finishScrubbing()
                }
            }
        default: break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Settings Popup Handler
        if handleSettingsPopupTouchesEnded() { return }

        AudioManager.shared.stopScrubbing()
        HapticsManager.shared.stopScrubbing()

        switch currentState {
        case .draggingDirty:
            let rockArea = CGRect(x: -self.size.width * 0.15, y: -self.size.height * 0.15,
                                  width: self.size.width * 0.3, height: self.size.height * 0.3)

            if rockArea.contains(pickedClothes.position) {
                pickedClothes.isHidden = true

                if currentItemIndex < itemsToWash.count {
                    let currentItem = itemsToWash[currentItemIndex]
                    spreadClothes.texture = SKTexture(imageNamed: currentItem.imageName)
                    spreadClothes.size = spreadClothesSize
                    setupStains(for: currentItem)

                    spreadClothes.isHidden = false
                    activeStains.forEach { $0.isHidden = false; $0.alpha = 1.0 }

                    beginWaitingForSoap()
                    revealNextBasketItem()
                }
            } else {
                pickedClothes.isHidden = true
                currentState = .idle
            }

        case .draggingSoap:
            guard let dragged = draggedSoap, let soapType = selectedSoapType else { return }

            if spreadClothes.contains(dragged.position) {
                validateSoapDrop(soapType, soapNode: dragged)
            } else {
                dragged.removeFromParent()
                draggedSoap = nil
                selectedSoapType = nil
                currentState = .waitingSoap
            }

        case .draggingClean:
            if rightBasket.contains(pickedClothes.position) {
                moveToCleanBasket()
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
