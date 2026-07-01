//
//  EndScene.swift
//  Laundry
//
//  Created by Aulia Agus on 01/07/26.
//

import SpriteKit

class EndScene: SKScene {

    private var okButton: SKSpriteNode!
    private var finishButton: SKSpriteNode!
    private var stars: [SKSpriteNode] = []

    private let cardSize = CGSize(width: 300, height: 380)

    override func didMove(to view: SKView) {
        addBackground(imageNamed: "bg-end")
        addDayLabel(day: GameState.shared.currentDay)

        let cardCenter = CGPoint(x: size.width / 2, y: size.height / 2)

        addRewardCard(at: cardCenter)
        addStars(at: cardCenter)
        addRewardLabel(at: cardCenter)
        addCoinReward(at: cardCenter)
        addButtons(at: cardCenter)

        animateStars()
    }

    // MARK: - Card contents

    private func addRewardCard(at center: CGPoint) {
        let card = SKSpriteNode(imageNamed: "reward-card")
        card.size = cardSize
        card.position = center
        card.zPosition = 5
        addChild(card)
    }

    private func addStars(at center: CGPoint) {
        let offsets: [CGFloat] = [-64, 0, 64]
        for offset in offsets {
            let star = SKSpriteNode(imageNamed: "icon-star-off")
            star.size = CGSize(width: 48, height: 48)
            star.position = CGPoint(x: center.x + offset, y: center.y + cardSize.height * 0.32)
            star.zPosition = 6
            addChild(star)
            stars.append(star)
        }
    }

    private func addRewardLabel(at center: CGPoint) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "REWARD"
        label.fontSize = 22
        label.fontColor = .black
        label.position = CGPoint(x: center.x, y: center.y + cardSize.height * 0.14)
        label.zPosition = 6
        addChild(label)
    }

    private func addCoinReward(at center: CGPoint) {
        let coinIcon = SKSpriteNode(imageNamed: "icon-coin")
        coinIcon.size = CGSize(width: 34, height: 34)
        coinIcon.position = CGPoint(x: center.x - 40, y: center.y)
        coinIcon.zPosition = 6
        addChild(coinIcon)

        let amountLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        amountLabel.text = formattedCoins(GameState.shared.coinsEarned)
        amountLabel.fontSize = 26
        amountLabel.fontColor = .black
        amountLabel.horizontalAlignmentMode = .left
        amountLabel.verticalAlignmentMode = .center
        amountLabel.position = CGPoint(x: center.x - 15, y: center.y)
        amountLabel.zPosition = 6
        addChild(amountLabel)
    }

    private func addButtons(at center: CGPoint) {
        okButton = makeButton(
            imageNamed: "main-button",
            text: "OK",
            position: CGPoint(x: center.x, y: center.y - cardSize.height * 0.22),
            scale: 0.22,
            nodeName: "ok"
        )

        finishButton = makeButton(
            imageNamed: "main-button",
            text: "FINISH",
            position: CGPoint(x: center.x, y: center.y - cardSize.height * 0.36),
            scale: 0.15,
            nodeName: "finish"
        )
    }

    // MARK: - Stars

    /// Percentage of the maximum possible payout this order could have earned (4000/item, minus tears).
    private func starCount() -> Int {
        let maxPossible = max(GameState.shared.clothesCount * 4000, 1)
        let percentage = CGFloat(GameState.shared.coinsEarned) / CGFloat(maxPossible) * 100

        if percentage >= 80 { return 3 }
        if percentage >= 40 { return 2 }
        return 1
    }

    private func animateStars() {
        let earned = starCount()

        for (index, star) in stars.enumerated() {
            guard index < earned else { continue }

            let delay = 0.3 * Double(index + 1)
            star.run(.sequence([
                .wait(forDuration: delay),
                .run { star.texture = SKTexture(imageNamed: "icon-star-on") },
                .scale(to: 1.3, duration: 0.1),
                .scale(to: 1.0, duration: 0.1)
            ]))
        }
    }

    // MARK: - Formatting

    private func formattedCoins(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        switch tappedNodeName(at: location) {
        case "ok":
            runButtonTapAnimation(on: okButton) {
                GameState.shared.score += GameState.shared.coinsEarned
                GameState.shared.resetForNewDay()
                self.goTo(CustomerOrderScene(size: self.size))
            }
        case "finish":
            runButtonTapAnimation(on: finishButton) {
                GameState.shared.resetAll()
                self.goTo(MainMenuScene(size: self.size))
            }
        default:
            break
        }
    }
}
