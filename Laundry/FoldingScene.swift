//
//  FoldingScene.swift
//  Laundry
//
//  Created by Aulia Agus on 01/07/26.
//
//  A single leaf-wrapped package sits center screen. The player first drags
//  the clothes out of the basket and into the package, then swipes in the
//  direction of the glowing arrow to fold each of its four flaps (states 1→5),
//  then drags the rope onto the package to tie it off before handing back to
//  the customer.

import SpriteKit

class FoldingScene: SKScene {

    private enum FoldArrow: CaseIterable {
        case right, left, up, down
    }

    private var currentState: Int = 1
    private var clothesPlaced = false
    private var isRopeTied = false
    private var isDraggingRope = false
    private var isDraggingClothes = false
    private var ropeDragOffset = CGPoint.zero
    private var clothesDragOffset = CGPoint.zero
    private var swipeStart: CGPoint?

    private var leafBack: SKSpriteNode!
    private var leafFront: SKSpriteNode!
    private var clothesPile: SKSpriteNode!
    private var clothesShadow: SKSpriteNode!
    private var clothesDragIcon: SKSpriteNode!
    private var rope: SKSpriteNode!
    private var knottedRope: SKSpriteNode!
    private var basket: SKSpriteNode!
    private var arrows: [FoldArrow: SKSpriteNode] = [:]

    private var helpButton: SKSpriteNode!
    private var hintLabel: SKLabelNode!

    private let minSwipeDistance: CGFloat = 60
    private let leafSize = CGSize(width: 300, height: 300)
    private let ropeSize = CGSize(width: 90, height: 90)

    private var packageCenter: CGPoint { CGPoint(x: size.width * 0.5, y: size.height * 0.55) }
    private var ropeStartPosition: CGPoint { CGPoint(x: size.width * 0.88, y: size.height * 0.3) }
    private var basketPosition: CGPoint { CGPoint(x: size.width * 0.1, y: size.height * 0.2) }

    private var packageBounds: CGRect {
        CGRect(
            x: packageCenter.x - leafSize.width / 2,
            y: packageCenter.y - leafSize.height / 2,
            width: leafSize.width,
            height: leafSize.height
        )
    }

    override func didMove(to view: SKView) {
        addBackground(imageNamed: "packagingBackground")
        addCurrencyHUD(topLeftOrigin: CGPoint(x: size.width * 0.05, y: size.height * 0.90), day: GameState.shared.currentDay, coins: GameState.shared.score)
        addStationArrows(current: .folding)

        addBasket()
        addClothesLayer()
        addClothesDragIcon()
        addLeafLayers()
        addArrows()
        addRope()
        addKnottedRope()

        helpButton = makeButton(
            imageNamed: AssetName.UI.btnInstruction,
            position: CGPoint(x: size.width * 0.85, y: size.height * 0.90),
            scale: 0.8,
            nodeName: "help"
        )

        hintLabel = makeHintLabel(position: CGPoint(x: size.width / 2, y: size.height * 0.08))

        addSettingsButton()

        refreshState()
        showHint(initialHintText, on: hintLabel)
    }

    /// Whether the clothes have actually reached the basket this scene pulls from — see
    /// `GameState.isReadyForFolding`. While false, the basket stays empty and un-draggable.
    private var isFoldingReady: Bool { GameState.shared.isReadyForFolding }

    private var initialHintText: String {
        guard !isFoldingReady else { return Loc.t(.foldingHintDragClothes) }
        return GameState.shared.isFullyWashed ? Loc.t(.foldingHintNotDried) : Loc.t(.foldingHintNotWashed)
    }

    // MARK: - Setup

    private func addBasket() {
        basket = SKSpriteNode(imageNamed: isFoldingReady ? "packagingBasketFull" : "packagingBasketEmpty")
        basket.size = CGSize(width: 90, height: 70)
        basket.position = basketPosition
        basket.zPosition = 5
        addChild(basket)
    }

    private func addClothesLayer() {
        clothesShadow = SKSpriteNode(imageNamed: "benchmarkFoldedClothesPiled")
        clothesShadow.size = leafSize
        clothesShadow.position = packageCenter
        clothesShadow.zPosition = 1.0
        clothesShadow.isHidden = true
        addChild(clothesShadow)

        clothesPile = SKSpriteNode(imageNamed: "packagingFoldedClothes\(GameState.shared.clothesCount)")
        clothesPile.name = "clothesPile"
        clothesPile.size = CGSize(width: leafSize.width * 0.8, height: leafSize.height * 0.8)
        clothesPile.position = packageCenter
        clothesPile.zPosition = 1.1
        clothesPile.isHidden = true
        addChild(clothesPile)
    }

