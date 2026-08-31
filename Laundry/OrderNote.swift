//
//  OrderNote.swift
//  Laundry
//
//  The paper order slip pinned to the top edge of the HUD, next to the day badge —
//  tap it to re-read what the current customer actually asked for without walking all
//  the way back to the front desk. Same convention as HomeButton/SettingsPopup:
//  "overlay node named X, removed on close".
//

import SpriteKit

private let paperCream = UIColor(red: 255.0/255.0, green: 247.0/255.0, blue: 234.0/255.0, alpha: 1.0)
private let inkBrown = UIColor(red: 143.0/255.0, green: 43.0/255.0, blue: 18.0/255.0, alpha: 1.0)
private let scribbleGrey = UIColor(red: 143.0/255.0, green: 43.0/255.0, blue: 18.0/255.0, alpha: 0.35)

extension SKScene {

    // MARK: - The slip

    /// Hangs a torn-bottom paper slip down from `topEdgeAnchor` (put that on the scene's top
    /// edge — the slip is drawn entirely below it, with a sliver above so it reads as tucked
    /// behind the edge rather than floating).
    @discardableResult
    func addOrderNote(topEdgeAnchor: CGPoint) -> SKNode {
        let width: CGFloat = 48
        let height: CGFloat = 62

        let note = SKNode()
        note.name = "orderNote"
        note.position = topEdgeAnchor
        note.zPosition = 100
        addChild(note)

        let paper = SKShapeNode(path: tornPaperPath(width: width, height: height))
        paper.fillColor = paperCream
        paper.strokeColor = UIColor(red: 74.0/255.0, green: 26.0/255.0, blue: 26.0/255.0, alpha: 1.0)
        paper.lineWidth = 3
        paper.lineJoin = .round
        // Not named — taps hit-test to the slip's own children, which fall back to the
        // parent's name via `tappedNodeName(at:)`.
        note.addChild(paper)

        let title = SKLabelNode(fontNamed: AssetName.Font.comica)
        title.text = Loc.t(.orderNoteTitle)
        title.fontSize = 11
        title.fontColor = inkBrown
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: -16)
        title.zPosition = 1
        note.addChild(title)

        // Scribble rows standing in for handwriting — the real order is in the popup.
        for (index, lineWidth) in [width * 0.64, width * 0.48].enumerated() {
            let line = SKShapeNode(rectOf: CGSize(width: lineWidth, height: 2.5), cornerRadius: 1.25)
            line.fillColor = scribbleGrey
            line.strokeColor = .clear
            line.position = CGPoint(x: 0, y: -30 - CGFloat(index) * 10)
            line.zPosition = 1
            note.addChild(line)
        }

        // A slow sway so the slip reads as something you can poke, not part of the background.
        let swayRight = SKAction.rotate(toAngle: 0.025, duration: 1.4)
        let swayLeft = SKAction.rotate(toAngle: -0.025, duration: 1.4)
        swayRight.timingMode = .easeInEaseOut
        swayLeft.timingMode = .easeInEaseOut
        note.run(.repeatForever(.sequence([swayRight, swayLeft])))

