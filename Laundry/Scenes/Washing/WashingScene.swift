//
//  WashingScene.swift
//  Laundry
//
//  Drag a dirty item from the basket onto the washing stone, scrub it clean, then
//  drag it into the clean basket. Once an item's washProgress hits 1 it's picked up
//  by DryingScene's own basket automatically — no separate hand-off step needed.

import SpriteKit

class WashingScene: SKScene {

    private enum Interaction {
        case none
        case draggingFromPile(index: Int)
        case scrubbing(last: CGPoint)
        case draggingFromStone
    }

    private var itemNodes: [SKSpriteNode] = []
    private var stainOverlays: [SKSpriteNode?] = []

    private var activeIndex: Int?
    private var interaction: Interaction = .none

    private var leftBasketPiles: SKSpriteNode!
    private var rightBasketPiles: SKSpriteNode!
    private var helpButton: SKSpriteNode!
    private var hintLabel: SKLabelNode!

    private let itemSize = CGSize(width: 70, height: 90)
    private let spreadSize = CGSize(width: 150, height: 120)
    private let requiredScrubDistance: CGFloat = 800

    private var leftBasketPosition: CGPoint { CGPoint(x: size.width * 0.12, y: size.height * 0.22) }
    private var rightBasketPosition: CGPoint { CGPoint(x: size.width * 0.88, y: size.height * 0.22) }
    private var stoneCenter: CGPoint { CGPoint(x: size.width * 0.5, y: size.height * 0.45) }

    private var stoneZone: CGRect { CGRect(x: stoneCenter.x - 90, y: stoneCenter.y - 70, width: 180, height: 140) }
    private var leftBasketZone: CGRect { CGRect(x: leftBasketPosition.x - 60, y: leftBasketPosition.y - 50, width: 120, height: 110) }
    private var rightBasketZone: CGRect { CGRect(x: rightBasketPosition.x - 60, y: rightBasketPosition.y - 50, width: 120, height: 110) }

    override func didMove(to view: SKView) {
        GameState.shared.generateOrderIfNeeded()

        addBackground(imageNamed: "washingBackground")
        addCurrencyHUD(topLeftOrigin: CGPoint(x: size.width * 0.05, y: size.height * 0.90), day: GameState.shared.currentDay, coins: GameState.shared.score)
        addStationArrows(current: .washing)

        leftBasketPiles = addBasketVisual(at: leftBasketPosition)
        rightBasketPiles = addBasketVisual(at: rightBasketPosition)
        addSoaps()
        setupItems()

        helpButton = makeButton(
            imageNamed: AssetName.UI.btnInstruction,
            position: CGPoint(x: size.width * 0.93, y: size.height * 0.90),
            scale: 0.8,
            nodeName: "help"
        )

        hintLabel = makeHintLabel(position: CGPoint(x: size.width / 2, y: size.height * 0.85))

        AudioManager.shared.stopThemeBGM()
        AudioManager.shared.playRiverAmbience()
    }

    // MARK: - Setup

    @discardableResult
    private func addBasketVisual(at position: CGPoint) -> SKSpriteNode {
        let basket = SKSpriteNode(imageNamed: "washingBasket")
        basket.size = CGSize(width: 100, height: 78)
        basket.position = position
        basket.zPosition = 2
        addChild(basket)

        let piles = SKSpriteNode(imageNamed: "washingBasketPiles")
        piles.size = CGSize(width: 80, height: 46)
        piles.position = CGPoint(x: position.x, y: position.y + 18)
        piles.zPosition = 3
        addChild(piles)
        return piles
    }

    private func addSoaps() {
        let soap1 = SKSpriteNode(imageNamed: "washingSoap")
        soap1.size = CGSize(width: 64, height: 42)
        soap1.position = CGPoint(x: stoneCenter.x - 70, y: stoneCenter.y - 90)
        soap1.zPosition = 4
        addChild(soap1)

        let soap2 = SKSpriteNode(imageNamed: "washingSoap")
        soap2.size = CGSize(width: 64, height: 42)
        soap2.position = CGPoint(x: stoneCenter.x + 70, y: stoneCenter.y - 90)
        soap2.zPosition = 4
        addChild(soap2)
    }

    private func setupItems() {
        let types = GameState.shared.clothesTypes
        itemNodes = []
        stainOverlays = Array(repeating: nil, count: types.count)

        var dirtyCount = 0

        for (index, type) in types.enumerated() {
            let node = SKSpriteNode(imageNamed: type.imageName)
            node.name = "item-\(index)"
            node.zPosition = 5
            addChild(node)
            itemNodes.append(node)

            let progress = GameState.shared.itemProgress[index]

            if progress.isOnWashStone {
                activeIndex = index
                placeOnStone(index: index)
            } else if progress.isWashed {
                // Clean items merge into the basket's pile mound rather than showing
                // their own icon — they're no longer individually interactive anyway.
                node.isHidden = true
            } else {
                node.size = itemSize
                node.position = pileSlot(base: leftBasketPosition, slot: dirtyCount)
                dirtyCount += 1
            }
        }

        updateBasketPilesVisibility()
    }

    private func pileSlot(base: CGPoint, slot: Int) -> CGPoint {
        CGPoint(x: base.x + CGFloat(slot % 2) * 24 - 12, y: base.y - CGFloat(slot / 2) * 26)
    }

    private func countDirtyItems(excluding: Int?) -> Int {
        GameState.shared.itemProgress.indices.filter {
            $0 != excluding && $0 != activeIndex && !GameState.shared.itemProgress[$0].isWashed
        }.count
    }

