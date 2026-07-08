//
//  DryingScene.swift
//  Laundry
//
//  Created by Aulia Agus on 01/07/26.
//
//  Drag washed items from the wet basket onto the rope, blow into the mic to fill the
//  drying progress bar to 100%, then drag the dried item into the dry basket.

import SpriteKit
import AVFoundation

class DryingScene: SKScene {

    private enum DragOrigin {
        case basket
        case rope
    }

    private var itemNodes: [SKSpriteNode?] = []
    private var dragState: (index: Int, origin: DragOrigin)?

    /// Which rack slot each currently-hung item occupies, assigned once when it's hung and
    /// kept stable — picking up or removing one item never reflows the others' positions.
    private var itemSlots: [Int: Int] = [:]

    private var basketNode: SKSpriteNode!
    private var basketPiles: SKSpriteNode!
    private var dryBasketNode: SKSpriteNode!
    private var dryBasketPiles: SKSpriteNode!
    private var pickedClothes: SKSpriteNode!

    private var helpButton: SKSpriteNode!
    private var hintLabel: SKLabelNode!
    private var statusLabel: SKLabelNode!
    private var blowBarFill: SKShapeNode!
    private var blowPercentLabel: SKLabelNode!

    private let micEngine = AVAudioEngine()
    private var micPermissionGranted = false
    private var micEngineStarted = false
    private var isBlowing = false

    /// The leaf tool shown instead of the mic UI when Settings has the microphone turned off —
    /// swipe it across the rope to dry clothes instead of blowing.
    private var leafNode: SKSpriteNode?
    private var isFanning = false
    private var lastFanPoint: CGPoint?
    private var fanAccumDistance: CGFloat = 0
    private let fanSwipeDistance: CGFloat = 40

    /// Decorative rope-and-leaf-bundle prop shown next to the leaf tool — hides while the
    /// player is actively fanning, and never shows at all in microphone mode.
    private var leafRopeNode: SKSpriteNode?

    private var isOverblowing = false
    private let blowThreshold: Float = -20
    private let overblowThreshold: Float = -6

    private let itemSize = CGSize(width: 70, height: 90)
    private let blowBarWidth: CGFloat = 200
    private let blowBarHeight: CGFloat = 18

    /// Tints the actual clothing texture light blue while wet instead of laying a plain
    /// rectangular color block on top — colorBlendFactor only tints the art's own opaque
    /// pixels, so the wet look follows the garment's real silhouette (no visible box edges).
    private let wetTintColor = UIColor(red: 0.55, green: 0.78, blue: 0.95, alpha: 1.0)

    private var shakeCamera: SKCameraNode!

    private var ropeY: CGFloat { size.height * 0.78 }
    private var basketPosition: CGPoint { CGPoint(x: size.width * 0.15, y: size.height * 0.24) }
    private var dryBasketPosition: CGPoint { CGPoint(x: size.width * 0.85, y: size.height * 0.24) }
    private var rackZone: CGRect { CGRect(x: size.width * 0.15, y: ropeY - 60, width: size.width * 0.7, height: 90) }
    private var basketZone: CGRect { CGRect(x: basketPosition.x - 60, y: basketPosition.y - 50, width: 120, height: 110) }
    private var dryBasketZone: CGRect { CGRect(x: dryBasketPosition.x - 60, y: dryBasketPosition.y - 50, width: 120, height: 110) }

    override func didMove(to view: SKView) {
        // A camera lets us shake the whole screen (see shakeScreen()) by moving the camera
        // instead of scene content — positioned at scene center with no zoom/rotation, it
        // renders identically to having no camera at all until it's actually shaken.
        shakeCamera = SKCameraNode()
        shakeCamera.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(shakeCamera)
        camera = shakeCamera

        addBackground(imageNamed: "dryingBackground")
        addCurrencyHUD(topLeftOrigin: CGPoint(x: size.width * 0.05, y: size.height * 0.90), day: GameState.shared.currentDay, coins: GameState.shared.score)
        addStationArrows(current: .drying)

        addRope()
        addBasketVisual()
        addBlowBar()
        addStatusLabel()
        setupPickedClothesNode()
        setupItems()

        helpButton = makeButton(
            imageNamed: AssetName.UI.btnInstruction,
            position: CGPoint(x: size.width * 0.85, y: size.height * 0.90),
            scale: 0.8,
            nodeName: "help"
        )

        hintLabel = makeHintLabel(position: CGPoint(x: size.width / 2, y: size.height * 0.08))

        addSettingsButton()

        setupDryingInput()
    }

