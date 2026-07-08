//
//  SettingsPopup.swift
//  Laundry
//
//  The gear button + its popup (SFX/music volume, language, microphone), shared by
//  every scene the same way SKScene+Helpers shares showTipPopup. Follows the same
//  "overlay node named X, removed on close" convention as showTipPopup/showRewardPopup.
//

import SpriteKit

/// At most one settings popup is ever open at a time (single-window game), so a single
/// shared holder for the presenting scene's close callback is simpler than threading it
/// through node userData.
private enum SettingsPopupState {
    static var onClose: (() -> Void)?
}

extension SKScene {

    // MARK: - Button

    @discardableResult
    func addSettingsButton() -> SKSpriteNode {
        let center = sceneCenter
        return makeButton(
            imageNamed: AssetName.UI.btnSettings,
            position: CGPoint(x: center.x + size.width * 0.43, y: center.y + size.height * 0.40),
            scale: 0.8,
            nodeName: "settingsButton"
        )
    }

    /// Call alongside handleTipPopupTap/handleStationArrowTap from touchesBegan. `onClose` fires
    /// once, when the popup is dismissed — DryingScene uses it to switch between mic and leaf input.
    @discardableResult
    func handleSettingsButtonTap(nodeName: String?, onClose: (() -> Void)? = nil) -> Bool {
        guard nodeName == "settingsButton" else { return false }
        showSettingsPopup(onClose: onClose)
        return true
    }

    // MARK: - Popup

    func showSettingsPopup(onClose: (() -> Void)? = nil) {
        if let onClose {
            SettingsPopupState.onClose = onClose
        }

        childNode(withName: "settingsPopupOverlay")?.removeFromParent()

        let center = sceneCenter
        let panelSize = CGSize(width: min(size.width * 0.56, 460), height: min(size.height * 0.68, 250))

        let overlay = SKNode()
        overlay.name = "settingsPopupOverlay"
        overlay.zPosition = 600
        overlay.userData = NSMutableDictionary()
        addChild(overlay)

        let panel = SKSpriteNode(imageNamed: AssetName.UI.popUpFrame)
        panel.size = panelSize
        panel.position = center
        overlay.addChild(panel)

        let title = SKLabelNode(fontNamed: AssetName.Font.comica)
        title.text = Loc.t(.settingsTitle)
        title.fontSize = 22
        title.fontColor = .white
        title.position = CGPoint(x: center.x, y: center.y + 88)
        title.zPosition = 1
        overlay.addChild(title)

        let rowSpacing: CGFloat = 42
        var rowY = center.y + 40

        addSliderRow(to: overlay, labelKey: .sfx, value: SettingsManager.shared.sfxVolume, y: rowY, center: center, controlName: "sfx")
        rowY -= rowSpacing
        addSliderRow(to: overlay, labelKey: .music, value: SettingsManager.shared.musicVolume, y: rowY, center: center, controlName: "music")
        rowY -= rowSpacing
        addToggleRow(
            to: overlay, labelKey: .language,
            leftText: "ENG", rightText: "IND",
            isLeftActive: SettingsManager.shared.language == .en,
            y: rowY, center: center, controlName: "language"
        )
        rowY -= rowSpacing
        addToggleRow(
            to: overlay, labelKey: .microphone,
            leftText: Loc.t(.on), rightText: Loc.t(.off),
            isLeftActive: SettingsManager.shared.microphoneEnabled,
            y: rowY, center: center, controlName: "microphone"
        )

        let closeBtn = SKSpriteNode(imageNamed: AssetName.UI.btnClose)
        closeBtn.name = "settingsPopupClose"
        closeBtn.setScale(0.55)
        closeBtn.position = CGPoint(x: center.x + panelSize.width * 0.48, y: center.y + panelSize.height * 0.46)
        closeBtn.zPosition = 2
        overlay.addChild(closeBtn)
    }

    private func addSliderRow(to overlay: SKNode, labelKey: LocKey, value: Float, y: CGFloat, center: CGPoint, controlName: String) {
        let label = SKLabelNode(fontNamed: AssetName.Font.comica)
        label.text = Loc.t(labelKey)
        label.fontSize = 18
        label.fontColor = .white
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: center.x - 195, y: y)
        label.zPosition = 1
        overlay.addChild(label)

        let trackWidth: CGFloat = 220
        let track = SKSpriteNode(imageNamed: AssetName.UI.slideBase)
        track.name = "sliderTrack-\(controlName)"
        track.size = CGSize(width: trackWidth, height: 20)
        track.position = CGPoint(x: center.x + 40, y: y)
        track.zPosition = 1
        overlay.addChild(track)

        let fill = SKShapeNode()
        fill.name = "sliderFill-\(controlName)"
        fill.fillColor = sliderFillColor
        fill.strokeColor = .clear
        fill.position = track.position
        fill.zPosition = 1.5
        overlay.addChild(fill)
        setSliderFillPath(fill, trackWidth: trackWidth, fraction: CGFloat(value))

