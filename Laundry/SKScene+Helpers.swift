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

    /// The polished Day + Gem badges shown top-left on every gameplay scene (sun icon badge,
    /// gem icon badge, laid out left-to-right from `topLeftOrigin`).
    @discardableResult
    func addCurrencyHUD(topLeftOrigin: CGPoint, day: Int, coins: Int) -> (day: SKSpriteNode, gem: SKSpriteNode) {
        let horizontalSpacing: CGFloat = 15
        var currentX = topLeftOrigin.x

        let dayHud = SKSpriteNode(imageNamed: AssetName.UI.hudIndicator)
        dayHud.position = CGPoint(x: currentX + dayHud.size.width / 2, y: topLeftOrigin.y)
        dayHud.zPosition = 100
        addChild(dayHud)
        addHUDContent(to: dayHud, icon: AssetName.UI.sunIcon, text: "\(Loc.t(.day)) \(day)")

        currentX += dayHud.size.width + horizontalSpacing

        let gemHud = SKSpriteNode(imageNamed: AssetName.UI.hudIndicator)
        gemHud.position = CGPoint(x: currentX + gemHud.size.width / 2, y: topLeftOrigin.y)
        gemHud.zPosition = 100
        addChild(gemHud)
        addHUDContent(to: gemHud, icon: AssetName.UI.gemIcon, text: "\(coins)")

        return (dayHud, gemHud)
    }

    private func addHUDContent(to hud: SKSpriteNode, icon: String, text: String) {
        let content = SKNode()
        let iconNode = SKSpriteNode(imageNamed: icon)
        iconNode.position = .zero

        let label = SKLabelNode(fontNamed: AssetName.Font.comica)
        label.text = text
        label.fontSize = 24
        label.fontColor = UIColor(red: 255.0/255.0, green: 247.0/255.0, blue: 234.0/255.0, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: iconNode.size.width / 2 + 10, y: 0)

        content.addChild(iconNode)
        content.addChild(label)

        let totalWidth = (iconNode.size.width / 2) + 10 + label.frame.width
        content.position = CGPoint(x: -totalWidth / 2, y: 0)
        content.zPosition = 101
        hud.addChild(content)
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
    /// White text over a black drop-shadow copy (stashed in userData) so it reads over any background.
    @discardableResult
    func makeHintLabel(position: CGPoint, fontSize: CGFloat = 18, maxWidth: CGFloat? = nil) -> SKLabelNode {
        let shadow = SKLabelNode(fontNamed: "AvenirNext-Bold")
        shadow.fontSize = fontSize
        shadow.fontColor = .black
        shadow.numberOfLines = 0
        shadow.preferredMaxLayoutWidth = maxWidth ?? size.width * 0.8
        shadow.position = CGPoint(x: position.x + 2, y: position.y - 2)
        shadow.zPosition = 19
        shadow.alpha = 0
        addChild(shadow)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.fontSize = fontSize
        label.fontColor = .white
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = maxWidth ?? size.width * 0.8
        label.position = position
        label.zPosition = 20
        label.alpha = 0
        label.userData = NSMutableDictionary()
        label.userData?["shadowLabel"] = shadow
        addChild(label)
        return label
    }

    /// Fades the hint label (and its drop-shadow) in, holds it, then fades it out.
    func showHint(_ text: String, on label: SKLabelNode) {
        let fade = SKAction.sequence([
            .fadeIn(withDuration: 0.2),
            .wait(forDuration: 2.0),
            .fadeOut(withDuration: 0.4)
        ])

        label.removeAllActions()
        label.text = text
        label.alpha = 0
        label.run(fade)

        if let shadow = label.userData?["shadowLabel"] as? SKLabelNode {
            shadow.removeAllActions()
            shadow.text = text
            shadow.alpha = 0
            shadow.run(fade)
        }
    }

    /// The scene's visual center in its own coordinate space, accounting for anchorPoint —
    /// (0,0) for a centered-anchor scene, (size/2) for a default bottom-left-anchor scene.
    var sceneCenter: CGPoint {
        CGPoint(x: size.width * (0.5 - anchorPoint.x), y: size.height * (0.5 - anchorPoint.y))
    }

    /// Shows the wood-panel info popup (with a close button) used for the "i" tip on every
    /// scene. Replaces any popup already showing. Dismissed via `handleTipPopupTap(at:)`.
    @discardableResult
    func showTipPopup(text: String, footnote: String? = nil) -> SKNode {
        childNode(withName: "tipPopupOverlay")?.removeFromParent()

        let center = sceneCenter
        let panelSize = CGSize(width: min(size.width * 0.82, 360), height: footnote != nil ? 220 : 190)

        let overlay = SKNode()
        overlay.name = "tipPopupOverlay"
        overlay.zPosition = 500
        addChild(overlay)

        let panel = SKSpriteNode(imageNamed: AssetName.UI.popUpFrame)
        panel.size = panelSize
        panel.position = center
        overlay.addChild(panel)

        let label = SKLabelNode(fontNamed: AssetName.Font.comica)
        label.text = text.uppercased()
        label.fontSize = 22
        label.fontColor = .white
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = panelSize.width * 0.82
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: center.x, y: center.y + (footnote != nil ? 18 : 0))
        label.zPosition = 1
        overlay.addChild(label)

        if let footnote {
            let footnoteLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
            footnoteLabel.text = footnote
            footnoteLabel.fontSize = 13
            footnoteLabel.fontColor = .white
            footnoteLabel.numberOfLines = 0
            footnoteLabel.preferredMaxLayoutWidth = panelSize.width * 0.82
            footnoteLabel.verticalAlignmentMode = .center
            footnoteLabel.horizontalAlignmentMode = .center
            footnoteLabel.position = CGPoint(x: center.x, y: center.y - panelSize.height * 0.32)
            footnoteLabel.zPosition = 1
            overlay.addChild(footnoteLabel)
        }

        let closeBtn = SKSpriteNode(imageNamed: AssetName.UI.btnClose)
        closeBtn.name = "tipPopupClose"
        closeBtn.setScale(0.7)
        closeBtn.position = CGPoint(x: center.x + panelSize.width * 0.47, y: center.y + panelSize.height * 0.46)
        closeBtn.zPosition = 2
        overlay.addChild(closeBtn)

        return overlay
    }

    /// If a tip popup is showing, consumes this tap — dismissing on the close button, or just
    /// swallowing the tap otherwise — and returns true so the caller should stop processing it.
    @discardableResult
    func handleTipPopupTap(at location: CGPoint) -> Bool {
        guard childNode(withName: "tipPopupOverlay") != nil else { return false }
        if tappedNodeName(at: location) == "tipPopupClose" {
            childNode(withName: "tipPopupOverlay")?.removeFromParent()
        }
        return true
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
