//
//  DryingScene.swift
//  Laundry
//
//  Created by Aulia Agus on 01/07/26.
//
//  Drag wet items from the basket onto the line, then blow into the mic to dry
//  everything currently hung. Once hung, an item stays on the line (isHungToDry
//  persists in GameState); only dryness still changes as the player blows.

import SpriteKit
import AVFoundation

class DryingScene: SKScene {

    private var itemNodes: [SKSpriteNode] = []
    private var wetOverlays: [SKSpriteNode] = []

    private var draggingIndex: Int?

    private var helpButton: SKSpriteNode!
    private var hintLabel: SKLabelNode!
    private var statusLabel: SKLabelNode!
    private var blowBarFill: SKSpriteNode!

    private let micEngine = AVAudioEngine()
    private var micPermissionGranted = false
    private var isTooStrongActive = false
    private var isBlowing = false

    private let itemSize = CGSize(width: 70, height: 90)
    private let blowBarWidth: CGFloat = 200
    private let blowBarHeight: CGFloat = 18

    private var lineY: CGFloat { size.height * 0.78 }
    private var basketPosition: CGPoint { CGPoint(x: size.width * 0.12, y: size.height * 0.24) }
    private var rackZone: CGRect { CGRect(x: size.width * 0.15, y: lineY - 60, width: size.width * 0.7, height: 90) }

    override func didMove(to view: SKView) {
        addBackground(imageNamed: "bg-clothesline")
        addDayLabel(day: GameState.shared.currentDay)
        addStationArrows(current: .drying)

        addClothesline()
        addBasketVisual(at: basketPosition)
        addBlowBar()
        addStatusLabel()
        setupItems()

        helpButton = makeButton(
            imageNamed: "icon-question",
            position: CGPoint(x: size.width - 50, y: size.height - 60),
            scale: 0.025,
            nodeName: "help"
        )

        hintLabel = makeHintLabel(position: CGPoint(x: size.width / 2, y: size.height * 0.32))

        requestMicPermissionAndStart()
    }

    override func willMove(from view: SKView) {
        stopMicEngine()
    }

    // MARK: - Setup

    private func addClothesline() {
        let line = SKSpriteNode(imageNamed: "clothesline")
        line.size = CGSize(width: size.width * 0.75, height: 8)
        line.position = CGPoint(x: size.width * 0.55, y: lineY)
        line.zPosition = 3
        addChild(line)
    }

    private func addBasketVisual(at position: CGPoint) {
        let basket = SKSpriteNode(imageNamed: "basket")
        basket.size = CGSize(width: 100, height: 78)
        basket.position = position
        basket.zPosition = 2
        addChild(basket)
    }

    private func setupItems() {
        let types = GameState.shared.clothesTypes
        itemNodes = []
        wetOverlays = []

        var hungCount = 0
        var basketCount = 0

        for (index, type) in types.enumerated() {
            let node = SKSpriteNode(imageNamed: type.imageName)
            node.size = itemSize
            node.name = "item-\(index)"
            node.zPosition = 5
            addChild(node)

            let overlay = SKSpriteNode(color: .systemBlue, size: node.size)
            overlay.alpha = 1 - GameState.shared.itemProgress[index].dryProgress
            overlay.zPosition = 1
            node.addChild(overlay)

            if GameState.shared.itemProgress[index].isHungToDry {
                node.position = rackSlotPosition(slot: hungCount)
                hungCount += 1
                addPeg(at: node.position.x)
            } else {
                node.position = basketSlotPosition(slot: basketCount)
                basketCount += 1
            }

            itemNodes.append(node)
            wetOverlays.append(overlay)
        }
    }

    private func addPeg(at x: CGFloat) {
        let peg = SKSpriteNode(imageNamed: "clothespeg")
        peg.size = CGSize(width: 14, height: 20)
        peg.position = CGPoint(x: x, y: lineY)
        peg.zPosition = 4
        addChild(peg)
    }

    private func rackSlotPosition(slot: Int) -> CGPoint {
        let spacing: CGFloat = 80
        let startX = size.width * 0.55 - spacing * 1.5
        return CGPoint(x: startX + CGFloat(slot) * spacing, y: lineY - 55)
    }

    private func basketSlotPosition(slot: Int) -> CGPoint {
        CGPoint(x: basketPosition.x + CGFloat(slot % 2) * 24 - 12, y: basketPosition.y + CGFloat(slot / 2) * 26)
    }

    private func countHungItems(excluding: Int?) -> Int {
        GameState.shared.itemProgress.indices.filter { $0 != excluding && GameState.shared.itemProgress[$0].isHungToDry }.count
    }

