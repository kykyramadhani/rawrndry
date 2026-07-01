//
//  CustomerOrderScene.swift
//  Laundry
//
//  Created by Aulia Agus on 01/07/26.
//
//  Doubles as the handoff scene: once the order is fully processed, the pile
//  shown here switches from a dirty preview to a draggable clean pile that
//  the player delivers to the customer to finish the day.

import SpriteKit

class CustomerOrderScene: SKScene {

    private var okButton: SKSpriteNode!
    private var tipButton: SKSpriteNode!
    private var helpButton: SKSpriteNode!
    private var hintLabel: SKLabelNode!

    private var customer: SKSpriteNode!
    private var speechBubble: SKSpriteNode!
    private var bubbleLabel: SKLabelNode!

    private var pile: SKNode!
    private var pileOriginalPosition = CGPoint.zero
    private var isDraggingPile = false
    private var dragOffset = CGPoint.zero
    private var isHandedOff = false
    private var pileIsDraggable = false

    private let customerSize = CGSize(width: 140, height: 200)
    private let itemSize = CGSize(width: 70, height: 90)

    private let validationTexts = ["Thank you!", "Perfect!", "Amazing work!", "So fresh!", "Wonderful!"]

    override func didMove(to view: SKView) {
        generateOrderIfNeeded()

        addBackground(imageNamed: "bg-customer")
        addDayLabel(day: GameState.shared.currentDay)
        addStationArrows(current: .customer)

        addCustomer()
        addSpeechBubble()
        pile = buildClothesPile()
        updateSpeechBubbleText()

        hintLabel = makeHintLabel(position: CGPoint(x: size.width / 2, y: size.height * 0.28))

        okButton = makeButton(
            imageNamed: "main-button",
            text: "OK",
            position: CGPoint(x: size.width * 0.78, y: size.height * 0.12),
            scale: 0.22,
            nodeName: "ok"
        )

        tipButton = makeButton(
            imageNamed: "btn-tip",
            text: "TIP",
            position: CGPoint(x: size.width * 0.5, y: size.height * 0.08),
            scale: 0.18,
            nodeName: "tip"
        )

        helpButton = makeButton(
            imageNamed: "icon-question",
            position: CGPoint(x: size.width - 50, y: size.height - 60),
            scale: 0.025,
            nodeName: "help"
        )
    }

    // MARK: - Order generation

    /// Only generates a fresh order the first time this scene loads for the current day —
    /// revisiting via the station arrows mid-order must never re-randomize it.
    private func generateOrderIfNeeded() {
        guard GameState.shared.orderGeneratedDay != GameState.shared.currentDay else { return }

        let day = GameState.shared.currentDay
        let maxItems: Int
        switch day {
        case 1: maxItems = 1
        case 2: maxItems = 2
        default: maxItems = 3
        }
        let count = day == 1 ? 1 : Int.random(in: 1...maxItems)

        GameState.shared.orderType = OrderType.allCases.randomElement() ?? .washOnly
        GameState.shared.clothesCount = count
        GameState.shared.clothesTypes = (0..<count).map { _ in
            ClothingType.allCases.randomElement() ?? .shirt
        }
        GameState.shared.itemStains = (0..<count).map { _ in "stain-\(Int.random(in: 1...3))" }
        GameState.shared.itemProgress = Array(repeating: LaundryItemProgress(), count: count)
        GameState.shared.tornItemsCount = 0
        GameState.shared.orderGeneratedDay = day
    }

    // MARK: - Scene setup

    private func addCustomer() {
        let imageName = GameState.shared.currentDay == 1 ? "customer-1" : "customer-2"
        customer = SKSpriteNode(imageNamed: imageName)
        customer.size = customerSize
        customer.position = CGPoint(x: size.width * 0.78, y: size.height * 0.42)
        customer.zPosition = 5
        addChild(customer)
    }

    private func addSpeechBubble() {
        speechBubble = SKSpriteNode(imageNamed: "speech-bubble")
        speechBubble.size = CGSize(width: 190, height: 110)
        speechBubble.position = CGPoint(x: size.width * 0.68, y: size.height * 0.68)
        speechBubble.zPosition = 6
        addChild(speechBubble)

        bubbleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        bubbleLabel.fontSize = 16
        bubbleLabel.fontColor = .black
        bubbleLabel.numberOfLines = 0
        bubbleLabel.preferredMaxLayoutWidth = speechBubble.size.width * 0.85
        bubbleLabel.verticalAlignmentMode = .center
        bubbleLabel.zPosition = 1
        speechBubble.addChild(bubbleLabel)
    }

