//
//  WashingScene.swift
//  Laundry
//
//  Created by Aulia Agus on 01/07/26.
//
//  Drag a dirty item from the basket onto the washboard, scrub it clean with the
//  hand, then drag it into the clean basket. Only one item can be on the board
//  at a time; wash progress persists in GameState so leaving mid-scrub is safe.

import SpriteKit
import CoreHaptics

class WashingScene: SKScene {

    private var itemNodes: [SKSpriteNode] = []
    private var stainNodes: [SKSpriteNode] = []

    private var boardIndex: Int?
    private var draggingIndex: Int?

    private var handNode: SKSpriteNode!
    private var isScrubbing = false

    private var helpButton: SKSpriteNode!
    private var hintLabel: SKLabelNode!
    private var boardShape: SKShapeNode!

    private var engine: CHHapticEngine?

    private let itemSize = CGSize(width: 70, height: 90)

    private var dirtyBasketPosition: CGPoint { CGPoint(x: size.width * 0.12, y: size.height * 0.3) }
    private var cleanBasketPosition: CGPoint { CGPoint(x: size.width * 0.88, y: size.height * 0.3) }
    private var boardPosition: CGPoint { CGPoint(x: size.width * 0.5, y: size.height * 0.5) }
    private var handStartPosition: CGPoint { CGPoint(x: size.width * 0.5, y: size.height * 0.16) }
    private var boardZoneRect: CGRect {
        CGRect(x: boardPosition.x - 90, y: boardPosition.y - 65, width: 180, height: 130)
    }
    private var cleanBasketZoneRect: CGRect {
        CGRect(x: cleanBasketPosition.x - 70, y: cleanBasketPosition.y - 60, width: 140, height: 120)
    }

    override func didMove(to view: SKView) {
        addBackground(imageNamed: "bg-river")
        addDayLabel(day: GameState.shared.currentDay)
        addStationArrows(current: .washing)

        addBasketVisual(at: dirtyBasketPosition)
        addBasketVisual(at: cleanBasketPosition)
        addWashboardZone()
        setupItems()

        handNode = SKSpriteNode(imageNamed: "hand")
        handNode.size = CGSize(width: 70, height: 70)
        handNode.position = handStartPosition
        handNode.zPosition = 20
        addChild(handNode)

        helpButton = makeButton(
            imageNamed: "icon-question",
            position: CGPoint(x: size.width - 50, y: size.height - 60),
            scale: 0.025,
            nodeName: "help"
        )

        hintLabel = makeHintLabel(position: CGPoint(x: size.width / 2, y: size.height * 0.85))

        prepareHaptics()
    }

    // MARK: - Setup

    private func addBasketVisual(at position: CGPoint) {
        let basket = SKSpriteNode(imageNamed: "basket")
        basket.size = CGSize(width: 100, height: 78)
        basket.position = position
        basket.zPosition = 2
        addChild(basket)
    }

    private func addWashboardZone() {
        boardShape = SKShapeNode(ellipseOf: CGSize(width: 160, height: 120))
        boardShape.position = boardPosition
        boardShape.fillColor = SKColor.white.withAlphaComponent(0.3)
        boardShape.strokeColor = .darkGray
        boardShape.lineWidth = 3
        boardShape.zPosition = 1
        addChild(boardShape)
    }

    private func setupItems() {
        let types = GameState.shared.clothesTypes
        itemNodes = []
        stainNodes = []

        var dirtyCount = 0
        var cleanCount = 0

        for (index, type) in types.enumerated() {
            let node = SKSpriteNode(imageNamed: type.imageName)
            node.size = itemSize
            node.name = "item-\(index)"
            node.zPosition = 5
            addChild(node)

            let stain = SKSpriteNode(imageNamed: GameState.shared.itemStains[index])
            stain.setScale(0.16)
            stain.zPosition = 1
            stain.alpha = 1 - GameState.shared.itemProgress[index].washProgress
            node.addChild(stain)

            if GameState.shared.itemProgress[index].isWashed {
                node.position = pileSlot(base: cleanBasketPosition, slot: cleanCount)
                cleanCount += 1
            } else {
                node.position = pileSlot(base: dirtyBasketPosition, slot: dirtyCount)
                dirtyCount += 1
            }

            itemNodes.append(node)
            stainNodes.append(stain)
        }
    }

