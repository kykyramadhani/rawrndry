//
//  FoldingScene.swift
//  Laundry
//
//  Created by Aulia Agus on 01/07/26.
//
//  Drag a dry item from the basket onto the table, then swipe over it in all
//  four directions (down, right, up, left) to wrap it. Once every item is
//  wrapped, DONE returns to the customer.

import SpriteKit

class FoldingScene: SKScene {

    private enum Interaction {
        case none
        case draggingFromBasket(index: Int)
        case wrapping(start: CGPoint)
    }

    private var itemNodes: [SKSpriteNode] = []
    private var directionIndicators: [WrapDirection: SKSpriteNode] = [:]

    private var activeIndex: Int?
    private var interaction: Interaction = .none

    private var doneButton: SKSpriteNode!
    private var helpButton: SKSpriteNode!
    private var hintLabel: SKLabelNode!

    private let itemSize = CGSize(width: 70, height: 90)
    private let tableSize = CGSize(width: 200, height: 140)

    private var tableCenter: CGPoint { CGPoint(x: size.width * 0.5, y: size.height * 0.48) }
    private var tableZone: CGRect {
        CGRect(x: tableCenter.x - tableSize.width / 2, y: tableCenter.y - tableSize.height / 2, width: tableSize.width, height: tableSize.height)
    }
    private var basketPosition: CGPoint { CGPoint(x: size.width * 0.1, y: size.height * 0.78) }
    private var outputPosition: CGPoint { CGPoint(x: size.width * 0.9, y: size.height * 0.78) }

    override func didMove(to view: SKView) {
        addBackground(imageNamed: "bg-folding")
        addDayLabel(day: GameState.shared.currentDay)
        addStationArrows(current: .folding)

        addTableShape()
        addDirectionIndicators()
        addBasketVisual(at: basketPosition)
        addBasketVisual(at: outputPosition)
        setupItems()

        doneButton = makeButton(
            imageNamed: "main-button",
            text: "DONE",
            position: CGPoint(x: size.width * 0.85, y: size.height * 0.15),
            scale: 0.16,
            nodeName: "done"
        )

        helpButton = makeButton(
            imageNamed: "icon-question",
            position: CGPoint(x: size.width - 50, y: size.height - 60),
            scale: 0.025,
            nodeName: "help"
        )

        hintLabel = makeHintLabel(position: CGPoint(x: size.width / 2, y: size.height * 0.85))
    }

    // MARK: - Setup

    private func addTableShape() {
        let table = SKShapeNode(ellipseOf: tableSize)
        table.position = tableCenter
        table.fillColor = SKColor.white.withAlphaComponent(0.3)
        table.strokeColor = .darkGray
        table.lineWidth = 3
        table.zPosition = 1
        addChild(table)
    }

    private func addDirectionIndicators() {
        let offset: CGFloat = 90
        let configs: [(WrapDirection, CGPoint, CGFloat)] = [
            (.swipeDown, CGPoint(x: tableCenter.x, y: tableCenter.y + offset), -.pi / 2),
            (.swipeRight, CGPoint(x: tableCenter.x - offset * 1.3, y: tableCenter.y), 0),
            (.swipeUp, CGPoint(x: tableCenter.x, y: tableCenter.y - offset), .pi / 2),
            (.swipeLeft, CGPoint(x: tableCenter.x + offset * 1.3, y: tableCenter.y), .pi)
        ]

        for (direction, position, rotation) in configs {
            let arrow = SKSpriteNode(imageNamed: "arrow-right")
            arrow.size = CGSize(width: 30, height: 30)
            arrow.position = position
            arrow.zRotation = rotation
            arrow.alpha = 0
            arrow.zPosition = 2
            addChild(arrow)
            directionIndicators[direction] = arrow
        }
    }

    private func addBasketVisual(at position: CGPoint) {
        let basket = SKSpriteNode(imageNamed: "basket")
        basket.size = CGSize(width: 90, height: 70)
        basket.position = position
        basket.zPosition = 2
        addChild(basket)
    }

    private func setupItems() {
        let types = GameState.shared.clothesTypes
        itemNodes = []

        var basketCount = 0
        var outputCount = 0

        for (index, type) in types.enumerated() {
            let node = SKSpriteNode(imageNamed: type.imageName)
            node.size = itemSize
            node.name = "item-\(index)"
            node.zPosition = 5
            addChild(node)

            if GameState.shared.itemProgress[index].isFolded {
                node.position = pileSlot(base: outputPosition, slot: outputCount)
                outputCount += 1
            } else {
                node.position = pileSlot(base: basketPosition, slot: basketCount)
                basketCount += 1
            }

            itemNodes.append(node)
        }
    }