    override func willMove(from view: SKView) {
        teardownDryingInput()
    }

    // MARK: - Input mode (microphone vs leaf swipe)

    private func setupDryingInput() {
        if SettingsManager.shared.microphoneEnabled {
            requestMicPermissionAndStart()
        } else {
            addLeafTool()
            addLeafRopeProp()
            showHint(Loc.t(.dryingHintSwipeLeaf), on: hintLabel)
        }
    }

    private func teardownDryingInput() {
        if micEngineStarted {
            stopMicEngine()
        }
        leafNode?.removeFromParent()
        leafNode = nil
        leafRopeNode?.removeFromParent()
        leafRopeNode = nil
        isFanning = false
        lastFanPoint = nil
        isOverblowing = false
    }

    /// Called when the settings popup closes, in case the microphone toggle changed mid-scene.
    private func refreshDryingInputMode() {
        teardownDryingInput()
        setupDryingInput()
    }

    /// Hidden at rest — it only appears while the player is actively dragging/fanning it
    /// (see touchesBegan/touchesEnded/touchesCancelled), so it doesn't clutter the rope area
    /// when it's not in use.
    private func addLeafTool() {
        let leaf = SKSpriteNode(imageNamed: "dryingLeafFan")
        leaf.name = "leafTool"
        leaf.size = CGSize(width: 74, height: 60)
        leaf.position = CGPoint(x: size.width * 0.5, y: ropeY - 70)
        leaf.zPosition = 40
        leaf.isHidden = true
        addChild(leaf)
        leafNode = leaf
    }

    /// Sits just below center screen — clear of the fan and the hanging rack so it doesn't
    /// compete with either.
    private func addLeafRopeProp() {
        let prop = SKSpriteNode(imageNamed: "dryingLeafRope")
        prop.size = CGSize(width: 66, height: 66)
        prop.position = CGPoint(x: size.width * 0.5, y: size.height * 0.45)
        prop.zPosition = 4
        addChild(prop)
        leafRopeNode = prop
    }

    // MARK: - Setup

    /// dryingRope.png is baked at the same canvas size as dryingBackground.png, with the rope
    /// already drawn in place — so it's overlaid full-screen rather than stretched into a thin bar.
    private func addRope() {
        let rope = SKSpriteNode(imageNamed: "dryingRope")
        rope.position = CGPoint(x: size.width / 2, y: size.height / 2)
        rope.size = size
        rope.zPosition = 0
        addChild(rope)
    }

    /// Same basket + pile formatting as WashingScene: an empty basket sprite with the
    /// pattern-specific pile sprite sized and positioned to exactly overlay it (not a
    /// smaller, offset sliver), for every pattern 1...4.
    private func addBasketVisual() {
        basketNode = SKSpriteNode(imageNamed: "dryingBasket")
        basketNode.size = CGSize(width: 100, height: 78)
        basketNode.position = basketPosition
        basketNode.zPosition = 2
        addChild(basketNode)

        basketPiles = SKSpriteNode(imageNamed: "dryingBasketPiles1")
        basketPiles.size = basketNode.size
        basketPiles.position = basketNode.position
        basketPiles.zPosition = 3
        addChild(basketPiles)

        dryBasketNode = SKSpriteNode(imageNamed: "dryingBasket")
        dryBasketNode.size = CGSize(width: 100, height: 78)
        dryBasketNode.position = dryBasketPosition
        dryBasketNode.zPosition = 2
        addChild(dryBasketNode)

        dryBasketPiles = SKSpriteNode(imageNamed: "dryingBasketPiles1")
        dryBasketPiles.size = dryBasketNode.size
        dryBasketPiles.position = dryBasketNode.position
        dryBasketPiles.zPosition = 3
        addChild(dryBasketPiles)
    }