    private func pileSlot(base: CGPoint, slot: Int) -> CGPoint {
        CGPoint(x: base.x + CGFloat(slot % 2) * 24 - 12, y: base.y + CGFloat(slot / 2) * 26)
    }

    private func countDirtyItems(excluding: Int?) -> Int {
        GameState.shared.itemProgress.indices.filter {
            $0 != excluding && $0 != boardIndex && !GameState.shared.itemProgress[$0].isWashed
        }.count
    }

    private func countCleanItems(excluding: Int?) -> Int {
        GameState.shared.itemProgress.indices.filter {
            $0 != excluding && $0 != boardIndex && GameState.shared.itemProgress[$0].isWashed
        }.count
    }

    // MARK: - Haptics

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {}
    }

    private func playHaptic() {
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [], relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {}
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let name = tappedNodeName(at: location)

        if handleStationArrowTap(nodeName: name, current: .washing) { return }

        if name == "help" {
            runButtonTapAnimation(on: helpButton) {
                self.showHint("Drag a dirty item onto the board, scrub it clean, then drag it to the clean basket!", on: self.hintLabel)
            }
            return
        }

        if let name, name.hasPrefix("item-"), let index = Int(name.dropFirst("item-".count)) {
            let isOnBoard = boardIndex == index
            let isInDirtyBasket = !GameState.shared.itemProgress[index].isWashed && !isOnBoard

            guard isOnBoard || isInDirtyBasket else { return }

            if isInDirtyBasket && boardIndex != nil {
                showHint("Finish the item on the board first!", on: hintLabel)
                return
            }

            draggingIndex = index
            return
        }

        if handNode.contains(location) {
            isScrubbing = true
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let index = draggingIndex {
            itemNodes[index].position = location
            return
        }

        guard isScrubbing else { return }
        handNode.position = location

        guard let boardIndex,
              GameState.shared.itemProgress[boardIndex].washProgress < 1,
              itemNodes[boardIndex].contains(location) else { return }

        GameState.shared.itemProgress[boardIndex].washProgress = min(1, GameState.shared.itemProgress[boardIndex].washProgress + 0.02)
        stainNodes[boardIndex].alpha = 1 - GameState.shared.itemProgress[boardIndex].washProgress
        playHaptic()

        if GameState.shared.itemProgress[boardIndex].washProgress >= 1 {
            showHint("Clean! Drag it to the clean basket.", on: hintLabel)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isScrubbing = false

        guard let index = draggingIndex else { return }
        draggingIndex = nil
        resolveDrop(index: index)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isScrubbing = false
        draggingIndex = nil
    }

    private func resolveDrop(index: Int) {
        let node = itemNodes[index]

        if boardIndex == index {
            if cleanBasketZoneRect.contains(node.position) && GameState.shared.itemProgress[index].isWashed {
                boardIndex = nil
                let slot = countCleanItems(excluding: index)
                node.run(.move(to: pileSlot(base: cleanBasketPosition, slot: slot), duration: 0.2))
            } else {
                node.run(.move(to: boardPosition, duration: 0.2))
            }
        } else if boardZoneRect.contains(node.position) && boardIndex == nil {
            boardIndex = index
            node.run(.move(to: boardPosition, duration: 0.2))
        } else {
            let slot = countDirtyItems(excluding: index)
            node.run(.move(to: pileSlot(base: dirtyBasketPosition, slot: slot), duration: 0.2))
        }
    }
}
