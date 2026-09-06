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

extension SKScene {

    // MARK: - The slip

    /// Hangs the order slip from `topEdgeAnchor` — put that on the scene's top edge and the
    /// art hangs entirely below it. Anchored at its own top edge so the idle sway pivots from
    /// where it's pinned rather than swinging about its middle.
    @discardableResult
    func addOrderNote(topEdgeAnchor: CGPoint) -> SKSpriteNode {
        let width: CGFloat = 48

        let note = SKSpriteNode(imageNamed: AssetName.UI.orderNote(language: SettingsManager.shared.language))
        note.name = "orderNote"
        note.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        note.size = CGSize(width: width, height: width * note.texture!.size().height / note.texture!.size().width)
        note.position = topEdgeAnchor
        note.zPosition = 100
        addChild(note)

        // A slow sway so the slip reads as something you can poke, not part of the background.
        let swayRight = SKAction.rotate(toAngle: 0.025, duration: 1.4)
        let swayLeft = SKAction.rotate(toAngle: -0.025, duration: 1.4)
        swayRight.timingMode = .easeInEaseOut
        swayLeft.timingMode = .easeInEaseOut
        note.run(.repeatForever(.sequence([swayRight, swayLeft])))

        return note
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