        return note
    }

    /// A rectangle whose bottom edge is torn into three humps, drawn hanging *down* from the
    /// origin (with a small sliver above it, hidden behind the screen edge).
    private func tornPaperPath(width: CGFloat, height: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let halfWidth = width / 2
        let overhang: CGFloat = 8         // tucked behind the top edge
        let tearHeight: CGFloat = 5

        path.move(to: CGPoint(x: -halfWidth, y: overhang))
        path.addLine(to: CGPoint(x: halfWidth, y: overhang))
        path.addLine(to: CGPoint(x: halfWidth, y: -height + tearHeight))

        let humps = 3
        let humpWidth = width / CGFloat(humps)
        for index in 0..<humps {
            let endX = halfWidth - humpWidth * CGFloat(index + 1)
            let controlX = endX + humpWidth / 2
            let dipsDown = index % 2 == 0
            path.addQuadCurve(
                to: CGPoint(x: endX, y: -height + tearHeight),
                control: CGPoint(x: controlX, y: -height + (dipsDown ? -tearHeight : tearHeight * 2.4))
            )
        }

        path.closeSubpath()
        return path
    }

    /// Call alongside handleTipPopupTap/handleHomeButtonTap from touchesBegan.
    @discardableResult
    func handleOrderNoteTap(nodeName: String?) -> Bool {
        guard nodeName == "orderNote" else { return false }
        guard let note = childNode(withName: "orderNote") else {
            showOrderPopup()
            return true
        }
        let bump = SKAction.sequence([
            .scale(to: 0.92, duration: 0.08),
            .scale(to: 1.0, duration: 0.08)
        ])
        note.run(bump) { self.showOrderPopup() }
        return true
    }

    // MARK: - Popup

    /// The order exactly as GameState has it: who ordered, which fragrance they insisted on
    /// (if any), and which of their clothes are already washed.
    @discardableResult
    func showOrderPopup() -> SKNode {
        childNode(withName: "orderPopupOverlay")?.removeFromParent()

        let state = GameState.shared
        let center = sceneCenter
        let panelSize = CGSize(width: min(size.width * 0.78, 360), height: 240)

        let overlay = SKNode()
        overlay.name = "orderPopupOverlay"
        overlay.zPosition = 500
        addChild(overlay)

        let panel = SKSpriteNode(imageNamed: AssetName.UI.popUpFrame)
        panel.size = panelSize
        panel.position = center
        overlay.addChild(panel)

        let title = SKLabelNode(fontNamed: AssetName.Font.comica)
        title.text = Loc.t(.orderNoteTitle)
        title.fontSize = 24
        title.fontColor = .white
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: center.x, y: center.y + panelSize.height * 0.32)
        title.zPosition = 1
        overlay.addChild(title)

        // Customer portrait, cropped to head-and-shoulders by an SKCropNode — the character
        // art is full-body, and shrinking all of it to fit here makes the face unreadable.
        let portraitTexture = SKTexture(imageNamed: state.currentCustomerImage)
        let portraitWidth: CGFloat = 74
        let portrait = SKSpriteNode(texture: portraitTexture)
        portrait.setScale(portraitWidth / portraitTexture.size().width)
        portrait.position = CGPoint(x: 0, y: -portrait.size.height * 0.28)

        let crop = SKCropNode()
        crop.maskNode = SKSpriteNode(color: .white, size: CGSize(width: portraitWidth, height: portraitWidth))
        crop.position = CGPoint(x: center.x - panelSize.width * 0.28, y: center.y + 6)
        crop.zPosition = 1
        crop.addChild(portrait)
        overlay.addChild(crop)

        let textX = center.x - panelSize.width * 0.12
        let requestedSoap = state.currentOrderItems.first?.requestedSoap

        let soapLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        soapLabel.text = "\(Loc.t(.orderNoteSoap)): \(requestedSoap?.displayName ?? Loc.t(.orderNoteAnySoap))"
        soapLabel.fontSize = 19
        soapLabel.fontColor = .white
        soapLabel.horizontalAlignmentMode = .left
        soapLabel.verticalAlignmentMode = .center
        soapLabel.position = CGPoint(x: textX, y: center.y + 34)
        soapLabel.zPosition = 1
        overlay.addChild(soapLabel)

        if let requestedSoap {
            let soapIcon = SKSpriteNode(imageNamed: AssetName.Item.washingSoap(id: requestedSoap.holderID))
            soapIcon.size = CGSize(width: 34, height: 34)
            soapIcon.position = CGPoint(x: textX + soapLabel.frame.width + 24, y: center.y + 34)
            soapIcon.zPosition = 1
            overlay.addChild(soapIcon)
        }

        let clothesLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        clothesLabel.text = "\(Loc.t(.orderNoteClothes)): \(state.currentOrderItems.count)"
        clothesLabel.fontSize = 19
        clothesLabel.fontColor = .white
        clothesLabel.horizontalAlignmentMode = .left
        clothesLabel.verticalAlignmentMode = .center
        clothesLabel.position = CGPoint(x: textX, y: center.y + 4)
        clothesLabel.zPosition = 1
        overlay.addChild(clothesLabel)

        addOrderChecklist(to: overlay, items: state.currentOrderItems,
                          origin: CGPoint(x: textX, y: center.y - 34))

        let closeBtn = SKSpriteNode(imageNamed: AssetName.UI.btnClose)
        closeBtn.name = "orderPopupClose"
        closeBtn.setScale(0.7)
        closeBtn.position = CGPoint(x: center.x + panelSize.width * 0.47, y: center.y + panelSize.height * 0.44)
        closeBtn.zPosition = 2
        overlay.addChild(closeBtn)

        return overlay
    }

    /// One thumbnail per item in the order, dimmed once that item is already washed — so the
    /// slip doubles as "what's left to do", not just "what was asked for".
    private func addOrderChecklist(to overlay: SKNode, items: [LaundryItem], origin: CGPoint) {
        let thumbnailSize: CGFloat = 38
        let spacing: CGFloat = 8

        for (index, item) in items.enumerated() {
            let isWashed = GameState.shared.itemProgress.indices.contains(index)
                && GameState.shared.itemProgress[index].isWashed

            let thumbnail = SKSpriteNode(imageNamed: AssetName.Item.washingPickedClothes(patternID: item.patternID))
            thumbnail.size = CGSize(width: thumbnailSize, height: thumbnailSize)
            thumbnail.position = CGPoint(x: origin.x + thumbnailSize / 2 + CGFloat(index) * (thumbnailSize + spacing), y: origin.y)
            thumbnail.zPosition = 1
            thumbnail.alpha = isWashed ? 0.35 : 1.0
            overlay.addChild(thumbnail)

            guard isWashed else { continue }
            let tick = SKLabelNode(fontNamed: AssetName.Font.comica)
            tick.text = "✓"
            tick.fontSize = 22
            tick.fontColor = UIColor(red: 0.44, green: 0.83, blue: 0.45, alpha: 1.0)
            tick.verticalAlignmentMode = .center
            tick.position = thumbnail.position
            tick.zPosition = 2
            overlay.addChild(tick)
        }
    }

    /// If the order popup is showing, consumes this tap — dismissing on the close button, or
    /// just swallowing it otherwise — and returns true so the caller stops processing it.
    @discardableResult
    func handleOrderPopupTap(at location: CGPoint) -> Bool {
        guard childNode(withName: "orderPopupOverlay") != nil else { return false }
        if tappedNodeName(at: location) == "orderPopupClose" {
            childNode(withName: "orderPopupOverlay")?.removeFromParent()
        }
        return true
    }
}
