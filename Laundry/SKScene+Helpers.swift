//
//  SKScene+Helpers.swift
//  Laundry
//
//  Created by Aulia Agus on 01/07/26.
//
//  Shared helpers used by every scene: scene transitions, background/button
//  setup, and the standard button-tap feedback animation.

import SpriteKit

extension SKScene {

    /// Fades to the given scene, matching this scene's scale mode.
    func goTo(_ scene: SKScene, duration: TimeInterval = 0.8) {
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: .fade(withDuration: duration))
    }

    @discardableResult
    func addBackground(imageNamed name: String) -> SKSpriteNode {
        let background = SKSpriteNode(imageNamed: name)
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.size = size
        background.zPosition = -1
        background.name = "background"
        addChild(background)
        return background
    }

    /// Builds a tappable sprite button with an optional centered label, and adds it to the scene.
    @discardableResult
    func makeButton(imageNamed name: String, text: String? = nil, position: CGPoint, scale: CGFloat = 1.0, nodeName: String) -> SKSpriteNode {
        let button = SKSpriteNode(imageNamed: name)
        button.name = nodeName
        button.position = position
        button.setScale(scale)
        button.zPosition = 10
        addChild(button)

        if let text {
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = text
            label.fontSize = 22
            label.fontColor = .black
            label.verticalAlignmentMode = .center
            label.zPosition = 1
            button.addChild(label)
        }

        return button
    }

    @discardableResult
    func addDayLabel(day: Int) -> SKNode {
        let badge = SKShapeNode(rectOf: CGSize(width: 120, height: 44), cornerRadius: 12)
        badge.fillColor = .white
        badge.strokeColor = .black
        badge.position = CGPoint(x: 90, y: size.height - 60)
        badge.zPosition = 10
        addChild(badge)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "Day \(day)"
        label.fontSize = 20
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        badge.addChild(label)

        return badge
    }

    /// Scales the node down to 90% and back to its original size — the standard button-tap feedback.
    func runButtonTapAnimation(on node: SKNode, completion: @escaping () -> Void = {}) {
        let originalScale = node.xScale
        let scaleDown = SKAction.scale(to: originalScale * 0.9, duration: 0.08)
        let scaleUp = SKAction.scale(to: originalScale, duration: 0.08)
        node.run(.sequence([scaleDown, scaleUp]), completion: completion)
    }

    /// Returns the name of the tapped node, falling back to its parent (labels sit on top of their button).
    func tappedNodeName(at location: CGPoint) -> String? {
        let node = atPoint(location)
        return node.name ?? node.parent?.name
    }

    /// A label used for transient tips/hints — starts invisible; call `showHint(_:on:)` to display it.
    @discardableResult
    func makeHintLabel(position: CGPoint, fontSize: CGFloat = 18, maxWidth: CGFloat? = nil) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.fontSize = fontSize
        label.fontColor = .black
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = maxWidth ?? size.width * 0.8
        label.position = position
        label.zPosition = 20
        label.alpha = 0
        addChild(label)
        return label
    }

    /// Fades the hint label in, holds it, then fades it out.
    func showHint(_ text: String, on label: SKLabelNode) {
        label.removeAllActions()
        label.text = text
        label.alpha = 0
        label.run(.sequence([
            .fadeIn(withDuration: 0.2),
            .wait(forDuration: 2.0),
            .fadeOut(withDuration: 0.4)
        ]))
    }

    /// A rounded track + fill pair for showing scrub/task progress. Update the fill with `setProgressBarFill`.
    @discardableResult
    func makeProgressBar(position: CGPoint, width: CGFloat = 260, height: CGFloat = 24) -> (track: SKShapeNode, fill: SKShapeNode) {
        let track = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height / 2)
        track.strokeColor = .black
        track.fillColor = .white
        track.position = position
        track.zPosition = 10
        addChild(track)

        let fill = SKShapeNode()
        fill.fillColor = .systemBlue
        fill.strokeColor = .clear
        fill.zPosition = 1
        track.addChild(fill)

        return (track, fill)
    }

    /// Sets a progress-bar fill (created by `makeProgressBar`) to a 0...1 fraction of its track's size.
    func setProgressBarFill(_ fill: SKShapeNode, progress: CGFloat, width: CGFloat = 260, height: CGFloat = 24) {
        let clamped = max(0, min(1, progress))
        let filledWidth = width * clamped
        fill.path = CGPath(
            roundedRect: CGRect(x: -width / 2, y: -height / 2, width: filledWidth, height: height),
            cornerWidth: height / 2,
            cornerHeight: height / 2,
            transform: nil
        )
    }
}