    private func updateSpeechBubbleText() {
        if GameState.shared.isReadyForHandoff {
            bubbleLabel.text = "My clothes are ready?"
        } else {
            bubbleLabel.text = orderSummary()
        }
    }

    private func orderSummary() -> String {
        var counts: [ClothingType: Int] = [:]
        for type in GameState.shared.clothesTypes {
            counts[type, default: 0] += 1
        }

        let itemsText = ClothingType.allCases.compactMap { type -> String? in
            guard let count = counts[type], count > 0 else { return nil }
            return "\(count)x \(type.displayName)"
        }.joined(separator: ", ")

        return "\(itemsText) — \(GameState.shared.orderType.displayName)"
    }

    private func buildClothesPile() -> SKNode {
        pileOriginalPosition = CGPoint(x: size.width * 0.2, y: size.height * 0.25)
        pileIsDraggable = GameState.shared.isReadyForHandoff

        let container = SKNode()
        container.position = pileOriginalPosition
        container.zPosition = 5

        let spacing: CGFloat = 30
        for (index, type) in GameState.shared.clothesTypes.enumerated() {
            let clothing = SKSpriteNode(imageNamed: type.imageName)
            clothing.size = itemSize
            clothing.zRotation = CGFloat.random(in: -0.15...0.15)
            clothing.position = CGPoint(
                x: CGFloat.random(in: -10...10),
                y: CGFloat(index) * spacing
            )
            container.addChild(clothing)

            if !pileIsDraggable {
                let stainName = index < GameState.shared.itemStains.count ? GameState.shared.itemStains[index] : "stain-1"
                let stain = SKSpriteNode(imageNamed: stainName)
                stain.setScale(0.16)
                stain.zPosition = 1
                clothing.addChild(stain)
            }
        }

        addChild(container)
        return container
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let name = tappedNodeName(at: location)

        if handleStationArrowTap(nodeName: name, current: .customer) { return }

        switch name {
        case "ok":
            runButtonTapAnimation(on: okButton) {
                self.goTo(WashingScene(size: self.size))
            }
            return
        case "tip":
            runButtonTapAnimation(on: tipButton) {
                self.showHint("Tip: use the arrows to visit Washing, Drying, and Folding!", on: self.hintLabel)
            }
            return
        case "help":
            runButtonTapAnimation(on: helpButton) {
                self.showHint("Use the arrows to visit each station, then bring the clean laundry back here to hand it off.", on: self.hintLabel)
            }
            return
        default:
            break
        }

        guard pileIsDraggable, !isHandedOff, pile.calculateAccumulatedFrame().contains(location) else { return }
        isDraggingPile = true
        dragOffset = CGPoint(x: pile.position.x - location.x, y: pile.position.y - location.y)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDraggingPile, let touch = touches.first else { return }
        let location = touch.location(in: self)
        pile.position = CGPoint(x: location.x + dragOffset.x, y: location.y + dragOffset.y)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDraggingPile else { return }
        isDraggingPile = false

        let dropZone = customer.frame.insetBy(dx: -40, dy: -40)
        if dropZone.contains(pile.position) {
            handOffClothes()
        } else {
            pile.run(.move(to: pileOriginalPosition, duration: 0.3))
            showHint("Bring the clean clothes to the customer!", on: hintLabel)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDraggingPile = false
    }

    // MARK: - Handoff

    private func handOffClothes() {
        isHandedOff = true
        playSound("sfx-drop")

        pile.run(.move(to: customer.position, duration: 0.3)) { [weak self] in
            self?.completeHandoff()
        }
    }

    private func completeHandoff() {
        bubbleLabel.text = validationTexts.randomElement() ?? "Thank you!"
        playSound("sfx-success")

        calculateCoins()

        run(.sequence([
            .wait(forDuration: 1.5),
            .run { [weak self] in
                guard let self else { return }
                self.goTo(EndScene(size: self.size))
            }
        ]))
    }

    private func calculateCoins() {
        let base = GameState.shared.clothesCount * 4000
        let deduction = GameState.shared.tornItemsCount * 1000
        GameState.shared.coinsEarned = max(0, base - deduction)
    }

    private func playSound(_ name: String) {
        run(.playSoundFileNamed("\(name).wav", waitForCompletion: false))
    }
}
