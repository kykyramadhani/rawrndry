//
//  ShopPopup.swift
//  Laundry
//
//  The shop: a grid of day boosts on the left, the selected one's description on the
//  right, and a BUY button under it. Opened from the SHOP button on the start screen —
//  boosts are bought between days and last exactly one day. Same convention as
//  SettingsPopup/HomeButton: "overlay node named X, removed on close".
//

import SpriteKit

/// A single thing the shop sells. Adding one is a new case plus its art and copy —
/// the grid, the description panel and the buying all read from here.
enum ShopItem: String, CaseIterable {
    // Order here is the order they appear in the grid.
    case gemMultiplier
    case addTime

    var price: Int {
        switch self {
        case .addTime, .gemMultiplier: return 3000
        }
    }

    var iconName: String {
        switch self {
        case .addTime: return AssetName.Shop.itemAddTime
        case .gemMultiplier: return AssetName.Shop.itemGemMultiplier
        }
    }

    var displayName: String {
        Loc.t(self == .addTime ? .shopItemAddTimeName : .shopItemGemMultiplierName)
    }

    var details: String {
        Loc.t(self == .addTime ? .shopItemAddTimeDesc : .shopItemGemMultiplierDesc)
    }

    /// Whether this boost is already paid for and running today.
    var isActive: Bool { GameState.shared.activeBoosts.contains(rawValue) }

    /// Turns the boost on for the day. The shop checks affordability and double-buying
    /// before calling this.
    func apply() {
        GameState.shared.activeBoosts.insert(rawValue)
        switch self {
        // Half again as long a shift: the 8AM–6PM clock still runs end to end, it just
        // takes more real time to get there, so more customers fit into the day.
        case .addTime: GameState.shared.extraShiftDuration += GameState.baseDayShiftRealDuration * 0.5
        case .gemMultiplier: GameState.shared.gemMultiplier = 2
        }
    }
}

extension SKScene {

    // MARK: - The SHOP button

    /// The start screen's shop button, top-left. Its label is drawn into the artwork, so it
    /// swaps per language once the other languages' art exists.
    @discardableResult
    func addShopButton(at position: CGPoint) -> SKSpriteNode {
        let button = makeLocalizedButton(
            base: AssetName.UI.shopButtonBase,
            fallbackImage: AssetName.UI.hudIndicator,
            text: Loc.t(.shopTitle),
            nodeName: "shopButton"
        )
        button.position = position
        button.zPosition = 100
        addChild(button)
        return button
    }

    /// A button whose label is baked into its art, falling back to plain art plus a text
    /// label while that art is still missing — so the shop works today and needs no code
    /// change when the localized images are dropped in.
    private func makeLocalizedButton(base: String, fallbackImage: String, text: String, nodeName: String) -> SKSpriteNode {
        let language = SettingsManager.shared.language

        if let imageName = AssetName.UI.localizedButtonImage(base, language: language) {
            let button = SKSpriteNode(imageNamed: imageName)
            button.name = nodeName
            return button
        }

        let button = SKSpriteNode(imageNamed: fallbackImage)
        button.name = nodeName

        let label = SKLabelNode(fontNamed: AssetName.Font.comica)
        label.text = text
        label.fontSize = 22
        label.fontColor = UIColor(red: 255.0/255.0, green: 247.0/255.0, blue: 234.0/255.0, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.zPosition = 1
        button.addChild(label)

        return button
    }

    @discardableResult
    func handleShopButtonTap(nodeName: String?) -> Bool {
        guard nodeName == "shopButton" else { return false }
        guard let button = childNode(withName: "shopButton") else {
            showShopPopup()
            return true
        }
        runButtonTapAnimation(on: button) { self.showShopPopup() }
        return true
    }

    // MARK: - Popup

    @discardableResult
    func showShopPopup() -> SKNode {
        childNode(withName: "shopOverlay")?.removeFromParent()

        let center = sceneCenter
        let frameSize = CGSize(width: min(size.width * 0.74, 620), height: size.height * 0.86)

        let overlay = SKNode()
        overlay.name = "shopOverlay"
        overlay.zPosition = 700
        addChild(overlay)

        let dim = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.35), size: size)
        dim.position = center
        overlay.addChild(dim)

        // The frame: a brown mat with a cream page inside it, matching the wooden-signboard
        // look the rest of the game's panels use.
        let frame = SKShapeNode(rectOf: frameSize, cornerRadius: 14)
        frame.fillColor = UIColor(red: 174.0/255.0, green: 112.0/255.0, blue: 60.0/255.0, alpha: 1.0)
        frame.strokeColor = UIColor(red: 107.0/255.0, green: 68.0/255.0, blue: 35.0/255.0, alpha: 1.0)
        frame.lineWidth = 4
        frame.position = center
        frame.zPosition = 1
        overlay.addChild(frame)