    /// The clothes sitting in the basket, dragged into the package to reveal `clothesPile`.
    /// Hidden until `isFoldingReady` — an empty basket has nothing to drag out.
    private func addClothesDragIcon() {
        clothesDragIcon = SKSpriteNode(imageNamed: "packagingFoldedClothes\(GameState.shared.clothesCount)")
        clothesDragIcon.name = "clothesDragIcon"
        clothesDragIcon.size = CGSize(width: 100, height: 100)
        clothesDragIcon.position = basketPosition
        clothesDragIcon.zPosition = 6
        clothesDragIcon.isHidden = !isFoldingReady
        addChild(clothesDragIcon)
    }

    private func addLeafLayers() {
        leafBack = SKSpriteNode(imageNamed: "packagingState1Back")
        leafBack.name = "leafBack"
        leafBack.size = leafSize
        leafBack.position = packageCenter
        leafBack.zPosition = 0
        addChild(leafBack)

        leafFront = SKSpriteNode(imageNamed: "packagingState2Front")
        leafFront.name = "leafFront"
        leafFront.size = leafSize
        leafFront.position = packageCenter
        leafFront.zPosition = 2
        leafFront.isHidden = true
        addChild(leafFront)
    }

    private func addArrows() {
        let offset: CGFloat = 165
        let configs: [(FoldArrow, CGPoint, CGFloat)] = [
            (.right, CGPoint(x: packageCenter.x + offset, y: packageCenter.y), 0),
            (.left, CGPoint(x: packageCenter.x - offset, y: packageCenter.y), .pi),
            (.up, CGPoint(x: packageCenter.x, y: packageCenter.y + offset), .pi / 2),
            (.down, CGPoint(x: packageCenter.x, y: packageCenter.y - offset), -.pi / 2)
        ]

        for (direction, position, rotation) in configs {
            let arrow = SKSpriteNode(imageNamed: "arrow-right")
            arrow.size = CGSize(width: 38, height: 38)
            arrow.position = position
            arrow.zRotation = rotation
            arrow.alpha = 0.3
            arrow.zPosition = 4
            addChild(arrow)
            arrows[direction] = arrow
        }
    }

    private func addRope() {
        rope = SKSpriteNode(imageNamed: "packagingRope")
        rope.name = "rope"
        rope.size = ropeSize
        rope.position = ropeStartPosition
        rope.zPosition = 3
        rope.isHidden = true
        addChild(rope)
    }

    private func addKnottedRope() {
        knottedRope = SKSpriteNode(imageNamed: "packagingKnottedRope")
        knottedRope.size = ropeSize
        knottedRope.position = packageCenter
        knottedRope.zPosition = 3.5
        knottedRope.isHidden = true
        addChild(knottedRope)
    }

    // MARK: - State machine

    private func refreshState() {
        leafBack.texture = SKTexture(imageNamed: "packagingState\(currentState)Back")

        if currentState == 1 {
            leafFront.isHidden = true
        } else {
            leafFront.isHidden = false
            leafFront.texture = SKTexture(imageNamed: "packagingState\(currentState)Front")
        }

        refreshArrows()

        if currentState == 5 {
            rope.isHidden = false
            showHint(Loc.t(.foldingHintTieRope), on: hintLabel)
        }
    }

    private func activeArrow(for state: Int) -> FoldArrow? {
        switch state {
        case 1: return .right
        case 2: return .left
        case 3: return .down
        case 4: return .up
        default: return nil
        }
    }

