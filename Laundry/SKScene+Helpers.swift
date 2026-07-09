//
//  SKScene+Helpers.swift
//  Laundry
//
//  Created by Aulia Agus on 01/07/26.
//
//  Shared helpers used by every scene: scene transitions, background/button
//  setup, and the standard button-tap feedback animation.

import SpriteKit
import CoreImage

/// The overlay node used by `showSpotlightTutorial` — a plain `SKNode` can't carry the stored
/// `bumpedTargets` list needed to restore each highlighted node's zPosition once the spotlight
/// moves on or is dismissed.
private final class SpotlightOverlayNode: SKNode {
    var bumpedTargets: [(target: SKNode, originalZPosition: CGFloat)] = []
}

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

    /// Dims the whole scene and makes every node in `targets` glow with a slow, stable-alpha
    /// breathing halo, with an optional caption speech bubble above them — a spotlight-style
    /// tutorial pointing at whatever the player should act on next. Pass `caption: nil` for a
    /// glow-only beat (e.g. to draw the eye first, before revealing the caption a moment later
    /// with a follow-up call). Purely visual: each target's zPosition is bumped above the dim
    /// rect so it reads as highlighted rather than dimmed, but touch handling is untouched, so
    /// tapping a target still works exactly as before. Replacing an active spotlight (calling
    /// this again, or `dismissSpotlightTutorial()`) restores every bumped target's original
    /// zPosition first — call it whenever a later tutorial step supersedes an earlier one.
    @discardableResult
    func showSpotlightTutorial(around targets: [SKNode], caption: String? = nil) -> SKNode {
        dismissSpotlightTutorial()
        guard !targets.isEmpty else { return SKNode() }

        let overlayZ: CGFloat = 400
        let edgeMargin: CGFloat = 16

        let overlay = SpotlightOverlayNode()
        overlay.name = "spotlightTutorialOverlay"
        overlay.zPosition = overlayZ
        overlay.alpha = 0
        addChild(overlay)

        let dim = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.62), size: size)
        dim.position = sceneCenter
        dim.zPosition = 0
        overlay.addChild(dim)

        var unionFrame: CGRect?
        for target in targets {
            let frame = target.calculateAccumulatedFrame()
            unionFrame = unionFrame.map { $0.union(frame) } ?? frame

            addBreathingGlow(for: target, frame: frame, to: overlay)

            // Bumped above the dim rect so it reads as spotlighted instead of dimmed. Restored
            // by dismissSpotlightTutorial() (or the next showSpotlightTutorial call) via
            // overlay.bumpedTargets, never left stuck at this elevated zPosition.
            overlay.bumpedTargets.append((target, target.zPosition))
            target.zPosition = overlayZ + 2
        }

        if let caption {
            let bubbleSize = CGSize(width: min(size.width * 0.72, 320), height: 96)
            let anchor = unionFrame ?? CGRect(origin: sceneCenter, size: .zero)

            // Prefer sitting above the target, but flip below it if there isn't enough headroom —
            // and always clamp both axes so the bubble (a big, roughly screen-width sprite) never
            // extends past the scene edges no matter how close to a corner its target sits.
            let bounds = CGRect(x: sceneCenter.x - size.width / 2, y: sceneCenter.y - size.height / 2,
                                 width: size.width, height: size.height)
            let halfBubbleW = bubbleSize.width / 2
            let halfBubbleH = bubbleSize.height / 2
            let gap: CGFloat = 24

            let spaceAbove = bounds.maxY - anchor.maxY
            let placeAbove = spaceAbove >= bubbleSize.height + gap + edgeMargin
            let rawY = placeAbove ? anchor.maxY + halfBubbleH + gap : anchor.minY - halfBubbleH - gap

            let clampedX = min(max(anchor.midX, bounds.minX + halfBubbleW + edgeMargin), bounds.maxX - halfBubbleW - edgeMargin)
            let clampedY = min(max(rawY, bounds.minY + halfBubbleH + edgeMargin), bounds.maxY - halfBubbleH - edgeMargin)

            let bubble = SKNode()
            bubble.position = CGPoint(x: clampedX, y: clampedY)
            bubble.zPosition = 5
            bubble.setScale(0)
            overlay.addChild(bubble)

            let bubbleBg = SKSpriteNode(imageNamed: AssetName.UI.speechBubble)
            bubbleBg.size = bubbleSize
            bubble.addChild(bubbleBg)

            let label = SKLabelNode(fontNamed: AssetName.Font.comica)
            label.text = caption.uppercased()
            label.fontSize = 18
            label.fontColor = UIColor(red: 143.0/255.0, green: 43.0/255.0, blue: 18.0/255.0, alpha: 1.0)
            label.numberOfLines = 0
            label.preferredMaxLayoutWidth = bubbleSize.width * 0.82
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.zPosition = 1
            bubble.addChild(label)

            bubble.run(.sequence([
                .wait(forDuration: 0.15),
                .scale(to: 1.05, duration: 0.25),
                .scale(to: 1.0, duration: 0.1)
            ]))
        }

        overlay.run(.fadeIn(withDuration: 0.25))

        return overlay
    }

    /// Single-target convenience for `showSpotlightTutorial(around:caption:)`.
    @discardableResult
    func showSpotlightTutorial(around target: SKNode, caption: String? = nil) -> SKNode {
        showSpotlightTutorial(around: [target], caption: caption)
    }

    /// Removes the active spotlight tutorial overlay, if any, restoring every target it bumped
    /// back to its original zPosition. Safe to call even when nothing is showing.
    func dismissSpotlightTutorial() {
        guard let overlay = childNode(withName: "spotlightTutorialOverlay") as? SpotlightOverlayNode else { return }
        overlay.bumpedTargets.forEach { $0.target.zPosition = $0.originalZPosition }
        overlay.removeFromParent()
    }

    /// If the active spotlight tutorial is showing and `location` lands on whatever it's
    /// currently highlighting, dismisses it — closing that step the instant the player actually
    /// taps the thing it was pointing at, instead of waiting for the next step (or scene
    /// transition) to clear it. Doesn't consume the touch — call this alongside, not instead
    /// of, the scene's own hit-testing for `location` so the tap still performs its real action.
    func dismissSpotlightTutorialIfTargetTapped(at location: CGPoint) {
        guard let overlay = childNode(withName: "spotlightTutorialOverlay") as? SpotlightOverlayNode else { return }
        guard overlay.bumpedTargets.contains(where: { $0.target.contains(location) }) else { return }
        dismissSpotlightTutorial()
    }

    /// A stable white glow standing in for a glow texture we don't have: a tinted,
    /// additively-blended copy of `target`'s own texture (so it hugs its exact silhouette
    /// rather than a generic shape), softened with a Gaussian blur. Alpha stays constant —
    /// only its size slowly breathes from small to large and back, on a loop.
    private func addBreathingGlow(for target: SKNode, frame: CGRect, to overlay: SKNode) {
        guard frame.width > 0, frame.height > 0 else { return }

        let glowColor = UIColor.white
        let glowSize = CGSize(width: frame.width * 1.25, height: frame.height * 1.25)

        let glowSprite: SKSpriteNode
        if let spriteTarget = target as? SKSpriteNode, let texture = spriteTarget.texture {
            glowSprite = SKSpriteNode(texture: texture)
        } else {
            glowSprite = SKSpriteNode(color: glowColor, size: glowSize)
        }
        glowSprite.size = glowSize
        glowSprite.color = glowColor
        glowSprite.colorBlendFactor = 1.0
        glowSprite.blendMode = .add

        // Floored so small targets (e.g. the ~38pt fold-direction arrows) still get a clearly
        // visible bloom — 12% of their own size blurs down to almost nothing at that scale.
        let blurRadius = max(max(frame.width, frame.height) * 0.12, 8)

        let blur = SKEffectNode()
        blur.shouldRasterize = true
        blur.filter = CIFilter(name: "CIGaussianBlur", parameters: [
            "inputRadius": blurRadius
        ])
        blur.alpha = 0.85
        blur.position = CGPoint(x: frame.midX, y: frame.midY)
        blur.zPosition = 1
        blur.setScale(0.96)
        blur.addChild(glowSprite)
        overlay.addChild(blur)

        let grow = SKAction.scale(to: 1.04, duration: 1.6)
        grow.timingMode = .easeInEaseOut
        let shrink = SKAction.scale(to: 0.96, duration: 1.6)
        shrink.timingMode = .easeInEaseOut
        blur.run(.repeatForever(.sequence([grow, shrink])))
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