        let inset: CGFloat = 18
        let page = SKShapeNode(rectOf: CGSize(width: frameSize.width - inset, height: frameSize.height - inset), cornerRadius: 8)
        page.fillColor = UIColor(red: 243.0/255.0, green: 213.0/255.0, blue: 165.0/255.0, alpha: 1.0)
        page.strokeColor = .clear
        page.position = center
        page.zPosition = 2
        overlay.addChild(page)

        // Title tab, sitting on the frame's top edge.
        let titleTab = makeLocalizedButton(
            base: AssetName.UI.shopButtonBase,
            fallbackImage: AssetName.UI.hudIndicator,
            text: Loc.t(.shopTitle),
            nodeName: "shopTitleTab"
        )
        titleTab.name = nil          // decorative here — the button on the start screen owns that name
        titleTab.position = CGPoint(x: center.x, y: center.y + frameSize.height / 2)
        titleTab.zPosition = 5
        overlay.addChild(titleTab)

        let closeBtn = SKSpriteNode(imageNamed: AssetName.UI.btnClose)
        closeBtn.name = "shopClose"
        closeBtn.setScale(0.8)
        closeBtn.position = CGPoint(x: center.x + frameSize.width / 2 - 4, y: center.y + frameSize.height / 2 + 4)
        closeBtn.zPosition = 6
        overlay.addChild(closeBtn)

        let panelGap: CGFloat = 14
        let panelHeight = frameSize.height - inset - 28
        let leftWidth = (frameSize.width - inset - 28 - panelGap) * 0.55
        let rightWidth = (frameSize.width - inset - 28 - panelGap) * 0.45
        let leftCenterX = center.x - frameSize.width / 2 + inset / 2 + 14 + leftWidth / 2
        let rightCenterX = leftCenterX + leftWidth / 2 + panelGap + rightWidth / 2

        addShopPanel(to: overlay, center: CGPoint(x: leftCenterX, y: center.y), size: CGSize(width: leftWidth, height: panelHeight))
        addShopPanel(to: overlay, center: CGPoint(x: rightCenterX, y: center.y), size: CGSize(width: rightWidth, height: panelHeight))

        addShopGrid(to: overlay, center: CGPoint(x: leftCenterX, y: center.y), size: CGSize(width: leftWidth, height: panelHeight))
        refreshShopDetail(selected: nil)