    private func pileSlot(base: CGPoint, slot: Int) -> CGPoint {
        CGPoint(x: base.x + CGFloat(slot % 2) * 24 - 12, y: base.y - CGFloat(slot / 2) * 26)
    }

    private func countBasketItems(excluding: Int?) -> Int {
        GameState.shared.itemProgress.indices.filter {
            $0 != excluding && $0 != activeIndex && !GameState.shared.itemProgress[$0].isFolded
        }.count
    }

    private func countOutputItems(excluding: Int?) -> Int {
        GameState.shared.itemProgress.indices.filter { $0 != excluding && GameState.shared.itemProgress[$0].isFolded }.count
    }

    private func refreshIndicators(for index: Int?) {
        for direction in WrapDirection.allCases {
            guard let indicator = directionIndicators[direction] else { continue }
            guard let index else {
                indicator.alpha = 0
                continue
            }
            let isDone = GameState.shared.itemProgress[index].wrapDirections.contains(direction)
            indicator.alpha = isDone ? 1.0 : 0.35
            indicator.color = .systemGreen
            indicator.colorBlendFactor = isDone ? 0.6 : 0
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let name = tappedNodeName(at: location)

        if handleStationArrowTap(nodeName: name, current: .folding) { return }

        if name == "help" {
            runButtonTapAnimation(on: helpButton) {
                self.showHint("Drag clothes onto the table, then swipe over it down, right, up, and left to wrap it!", on: self.hintLabel)
            }
            return
        }

        if name == "done" {
            handleDoneTapped()
            return
        }

        if let name, name.hasPrefix("item-"), let index = Int(name.dropFirst("item-".count)) {
            if activeIndex == index {
                interaction = .wrapping(start: location)
            } else if activeIndex == nil, !GameState.shared.itemProgress[index].isFolded {
                interaction = .draggingFromBasket(index: index)
            }
            return
        }

        // Anywhere else counts as the start of a wrap swipe as long as an item is on the
        // table — restricting this to tableZone used to miss swipes that naturally start
        // near the direction indicators, which sit outside that tighter rect.
        if activeIndex != nil {
            interaction = .wrapping(start: location)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if case .draggingFromBasket(let index) = interaction {
            itemNodes[index].position = touch.location(in: self)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        switch interaction {
        case .draggingFromBasket(let index):
            resolveBasketDrop(index: index)
        case .wrapping(let start):
            resolveWrapGesture(from: start, to: location)
        case .none:
            break
        }

        interaction = .none
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        interaction = .none
    }

    private func resolveBasketDrop(index: Int) {
        let node = itemNodes[index]

        if activeIndex == nil, tableZone.contains(node.position) {
            activeIndex = index
            node.run(.move(to: tableCenter, duration: 0.2))
            refreshIndicators(for: index)
        } else {
            let slot = countBasketItems(excluding: index)
            node.run(.move(to: pileSlot(base: basketPosition, slot: slot), duration: 0.2))
        }
    }

    private func resolveWrapGesture(from start: CGPoint, to end: CGPoint) {
        guard let index = activeIndex else { return }

        let dx = end.x - start.x
        let dy = end.y - start.y
        let minDistance: CGFloat = 30
        guard abs(dx) > minDistance || abs(dy) > minDistance else { return }

        let direction: WrapDirection
        if abs(dx) > abs(dy) {
            direction = dx > 0 ? .swipeRight : .swipeLeft
        } else {
            direction = dy > 0 ? .swipeUp : .swipeDown
        }

        guard !GameState.shared.itemProgress[index].wrapDirections.contains(direction) else {
            showHint("Already folded that side!", on: hintLabel)
            return
        }

        GameState.shared.itemProgress[index].wrapDirections.insert(direction)
        refreshIndicators(for: index)
        itemNodes[index].run(.sequence([.scale(to: 1.1, duration: 0.1), .scale(to: 1.0, duration: 0.1)]))

        if GameState.shared.itemProgress[index].isFolded {
            completeFolding(index: index)
        }
    }

    private func completeFolding(index: Int) {
        showHint("📦 Packed!", on: hintLabel)
        activeIndex = nil
        refreshIndicators(for: nil)

        let slot = countOutputItems(excluding: index)
        itemNodes[index].run(.move(to: pileSlot(base: outputPosition, slot: slot), duration: 0.3))
    }

    private func handleDoneTapped() {
        guard GameState.shared.isFullyFolded else {
            showHint("Wrap every item before you're done!", on: hintLabel)
            return
        }

        runButtonTapAnimation(on: doneButton) {
            self.goTo(CustomerOrderScene(size: self.size))
        }
    }
}