        let thumb = SKSpriteNode(imageNamed: AssetName.UI.slider)
        thumb.name = "sliderThumb-\(controlName)"
        thumb.size = CGSize(width: 28, height: 28)
        thumb.position = CGPoint(x: track.position.x - trackWidth / 2 + trackWidth * CGFloat(value), y: y)
        thumb.zPosition = 2
        overlay.addChild(thumb)
    }

    /// The amber fill used by every slider/progress-bar style track in the game.
    var sliderFillColor: SKColor {
        SKColor(red: 1.0, green: 0.796, blue: 0.302, alpha: 1.0)
    }

    private func setSliderFillPath(_ fill: SKShapeNode, trackWidth: CGFloat, fraction: CGFloat) {
        let height: CGFloat = 14
        let filledWidth = trackWidth * max(0, min(1, fraction))
        fill.path = CGPath(
            roundedRect: CGRect(x: -trackWidth / 2, y: -height / 2, width: filledWidth, height: height),
            cornerWidth: height / 2,
            cornerHeight: height / 2,
            transform: nil
        )
    }

    private func addToggleRow(to overlay: SKNode, labelKey: LocKey, leftText: String, rightText: String, isLeftActive: Bool, y: CGFloat, center: CGPoint, controlName: String) {
        let label = SKLabelNode(fontNamed: AssetName.Font.comica)
        label.text = Loc.t(labelKey)
        label.fontSize = 18
        label.fontColor = .white
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: center.x - 195, y: y)
        label.zPosition = 1
        overlay.addChild(label)

        let spacing: CGFloat = 96
        overlay.addChild(makeToggleButton(text: leftText, isActive: isLeftActive, position: CGPoint(x: center.x + 20, y: y), nodeName: "toggle-\(controlName)-left"))
        overlay.addChild(makeToggleButton(text: rightText, isActive: !isLeftActive, position: CGPoint(x: center.x + 20 + spacing, y: y), nodeName: "toggle-\(controlName)-right"))
    }

    private func makeToggleButton(text: String, isActive: Bool, position: CGPoint, nodeName: String) -> SKSpriteNode {
        let button = SKSpriteNode(imageNamed: AssetName.UI.btnSecondary)
        button.name = nodeName
        button.size = CGSize(width: 84, height: 40)
        button.position = position
        button.zPosition = 1
        if !isActive {
            button.color = .darkGray
            button.colorBlendFactor = 0.75
        }

        let label = SKLabelNode(fontNamed: AssetName.Font.comica)
        label.text = text
        label.fontSize = 16
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        label.zPosition = 1
        button.addChild(label)

        return button
    }

    // MARK: - Touch handling

    /// Call first (or alongside handleTipPopupTap) in every scene's touchesBegan.
    @discardableResult
    func handleSettingsPopupTouchesBegan(at location: CGPoint) -> Bool {
        guard let overlay = childNode(withName: "settingsPopupOverlay") else { return false }
        let name = tappedNodeName(at: location)

        if name == "settingsPopupClose" {
            overlay.removeFromParent()
            let onClose = SettingsPopupState.onClose
            SettingsPopupState.onClose = nil
            onClose?()
            return true
        }

        if name == "toggle-language-left" || name == "toggle-language-right" {
            SettingsManager.shared.language = (name == "toggle-language-left") ? .en : .id
            showSettingsPopup()
            return true
        }

        if name == "toggle-microphone-left" || name == "toggle-microphone-right" {
            SettingsManager.shared.microphoneEnabled = (name == "toggle-microphone-left")
            showSettingsPopup()
            return true
        }

        if name == "sliderThumb-sfx" || name == "sliderTrack-sfx" {
            overlay.userData?["dragging"] = "sfx"
            updateSlider(named: "sfx", overlay: overlay, touchX: location.x)
            return true
        }

        if name == "sliderThumb-music" || name == "sliderTrack-music" {
            overlay.userData?["dragging"] = "music"
            updateSlider(named: "music", overlay: overlay, touchX: location.x)
            return true
        }

        // Tap anywhere else inside the popup just swallows the touch, same as showTipPopup.
        return true
    }

    /// Call at the top of touchesMoved, before any scene-specific drag logic.
    @discardableResult
    func handleSettingsPopupTouchesMoved(at location: CGPoint) -> Bool {
        guard let overlay = childNode(withName: "settingsPopupOverlay"),
              let dragging = overlay.userData?["dragging"] as? String else { return false }
        updateSlider(named: dragging, overlay: overlay, touchX: location.x)
        return true
    }

    /// Call at the top of touchesEnded/touchesCancelled, before any scene-specific drag logic.
    @discardableResult
    func handleSettingsPopupTouchesEnded() -> Bool {
        guard let overlay = childNode(withName: "settingsPopupOverlay"),
              overlay.userData?["dragging"] != nil else { return false }
        overlay.userData?["dragging"] = nil
        return true
    }

    private func updateSlider(named name: String, overlay: SKNode, touchX: CGFloat) {
        guard let track = overlay.childNode(withName: "sliderTrack-\(name)") as? SKSpriteNode,
              let thumb = overlay.childNode(withName: "sliderThumb-\(name)") as? SKSpriteNode,
              let fill = overlay.childNode(withName: "sliderFill-\(name)") as? SKShapeNode else { return }

        let trackWidth = track.size.width
        let minX = track.position.x - trackWidth / 2
        let fraction = max(0, min(1, (touchX - minX) / trackWidth))
        thumb.position.x = minX + trackWidth * fraction
        setSliderFillPath(fill, trackWidth: trackWidth, fraction: fraction)

        if name == "sfx" {
            SettingsManager.shared.sfxVolume = Float(fraction)
        } else {
            SettingsManager.shared.musicVolume = Float(fraction)
        }
        AudioManager.shared.refreshVolumes()
    }
}