    private func countBasketItems(excluding: Int?) -> Int {
        GameState.shared.itemProgress.indices.filter { $0 != excluding && !GameState.shared.itemProgress[$0].isHungToDry }.count
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
        guard !isTooStrongActive else { return }

        if power > -5 {
            isBlowing = false
            triggerTooStrong()
            return
        }

        if power > -20 {
            if !isBlowing {
                isBlowing = true
                handleValidBlow(power: power)
            }
        } else {
            isBlowing = false
        }
    }

    // MARK: - Blow handling

    private func handleValidBlow(power: Float) {
        var driedAny = false

        for index in GameState.shared.itemProgress.indices where GameState.shared.itemProgress[index].isHungToDry {
            guard GameState.shared.itemProgress[index].dryProgress < 1 else { continue }
            GameState.shared.itemProgress[index].dryProgress = min(1, GameState.shared.itemProgress[index].dryProgress + 0.12)
            wetOverlays[index].alpha = 1 - GameState.shared.itemProgress[index].dryProgress
            driedAny = true

            if GameState.shared.itemProgress[index].dryProgress >= 1 {
                showHint("✨ Dry!", on: hintLabel)
            }
        }

        guard driedAny else { return }

        playSound("sfx-blow")
        swayHungClothes()
        updateBlowBar(power: power)
    }

    private func swayHungClothes() {
        let degreesToRadians: (CGFloat) -> CGFloat = { $0 * .pi / 180 }
        let sway = SKAction.sequence([
            .rotate(toAngle: degreesToRadians(5), duration: 0.1, shortestUnitArc: true),
            .rotate(toAngle: degreesToRadians(-5), duration: 0.15, shortestUnitArc: true),
            .rotate(toAngle: 0, duration: 0.1, shortestUnitArc: true)
        ])
        for index in GameState.shared.itemProgress.indices where GameState.shared.itemProgress[index].isHungToDry {
            itemNodes[index].run(sway)
        }
    }

    private func updateBlowBar(power: Float) {
        let fraction = CGFloat((power - (-20)) / ((-5) - (-20))).clamped(to: 0...1)
        blowBarFill.size.width = blowBarWidth * fraction
    }

    private func triggerTooStrong() {
        let hungIndices = GameState.shared.itemProgress.indices.filter { GameState.shared.itemProgress[$0].isHungToDry }
        guard !hungIndices.isEmpty else { return }

        isTooStrongActive = true
        playSound("sfx-fail")
        showStatus("Too strong!")

        let slide = SKAction.moveBy(x: size.width, y: 0, duration: 0.4)
        slide.timingMode = .easeOut
        for index in hungIndices {
            itemNodes[index].run(slide)
        }

        run(.sequence([
            .wait(forDuration: 1.5),
            .run { [weak self] in self?.resetAfterTooStrong(hungIndices: hungIndices) }
        ]))
    }

    private func resetAfterTooStrong(hungIndices: [Int]) {
        hideStatus()

        for (slot, index) in hungIndices.enumerated() {
            GameState.shared.itemProgress[index].dryProgress = 0
            wetOverlays[index].alpha = 1
            itemNodes[index].position = rackSlotPosition(slot: slot)
        }

        isTooStrongActive = false
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

        if handleStationArrowTap(nodeName: name, current: .drying) { return }

        if name == "help" {
            runButtonTapAnimation(on: helpButton) {
                self.showHint("Drag clothes from the basket onto the line, then blow into the mic to dry them!", on: self.hintLabel)
            }
            return
        }

        if let name, name.hasPrefix("item-"), let index = Int(name.dropFirst("item-".count)) {
            guard !GameState.shared.itemProgress[index].isHungToDry else { return }
            draggingIndex = index
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let index = draggingIndex, let touch = touches.first else { return }
        itemNodes[index].position = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let index = draggingIndex else { return }
        draggingIndex = nil
        resolveDrop(index: index)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        draggingIndex = nil
    }

    private func resolveDrop(index: Int) {
        let node = itemNodes[index]

        if rackZone.contains(node.position) {
            GameState.shared.itemProgress[index].isHungToDry = true
            let slot = countHungItems(excluding: index)
            node.run(.move(to: rackSlotPosition(slot: slot), duration: 0.2))
            addPeg(at: rackSlotPosition(slot: slot).x)
        } else {
            let slot = countBasketItems(excluding: index)
            node.run(.move(to: basketSlotPosition(slot: slot), duration: 0.2))
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