    private func refreshArrows() {
        guard clothesPlaced else {
            for (_, arrow) in arrows {
                arrow.removeAction(forKey: "pulse")
                arrow.alpha = 0
                arrow.setScale(1.0)
            }
            return
        }

        let active = activeArrow(for: currentState)
        for (direction, arrow) in arrows {
            arrow.removeAction(forKey: "pulse")
            guard direction == active else {
                arrow.alpha = currentState == 5 ? 0 : 0.3
                arrow.setScale(1.0)
                continue
            }

            arrow.alpha = 1.0
            let pulse = SKAction.sequence([
                .scale(to: 1.15, duration: 0.4),
                .scale(to: 1.0, duration: 0.4)
            ])
            arrow.run(.repeatForever(pulse), withKey: "pulse")
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let name = tappedNodeName(at: location)

        if handleSettingsPopupTouchesBegan(at: location) { return }
        if handleTipPopupTap(at: location) { return }

        if handleStationArrowTap(nodeName: name, current: .folding) { return }
        if handleSettingsButtonTap(nodeName: name) { return }

        if name == "help" {
            runButtonTapAnimation(on: helpButton) {
                self.showTipPopup(text: Loc.t(.infoFolding))
            }
            return
        }

        if isFoldingReady, !clothesPlaced, clothesDragIcon.frame.insetBy(dx: -10, dy: -10).contains(location) {
            isDraggingClothes = true
            clothesDragOffset = CGPoint(x: clothesDragIcon.position.x - location.x, y: clothesDragIcon.position.y - location.y)
            return
        }

        if currentState == 5, !isRopeTied, rope.frame.insetBy(dx: -10, dy: -10).contains(location) {
            isDraggingRope = true
            ropeDragOffset = CGPoint(x: rope.position.x - location.x, y: rope.position.y - location.y)
            rope.texture = SKTexture(imageNamed: "packagingPickedRope")
            return
        }

        guard clothesPlaced else { return }
        swipeStart = location
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if handleSettingsPopupTouchesMoved(at: location) { return }

        if isDraggingClothes {
            clothesDragIcon.position = CGPoint(x: location.x + clothesDragOffset.x, y: location.y + clothesDragOffset.y)
            return
        }

        guard isDraggingRope else { return }
        rope.position = CGPoint(x: location.x + ropeDragOffset.x, y: location.y + ropeDragOffset.y)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if handleSettingsPopupTouchesEnded() { return }

        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if isDraggingClothes {
            isDraggingClothes = false
            resolveClothesDrop()
            return
        }

        if isDraggingRope {
            isDraggingRope = false
            resolveRopeDrop()
            return
        }

        if let start = swipeStart {
            resolveSwipe(from: start, to: location)
        }
        swipeStart = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDraggingClothes = false
        isDraggingRope = false
        swipeStart = nil
    }

    // MARK: - Swipe resolution

    private func resolveSwipe(from start: CGPoint, to end: CGPoint) {
        let dx = end.x - start.x
        let dy = end.y - start.y

        guard isCorrectSwipe(dx: dx, dy: dy) else {
            shakeActiveArrow()
            return
        }

        playSound("folding")
        leafBack.run(.sequence([.scale(to: 1.05, duration: 0.1), .scale(to: 1.0, duration: 0.1)]))
        leafFront.run(.sequence([.scale(to: 1.05, duration: 0.1), .scale(to: 1.0, duration: 0.1)]))

        currentState += 1
        refreshState()
    }

    private func isCorrectSwipe(dx: CGFloat, dy: CGFloat) -> Bool {
        switch currentState {
        case 1: return dx < -minSwipeDistance && abs(dx) > abs(dy)
        case 2: return dx > minSwipeDistance && abs(dx) > abs(dy)
        case 3: return dy > minSwipeDistance && abs(dy) > abs(dx)
        case 4: return dy < -minSwipeDistance && abs(dy) > abs(dx)
        default: return false
        }
    }

    private func shakeActiveArrow() {
        guard let active = activeArrow(for: currentState), let arrow = arrows[active] else { return }
        let shake = SKAction.sequence([
            .moveBy(x: 8, y: 0, duration: 0.05),
            .moveBy(x: -16, y: 0, duration: 0.05),
            .moveBy(x: 16, y: 0, duration: 0.05),
            .moveBy(x: -8, y: 0, duration: 0.05)
        ])
        arrow.run(.repeat(shake, count: 3))
    }

    // MARK: - Clothes drag

    private func resolveClothesDrop() {
        guard packageBounds.contains(clothesDragIcon.position) else {
            clothesDragIcon.run(.move(to: basketPosition, duration: 0.3))
            showHint(Loc.t(.foldingHintDragClothesToCenter), on: hintLabel)
            return
        }

        clothesPlaced = true
        clothesDragIcon.isHidden = true
        clothesShadow.isHidden = false
        clothesPile.isHidden = false
        basket.texture = SKTexture(imageNamed: "packagingBasketEmpty")

        refreshState()
        showHint(Loc.t(.foldingHintSwipeToFold), on: hintLabel)
    }

    // MARK: - Rope drag

    private func resolveRopeDrop() {
        guard packageBounds.contains(rope.position) else {
            rope.run(.move(to: ropeStartPosition, duration: 0.3))
            rope.texture = SKTexture(imageNamed: "packagingRope")
            showHint(Loc.t(.foldingHintDragRopeToCenter), on: hintLabel)
            return
        }

        completePackaging()
    }

    private func completePackaging() {
        isRopeTied = true
        rope.isHidden = true

        knottedRope.isHidden = false
        knottedRope.setScale(0.5)
        knottedRope.run(.scale(to: 1.0, duration: 0.25))

        showHint(Loc.t(.foldingHintPackaged), on: hintLabel)

        GameState.shared.isPackaged = true

        run(.sequence([
            .wait(forDuration: 1.5),
            .run { [weak self] in
                guard let self else { return }
                self.goTo(CustomerScene.makeCurrent(size: self.size))
            }
        ]))
    }

    // MARK: - Sound

    private func playSound(_ name: String) {
        AudioManager.shared.playSFX(name)
    }
}