    private func setupPickedClothesNode() {
        pickedClothes = SKSpriteNode(imageNamed: "dryingClothesPicked1")
        pickedClothes.size = itemSize
        pickedClothes.zPosition = 30
        pickedClothes.isHidden = true
        addChild(pickedClothes)
    }

    private func setupItems() {
        itemNodes = Array(repeating: nil, count: GameState.shared.clothesTypes.count)
        itemSlots = [:]

        for index in GameState.shared.itemProgress.indices where GameState.shared.itemProgress[index].isHungToDry {
            hangItem(index: index)
        }

        updateBasketPilesVisibility()
        updateBlowBar()
    }

    private func makeHungItemNode(index: Int) -> SKSpriteNode {
        let variant = GameState.shared.itemProgress[index].dryingVariant
        let node = SKSpriteNode(imageNamed: "dryingClothesHanged\(variant)")
        node.size = itemSize
        node.name = "item-\(index)"
        node.zPosition = 5

        let progress = GameState.shared.itemProgress[index].dryProgress
        node.color = wetTintColor
        node.colorBlendFactor = 1 - progress

        return node
    }

    /// Hangs `index` at its previously-assigned rack slot, or claims the next free one if
    /// this is the first time it's being hung. The slot sticks until `freeSlot(for:)` is
    /// called, so picking up or removing a different item never moves this one.
    private func hangItem(index: Int) {
        let slot = itemSlots[index] ?? nextFreeSlot()
        itemSlots[index] = slot

        let node = makeHungItemNode(index: index)
        node.position = rackSlotPosition(slot: slot)
        addChild(node)
        itemNodes[index] = node
    }

    private func nextFreeSlot() -> Int {
        var slot = 0
        while itemSlots.values.contains(slot) { slot += 1 }
        return slot
    }

    /// Releases `index`'s rack slot once it's no longer hung (dried and collected, or
    /// dropped/fallen back into the wet basket) so a future item can claim it.
    private func freeSlot(for index: Int) {
        itemSlots.removeValue(forKey: index)
    }

    private func rackSlotPosition(slot: Int) -> CGPoint {
        let spacing: CGFloat = 80
        let startX = size.width * 0.55 - spacing * 1.5
        return CGPoint(x: startX + CGFloat(slot) * spacing, y: ropeY - 55)
    }

    private func updateBasketPilesVisibility() {
        if let index = GameState.shared.itemProgress.firstIndex(where: {
            $0.isWashed && !$0.isHungToDry && !$0.isDried
        }) {
            basketPiles.texture = SKTexture(imageNamed: "dryingBasketPiles\(GameState.shared.itemProgress[index].dryingVariant)")
            basketPiles.isHidden = false
        } else {
            basketPiles.isHidden = true
        }

        if let index = GameState.shared.itemProgress.firstIndex(where: { $0.isDried && !$0.isHungToDry }) {
            dryBasketPiles.texture = SKTexture(imageNamed: "dryingBasketPiles\(GameState.shared.itemProgress[index].dryingVariant)")
            dryBasketPiles.isHidden = false
        } else {
            dryBasketPiles.isHidden = true
        }
    }