    private func countCleanItems(excluding: Int?) -> Int {
        GameState.shared.itemProgress.indices.filter {
            $0 != excluding && $0 != activeIndex && GameState.shared.itemProgress[$0].isWashed
        }.count
    }

    private func updateBasketPilesVisibility() {
        leftBasketPiles.isHidden = countDirtyItems(excluding: nil) == 0
        rightBasketPiles.isHidden = countCleanItems(excluding: nil) == 0
    }

    /// Moves the given item's node onto the stone and shows/updates its stain overlay.
    private func placeOnStone(index: Int) {
        let node = itemNodes[index]
        node.texture = SKTexture(imageNamed: "washingClothes1")
        node.size = spreadSize
        node.position = stoneCenter
        node.zPosition = 5

        let progress = GameState.shared.itemProgress[index].washProgress
        let stain: SKSpriteNode
        if let existing = stainOverlays[index] {
            stain = existing
        } else {
            stain = SKSpriteNode(imageNamed: "washingStain")
            stain.size = CGSize(width: 60, height: 60)
            stain.position = CGPoint(x: 5, y: -5)
            stain.zPosition = 1
            node.addChild(stain)
            stainOverlays[index] = stain
        }
        stain.alpha = 1 - progress
        stain.isHidden = progress >= 1
    }

    /// Slides a just-cleaned item into the basket, then hides it so it merges into
    /// the basket's pile mound instead of sitting there showing its own icon.
    private func moveItemIntoCleanBasket(index: Int) {
        let node = itemNodes[index]
        node.run(.move(to: rightBasketPosition, duration: 0.2)) {
            node.isHidden = true
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let name = tappedNodeName(at: location)

        if handleTipPopupTap(at: location) { return }

        if handleStationArrowTap(nodeName: name, current: .washing) { return }

        if name == "help" {
            runButtonTapAnimation(on: helpButton) {
                self.showTipPopup(text: "Drag the clothes from the dirty piles and scrub it, then put in the clean piles")
            }
            return
        }

        guard case .none = interaction else { return }

        if let activeIndex {
            let progress = GameState.shared.itemProgress[activeIndex]
            guard itemNodes[activeIndex].contains(location) else { return }
            if progress.isWashed {
                interaction = .draggingFromStone
            } else {
                interaction = .scrubbing(last: location)
            }
            return
        }

        if let name, name.hasPrefix("item-"), let index = Int(name.dropFirst("item-".count)),
           !GameState.shared.itemProgress[index].isWashed {
            interaction = .draggingFromPile(index: index)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        switch interaction {
        case .draggingFromPile(let index):
            itemNodes[index].position = location

        case .scrubbing(let last):
            guard let activeIndex, itemNodes[activeIndex].contains(location) else { return }
            let distance = hypot(location.x - last.x, location.y - last.y)
            interaction = .scrubbing(last: location)

            var progress = GameState.shared.itemProgress[activeIndex]
            progress.washProgress = min(1, progress.washProgress + distance / requiredScrubDistance)
            GameState.shared.itemProgress[activeIndex] = progress

            stainOverlays[activeIndex]?.alpha = 1 - progress.washProgress
            AudioManager.shared.playScrubbing()

            if progress.isWashed {
                stainOverlays[activeIndex]?.isHidden = true
                AudioManager.shared.stopScrubbing()
                showHint("Clean! Drag it to the basket!", on: hintLabel)
            }

        case .draggingFromStone:
            itemNodes[activeIndex ?? 0].position = location

        case .none:
            break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        AudioManager.shared.stopScrubbing()
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        switch interaction {
        case .draggingFromPile(let index):
            resolvePileDrop(index: index, at: location)
        case .scrubbing:
            break
        case .draggingFromStone:
            resolveStoneDrop(at: location)
        case .none:
            break
        }

        interaction = .none
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        AudioManager.shared.stopScrubbing()
        switch interaction {
        case .draggingFromPile(let index):
            itemNodes[index].run(.move(to: pileSlot(base: leftBasketPosition, slot: countDirtyItems(excluding: index)), duration: 0.2))
        case .draggingFromStone:
            itemNodes[activeIndex ?? 0].run(.move(to: stoneCenter, duration: 0.2))
        default:
            break
        }
        interaction = .none
    }

    private func resolvePileDrop(index: Int, at position: CGPoint) {
        if activeIndex == nil, stoneZone.contains(position) {
            activeIndex = index
            var progress = GameState.shared.itemProgress[index]
            progress.isOnWashStone = true
            GameState.shared.itemProgress[index] = progress
            placeOnStone(index: index)
        } else {
            itemNodes[index].run(.move(to: pileSlot(base: leftBasketPosition, slot: countDirtyItems(excluding: index)), duration: 0.2))
        }
        updateBasketPilesVisibility()
    }

    private func resolveStoneDrop(at position: CGPoint) {
        guard let index = activeIndex else { return }

        if rightBasketZone.contains(position) {
            var progress = GameState.shared.itemProgress[index]
            progress.isOnWashStone = false
            GameState.shared.itemProgress[index] = progress
            activeIndex = nil

            moveItemIntoCleanBasket(index: index)
            showHint("Nice and clean!", on: hintLabel)
        } else {
            itemNodes[index].run(.move(to: stoneCenter, duration: 0.2))
        }
        updateBasketPilesVisibility()
    }
}
