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
    private var isRopeTied = false
    private var isDraggingRope = false
    private var isDraggingClothes = false
    private var ropeDragOffset = CGPoint.zero
    private var clothesDragOffset = CGPoint.zero
    private var swipeStart: CGPoint?

    private var leafBack: SKSpriteNode!
    private var leafFront: SKSpriteNode!
    private var clothesPile: SKNode! // Container untuk tumpukan pakaian
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
    
    // 🔥 PENGATURAN JARAK TUMPUKAN (Hanya vertikal agar tumpukan lurus)
    private let stackVerticalOffset: CGFloat = 16.0
    
    // 🔥 PENGATURAN UKURAN PAKAIAN ADAPTIF
    private var foldedClothesSize: CGSize {
        // Ambil jumlah pakaian yang selesai dikeringkan
        let driedCount = GameState.shared.itemProgress.filter { $0.isDried }.count
        let scale: CGFloat
        
        // Sesuaikan skala berdasarkan jumlah pakaian agar selalu muat di dalam daun
        switch driedCount {
        case 0, 1:
            scale = 0.58 // Ukuran normal
        case 2:
            scale = 0.50 // Sedikit lebih kecil
        case 3:
            scale = 0.42 // Lebih kecil lagi
        default:
            scale = 0.35 // Otomatis diperkecil maksimal untuk >3 pakaian
        }
        
        return CGSize(width: leafSize.width * scale, height: leafSize.height * scale)
    }

    private var packageCenter: CGPoint { CGPoint(x: size.width * 0.5, y: size.height * 0.5) }
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
    
    // DATA DARI QUEUE
    /// Mengambil pattern pakaian yang berada PALING ATAS pada tumpukan (terakhir masuk antrean selesai).
    private var topPatternID: Int {
        return GameState.shared.itemProgress.filter { $0.isDried }.last?.dryingVariant ?? 1
    }

    /// Index of the next basket item still waiting to be dragged into the package, in
    /// clothesCount order — nil once every item has been stacked.
    private var nextUnfoldedIndex: Int? {
        GameState.shared.itemProgress.firstIndex(where: { !$0.isFolded })
    }

    private var clothesPlaced: Bool { nextUnfoldedIndex == nil }

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

    private var isFoldingReady: Bool { GameState.shared.isReadyForFolding }

    private var initialHintText: String {
        guard !isFoldingReady else { return Loc.t(.foldingHintDragClothes) }
        return GameState.shared.isFullyWashed ? Loc.t(.foldingHintNotDried) : Loc.t(.foldingHintNotWashed)
    }

    // MARK: - Setup

    private func addBasket() {
        basket = SKSpriteNode(imageNamed: "packagingBasketEmpty")
        basket.size = CGSize(width: 90, height: 70)
        basket.position = basketPosition
        basket.zPosition = 6
        addChild(basket)
        updateBasketTexture()
    }

    /// One sprite per item already dragged into the package, restored in clothesCount
    /// order if the player left mid-stack via the station arrows and came back — each
    /// sits a touch higher than the last so the most recently placed item stays on top.
    /// Sized to sit inside the wrap's actual cutout window, not the full leaf art's bounds —
    /// at leafSize's own scale it spilled out past the folded flaps into the background.
    private func addClothesLayer() {
        clothesShadow = SKSpriteNode(imageNamed: "benchmarkFoldedClothesPiled")
        clothesShadow.size = foldedClothesSize
        clothesShadow.position = packageCenter
        clothesShadow.zPosition = 1.0
        clothesShadow.isHidden = true
        addChild(clothesShadow)

        // Container the placed items stack into, one on top of the last.
        clothesPile = SKNode()
        clothesPile.name = "clothesPile"
        clothesPile.position = packageCenter
        clothesPile.zPosition = 2.0 // below leafFront (3.0)
        clothesPile.isHidden = true
        addChild(clothesPile)

        for index in GameState.shared.itemProgress.indices where GameState.shared.itemProgress[index].isFolded {
            addPlacedClothesSprite(for: index)
        }
    }

    /// Vertical slot for the nth item in the stack, centered across every dried item so the
    /// pile doesn't drift up/down as items are added one at a time.
    private func stackSlotPosition(for slot: Int) -> CGPoint {
        let count = CGFloat(GameState.shared.itemProgress.filter { $0.isDried }.count)
        let startY = -((count - 1) * stackVerticalOffset) / 2
        return CGPoint(x: 0, y: startY + CGFloat(slot) * stackVerticalOffset)
    }

    private func addPlacedClothesSprite(for index: Int) {
        let variant = GameState.shared.itemProgress[index].dryingVariant
        let sprite = SKSpriteNode(imageNamed: "packagingFoldedClothes\(variant)")
        sprite.size = foldedClothesSize
        let slot = clothesPile.children.count
        sprite.position = stackSlotPosition(for: slot)
        sprite.zPosition = CGFloat(slot) * 0.1
        clothesPile.addChild(sprite)

        clothesShadow.isHidden = false
        clothesPile.isHidden = false
    }

    /// The next basket item lifted out and dragged into the package. Hidden except while
    /// actively being dragged, and re-textured after every drop to match whichever item
    /// is up next.
    private func addClothesDragIcon() {
        clothesDragIcon = SKSpriteNode()
        clothesDragIcon.name = "clothesDragIcon"
        clothesDragIcon.size = foldedClothesSize
        clothesDragIcon.position = basketPosition
        clothesDragIcon.zPosition = 7 // Harus paling atas saat di-drag
        clothesDragIcon.isHidden = true
        addChild(clothesDragIcon)
        refreshClothesDragIcon()
    }

    private func refreshClothesDragIcon() {
        guard let index = nextUnfoldedIndex else { return }
        let variant = GameState.shared.itemProgress[index].dryingVariant
        clothesDragIcon.texture = SKTexture(imageNamed: "packagingFoldedClothes\(variant)")
    }

    /// Basket art shows exactly how many items are left to fold (packagingBasket1...4),
    /// down to packagingBasketEmpty once the last one's been dragged out.
    private func updateBasketTexture() {
        let remaining = GameState.shared.itemProgress.filter { !$0.isFolded }.count
        guard isFoldingReady, remaining > 0 else {
            basket.texture = SKTexture(imageNamed: "packagingBasketEmpty")
            return
        }
        basket.texture = SKTexture(imageNamed: "packagingBasket\(min(remaining, 4))")
    }

    private func addLeafLayers() {
        leafBack = SKSpriteNode(imageNamed: "packagingState1Back")
        leafBack.name = "leafBack"
        leafBack.size = leafSize
        leafBack.position = packageCenter
        leafBack.zPosition = 0 // Paling bawah
        addChild(leafBack)

        leafFront = SKSpriteNode(imageNamed: "packagingState2Front")
        leafFront.name = "leafFront"
        leafFront.size = leafSize
        leafFront.position = packageCenter
        leafFront.zPosition = 3 // Di atas pakaian (2.0) tapi di bawah arrow/tali
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
        rope.zPosition = 5
        addChild(rope)
    }

    private func addKnottedRope() {
        knottedRope = SKSpriteNode(imageNamed: "packagingKnottedRope")
        knottedRope.size = ropeSize
        knottedRope.position = packageCenter
        knottedRope.zPosition = 5
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

        if isFoldingReady, !clothesPlaced, clothesDragIcon.frame.insetBy(dx: -10, dy: -10).contains(location) || basket.contains(location) {
            isDraggingClothes = true
            clothesDragIcon.isHidden = false
            clothesDragOffset = CGPoint(x: clothesDragIcon.position.x - location.x, y: clothesDragIcon.position.y - location.y)
            return
        }

        if !isRopeTied, rope.frame.insetBy(dx: -10, dy: -10).contains(location) {
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
        if isDraggingClothes {
            clothesDragIcon.position = basketPosition
            clothesDragIcon.isHidden = true
        }
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
            clothesDragIcon.run(.sequence([
                .move(to: basketPosition, duration: 0.3),
                .run { [weak self] in self?.clothesDragIcon.isHidden = true }
            ]))
            showHint(Loc.t(.foldingHintDragClothesToCenter), on: hintLabel)
            return
        }

        guard let index = nextUnfoldedIndex else { return }
        GameState.shared.itemProgress[index].isFolded = true
        addPlacedClothesSprite(for: index)

        clothesDragIcon.isHidden = true
        clothesDragIcon.position = basketPosition
        updateBasketTexture()

        guard clothesPlaced else {
            refreshClothesDragIcon()
            showHint(Loc.t(.foldingHintDragClothes), on: hintLabel)
            return
        }

        refreshState()
        showHint(Loc.t(.foldingHintSwipeToFold), on: hintLabel)
    }

    // MARK: - Rope drag

    private func resolveRopeDrop() {
        guard currentState == 5 else {
            rope.run(.move(to: ropeStartPosition, duration: 0.3))
            rope.texture = SKTexture(imageNamed: "packagingRope")
            return
        }

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
        leafFront.texture = SKTexture(imageNamed: "packagingState6Front")

        // Sealed now — no reason to still show the folded clothes underneath the closed wrap.
        clothesPile.isHidden = true
        clothesShadow.isHidden = true

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
