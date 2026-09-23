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
    private var chevronRight: SKSpriteNode!

    /// Set once ever after the spotlight tutorial's final ("tap the arrow") step is shown, so
    /// this walkthrough — gated to Day 1's very first item — never replays on later orders.
    private static let tutorialSeenKey = TutorialFlag.washingSpotlight.rawValue

    /// True for the entire first-ever wash, from didMove until the final step fires — gates
    /// each of the five state-transition hooks below without re-checking UserDefaults each time.
    private var tutorialActive = false

    // Soap holders (static) and the node currently being dragged from one
    private var soapHolder1: SKSpriteNode!
    private var soapHolder2: SKSpriteNode!
    private var draggedSoap: SKSpriteNode?
    private var selectedSoapType: SoapFragrance?
    
    //bubble washing
    private var lastBubbleLocation: CGPoint?
    private let bubbleCooldownDistance: CGFloat = 20.0

    /// The fragrance burst sitting on the current item — petals or foam, thinning out as the
    /// item is scrubbed. Nil whenever no soap has been applied to whatever's on the stone.
    private var soapSpray: SKNode?
    /// The alpha `soapSpray` settled at, so scrubbing fades it out from the right starting point.
    private var soapSprayOpacity: CGFloat = 0.9


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
    private let spreadClothesPosition = CGPoint(x: -0.03, y: -0.08)

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
        // This scene uses a centered anchorPoint (see above), so HUD/button positions are
        // offsets from scene-center rather than the bottom-left-anchor fractions used in the
        // other scenes (e.g. size.width * 0.85 for a "near the right edge" button here).
        let hud = addCurrencyHUD(topLeftOrigin: CGPoint(x: -size.width * 0.45, y: size.height * 0.40), day: GameState.shared.currentDay, coins: GameState.shared.score)

        // The order slip hangs off the top edge just right of the gem badge — same corner as
        // the day marker, so "what did they ask for again?" never means walking back to the
        // front desk mid-wash.
        addOrderNote(topEdgeAnchor: CGPoint(x: hud.gem.frame.maxX + 36, y: size.height * 0.5))

        setupLeftBasket()
        setupClothesOnSteps()
        setupSoaps()
        setupRightBasket()
        chevronRight = addStationArrows(current: .washing, showLeft: false).right

        // STANDARD INSTRUCTION BUTTON
        helpButton = makeButton(
            imageNamed: AssetName.UI.btnInstruction,
            position: CGPoint(x: size.width * 0.35, y: size.height * 0.40),
            scale: 0.8,
            nodeName: "help"
        )

        // STANDARD HINT LABEL
        hintLabel = makeHintLabel(position: CGPoint(x: 0, y: -size.height * 0.42))

        // STANDARD SETTINGS BUTTON
        addSettingsButton()

        // STANDARD HOME BUTTON
        addHomeButton()

        updateBasketPile()
        restoreCleanBasketIfNeeded()

        tutorialActive = GameState.shared.currentDay == 1
            && currentItemIndex == 0
            && !UserDefaults.standard.bool(forKey: Self.tutorialSeenKey)
        if tutorialActive {
            showSpotlightTutorial(around: [leftBasket, basketPiles], caption: Loc.t(.tutorialWashingBasket))
        }

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

        soapSpray?.removeFromParent()
        soapSpray = nil

        requiredScrubAmount = (item.stain == .hard) ? 1200.0 : 600.0
        scrubAmount = 0.0

        let randomStainID = Int.random(in: 1...4)
        let stain = SKSpriteNode(imageNamed: AssetName.Item.washingStain(id: randomStainID))

        stain.size = CGSize(width: spreadClothesSize.width, height: spreadClothesSize.height)

        stain.position = CGPoint(x: 0, y: 0)
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
            // Counted against the payout at handoff — without this the deduction there had
            // nothing to deduct for, so every order scored a silent three stars.
            GameState.shared.wrongSoapCount += 1
            showHint(Loc.t(.WashingWrongSoap), on: hintLabel)
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

        showSoapSpray(soap)

        // Only counts when the customer actually named a fragrance — matching "anything goes"
        // takes no skill.
        if itemsToWash[currentItemIndex].requestedSoap != nil {
            GameCenterManager.shared.advance(.soapSommelier, by: 1)
        }

        currentState = .readyToScrub

        // "The clothes and the stone" — spreadClothes sits directly on the washing stone
        // (the stone itself is baked into the background art, with no separate node to target).
        if tutorialActive, currentItemIndex == 0 {
            showSpotlightTutorial(around: [spreadClothes], caption: Loc.t(.tutorialWashingScrub))
        }
    }

    private func finishScrubbing() {
        currentState = .clean
        activeStains.forEach { $0.isHidden = true }

        soapSpray?.run(.sequence([.fadeOut(withDuration: 0.4), .removeFromParent()]))
        soapSpray = nil
        lastBubbleLocation = nil

        GameCenterManager.shared.advance(.elbowGrease, by: Double(requiredScrubAmount))

        AudioManager.shared.stopScrubbing()
        HapticsManager.shared.stopScrubbing()
        showHint(Loc.t(.washingHintClean), on: hintLabel)

        if tutorialActive, currentItemIndex == 0 {
            showSpotlightTutorial(around: [spreadClothes, rightBasket], caption: Loc.t(.tutorialWashingCleanBasket))
        }
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
        if GameState.shared.itemProgress.indices.contains(currentItemIndex) {
            GameState.shared.itemProgress[currentItemIndex].washProgress = 1
        }

        GameCenterManager.shared.unlock(.firstWash)

        currentItemIndex += 1
        updateBasketPile()

        if currentItemIndex >= itemsToWash.count {
            showHint(Loc.t(.washingHintNiceClean), on: hintLabel)

            if tutorialActive {
                tutorialActive = false
                UserDefaults.standard.set(true, forKey: Self.tutorialSeenKey)
                showSpotlightTutorial(around: chevronRight, caption: Loc.t(.tutorialWashingNextArrow))
            }
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
        if handleOrderPopupTap(at: location) { return }
        if handleHomeConfirmPopupTap(at: location) { return }
        if handleStationArrowTap(nodeName: name, current: .washing) { return }
        if handleSettingsButtonTap(nodeName: name) { return }
        if handleHomeButtonTap(nodeName: name) { return }
        if handleOrderNoteTap(nodeName: name) { return }

        // Help Button Handler
        if name == "help" {
            runButtonTapAnimation(on: helpButton) {
                self.showTipPopup(text: Loc.t(.infoWashing))
            }
            return
        }

        dismissSpotlightTutorialIfTargetTapped(at: location)

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
            } else if spreadClothes.contains(location) {
                showHint(Loc.t(.washingNoSoap), on: hintLabel)
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

                //bubbles
                if let lastBubbleLoc = lastBubbleLocation {
                    let distanceSinceLastBubble = hypot(location.x - lastBubbleLoc.x, location.y - lastBubbleLoc.y)
                    if distanceSinceLastBubble >= bubbleCooldownDistance {
                        createBubbleChips(at: location)
                        lastBubbleLocation = location
                    }
                } else {
                    lastBubbleLocation = location
                }
                
                let progress = min(1.0, scrubAmount / requiredScrubAmount)
                for stain in activeStains { stain.alpha = 1.0 - progress }
                soapSpray?.alpha = soapSprayOpacity * (1 - progress * 0.65)
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
                // Nothing left in the queue would otherwise leave the scene stuck in
                // .draggingDirty forever, with no way back to .idle.
                currentState = .idle

                if currentItemIndex < itemsToWash.count {
                    let currentItem = itemsToWash[currentItemIndex]
                    spreadClothes.texture = SKTexture(imageNamed: currentItem.imageName)
                    spreadClothes.size = spreadClothesSize
                    setupStains(for: currentItem)

                    spreadClothes.isHidden = false
                    activeStains.forEach { $0.isHidden = false; $0.alpha = 1.0 }

                    beginWaitingForSoap()
                    revealNextBasketItem()

                    if tutorialActive, currentItemIndex == 0 {
                        showSpotlightTutorial(around: [soapHolder1, soapHolder2], caption: Loc.t(.tutorialWashingSoap))
                    }
                }
            } else {
                pickedClothes.isHidden = true
                currentState = .idle
            }

        case .draggingSoap:
            guard let dragged = draggedSoap, let soapType = selectedSoapType else {
                draggedSoap?.removeFromParent()
                draggedSoap = nil
                selectedSoapType = nil
                currentState = .waitingSoap
                return
            }

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
        lastBubbleLocation = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    //MARK: soap spray

    /// The visible "soap is on" layer — the fragrance's own art thrown across the clothes,
    /// settling into a translucent film that thins out as the item comes clean. Lives as a
    /// child of `spreadClothes` so it travels with the clothes and dies with them.
    private func showSoapSpray(_ soap: SoapFragrance) {
        soapSpray?.removeFromParent()

        let spray = SKNode()
        spray.name = "soapSpray"
        spray.zPosition = 2
        spray.alpha = 0
        spreadClothes.addChild(spray)
        soapSpray = spray

        let piece = SKSpriteNode(imageNamed: soap.sprayTexture)
        piece.size = soap.spraySize
        piece.zRotation = CGFloat.random(in: -0.5...0.5)
        piece.position = CGPoint(x: CGFloat.random(in: -14...14), y: CGFloat.random(in: -14...14))
        piece.setScale(0.5)
        spray.addChild(piece)

        // Overshoots then settles back to exactly `spraySize` — the burst reads as thrown on,
        // but the art ends up at the size it was drawn for.
        piece.run(.sequence([
            .scale(to: 1.08, duration: 0.22),
            .scale(to: 1.0, duration: 0.12)
        ]))

        soapSprayOpacity = soap.sprayOpacity
        spray.run(.fadeAlpha(to: soapSprayOpacity, duration: 0.2))
    }

    //MARK: bubbles
    private func createBubbleChips(at point: CGPoint) {
        let bubbleCount = Int.random(in: 1...3)
        
        for _ in 0..<bubbleCount {
            let bubble = SKSpriteNode(imageNamed: AssetName.Item.bubbleParticle)

            let diameter = CGFloat.random(in: 12...26)
            bubble.size = CGSize(width: diameter, height: diameter)

            bubble.position = point
            bubble.zPosition = 20
            
            addChild(bubble)
            
            let dx = CGFloat.random(in: -40...40)
            let dy = CGFloat.random(in: -40...40)
            
            bubble.run(
                .sequence([
                    .group([
                        .moveBy(x: dx, y: dy, duration: 0.3),
                        .scale(to: 1.3, duration: 0.3)
                    ]),
                    .fadeOut(withDuration: 0.1),
                    .removeFromParent()
                ])
            )
        }
    }

}
