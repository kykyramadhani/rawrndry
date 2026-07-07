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
    private var wetOverlays: [SKSpriteNode?] = []
    private var dragState: (index: Int, origin: DragOrigin)?

    private var basketNode: SKSpriteNode!
    private var basketPiles: SKSpriteNode!
    private var dryBasketNode: SKSpriteNode!
    private var dryBasketPiles: SKSpriteNode!
    private var pickedClothes: SKSpriteNode!

    private var helpButton: SKSpriteNode!
    private var hintLabel: SKLabelNode!
    private var statusLabel: SKLabelNode!
    private var blowBarFill: SKSpriteNode!
    private var blowPercentLabel: SKLabelNode!

    private let micEngine = AVAudioEngine()
    private var micPermissionGranted = false
    private var isBlowing = false

    private let itemSize = CGSize(width: 70, height: 90)
    private let blowBarWidth: CGFloat = 200
    private let blowBarHeight: CGFloat = 18

    private var ropeY: CGFloat { size.height * 0.78 }
    private var basketPosition: CGPoint { CGPoint(x: size.width * 0.15, y: size.height * 0.24) }
    private var dryBasketPosition: CGPoint { CGPoint(x: size.width * 0.85, y: size.height * 0.24) }
    private var rackZone: CGRect { CGRect(x: size.width * 0.15, y: ropeY - 60, width: size.width * 0.7, height: 90) }
    private var basketZone: CGRect { CGRect(x: basketPosition.x - 60, y: basketPosition.y - 50, width: 120, height: 110) }
    private var dryBasketZone: CGRect { CGRect(x: dryBasketPosition.x - 60, y: dryBasketPosition.y - 50, width: 120, height: 110) }

    override func didMove(to view: SKView) {
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
            position: CGPoint(x: size.width * 0.93, y: size.height * 0.90),
            scale: 0.8,
            nodeName: "help"
        )

        hintLabel = makeHintLabel(position: CGPoint(x: size.width / 2, y: size.height * 0.32))

        requestMicPermissionAndStart()
    }

    override func willMove(from view: SKView) {
        stopMicEngine()
    }

    // MARK: - Setup

    private func addRope() {
        let rope = SKSpriteNode(imageNamed: "dryingRope")
        rope.size = CGSize(width: size.width * 0.75, height: 8)
        rope.position = CGPoint(x: size.width * 0.55, y: ropeY)
        rope.zPosition = 3
        addChild(rope)
    }

    private func addBasketVisual() {
        basketNode = SKSpriteNode(imageNamed: "dryingBasket")
        basketNode.size = CGSize(width: 100, height: 78)
        basketNode.position = basketPosition
        basketNode.zPosition = 2
        addChild(basketNode)

        basketPiles = SKSpriteNode(imageNamed: "dryingBasketPiles")
        basketPiles.size = CGSize(width: 80, height: 46)
        basketPiles.position = CGPoint(x: basketPosition.x, y: basketPosition.y + 18)
        basketPiles.zPosition = 3
        addChild(basketPiles)

        dryBasketNode = SKSpriteNode(imageNamed: "dryingBasket")
        dryBasketNode.size = CGSize(width: 100, height: 78)
        dryBasketNode.position = dryBasketPosition
        dryBasketNode.zPosition = 2
        addChild(dryBasketNode)

        dryBasketPiles = SKSpriteNode(imageNamed: "dryingBasketPiles")
        dryBasketPiles.size = CGSize(width: 80, height: 46)
        dryBasketPiles.position = CGPoint(x: dryBasketPosition.x, y: dryBasketPosition.y + 18)
        dryBasketPiles.zPosition = 3
        addChild(dryBasketPiles)
    }

    private func setupPickedClothesNode() {
        pickedClothes = SKSpriteNode(imageNamed: "washingPickedClothes1")
        pickedClothes.size = itemSize
        pickedClothes.zPosition = 30
        pickedClothes.isHidden = true
        addChild(pickedClothes)
    }

    private func setupItems() {
        itemNodes = Array(repeating: nil, count: GameState.shared.clothesTypes.count)
        wetOverlays = Array(repeating: nil, count: GameState.shared.clothesTypes.count)

        var hungCount = 0
        for index in GameState.shared.itemProgress.indices where GameState.shared.itemProgress[index].isHungToDry {
            hangItem(index: index, slot: hungCount)
            hungCount += 1
        }

        updateBasketPilesVisibility()
        updateBlowBar()
    }

    private func makeHungItemNode(index: Int) -> SKSpriteNode {
        let node = SKSpriteNode(imageNamed: "dryingClothesHanged")
        node.size = itemSize
        node.name = "item-\(index)"
        node.zPosition = 5

        let wetOverlay = SKSpriteNode(color: UIColor.blue.withAlphaComponent(0.5), size: itemSize)
        wetOverlay.zPosition = 1
        let progress = GameState.shared.itemProgress[index].dryProgress
        wetOverlay.alpha = 1 - progress
        wetOverlay.isHidden = progress >= 1
        node.addChild(wetOverlay)
        wetOverlays[index] = wetOverlay

        return node
    }

    private func hangItem(index: Int, slot: Int) {
        let node = makeHungItemNode(index: index)
        node.position = rackSlotPosition(slot: slot)
        addChild(node)
        itemNodes[index] = node
    }

    private func rackSlotPosition(slot: Int) -> CGPoint {
        let spacing: CGFloat = 80
        let startX = size.width * 0.55 - spacing * 1.5
        return CGPoint(x: startX + CGFloat(slot) * spacing, y: ropeY - 55)
    }

    private func countHungItems(excluding: Int?) -> Int {
        GameState.shared.itemProgress.indices.filter { $0 != excluding && GameState.shared.itemProgress[$0].isHungToDry }.count
    }

    /// Items that have been washed but not yet hung or finished drying — the wet pile.
    private func countBasketItems() -> Int {
        GameState.shared.itemProgress.indices.filter {
            let progress = GameState.shared.itemProgress[$0]
            return progress.isWashed && !progress.isHungToDry && !progress.isDried
        }.count
    }

    /// Items that finished drying and were dragged off the rope into the dry basket.
    private func countDryBasketItems() -> Int {
        GameState.shared.itemProgress.indices.filter {
            let progress = GameState.shared.itemProgress[$0]
            return progress.isDried && !progress.isHungToDry
        }.count
    }

    private func updateBasketPilesVisibility() {
        basketPiles.isHidden = countBasketItems() == 0
        dryBasketPiles.isHidden = countDryBasketItems() == 0
    }

    private func addBlowBar() {
        let bg = SKSpriteNode(imageNamed: "progress-bar-bg")
        bg.size = CGSize(width: blowBarWidth, height: blowBarHeight)
        bg.position = CGPoint(x: size.width / 2, y: size.height * 0.12)
        bg.zPosition = 10
        addChild(bg)

        let fill = SKSpriteNode(imageNamed: "progress-bar-fill")
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.size = CGSize(width: 0, height: blowBarHeight - 4)
        fill.position = CGPoint(x: -blowBarWidth / 2, y: 0)
        fill.zPosition = 11
        bg.addChild(fill)
        blowBarFill = fill

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
                    self.showHint("Microphone access is required to dry clothes — enable it in Settings.", on: self.hintLabel)
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
            showHint("Couldn't start the microphone.", on: hintLabel)
            return
        }

        let inputNode = micEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }

        do {
            try micEngine.start()
        } catch {
            showHint("Couldn't start the microphone.", on: hintLabel)
        }
    }

    private func stopMicEngine() {
        micEngine.inputNode.removeTap(onBus: 0)
        micEngine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
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
        if power > -20 {
            if !isBlowing {
                isBlowing = true
                handleValidBlow()
            }
        } else {
            isBlowing = false
        }
    }

    // MARK: - Blow handling

    private func handleValidBlow() {
        let dryingIndices = GameState.shared.itemProgress.indices.filter {
            GameState.shared.itemProgress[$0].isHungToDry && GameState.shared.itemProgress[$0].dryProgress < 1
        }
        guard !dryingIndices.isEmpty else { return }

        for index in dryingIndices {
            let progress = min(1, GameState.shared.itemProgress[index].dryProgress + 0.12)
            GameState.shared.itemProgress[index].dryProgress = progress
            wetOverlays[index]?.alpha = 1 - progress
            wetOverlays[index]?.isHidden = progress >= 1
        }

        playSound("sfx-blow")
        swayAndFlash(indices: dryingIndices)
        updateBlowBar()

        if GameState.shared.isFullyDried {
            showStatus("All dry!")
            playSound("sfx-success")
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
            node.texture = SKTexture(imageNamed: "dryingClothesBlowed")
            node.run(sway) {
                guard GameState.shared.itemProgress[index].isHungToDry else { return }
                node.texture = SKTexture(imageNamed: "dryingClothesHanged")
            }
        }
    }

    /// Bar reflects actual drying progress (average of all hung items) toward 100% — not raw mic volume.
    private func updateBlowBar() {
        let hungProgress = GameState.shared.itemProgress.filter { $0.isHungToDry }.map { $0.dryProgress }
        let fraction = hungProgress.isEmpty ? 0 : hungProgress.reduce(0, +) / CGFloat(hungProgress.count)
        blowBarFill.size.width = blowBarWidth * fraction
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

    private func playSound(_ name: String) {
        run(.playSoundFileNamed("\(name).wav", waitForCompletion: false))
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let name = tappedNodeName(at: location)

        if handleTipPopupTap(at: location) { return }

        if handleStationArrowTap(nodeName: name, current: .drying) { return }

        if name == "help" {
            runButtonTapAnimation(on: helpButton) {
                self.showTipPopup(
                    text: "Make the blow sound on your microphone, don't blow too hard",
                    footnote: "*you can turn off microphone feature on setting button"
                )
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
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard dragState != nil, let touch = touches.first else { return }
        pickedClothes.position = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let drag = dragState else { return }
        dragState = nil
        pickedClothes.isHidden = true
        resolveDrop(index: drag.index, origin: drag.origin, at: pickedClothes.position)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let drag = dragState else { return }
        dragState = nil
        pickedClothes.isHidden = true
        if drag.origin == .rope {
            hangItem(index: drag.index, slot: countHungItems(excluding: nil))
        }
        updateBasketPilesVisibility()
    }

    private func beginDrag(index: Int, from origin: DragOrigin, at location: CGPoint) {
        dragState = (index, origin)

        if origin == .rope {
            itemNodes[index]?.removeFromParent()
            itemNodes[index] = nil
        }

        pickedClothes.position = location
        pickedClothes.isHidden = false
        updateBasketPilesVisibility()
    }

    private func resolveDrop(index: Int, origin: DragOrigin, at position: CGPoint) {
        switch origin {
        case .basket:
            if rackZone.contains(position) {
                GameState.shared.itemProgress[index].isHungToDry = true
                hangItem(index: index, slot: countHungItems(excluding: index))
            }
        case .rope:
            let progress = GameState.shared.itemProgress[index]
            if progress.isDried, dryBasketZone.contains(position) {
                GameState.shared.itemProgress[index].isHungToDry = false
            } else if !progress.isDried, basketZone.contains(position) {
                GameState.shared.itemProgress[index].isHungToDry = false
                GameState.shared.itemProgress[index].dryProgress = 0
            } else {
                hangItem(index: index, slot: countHungItems(excluding: index))
            }
        }

        relayoutHungItems()
        updateBasketPilesVisibility()
        updateBlowBar()
    }

    private func relayoutHungItems() {
        let hungIndices = GameState.shared.itemProgress.indices.filter { GameState.shared.itemProgress[$0].isHungToDry }
        for (slot, index) in hungIndices.enumerated() {
            itemNodes[index]?.run(.move(to: rackSlotPosition(slot: slot), duration: 0.2))
        }
    }
}