        return overlay
    }

    private func addShopPanel(to overlay: SKNode, center: CGPoint, size panelSize: CGSize) {
        let panel = SKShapeNode(rectOf: panelSize, cornerRadius: 10)
        panel.fillColor = UIColor(red: 255.0/255.0, green: 243.0/255.0, blue: 214.0/255.0, alpha: 1.0)
        panel.strokeColor = .clear
        panel.position = center
        panel.zPosition = 3
        overlay.addChild(panel)
    }

    /// The item grid: slots laid out left-to-right from the panel's top-left corner, so a
    /// third item lands beside the first two without any layout maths changing.
    private func addShopGrid(to overlay: SKNode, center: CGPoint, size panelSize: CGSize) {
        let slotSize: CGFloat = 62
        let spacing: CGFloat = 12
        let padding: CGFloat = 16
        let perRow = max(1, Int((panelSize.width - padding * 2 + spacing) / (slotSize + spacing)))

        for (index, item) in ShopItem.allCases.enumerated() {
            let column = index % perRow
            let row = index / perRow

            let slot = SKSpriteNode(imageNamed: AssetName.Shop.slot)
            slot.name = "shopSlot_\(item.rawValue)"
            slot.size = CGSize(width: slotSize, height: slotSize)
            slot.position = CGPoint(
                x: center.x - panelSize.width / 2 + padding + slotSize / 2 + CGFloat(column) * (slotSize + spacing),
                y: center.y + panelSize.height / 2 - padding - slotSize / 2 - CGFloat(row) * (slotSize + spacing + 10)
            )
            slot.zPosition = 4
            overlay.addChild(slot)

            let icon = SKSpriteNode(imageNamed: item.iconName)
            let iconTexture = icon.texture!.size()
            let iconWidth = slotSize * 0.62
            icon.size = CGSize(width: iconWidth, height: iconWidth * iconTexture.height / iconTexture.width)
            icon.position = CGPoint(x: 0, y: slotSize * 0.09)
            icon.zPosition = 1
            slot.addChild(icon)

            let priceIcon = SKSpriteNode(imageNamed: AssetName.UI.gemIcon)
            priceIcon.size = CGSize(width: 13, height: 13)
            priceIcon.position = CGPoint(x: -14, y: -slotSize * 0.32)
            priceIcon.zPosition = 1
            slot.addChild(priceIcon)

            let priceLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
            priceLabel.text = "\(item.price)"
            priceLabel.fontSize = 13
            priceLabel.fontColor = UIColor(red: 74.0/255.0, green: 45.0/255.0, blue: 28.0/255.0, alpha: 1.0)
            priceLabel.horizontalAlignmentMode = .left
            priceLabel.verticalAlignmentMode = .center
            priceLabel.position = CGPoint(x: -5, y: -slotSize * 0.32)
            priceLabel.zPosition = 1
            slot.addChild(priceLabel)
        }
    }

    // MARK: - Detail panel

    /// Redraws the right-hand panel for whatever is selected — the dashed empty state when
    /// nothing is, the item's card and a live BUY button when something is.
    private func refreshShopDetail(selected: ShopItem?) {
        guard let overlay = childNode(withName: "shopOverlay") else { return }
        overlay.childNode(withName: "shopDetail")?.removeFromParent()

        let center = sceneCenter
        let frameSize = CGSize(width: min(size.width * 0.74, 620), height: size.height * 0.86)
        let inset: CGFloat = 18
        let panelGap: CGFloat = 14
        let panelHeight = frameSize.height - inset - 28
        let leftWidth = (frameSize.width - inset - 28 - panelGap) * 0.55
        let rightWidth = (frameSize.width - inset - 28 - panelGap) * 0.45
        let leftCenterX = center.x - frameSize.width / 2 + inset / 2 + 14 + leftWidth / 2
        let rightCenterX = leftCenterX + leftWidth / 2 + panelGap + rightWidth / 2

        let detail = SKNode()
        detail.name = "shopDetail"
        detail.zPosition = 5
        overlay.addChild(detail)

        let brown = UIColor(red: 143.0/255.0, green: 43.0/255.0, blue: 18.0/255.0, alpha: 1.0)
        let panelTop = center.y + panelHeight / 2

        let prompt = SKLabelNode(fontNamed: AssetName.Font.comica)
        prompt.text = Loc.t(.shopSelectPrompt)
        prompt.fontSize = 13
        prompt.fontColor = brown
        prompt.numberOfLines = 0
        prompt.preferredMaxLayoutWidth = rightWidth - 24
        prompt.verticalAlignmentMode = .top
        prompt.horizontalAlignmentMode = .center
        prompt.position = CGPoint(x: rightCenterX, y: panelTop - 16)
        detail.addChild(prompt)

        let cardHeight = panelHeight * 0.52
        let cardWidth = rightWidth - 28
        let cardCenter = CGPoint(x: rightCenterX, y: panelTop - 16 - prompt.frame.height - 12 - cardHeight / 2)

        guard let selected else {
            let empty = SKSpriteNode(imageNamed: AssetName.Shop.descriptionEmpty)
            empty.size = CGSize(width: cardWidth, height: cardHeight)
            empty.position = cardCenter
            detail.addChild(empty)
            addBuyButton(to: detail, item: nil, center: CGPoint(x: rightCenterX, y: center.y - panelHeight / 2 + 30))
            return
        }

        let card = SKSpriteNode(imageNamed: AssetName.Shop.descriptionCard)
        card.size = CGSize(width: cardWidth, height: cardHeight)
        card.position = cardCenter
        detail.addChild(card)

        let icon = SKSpriteNode(imageNamed: selected.iconName)
        let iconTexture = icon.texture!.size()
        let iconWidth = cardHeight * 0.30
        icon.size = CGSize(width: iconWidth, height: iconWidth * iconTexture.height / iconTexture.width)
        icon.position = CGPoint(x: -cardWidth * 0.32, y: cardHeight * 0.25)
        icon.zPosition = 1
        card.addChild(icon)

        let nameLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        nameLabel.text = selected.displayName
        nameLabel.fontSize = 14
        nameLabel.fontColor = brown
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: -cardWidth * 0.16, y: cardHeight * 0.31)
        nameLabel.zPosition = 1
        card.addChild(nameLabel)

        let priceIcon = SKSpriteNode(imageNamed: AssetName.UI.gemIcon)
        priceIcon.size = CGSize(width: 14, height: 14)
        priceIcon.position = CGPoint(x: -cardWidth * 0.16 + 7, y: cardHeight * 0.13)
        priceIcon.zPosition = 1
        card.addChild(priceIcon)

        let priceLabel = SKLabelNode(fontNamed: AssetName.Font.comica)
        priceLabel.text = selected.isActive ? Loc.t(.shopActiveToday) : "\(selected.price)"
        priceLabel.fontSize = 13
        priceLabel.fontColor = brown
        priceLabel.horizontalAlignmentMode = .left
        priceLabel.verticalAlignmentMode = .center
        priceLabel.position = CGPoint(x: -cardWidth * 0.16 + 18, y: cardHeight * 0.13)
        priceLabel.zPosition = 1
        priceIcon.isHidden = selected.isActive
        card.addChild(priceLabel)

        let details = SKLabelNode(fontNamed: AssetName.Font.comica)
        details.text = selected.details
        details.fontSize = 11
        details.fontColor = brown
        details.numberOfLines = 0
        details.preferredMaxLayoutWidth = cardWidth - 26
        details.verticalAlignmentMode = .top
        details.horizontalAlignmentMode = .left
        details.position = CGPoint(x: -cardWidth / 2 + 13, y: -cardHeight * 0.08)
        details.zPosition = 1
        card.addChild(details)

        addBuyButton(to: detail, item: selected, center: CGPoint(x: rightCenterX, y: center.y - panelHeight / 2 + 30))
    }

    /// The BUY button. Dimmed and inert when there's nothing selected, nothing left to buy,
    /// or not enough gems — the shop never offers a purchase it would then refuse.
    private func addBuyButton(to detail: SKNode, item: ShopItem?, center: CGPoint) {
        let button = makeLocalizedButton(
            base: AssetName.UI.buyButtonBase,
            fallbackImage: AssetName.UI.buttonMain,
            text: Loc.t(.shopBuy),
            nodeName: "shopBuy"
        )
        button.position = center
        button.zPosition = 2

        let affordable = item.map { !$0.isActive && GameState.shared.score >= $0.price } ?? false
        button.alpha = affordable ? 1.0 : 0.45
        detail.addChild(button)
    }

    // MARK: - Touch handling

    /// Call alongside handleTipPopupTap/handleSettingsPopupTouchesBegan from touchesBegan.
    @discardableResult
    func handleShopPopupTap(at location: CGPoint) -> Bool {
        guard let overlay = childNode(withName: "shopOverlay") else { return false }
        let name = tappedNodeName(at: location)

        if name == "shopClose" {
            overlay.removeFromParent()
            return true
        }

        if let name, name.hasPrefix("shopSlot_"),
           let item = ShopItem(rawValue: String(name.dropFirst("shopSlot_".count))) {
            selectShopItem(item, in: overlay)
            return true
        }

        if name == "shopBuy" {
            buySelectedShopItem(in: overlay)
            return true
        }

        // Anything else inside the shop just swallows the tap, same as the other popups.
        return true
    }

    /// Swaps the slot art so only the tapped item reads as selected, and redraws the detail.
    private func selectShopItem(_ item: ShopItem, in overlay: SKNode) {
        for other in ShopItem.allCases {
            guard let slot = overlay.childNode(withName: "shopSlot_\(other.rawValue)") as? SKSpriteNode else { continue }
            slot.texture = SKTexture(imageNamed: other == item ? AssetName.Shop.slotActive : AssetName.Shop.slot)
        }
        overlay.userData = NSMutableDictionary()
        overlay.userData?["selected"] = item.rawValue
        refreshShopDetail(selected: item)
    }

    private func buySelectedShopItem(in overlay: SKNode) {
        guard let raw = overlay.userData?["selected"] as? String,
              let item = ShopItem(rawValue: raw) else { return }

        guard !item.isActive else {
            showShopToast(Loc.t(.shopAlreadyActive))
            return
        }
        guard GameState.shared.score >= item.price else {
            showShopToast(Loc.t(.shopNotEnoughGems))
            return
        }

        GameState.shared.score -= item.price
        item.apply()
        AudioManager.shared.playSFX("complete")
        refreshShopDetail(selected: item)
    }

    /// A short message inside the shop, for the two cases where a tap can't go through.
    private func showShopToast(_ text: String) {
        guard let overlay = childNode(withName: "shopOverlay") else { return }
        overlay.childNode(withName: "shopToast")?.removeFromParent()

        let label = SKLabelNode(fontNamed: AssetName.Font.comica)
        label.name = "shopToast"
        label.text = text
        label.fontSize = 15
        label.fontColor = UIColor(red: 143.0/255.0, green: 43.0/255.0, blue: 18.0/255.0, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: sceneCenter.x, y: sceneCenter.y - size.height * 0.46)
        label.zPosition = 10
        overlay.addChild(label)

        label.run(.sequence([.wait(forDuration: 1.6), .fadeOut(withDuration: 0.3), .removeFromParent()]))
    }
}