    /// Same look as the Settings popup's sliders (slideBase track + amber fill), minus the thumb —
    /// this one's a read-only progress display, not a control.
    private func addBlowBar() {
        let bg = SKSpriteNode(imageNamed: AssetName.UI.slideBase)
        bg.size = CGSize(width: blowBarWidth, height: blowBarHeight)
        bg.position = CGPoint(x: size.width / 2, y: size.height * 0.12)
        bg.zPosition = 10
        addChild(bg)

        let fill = SKShapeNode()
        fill.fillColor = sliderFillColor
        fill.strokeColor = .clear
        fill.zPosition = 11
        bg.addChild(fill)
        blowBarFill = fill
        setBlowBarFillPath(fraction: 0)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "0%"
        label.fontSize = 14
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: blowBarHeight)
        label.zPosition = 12
        bg.addChild(label)
        blowPercentLabel = label
    }

    private func setBlowBarFillPath(fraction: CGFloat) {
        let fillHeight = blowBarHeight - 6
        let filledWidth = blowBarWidth * max(0, min(1, fraction))
        blowBarFill.path = CGPath(
            roundedRect: CGRect(x: -blowBarWidth / 2, y: -fillHeight / 2, width: filledWidth, height: fillHeight),
            cornerWidth: fillHeight / 2,
            cornerHeight: fillHeight / 2,
            transform: nil
        )
    }

    private func addStatusLabel() {
        statusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        statusLabel.fontSize = 26
        statusLabel.fontColor = .white
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.45)
        statusLabel.zPosition = 20
        statusLabel.alpha = 0
        addChild(statusLabel)
    }

    // MARK: - Microphone

    private func requestMicPermissionAndStart() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                self.micPermissionGranted = granted
                if granted {
                    self.startMicEngine()
                } else {
                    self.showHint(Loc.t(.dryingHintMicPermission), on: self.hintLabel)
                }
            }
        }
    }

    private func startMicEngine() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
        } catch {
            showHint(Loc.t(.dryingHintMicStartFailed), on: hintLabel)
            return
        }

        let inputNode = micEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }

        do {
            try micEngine.start()
            micEngineStarted = true
        } catch {
            showHint(Loc.t(.dryingHintMicStartFailed), on: hintLabel)
        }
    }

    private func stopMicEngine() {
        micEngine.inputNode.removeTap(onBus: 0)
        micEngine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        micEngineStarted = false
    }

    /// Runs on the audio engine's internal thread — keep this cheap and hop to main before touching game state.
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        var sumOfSquares: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sumOfSquares += sample * sample
        }
        let rms = sqrt(sumOfSquares / Float(frameLength))
        let avgPower = 20 * log10(max(rms, 0.000001))

        DispatchQueue.main.async { [weak self] in
            self?.handleMicPower(avgPower)
        }
    }

    private func handleMicPower(_ power: Float) {
        if power > overblowThreshold {
            isBlowing = false
            if !isOverblowing {
                isOverblowing = true
                dropOverblownItems()
            }
        } else if power > blowThreshold {
            isOverblowing = false
            if !isBlowing {
                isBlowing = true
                advanceDrying()
            }
        } else {
            isBlowing = false
            isOverblowing = false
        }
    }

    // MARK: - Drying progress (advanced by either a mic blow or a leaf swipe)

    private func advanceDrying() {
        let dryingIndices = GameState.shared.itemProgress.indices.filter {
            GameState.shared.itemProgress[$0].isHungToDry && GameState.shared.itemProgress[$0].dryProgress < 1 && itemNodes[$0] != nil
        }
        guard !dryingIndices.isEmpty else { return }

        for index in dryingIndices {
            let progress = min(1, GameState.shared.itemProgress[index].dryProgress + 0.12)
            GameState.shared.itemProgress[index].dryProgress = progress
            itemNodes[index]?.colorBlendFactor = 1 - progress
        }

        swayAndFlash(indices: dryingIndices)
        updateBlowBar()

        if GameState.shared.isFullyDried {
            showStatus("All dry!")
            run(.sequence([.wait(forDuration: 1.5), .run { [weak self] in self?.hideStatus() }]))
        }
    }

    private func swayAndFlash(indices: [Int]) {
        let degreesToRadians: (CGFloat) -> CGFloat = { $0 * .pi / 180 }
        let sway = SKAction.sequence([
            .rotate(toAngle: degreesToRadians(5), duration: 0.1, shortestUnitArc: true),
            .rotate(toAngle: degreesToRadians(-5), duration: 0.15, shortestUnitArc: true),
            .rotate(toAngle: 0, duration: 0.1, shortestUnitArc: true)
        ])

        for index in indices {
            guard let node = itemNodes[index] else { continue }
            let variant = GameState.shared.itemProgress[index].dryingVariant
            node.texture = SKTexture(imageNamed: "dryingClothesBlowed\(variant)")
            node.run(sway) {
                guard GameState.shared.itemProgress[index].isHungToDry else { return }
                node.texture = SKTexture(imageNamed: "dryingClothesHanged\(variant)")
            }
        }
    }

    /// Blowing too hard drops any still-wet hung items back into the wet basket — a real penalty,
    /// distinct from the gentle sway a normal-strength blow triggers.
    private func dropOverblownItems() {
        let fallingIndices = GameState.shared.itemProgress.indices.filter {
            GameState.shared.itemProgress[$0].isHungToDry && GameState.shared.itemProgress[$0].dryProgress < 1 && itemNodes[$0] != nil
        }
        guard !fallingIndices.isEmpty else { return }

        showStatus("Too hard! It fell!")
        run(.sequence([.wait(forDuration: 1.0), .run { [weak self] in self?.hideStatus() }]))
        shakeScreen()
        HapticsManager.shared.playOverblowImpact()

        for index in fallingIndices {
            guard let node = itemNodes[index] else { continue }
            let variant = GameState.shared.itemProgress[index].dryingVariant
            let groundPosition = CGPoint(x: node.position.x, y: node.position.y - 60)

            node.run(.sequence([
                .group([
                    .moveBy(x: 0, y: -60, duration: 0.35),
                    .rotate(byAngle: .pi / 6, duration: 0.35)
                ]),
                .removeFromParent()
            ]))
            itemNodes[index] = nil
            freeSlot(for: index)

            // Leave a fallen-clothes sprite lying on the ground as a visible penalty beat,
            // then sweep the item back into the wet basket 2 seconds later — not instantly.
            // isHungToDry/dryProgress stay untouched until then, and the `itemNodes[$0] !=
            // nil` filters above keep this index out of advanceDrying/another overblow in
            // the meantime, so it can't be double-processed while it's "on the ground."
            let groundEffect = SKSpriteNode(imageNamed: "dryingClothesFallen\(variant)")
            groundEffect.size = itemSize
            groundEffect.position = groundPosition
            groundEffect.zRotation = .pi / 6
            groundEffect.zPosition = 4
            addChild(groundEffect)

            groundEffect.run(.sequence([
                .wait(forDuration: 2.0),
                .fadeOut(withDuration: 0.3),
                .removeFromParent(),
                .run { [weak self] in
                    guard let self else { return }
                    GameState.shared.itemProgress[index].isHungToDry = false
                    GameState.shared.itemProgress[index].dryProgress = 0
                    self.updateBasketPilesVisibility()
                    self.updateBlowBar()
                }
            ]))
        }
    }

    /// Jolts the camera through a quick decaying zigzag — since the camera defines the
    /// viewport, moving it (rather than any content node) shakes literally everything
    /// on screen, popups included, matching the force of an overblow.
    private func shakeScreen() {
        let originalPosition = shakeCamera.position
        let shake = SKAction.sequence([
            .moveBy(x: -14, y: 6, duration: 0.035),
            .moveBy(x: 22, y: -10, duration: 0.035),
            .moveBy(x: -20, y: 8, duration: 0.035),
            .moveBy(x: 16, y: -6, duration: 0.035),
            .moveBy(x: -10, y: 4, duration: 0.035),
            .moveBy(x: 6, y: -2, duration: 0.035),
            .move(to: originalPosition, duration: 0.03)
        ])
        shakeCamera.run(shake)
    }

    /// Bar reflects actual drying progress (average of all hung items) toward 100% — not raw mic volume.
    private func updateBlowBar() {
        let hungProgress = GameState.shared.itemProgress.filter { $0.isHungToDry }.map { $0.dryProgress }
        let fraction = hungProgress.isEmpty ? 0 : hungProgress.reduce(0, +) / CGFloat(hungProgress.count)
        setBlowBarFillPath(fraction: fraction)
        blowPercentLabel.text = "\(Int(fraction * 100))%"
    }

    // MARK: - UI helpers

    private func showStatus(_ text: String) {
        statusLabel.text = text
        statusLabel.alpha = 0
        statusLabel.run(.fadeIn(withDuration: 0.2))
    }

    private func hideStatus() {
        statusLabel.run(.fadeOut(withDuration: 0.2))
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let name = tappedNodeName(at: location)

        if handleSettingsPopupTouchesBegan(at: location) { return }
        if handleTipPopupTap(at: location) { return }

        if handleStationArrowTap(nodeName: name, current: .drying) { return }
        if handleSettingsButtonTap(nodeName: name, onClose: { [weak self] in self?.refreshDryingInputMode() }) { return }

        if name == "help" {
            runButtonTapAnimation(on: helpButton) {
                if SettingsManager.shared.microphoneEnabled {
                    self.showTipPopup(
                        text: Loc.t(.infoDryingMic),
                        footnote: Loc.t(.infoDryingMicFootnote)
                    )
                } else {
                    self.showTipPopup(
                        text: Loc.t(.infoDryingLeaf),
                        footnote: Loc.t(.infoDryingLeafFootnote)
                    )
                }
            }
            return
        }

        guard dragState == nil else { return }

        if let name, name.hasPrefix("item-"), let index = Int(name.dropFirst("item-".count)) {
            beginDrag(index: index, from: .rope, at: location)
            return
        }

        if basketPiles.contains(location) || basketNode.contains(location),
           let index = GameState.shared.itemProgress.firstIndex(where: { $0.isWashed && !$0.isHungToDry && !$0.isDried }) {
            beginDrag(index: index, from: .basket, at: location)
            return
        }

        if leafNode != nil {
            isFanning = true
            lastFanPoint = location
            fanAccumDistance = 0
            leafNode?.position = location
            leafNode?.isHidden = false
            leafRopeNode?.isHidden = true
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if handleSettingsPopupTouchesMoved(at: location) { return }

        if isFanning {
            leafNode?.position = location
            if let last = lastFanPoint {
                fanAccumDistance += hypot(location.x - last.x, location.y - last.y)
            }
            lastFanPoint = location
            if fanAccumDistance > fanSwipeDistance {
                fanAccumDistance = 0
                advanceDrying()
            }
            return
        }

        guard dragState != nil else { return }
        pickedClothes.position = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if handleSettingsPopupTouchesEnded() { return }

        if isFanning {
            isFanning = false
            lastFanPoint = nil
            leafNode?.isHidden = true
            leafRopeNode?.isHidden = false
            return
        }

        guard let drag = dragState else { return }
        dragState = nil
        pickedClothes.isHidden = true
        resolveDrop(index: drag.index, origin: drag.origin, at: pickedClothes.position)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isFanning {
            isFanning = false
            lastFanPoint = nil
            leafNode?.isHidden = true
            leafRopeNode?.isHidden = false
            return
        }

        guard let drag = dragState else { return }
        dragState = nil
        pickedClothes.isHidden = true
        if drag.origin == .rope {
            hangItem(index: drag.index)
        }
        updateBasketPilesVisibility()
    }

    private func beginDrag(index: Int, from origin: DragOrigin, at location: CGPoint) {
        dragState = (index, origin)

        if origin == .rope {
            itemNodes[index]?.removeFromParent()
            itemNodes[index] = nil
        }

        pickedClothes.texture = SKTexture(imageNamed: "dryingClothesPicked\(GameState.shared.itemProgress[index].dryingVariant)")
        pickedClothes.position = location
        pickedClothes.isHidden = false
        updateBasketPilesVisibility()
    }

    private func resolveDrop(index: Int, origin: DragOrigin, at position: CGPoint) {
        switch origin {
        case .basket:
            if rackZone.contains(position) {
                GameState.shared.itemProgress[index].isHungToDry = true
                hangItem(index: index)
            }
        case .rope:
            let progress = GameState.shared.itemProgress[index]
            if progress.isDried, dryBasketZone.contains(position) {
                GameState.shared.itemProgress[index].isHungToDry = false
                freeSlot(for: index)
            } else if !progress.isDried, basketZone.contains(position) {
                GameState.shared.itemProgress[index].isHungToDry = false
                GameState.shared.itemProgress[index].dryProgress = 0
                freeSlot(for: index)
            } else {
                hangItem(index: index)
            }
        }

        updateBasketPilesVisibility()
        updateBlowBar()
    }
}
